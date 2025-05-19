#!/bin/bash
set -euo pipefail
export AWS_PAGER=""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

CLUSTER_NAME="flask-api-ecs-cluster"
SERVICE_NAME="flask-api-ecs-service"
PORT=5000

echo "🔍 Looking up latest task ENI..."
TASK_ARN=$(aws ecs list-tasks   --cluster $CLUSTER_NAME   --service-name $SERVICE_NAME   --region $AWS_REGION   --query "taskArns[0]"   --output text)

if [[ "$TASK_ARN" == "None" || -z "$TASK_ARN" ]]; then
  echo "❌ No running tasks found for service."
  exit 1
fi

ENI_ID=$(aws ecs describe-tasks   --cluster $CLUSTER_NAME   --tasks "$TASK_ARN"   --region $AWS_REGION   --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value"   --output text)

if [[ "$ENI_ID" == "None" || -z "$ENI_ID" ]]; then
  echo "❌ Could not find ENI for task."
  exit 1
fi

PUBLIC_IP=$(aws ec2 describe-network-interfaces   --network-interface-ids "$ENI_ID"   --region $AWS_REGION   --query "NetworkInterfaces[0].Association.PublicIp"   --output text)

if [[ "$PUBLIC_IP" == "None" || -z "$PUBLIC_IP" ]]; then
  echo "❌ Task has no public IP."
  exit 1
fi

echo "🌐 Public Access URL: http://${PUBLIC_IP}:${PORT}"
