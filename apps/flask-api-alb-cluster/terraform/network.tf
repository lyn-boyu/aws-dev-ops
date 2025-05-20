# ------------------------------------------------------------------------------
# 1. Availability Zones
# Get list of available AZs in the selected AWS region
# ------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# ------------------------------------------------------------------------------
# 2. VPC (Virtual Private Cloud)
# The main virtual network for all ECS/Fargate resources
# ------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project}-${var.env}-vpc"
  }
}


# ------------------------------------------------------------------------------
# 3. Internet Gateway
# Required for public subnets to access the Internet
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project}-${var.env}-igw"
  }
}

# ------------------------------------------------------------------------------
# 4. Public Subnet A (AZ 0)
# Used for ECS services and ALB in one availability zone
# ------------------------------------------------------------------------------

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-${var.env}-public-a"
  }
}
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${var.env}-public-b"
  }
}

# ------------------------------------------------------------------------------
# 5. Private Subnet B (AZ 1)
# Used for ECS services and ALB in another availability zone
# ------------------------------------------------------------------------------
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-${var.env}-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-${var.env}-private-b"
  }
}

# ------------------------------------------------------------------------------
# 6. NAT Gateway
# ------------------------------------------------------------------------------
resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "${var.project}-${var.env}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id
  tags = {
    Name = "${var.project}-${var.env}-nat"
  }
}

# ------------------------------------------------------------------------------
# 7. Public Route Table 路由表 - 公共（IGW）
# Allows instances in public subnets to route traffic to Internet via IGW
# ------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.project}-${var.env}-public-rt"
  }
}
# 关联一个路由表：
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------------------
# 8. Public Route Table - Private (NAT)
#  路由表 - 私有（NAT）
# ------------------------------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.project}-${var.env}-private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}


# ------------------------------------------------------------------------------
# 9. Security Group for ECS Service
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
