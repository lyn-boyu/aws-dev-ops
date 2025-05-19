# ------------------------------------------------------------------------------
# ECS Cluster
# This defines a container orchestration cluster where your Fargate tasks will run
# ------------------------------------------------------------------------------

resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.env}-cluster" # Example: flask-api-dev-cluster
}
