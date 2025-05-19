#!/bin/bash
set -euo pipefail
export AWS_PAGER=""
AWS_REGION="us-east-2"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <vpc-id>"
  exit 1
fi

VPC_ID="$1"
echo "⚠️  Deleting VPC and all its dependencies: $VPC_ID"

# Delete Subnets
SUBNETS=$(aws ec2 describe-subnets --region $AWS_REGION --filters Name=vpc-id,Values=$VPC_ID --query 'Subnets[*].SubnetId' --output text)
for SUBNET_ID in $SUBNETS; do
  echo "🧹 Deleting Subnet: $SUBNET_ID"
  aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $AWS_REGION
done

# Detach and delete Internet Gateways
IGWS=$(aws ec2 describe-internet-gateways --region $AWS_REGION --filters Name=attachment.vpc-id,Values=$VPC_ID --query 'InternetGateways[*].InternetGatewayId' --output text)
for IGW_ID in $IGWS; do
  echo "🔌 Detaching IGW: $IGW_ID"
  aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $AWS_REGION
  echo "🧨 Deleting IGW: $IGW_ID"
  aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $AWS_REGION
done

# Delete route tables (except main)
ROUTES=$(aws ec2 describe-route-tables --region $AWS_REGION --filters Name=vpc-id,Values=$VPC_ID --query 'RouteTables[?Associations[?Main!=`true`]].RouteTableId' --output text)
for RT_ID in $ROUTES; do
  echo "🗺️  Deleting Route Table: $RT_ID"
  aws ec2 delete-route-table --route-table-id $RT_ID --region $AWS_REGION
done

# Delete non-default security groups
SG_IDS=$(aws ec2 describe-security-groups --region $AWS_REGION --filters Name=vpc-id,Values=$VPC_ID --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
for SG_ID in $SG_IDS; do
  echo "🛡️  Deleting Security Group: $SG_ID"
  aws ec2 delete-security-group --group-id $SG_ID --region $AWS_REGION
done

# Delete Network Interfaces (if any)
ENIs=$(aws ec2 describe-network-interfaces --region $AWS_REGION --filters Name=vpc-id,Values=$VPC_ID --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text)
for ENI in $ENIs; do
  echo "🔌 Deleting Network Interface: $ENI"
  aws ec2 delete-network-interface --network-interface-id $ENI --region $AWS_REGION || true
done


NAT_IDS=$(aws ec2 describe-nat-gateways --region $AWS_REGION --filter Name=vpc-id,Values=$VPC_ID --query 'NatGateways[*].NatGatewayId' --output text)
for NAT_ID in $NAT_IDS; do
  echo "🌀 Deleting NAT Gateway: $NAT_ID"
  aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID --region $AWS_REGION
done

ENIs=$(aws ec2 describe-network-interfaces --region $AWS_REGION --filters Name=vpc-id,Values=$VPC_ID --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text)
for ENI in $ENIs; do
  echo "🔌 Trying to delete ENI: $ENI"
  aws ec2 delete-network-interface --network-interface-id $ENI --region $AWS_REGION || echo "❗ Could not delete ENI: $ENI"
done


# Delete VPC
echo "🔥 Deleting VPC: $VPC_ID"
aws ec2 delete-vpc --vpc-id $VPC_ID --region $AWS_REGION

echo "✅ VPC and all its dependencies deleted."
