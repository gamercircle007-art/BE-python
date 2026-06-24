# Paythan Infrastructure - Terraform skeleton
# Target: AWS ECS Fargate + RDS PostgreSQL + ElastiCache Redis + ALB
#
# Usage:
#   cd infra/terraform
#   terraform init
#   terraform plan -var-file=environments/dev.tfvars
#   terraform apply -var-file=environments/dev.tfvars

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment for remote state (recommended for teams)
  # backend "s3" {
  #   bucket         = "paythan-terraform-state"
  #   key            = "paythan/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "paythan-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "paythan"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# --- Networking (placeholder) ---
# module "vpc" { ... }
# module "ecs" { ... }
# module "rds" { ... }
# module "elasticache" { ... }
# module "alb" { ... }

output "environment" {
  value = var.environment
}

output "aws_region" {
  value = var.aws_region
}