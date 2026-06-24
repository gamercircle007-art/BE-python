variable "aws_region" {
  description = "AWS region for Paythan infrastructure"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment: dev, staging, prod"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod"
  }
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "paythan"
}

# --- ECS ---
variable "backend_cpu" {
  type    = number
  default = 256
}

variable "backend_memory" {
  type    = number
  default = 512
}

variable "backend_desired_count" {
  type    = number
  default = 2
}

# --- RDS ---
variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

# --- Secrets (reference AWS Secrets Manager ARNs in production) ---
variable "jwt_secret_arn" {
  description = "ARN of JWT secret in AWS Secrets Manager"
  type        = string
  default     = ""
}