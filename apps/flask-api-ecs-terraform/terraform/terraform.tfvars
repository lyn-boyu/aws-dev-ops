# ==========================
# 🌎 AWS Region Configuration
# ==========================
aws_region = "us-west-2"  # Region to deploy all resources


# ==========================
# 🐳 Docker / ECR Settings
# ==========================
ecr_name = "flask-api-ecs-terraform"  # ECR repository name to host Docker image


# ==========================
# 📦 ECS Naming Conventions
# ==========================
project = "flask-api"     # Project prefix for naming resources
env     = "dev"           # Environment identifier (dev/stg/prod)


 