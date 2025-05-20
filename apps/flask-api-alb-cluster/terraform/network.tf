# ------------------------------------------------------------------------------
# Availability Zones
# Get list of available AZs in the selected AWS region
# ------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# Lookup default VPC for this region
data "aws_vpc" "default" {
  default = true
}

# Lookup public subnets in the default VPC
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }
}

# ------------------------------------------------------------------------------
# VPC (Virtual Private Cloud)
# The main virtual network for all ECS/Fargate resources
# ------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"          # Entire VPC CIDR block
  enable_dns_support   = true                   # Enable internal DNS resolution
  enable_dns_hostnames = true                   # Required for ECS hostnames

  tags = {
    Name = "${var.project}-${var.env}-vpc"
  }
}

# ------------------------------------------------------------------------------
# Internet Gateway
# Required for public subnets to access the Internet
# ------------------------------------------------------------------------------

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.env}-igw"
  }
}

# ------------------------------------------------------------------------------
# Public Subnet A (AZ 0)
# Used for ECS services and ALB in one availability zone
# ------------------------------------------------------------------------------

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"                             # Subnet range
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true                                     # Auto-assign public IP

  tags = {
    Name = "${var.project}-${var.env}-subnet-a"
  }
}

# ------------------------------------------------------------------------------
# Public Subnet B (AZ 1)
# Used for ECS services and ALB in another availability zone
# ------------------------------------------------------------------------------

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${var.env}-subnet-b"
  }
}

# ------------------------------------------------------------------------------
# Public Route Table
# Allows instances in public subnets to route traffic to Internet via IGW
# ------------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                   # Route all traffic
    gateway_id = aws_internet_gateway.gw.id   # To the internet gateway
  }

  tags = {
    Name = "${var.project}-${var.env}-rt"
  }
}

# Associate Subnet A with Public Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# Associate Subnet B with Public Route Table
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------------------
# Security Group for ECS Service
# Allows inbound access on port 5000 (Flask) from any IP
# ------------------------------------------------------------------------------

resource "aws_security_group" "ecs" {
  name        = "${var.project}-${var.env}-sg"
  description = "Allow inbound access on port 5000"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5000                      # Flask app port
    to_port     = 5000
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]             # Allow from all sources
    security_groups = [aws_security_group.alb.id]  # Allow from ALB security group
  }

  egress {
    from_port   = 0                         # Allow all outbound traffic
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.env}-ecs-sg"
  }
}
