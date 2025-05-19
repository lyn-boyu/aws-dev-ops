#!/bin/bash
set -euo pipefail

KEY_NAME="${KEY_NAME:-devops-ec2-key}"
KEY_PATH="$HOME/.ssh/${KEY_NAME}.pem"
REGION="${REGION:-us-east-1}"

# === 1. 创建 ~/.ssh 目录（如果不存在）===
mkdir -p "$(dirname "$KEY_PATH")"

# === 2. 检查是否已存在 ===
if [ -f "$KEY_PATH" ]; then
  echo "✅ SSH key already exists at: $KEY_PATH"
  exit 0
fi

# === 3. 创建 AWS Key Pair 并保存 PEM 文件 ===
echo "🔐 Creating AWS EC2 key pair: $KEY_NAME ..."
KEY_MATERIAL=$(aws ec2 create-key-pair \
  --region "$REGION" \
  --key-name "$KEY_NAME" \
  --query "KeyMaterial" \
  --output text)

# === 4. 写入文件并设置权限 ===
echo "$KEY_MATERIAL" > "$KEY_PATH"
chmod 400 "$KEY_PATH"

# === 5. 显式打印路径信息（不触发外部程序）===
echo "✅ Key saved securely to: $KEY_PATH"
echo "📌 To SSH: ssh -i $KEY_PATH ubuntu@<YOUR_EC2_IP>"
