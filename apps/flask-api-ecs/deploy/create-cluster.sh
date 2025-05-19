#!/bin/bash
set -euo pipefail
export AWS_PAGER=""

AWS_REGION="us-east-2"
CLUSTER_NAME="flask-api-ecs-cluster"

aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $AWS_REGION
echo "✅ ECS Cluster created: $CLUSTER_NAME"
