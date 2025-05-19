#!/bin/bash
set -euo pipefail

# === 1. 参数设置 ===
APP_NAME="${DOCKER_APP_NAME:-flask-api}"
REGION="${REGION:-us-east-1}"
IP_FILE="${IP_FILE:-$HOME/.ec2-hosts/${APP_NAME}-ip.txt}"

# === 2. 读取 IP 文件 ===
if [ ! -f "$IP_FILE" ]; then
  echo "❌ IP file not found: $IP_FILE"
  exit 0  # 不存在就退出，视为已清理
fi

PUBLIC_IP=$(cat "$IP_FILE")
echo "📄 Found public IP for ${APP_NAME}: $PUBLIC_IP"

# === 3. 查询 EC2 实例 ID ===
echo "🔍 Locating instance by IP..."
INSTANCE_ID=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=ip-address,Values=$PUBLIC_IP" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text 2>/dev/null || true)

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "None" ]; then
  echo "⚠️ No active EC2 instance found for IP: $PUBLIC_IP"
  echo "🧹 Cleaning up IP file..."
  rm -f "$IP_FILE"
  exit 0
fi

echo "✅ Instance ID found: $INSTANCE_ID"

# === 4. 终止实例 ===
echo "🗑️ Terminating instance $INSTANCE_ID..."
aws ec2 terminate-instances --region "$REGION" --instance-ids "$INSTANCE_ID" > /dev/null

# === 5. 等待终止完成 ===
echo "⏳ Waiting for termination..."
aws ec2 wait instance-terminated --region "$REGION" --instance-ids "$INSTANCE_ID"

# === 6. 清理 IP 文件 ===
rm -f "$IP_FILE"
echo "✅ Terminated instance and cleaned up $IP_FILE"
