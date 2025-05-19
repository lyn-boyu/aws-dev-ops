#!/bin/bash
set -euo pipefail
export AWS_PAGER=""

AWS_REGION="us-east-2"
IMAGE_NAME="flask-api-ecs"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}"

echo "🔍 Checking ECR repository..."
aws ecr describe-repositories --repository-names $IMAGE_NAME --region $AWS_REGION || \
  aws ecr create-repository --repository-name $IMAGE_NAME --region $AWS_REGION

echo "🔑 Authenticating Docker to ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_URL

echo "🐳 Building multi-platform Docker image for amd64..."
docker buildx create --use --name fargate-builder || true
docker buildx build \
  --platform linux/amd64 \
  --tag $ECR_URL:latest \
  --push \
  . # ← 注意是项目根目录

echo "✅ Image built and pushed: $ECR_URL:latest"
