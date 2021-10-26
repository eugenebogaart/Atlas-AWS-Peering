locals {
  # Generic project prefix, to rename most components
  prefix                = "EB"    
  # New empty Atlas project name to create in organization
  project_name           = "AWS-Peered-project"
  # Atlas region, https://docs.atlas.mongodb.com/reference/microsoft-azure/#microsoft-azure
  region                = "EU_WEST_1"
  # Atlas cluster name
  cluster_name		      = "${local.prefix}-Cluster"    
  # Atlas Pulic providor
  provider_name         = "AWS"
  # Atlas size name 
  atlas_size_name       = "M10"
  # Atlas cluster Cidr Block no overlapping with AWS
  atlas_cidr_block      = "10.10.5.0/24"

  # AWS Region
  aws_region            = "eu-west-1"
  # AWS CIDR block for new SG/VPC/Subnet/Routing
  # make sure this unique in your AWS account
  aws_route_cidr_block  = "10.11.4.0/23"
  # AWS Subnet block (first 256)
  aws_subnet1_cidr_block = "10.11.4.0/24"
  # AWS Subnet block (second 256)
  aws_subnet2_cidr_block = "10.11.5.0/24"

  # Atlas & Azure vm user_name
  admin_username        = "demouser1"
  # Instance type to use for testing
  aws_ec2_instance      = "t3.medium"
  # Instance name
  aws_ec2_name          = "${local.prefix}-vm"

  # Stuff to install in virtual machine
  python = [
      "sleep 10",
      "sudo apt-get -y update",
	    "sudo apt-get -y install python3-pip",
	    "sudo pip3 install pymongo==3.9.0",
	    "sudo pip3 install dnspython"
  ]
  mongodb = [
      "wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -",
      "echo 'deb [ arch=amd64,arm64 ] http://repo.mongodb.com/apt/ubuntu bionic/mongodb-enterprise/5.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-enterprise.list",
      "sudo apt-get update",
      "sudo apt-get install -y mongodb-enterprise mongodb-enterprise-shell mongodb-enterprise-tools"
  ]

  # Generic tag
  tags = { 
    Name = "${local.prefix}-tf-provisioned"
    OwnerContact = "eugene@mongodb.com"
    expire-on = timeadd(timestamp(), "760h")
    purpose = "opportunity"
  }
}

terraform {
  required_version = ">= 0.13.05"
}
