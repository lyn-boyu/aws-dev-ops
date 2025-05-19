#!/bin/bash
set -euo pipefail
export AWS_PAGER=""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

CLUSTER_NAME="flask-api-ecs-cluster"
SERVICE_NAME="flask-api-ecs-service"
REGION=$AWS_REGION

echo "🧹 Deleting ECS Service: $SERVICE_NAME..."
aws ecs update-service   --cluster $CLUSTER_NAME   --service $SERVICE_NAME   --desired-count 0   --region $REGION || true

aws ecs delete-service   --cluster $CLUSTER_NAME   --service $SERVICE_NAME   --region $REGION   --force || true

echo "🧹 Deleting ECS Cluster: $CLUSTER_NAME..."
aws ecs delete-cluster   --cluster $CLUSTER_NAME   --region $REGION || true

echo "✅ ECS service and cluster removed."
