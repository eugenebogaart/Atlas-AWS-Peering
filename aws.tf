provider "aws" {
  region  = local.aws_region
}

resource "aws_vpc" "vpc" {
  cidr_block = local.aws_route_cidr_block
  # Required to resolve hostname to internal addresses
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"

  tags = local.tags
}

resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = local.aws_subnet1_cidr_block
 
  tags = merge(
    local.tags, 
    { 
      Name = "${local.prefix}-terraform-provisioned"
    })
}

resource "aws_internet_gateway" "main_gw" {
  vpc_id = aws_vpc.vpc.id
  tags = local.tags 
}

resource "aws_route_table" "main_route" {
  vpc_id = aws_vpc.vpc.id
  route   { 
      cidr_block = local.atlas_cidr_block
      vpc_peering_connection_id = mongodbatlas_network_peering.test.connection_id
    }
  
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.main_gw.id
    }

  tags = local.tags
}

resource "aws_route_table_association" "main-subnet" {
  subnet_id = aws_subnet.subnet1.id
  route_table_id = aws_route_table.main_route.id
}

resource "aws_security_group" "main" {
  vpc_id = aws_vpc.vpc.id
  egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"   
    // Put your office or home address in it!
    cidr_blocks = [ local.provisoning_address_cdr ]
  }

  tags = local.tags
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = mongodbatlas_network_peering.test.connection_id
  auto_accept = true

  tags = {
    Side = "Accepter by Eugene's terraform script"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = local.aws_ec2_instance
  key_name        = var.key_name
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id       = aws_subnet.subnet1.id
  associate_public_ip_address = true

  #  Timing seems to be an issue. When able to login 
  #  some commands fail, therefor, sleep 10.
  
  provisioner "remote-exec" {
    inline = concat(local.python, local.mongodb)
  }

  connection {
    host        = aws_instance.web.public_ip
    agent       = false
    private_key = file(var.private_key_path)
    user        = "ubuntu"
  }

  tags = {
    OwnerContact = "eugene@mongodb.com"
    Name = local.aws_ec2_name
    provisioner = "Terraform"
    owner = "eugene.bogaart"
    expire-on = "2021-11-11"
    purpose = "opportunity"
  }
}

output "Virtual_Machine_Address" {
  description = "Virtual Machine Address"
  value = aws_instance.web.public_ip
}
