terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.29"
    }
  }
}


provider "aws" {
  region = "us-east-1" # CloudFront expects ACM resources in us-east-1 region only
}
