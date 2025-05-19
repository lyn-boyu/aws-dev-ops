#!/bin/bash
set -euo pipefail

# === 1. 参数设置 ===
DOCKER_APP_NAME="${DOCKER_APP_NAME:-flask-api}"
REGION="${REGION:-us-east-1}"
KEY_NAME="${KEY_NAME:-devops-ec2-key}"
IP_FILE="${IP_FILE:-$HOME/.ec2-hosts/${DOCKER_APP_NAME}-ip.txt}"
KEY_PATH="$HOME/.ssh/${KEY_NAME}.pem"
ECR_REPO="257288818401.dkr.ecr.${REGION}.amazonaws.com/${DOCKER_APP_NAME}"
EC2_USER="ubuntu"

# === 2. 检查 IP 文件 ===
if [ ! -f "$IP_FILE" ]; then
  echo "❌ ERROR: EC2 IP not found at $IP_FILE"
  exit 1
fi

EC2_IP=$(cat "$IP_FILE")
echo "📄 Loaded EC2 IP: $EC2_IP"

# === 3. 路径设置 ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKERFILE_PATH="$PROJECT_ROOT/deploy/Dockerfile"
APP_DIR="$PROJECT_ROOT/app"

if [ ! -d "$APP_DIR" ]; then
  echo "❌ ERROR: App directory not found at $APP_DIR"
  exit 1
fi

# === 4. 检查 ECR 仓库是否存在 ===
echo "🔍 Checking if ECR repository '${DOCKER_APP_NAME}' exists..."
REPO_EXISTS=$(aws ecr describe-repositories \
  --region "$REGION" \
  --repository-names "$DOCKER_APP_NAME" 2>/dev/null || true)

if [ -z "$REPO_EXISTS" ]; then
  echo "📦 Creating ECR repository: $DOCKER_APP_NAME ..."
  aws ecr create-repository --repository-name "$DOCKER_APP_NAME" --region "$REGION" > /dev/null
  echo "✅ ECR repository created."
else
  echo "✅ ECR repository already exists."
fi

# === 5. 启用 Buildx 并构建 amd64 镜像 ===
echo "🛠️ Building and pushing Docker image (platform: linux/amd64)..."
docker buildx inspect default >/dev/null 2>&1 || docker buildx create --use
docker buildx build \
  --platform linux/amd64 \
  -t "${ECR_REPO}:latest" \
  -f "$DOCKERFILE_PATH" "$APP_DIR" \
  --push

# === 6. SSH 部署容器（含 Docker 安装 + sudo 权限） ===
echo "🚀 Deploying to EC2 instance at $EC2_IP ..."
ssh  -o StrictHostKeyChecking=no -i "$KEY_PATH" "$EC2_USER@$EC2_IP" <<EOF
 set -euxo pipefail

  # 1.1 安装 Docker
  if ! command -v docker >/dev/null 2>&1; then
    echo "📦 Installing Docker..."
    sudo apt update -y
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ${EC2_USER}
    echo "✅ Docker installed."
  else
    echo "✅ Docker already installed."
  fi

  # 1.2 安装 AWS CLI（如未安装）
  if ! command -v aws >/dev/null 2>&1; then
    echo "📦 Installing AWS CLI..."
    sudo apt update -y
    sudo apt install -y awscli
  else
    echo "✅ AWS CLI already installed."
  fi

  # 2.1 登录 ECR
  aws ecr get-login-password --region $REGION \
  | sudo docker login --username AWS --password-stdin $ECR_REPO

  # 3. 拉取镜像并运行容器
  echo "🐳 Pulling container..."
  sudo docker pull ${ECR_REPO}:latest

  echo "🧹 Cleaning up..."
  sudo docker stop ${DOCKER_APP_NAME} || true
  sudo docker rm ${DOCKER_APP_NAME} || true

  echo "🚀 Running container..."
  sudo docker run -d --name ${DOCKER_APP_NAME} -p 80:5000 ${ECR_REPO}:latest
EOF

echo "✅ Deployed ${DOCKER_APP_NAME} to EC2"
echo "🌐 Visit your app at: http://${EC2_IP}"
