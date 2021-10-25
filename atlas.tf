#################################################################
#          Terraform file depends on variables.tf               #
#################################################################

#################################################################
#          Terraform file depends on locals.tf                  #
#################################################################

# Some remaining variables are still hardcoded, such Atlas shape 
# details. There are only used once, and most likely they are 
# not required to change

#################################################################
##################### MONGODB ATLAS SECTION #####################
#################################################################

provider "mongodbatlas" {
  # variable are provided via ENV
  # public_key = ""
  # private_key  = ""
}

resource "mongodbatlas_project" "proj1" {
  name   = local.project_id
  org_id = local.organization_id
}

resource "mongodbatlas_network_container" "test" {
  project_id       = mongodbatlas_project.proj1.id
  atlas_cidr_block = local.atlas_cidr_block
  provider_name    = local.provider_name
  region_name      = local.region
}

# Peering for project Project
resource "mongodbatlas_network_peering" "test" {
  accepter_region_name   = local.aws_region
  project_id             = mongodbatlas_project.proj1.id
  container_id           = mongodbatlas_network_container.test.container_id
  provider_name          = local.provider_name
  route_table_cidr_block = local.aws_route_cidr_block
  vpc_id                 = aws_vpc.vpc.id
  aws_account_id         = var.aws_account_id
}

resource "mongodbatlas_project_ip_access_list" "test" {
  project_id = mongodbatlas_project.proj1.id
  # We are adding IP address of 1 vm as a work around
  cidr_block = local.aws_subnet1_cidr_block
  comment    = aws_subnet.subnet1.arn
}

resource "mongodbatlas_cluster" "this" {
 name                  = local.cluster_name
 project_id            = mongodbatlas_project.proj1.id

 replication_factor           = 3
 cloud_backup                 = true
 auto_scaling_disk_gb_enabled = true
 mongo_db_major_version       = "5.0"

 provider_name               = local.provider_name
 provider_instance_size_name = local.atlas_size_name
 provider_region_name        = local.region
}

# This output all connection strings. For Private Network Peering
# one needs Custom DNS AWS enabled 
output "atlasclusterstring" {
   value = mongodbatlas_cluster.this.connection_strings[0]
}

# DATABASE USER
resource "mongodbatlas_database_user" "user1" {
  username           = local.admin_username
  password           = var.admin_password
  project_id         = mongodbatlas_project.proj1.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
  }
  labels {
    key   = "Name"
    value = local.admin_username
  }
  scopes {
    name = mongodbatlas_cluster.this.name
    type = "CLUSTER"
  }
}

output "user1" {
  value = mongodbatlas_database_user.user1.username
}
