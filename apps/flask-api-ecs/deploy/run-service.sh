#!/bin/bash
set -euo pipefail
export AWS_PAGER=""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

CLUSTER_NAME="flask-api-ecs-cluster"
SERVICE_NAME="flask-api-ecs-service"
IMAGE_NAME="flask-api-ecs"

# 检查服务是否已存在
SERVICE_EXISTS=$(aws ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME \
  --region $AWS_REGION \
  --query "services[0].status" \
  --output text 2>/dev/null || echo "MISSING")

if [[ "$SERVICE_EXISTS" == "ACTIVE" || "$SERVICE_EXISTS" == "DRAINING" ]]; then
  echo "🔁 Service already exists, updating..."
  aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $IMAGE_NAME \
    --desired-count 1 \
    --region $AWS_REGION
else
  echo "🚀 Creating new service..."
  aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --launch-type FARGATE \
    --task-definition $IMAGE_NAME \
    --desired-count 1 \
    --network-configuration "awsvpcConfiguration={\"subnets\":[\"$SUBNET_ID\"],\"securityGroups\":[\"$SECURITY_GROUP_ID\"],\"assignPublicIp\":\"ENABLED\"}" \
    --region $AWS_REGION
fi

# 获取任务 ID 和日志链接
TASK_ARN=$(aws ecs list-tasks \
  --cluster $CLUSTER_NAME \
  --service-name $SERVICE_NAME \
  --query 'taskArns[0]' --output text --region $AWS_REGION)

if [[ "$TASK_ARN" == "None" || -z "$TASK_ARN" ]]; then
  echo "⚠️ No running tasks found for service yet."
  exit 0
fi

TASK_ID=$(basename "$TASK_ARN")
LOG_STREAM_NAME="ecs/${IMAGE_NAME}/${TASK_ID}"
LOG_GROUP_NAME="/ecs/${IMAGE_NAME}"


for i in {1..12}; do
  PUBLIC_IP=$(aws ec2 describe-network-interfaces \
    --filters "Name=description,Values=Interface for ECS task *" \
              "Name=subnet-id,Values=$SUBNET_ID" \
    --region $AWS_REGION \
    --query "NetworkInterfaces[*].Association.PublicIp" \
    --output text)
  if [[ -n "$PUBLIC_IP" && "$PUBLIC_IP" != "None" ]]; then
    echo "✅ Public IP ready: http://$PUBLIC_IP:5000"
    break
  fi
  echo "⏳ Waiting for public IP..."
  sleep 5
done

echo "⏳ Waiting for log stream: $LOG_STREAM_NAME"
for i in {1..12}; do
  FOUND=$(aws logs describe-log-streams \
    --log-group-name "$LOG_GROUP_NAME" \
    --log-stream-name-prefix "$LOG_STREAM_NAME" \
    --region $AWS_REGION \
    --query "logStreams[?logStreamName=='$LOG_STREAM_NAME'] | length(@)" \
    --output text)
  if [[ "$FOUND" != "0" ]]; then
    echo "✅ Log stream found!"
    LOG_LINK="https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#logsV2:log-groups/log-group=/ecs/${IMAGE_NAME}/log-events/${LOG_STREAM_NAME}"
    echo "📜 Console log stream: $LOG_LINK"
    exit 0
  fi
  echo "⏱️  Retry $i: waiting for log stream..."
  sleep 5
done

for i in {1..12}; do
  PUBLIC_IP=$(aws ec2 describe-network-interfaces \
    --filters "Name=description,Values=Interface for ECS task *" \
              "Name=subnet-id,Values=$SUBNET_ID" \
    --region $AWS_REGION \
    --query "NetworkInterfaces[*].Association.PublicIp" \
    --output text)
  if [[ -n "$PUBLIC_IP" && "$PUBLIC_IP" != "None" ]]; then
    echo "✅ Public IP ready: http://$PUBLIC_IP:5000"
    break
  fi
  echo "⏳ Waiting for public IP..."
  sleep 5
done

echo "❌ Timeout: log stream was not created after 60 seconds."
exit 1
