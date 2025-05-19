# === AWS Provider Configuration ===
variable "aws_region" {
  description = "AWS region to deploy resources (e.g. us-west-2, us-east-1)"
  type        = string
}

# === Docker & ECR ===
variable "ecr_name" {
  description = "Name of the ECR Docker repository to create and push to"
  type        = string
}

# === ECS Resource Naming ===
variable "project" {
  description = "Project name prefix for tagging and naming AWS resources"
  type        = string
}

variable "env" {
  description = "Environment identifier (e.g. dev, stg, prod)"
  type        = string
}


 