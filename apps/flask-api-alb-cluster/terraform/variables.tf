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


 
 variable "desired_count" {
  description = "Number of ECS task replicas (for ALB load balancing)"
  type        = number
  default     = 2
}


variable "container_name" {
  description = "Name of the container inside the ECS task"
  type        = string
  default     = "flask-alb-api-pod"
}