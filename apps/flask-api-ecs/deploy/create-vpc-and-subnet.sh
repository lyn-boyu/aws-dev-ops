#!/bin/bash
set -euo pipefail
export AWS_PAGER=""

AWS_REGION="us-east-2"
VPC_NAME="flask-ecs-default-vpc"
SUBNET_NAME="flask-ecs-subnet"
SECURITY_GROUP_NAME="flask-ecs-sg"
PORT=5000

# 查询是否存在已命名的 VPC
echo "🔍 Checking for existing VPC named $VPC_NAME..."
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$VPC_NAME" \
  --region $AWS_REGION \
  --query "Vpcs[0].VpcId" \
  --output text 2>/dev/null)

if [[ "$VPC_ID" == "None" || -z "$VPC_ID" ]]; then
  echo "🚧 No VPC found, creating new one..."
  VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --region $AWS_REGION \
    --query 'Vpc.VpcId' --output text)

  aws ec2 create-tags --resources $VPC_ID \
    --tags Key=Name,Value=$VPC_NAME \
    --region $AWS_REGION
else
  echo "✅ Reusing VPC: $VPC_ID"
fi

# 查询或创建 Internet Gateway
IGW_ID=$(aws ec2 describe-internet-gateways \
  --region $AWS_REGION \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query "InternetGateways[0].InternetGatewayId" \
  --output text 2>/dev/null)

if [[ "$IGW_ID" == "None" || -z "$IGW_ID" ]]; then
  echo "🌐 Creating Internet Gateway..."
  IGW_ID=$(aws ec2 create-internet-gateway \
    --region $AWS_REGION \
    --query 'InternetGateway.InternetGatewayId' --output text)

  aws ec2 attach-internet-gateway \
    --vpc-id $VPC_ID \
    --internet-gateway-id $IGW_ID \
    --region $AWS_REGION
else
  echo "✅ Reusing Internet Gateway: $IGW_ID"
fi

# 路由表创建与关联
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region $AWS_REGION \
  --query "RouteTables[0].RouteTableId" --output text)

ROUTE_EXISTS=$(aws ec2 describe-route-tables \
  --route-table-ids $ROUTE_TABLE_ID \
  --region $AWS_REGION \
  --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0']" \
  --output text)

if [[ -z "$ROUTE_EXISTS" ]]; then
  echo "🛣️ Creating route to Internet Gateway..."
  aws ec2 create-route \
    --route-table-id $ROUTE_TABLE_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID \
    --region $AWS_REGION
fi

# 子网创建或重用
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=$SUBNET_NAME" \
  --region $AWS_REGION \
  --query "Subnets[0].SubnetId" \
  --output text 2>/dev/null)

if [[ "$SUBNET_ID" == "None" || -z "$SUBNET_ID" ]]; then
  echo "📦 Creating Subnet..."
  SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone ${AWS_REGION}a \
    --region $AWS_REGION \
    --query 'Subnet.SubnetId' --output text)

  aws ec2 create-tags --resources $SUBNET_ID \
    --tags Key=Name,Value=$SUBNET_NAME \
    --region $AWS_REGION

  aws ec2 associate-route-table \
    --subnet-id $SUBNET_ID \
    --route-table-id $ROUTE_TABLE_ID \
    --region $AWS_REGION

  aws ec2 modify-subnet-attribute \
    --subnet-id $SUBNET_ID \
    --map-public-ip-on-launch \
    --region $AWS_REGION
else
  echo "✅ Reusing Subnet: $SUBNET_ID"
fi

# 安全组创建或重用
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --region $AWS_REGION \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null)

if [[ "$SG_ID" == "None" || -z "$SG_ID" ]]; then
  echo "🔐 Creating Security Group..."
  SG_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Allow TCP ${PORT}" \
    --vpc-id $VPC_ID \
    --region $AWS_REGION \
    --query 'GroupId' --output text)

  aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port $PORT \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION
else
  echo "✅ Reusing Security Group: $SG_ID"
fi

# 写入 .env
echo "AWS_REGION=$AWS_REGION" > .env
echo "SUBNET_ID=$SUBNET_ID" >> .env
echo "SECURITY_GROUP_ID=$SG_ID" >> .env
echo "✅ Wrote values to .env"
