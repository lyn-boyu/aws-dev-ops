# ------------------------------------------------------------------------------
# CloudWatch Log Group for ECS Task Logs
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "flask_api" {
  name              = "/ecs/flask-alb-ecs-api-pod"
  retention_in_days = 7

  tags = {
    Name = "${var.project}-${var.env}-log-group"
  }
}


