#!/bin/bash
set -euo pipefail

# === 1. 参数化配置（支持从 Makefile 传入）===
REGION="${REGION:-us-east-1}"
APP_NAME="${APP_NAME:-flask-api}"
INSTANCE_TYPE="t2.micro"
SECURITY_GROUP_NAME="${APP_NAME}-sg"
INSTANCE_TAG="${APP_NAME}-$(date +%Y%m%d%H%M%S)"

KEY_NAME="${KEY_NAME:-devops-ec2-key}"
KEY_PATH="$HOME/.ssh/${KEY_NAME}.pem"
IP_FILE="${IP_FILE:-$HOME/.ec2-hosts/${APP_NAME}-ip.txt}"

# === 2. 创建所需目录（PEM 和 IP 文件）===
mkdir -p "$(dirname "$KEY_PATH")"
mkdir -p "$(dirname "$IP_FILE")"

# === 3. 获取最新 Ubuntu 20.04 AMI ID ===
echo "🔍 Fetching latest Ubuntu 20.04 LTS AMI in $REGION..."
AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
echo "✅ Found AMI ID: $AMI_ID"

# === 4. 确保 AWS 上的 Key Pair 存在，如果本地未保存则拉取 ===
if aws ec2 describe-key-pairs --region "$REGION" --key-names "$KEY_NAME" >/dev/null 2>&1; then
  echo "🔐 Key pair exists in AWS: $KEY_NAME"
  if [ ! -f "$KEY_PATH" ]; then
    echo "⚠️ Local PEM file not found at $KEY_PATH. Cannot SSH without it."
    exit 1
  fi
else
  echo "🔐 Creating key pair on AWS: $KEY_NAME ..."
  aws ec2 create-key-pair \
    --region "$REGION" \
    --key-name "$KEY_NAME" \
    --query "KeyMaterial" \
    --output text > "$KEY_PATH"
  chmod 400 "$KEY_PATH"
  echo "✅ Key saved to $KEY_PATH"
fi

# === 5. 创建或复用安全组 ===
echo "🛡️ Checking security group: $SECURITY_GROUP_NAME ..."
SG_ID=$(aws ec2 describe-security-groups \
  --region "$REGION" \
  --group-names "$SECURITY_GROUP_NAME" \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null || true)

if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
  echo "🛡️ Creating security group: $SECURITY_GROUP_NAME ..."
  SG_ID=$(aws ec2 create-security-group \
    --region "$REGION" \
    --group-name "$SECURITY_GROUP_NAME" \
    --description "Security group for $APP_NAME" \
    --query "GroupId" \
    --output text)

   echo "🌐 Opening default ports in security group..."

  for PORT in 22 80 443 5000; do
    echo "🔧 Ensuring TCP port $PORT is open..."
    RULE_EXISTS=$(aws ec2 describe-security-groups \
      --region "$REGION" \
      --group-ids "$SG_ID" \
      --query "SecurityGroups[0].IpPermissions[?FromPort==\`$PORT\` && ToPort==\`$PORT\` && IpProtocol==\`tcp\`]" \
      --output text)

    if [ -z "$RULE_EXISTS" ]; then
      aws ec2 authorize-security-group-ingress \
        --region "$REGION" \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port "$PORT" \
        --cidr 0.0.0.0/0
      echo "✅ Port $PORT opened."
    else
      echo "✅ Port $PORT already open. Skipping."
    fi
  done
else
  echo "🛡️ Reusing existing security group: $SG_ID"
fi

# === 6. 启动 EC2 实例 ===
echo "🚀 Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --region "$REGION" \
  --image-id "$AMI_ID" \
  --count 1 \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --iam-instance-profile Name=EC2ECRReadOnlyProfile \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_TAG}]" \
  --query "Instances[0].InstanceId" \
  --output text)

echo "⏳ Waiting for instance to be running..."
aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"

# === 7. 获取并保存公网 IP ===
PUBLIC_IP=$(aws ec2 describe-instances \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo "$PUBLIC_IP" > "$IP_FILE"
echo "🌍 EC2 Public IP: $PUBLIC_IP"
echo "📄 Saved to: $IP_FILE"
echo "🔑 SSH: ssh -i $KEY_PATH ubuntu@$PUBLIC_IP"
