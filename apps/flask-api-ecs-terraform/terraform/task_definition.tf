# ------------------------------------------------------------------------------
# ECS Task Definition
# This defines how your container will run on Fargate: CPU, memory, image, ports
# ------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project}-${var.env}-task"      # Logical name for task family
  requires_compatibilities = ["FARGATE"]                           # We're using AWS Fargate
  cpu                      = "256"                                 # CPU units (256 = 0.25 vCPU)
  memory                   = "512"                                 # Memory in MB
  network_mode             = "awsvpc"                              # Required for Fargate
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn # Role used to pull image and write logs

  container_definitions = jsonencode([
    {
      name  = "flask-api-pod",                                     # Container name in ECS
      image = "${aws_ecr_repository.flask_api.repository_url}:latest",                              # ECR image to pull

      essential = true,                                            # Must run for task to be considered healthy

      portMappings = [{
        containerPort = 5000,                                      # Flask app port
        protocol      = "tcp"
      }],

      environment = [
        {
          name  = "FLASK_ENV",
          value = "production"
        }
      ],

      logConfiguration = {
        logDriver = "awslogs",                                     # Send logs to CloudWatch Logs
        options = {
          awslogs-group         = "/ecs/${var.project}",           # Log group name
          awslogs-region        = var.aws_region,
          awslogs-stream-prefix = "ecs"                            # Prefix in log stream
        }
      }
    }
  ])
}
