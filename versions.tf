terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "= 3.6.0"
    }
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "~> 1.0.2"
    }
  }
  required_version = ">= 0.13"
}
