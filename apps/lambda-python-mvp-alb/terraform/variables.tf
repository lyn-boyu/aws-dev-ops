# AWS region to deploy infrastructure, e.g. us-west-2, us-east-1

# The AWS region where all resources will be created
variable "region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region"
}

# The CIDR block for the VPC. Must be a valid IPv4 network range.
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR range for the VPC"
}

# Number of subnet pairs (public + private). Each AZ will get one pair.
variable "subnet_count" {
  type        = number
  default     = 2
  description = "Number of subnet pairs (public + private)"
}

# A short prefix for resource names (e.g., lambda-mvp). Used for tagging and naming.
variable "project" {
  type        = string
  default     = "lambda-mvp"
  description = "Project or application name prefix"
}

# Environment tag used for grouping resources (e.g., dev, staging, prod).
variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment label (e.g., dev, staging, prod)"
}

# List of private subnet IDs that need internet access via NAT Gateway.
# Leave empty ([]) if Lambda does not require outbound connectivity.
variable "private_subnet_ids_with_egress" {
  type        = list(string)
  default     = []
  description = "Subset of private subnets to route through NAT"
}