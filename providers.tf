terraform {
  cloud {
    organization = "Infrastructure_State"
    workspaces {
      name = "backend_config"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
