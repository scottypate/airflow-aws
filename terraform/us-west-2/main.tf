terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  region = "us-west-2"
}

# Configure the AWS Provider
provider "aws" {
  region = local.region
}

module "airflow" {
  source   = "../modules/airflow"
  region   = local.region
  vpc_cidr = "10.1.0.0/16"
}

module "docker_registry" {
  source = "../modules/docker-registry"
}
