variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of all private subnet IDs (not necessarily all need NAT access)"
}

variable "private_subnet_ids_with_egress" {
  type        = list(string)
  default     = []
  description = "Subset of private_subnet_ids that should have NAT egress"
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones"
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}
