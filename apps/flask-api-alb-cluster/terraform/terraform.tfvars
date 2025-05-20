# ==========================
# 🌎 AWS Region Configuration
# ==========================
aws_region = "us-west-1"  # Region to deploy all resources


# ==========================
# 🐳 Docker / ECR Settings
# ==========================
ecr_name = "flask-alb-ecs-api"  # ECR repository name to host Docker image


# ==========================
# 📦 ECS Naming Conventions
# ==========================
project = "flask-alb-ecs-api"     # Project prefix for naming resources
env     = "dev"           # Environment identifier (dev/stg/prod)


# ==========================
# Number of ECS Fargate task replicas for ALB to load balance
desired_count = 2



# used in service.tf  task_definition.tf
container_name = "flask-alb-api-pod"