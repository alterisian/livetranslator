########################################################################################################################
# AWS provider setup with remote backend on S3
########################################################################################################################
terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "boquercom-tfstate"
    key     = "aws/boquercom.tfstate"
  }
}

provider "aws" {
  profile = "bcm_${terraform.workspace}"
  region  = var.region
}
