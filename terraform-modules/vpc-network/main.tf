# === VPC and Subnet Configuration ===

# Get a list of availability zones in the current region
# Used to distribute subnets across different AZs

data "aws_availability_zones" "available" {
  state = "available"
}

# Create the main VPC with DNS support enabled
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}

# Create public subnets across multiple AZs
# These subnets map public IPs and can host ALBs or NAT Gateways
resource "aws_subnet" "public" {
  count = var.subnet_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${var.environment}-public-subnet-${count.index + 1}"
  }
}

# Create private subnets across the same AZs
# These subnets do not map public IPs and are typically used for backend workloads
resource "aws_subnet" "private" {
  count = var.subnet_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project}-${var.environment}-private-subnet-${count.index + 1}"
  }
}

# Create an Internet Gateway for outbound access from public subnets
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.environment}-igw"
  }
}

# Create a route table for public subnets that routes 0.0.0.0/0 through the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-public-rt"
  }
}

# Associate each public subnet with the public route table
resource "aws_route_table_association" "public_assoc" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}