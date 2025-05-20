# ------------------------------------------------------------------------------
# ECS Fargate Service
# This defines how the task will be deployed and run across subnets and AZs
# ------------------------------------------------------------------------------

resource "aws_ecs_service" "app" {
  name            = "${var.project}-${var.env}-service"       # ECS service name
  cluster         = aws_ecs_cluster.main.id                   # Link to the ECS cluster
  launch_type     = "FARGATE"                                 # Use AWS Fargate (serverless containers)
  task_definition = aws_ecs_task_definition.app.arn           # Task definition to run
  desired_count = var.desired_count                                        # Number of containers to keep running
  health_check_grace_period_seconds = 60

  # Attach to ALB Target Group
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.container_name
    container_port   = 5000
  }

  # Each Fargate task must run in its own ENI, inside a VPC subnet with security group
  network_configuration {
    subnets = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ]

    assign_public_ip = true                                   # Auto-assign a public IP for internet access

    security_groups = [
      aws_security_group.ecs.id                               # Allow port 5000 access (from network.tf)
    ]
  }

  # Enable rolling deployments and container restarts if needed
  deployment_controller {
    type = "ECS"                                               # Default deployment controller (not CodeDeploy)
  }

  # Optional deployment parameters: speed and circuit breaker
  deployment_minimum_healthy_percent = 50                     # Allow 50% of tasks to go down during deployment
  deployment_maximum_percent         = 200                    # Allow up to 2x tasks during update
  enable_ecs_managed_tags            = true                   # ECS adds metadata tags automatically
  propagate_tags                     = "SERVICE"              # Propagate tags from service to tasks

  tags = {
    Name = "${var.project}-${var.env}-service"
  }
}
