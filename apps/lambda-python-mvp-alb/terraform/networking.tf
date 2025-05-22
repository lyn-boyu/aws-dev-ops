# Terraform module to create a VPC with public and private subnets, and a NAT gateway.
module "vpc_network" {
  source       = "./vpc-network"
  vpc_cidr     = var.vpc_cidr
  subnet_count = var.subnet_count
  project      = var.project
  environment  = var.environment
}

# This module creates a NAT gateway for outbound internet access from private subnets
module "nat_gateway" {
  source                          = "./nat-gateway"
  vpc_id                          = module.vpc_network.vpc_id
  azs                             = module.vpc_network.azs
  public_subnet_ids               = module.vpc_network.public_subnet_ids
  private_subnet_ids              = module.vpc_network.private_subnet_ids
  private_subnet_ids_with_egress = var.private_subnet_ids_with_egress
  project                         = var.project
  environment                     = var.environment
}