#!/bin/bash
set -euo pipefail
export AWS_PAGER=""

AWS_REGION="us-east-2"
CLUSTER_NAME="flask-api-ecs-cluster"
IMAGE_NAME="flask-api-ecs"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_URL="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}"

aws logs create-log-group --log-group-name /ecs/${IMAGE_NAME} --region $AWS_REGION || true

EXEC_ROLE_ARN=$(aws iam get-role --role-name ecsTaskExecutionRole \
  --query 'Role.Arn' --output text)

CONTAINER_DEFINITIONS=$(cat <<EOF
[
  {
    "name": "$IMAGE_NAME",
    "image": "$IMAGE_URL",
    "essential": true,
    "portMappings": [
      { "containerPort": 5000 }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/$IMAGE_NAME",
        "awslogs-region": "$AWS_REGION",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
EOF
)
aws ecs register-task-definition \
  --family $IMAGE_NAME \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu 256 \
  --memory 512 \
  --execution-role-arn "$EXEC_ROLE_ARN" \
  --container-definitions "$CONTAINER_DEFINITIONS" \
  --region $AWS_REGION

echo "✅ Task definition registered."
