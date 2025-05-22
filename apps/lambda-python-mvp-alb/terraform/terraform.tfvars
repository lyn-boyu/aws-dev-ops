region = "us-west-2"  # AWS region

vpc_cidr = "10.0.0.0/16"  # CIDR block for your VPC

subnet_count = 2  # Number of public/private subnet pairs

project = "lambda-mvp"  # Project name prefix for resources

environment = "dev"  # Environment name (dev, staging, prod)

# List of private subnets requiring NAT  
# Supported 3 type configurations:
# 1. [] — no private subnets use NAT (fully isolated)
# 2. [module.vpc_network.private_subnet_ids[0]] — only one subnet has NAT egress
# 3. module.vpc_network.private_subnet_ids — all subnets route through NAT
private_subnet_ids_with_egress = []  
