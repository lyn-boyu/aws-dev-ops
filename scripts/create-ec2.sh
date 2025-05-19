#!/bin/bash

# === 1. Basic Configuration ===
REGION="us-east-1"
AMI_ID=""  # Will be set dynamically latter
INSTANCE_TYPE="t2.micro"
KEY_NAME="my-ec2-key"
SECURITY_GROUP_NAME="flask-sg"
INSTANCE_TAG="FlaskApp"

echo "🌐 Setting AWS CLI region to $REGION..."
aws configure set region $REGION

# === 2. Fetch the latest Ubuntu 20.04 LTS AMI ID ===
echo "🔍 Fetching the latest Ubuntu 20.04 LTS AMI ID..."
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
echo "✅ Found AMI ID: $AMI_ID"

# === 3. Create key pair if not exists ===
if [ ! -f "${KEY_NAME}.pem" ]; then
  echo "🔐 Creating key pair: $KEY_NAME..."
  aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query "KeyMaterial" \
    --output text > "${KEY_NAME}.pem"
  chmod 400 "${KEY_NAME}.pem"
else
  echo "🔐 Key pair already exists: ${KEY_NAME}.pem. Skipping creation."
fi

# === 4. Create security group and open ports ===
echo "🛡️ Checking security group: $SECURITY_GROUP_NAME..."
SG_ID=$(aws ec2 describe-security-groups \
  --group-names $SECURITY_GROUP_NAME \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null)

if [ "$SG_ID" = "None" ] || [ -z "$SG_ID" ]; then
  echo "🛡️ Creating new security group..."
  SG_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for Flask App" \
    --query "GroupId" \
    --output text)
  echo "🔓 Allowing SSH (port 22) and Flask (port 5000) access..."
  aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 5000 --cidr 0.0.0.0/0
else
  echo "🛡️ Security group already exists: $SG_ID"
fi

# === 5. Launch EC2 instance ===
echo "🚀 Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
    --iam-instance-profile Name="EC2ECRReadOnlyProfile" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_TAG}]" \
  --query "Instances[0].InstanceId" \
  --output text)

echo "⏳ Waiting for instance to be in running state..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# === 6. Get public IP ===
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo "🎉 Instance is now running!"
echo "🌍 Public IP Address: $PUBLIC_IP"
echo "🔑 SSH access command:"
echo "ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
