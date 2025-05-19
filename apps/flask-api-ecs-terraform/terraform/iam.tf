# ------------------------------------------------------------------------------
# IAM Role for ECS Task Execution
# Allows ECS to pull image from ECR and write to CloudWatch Logs
# ------------------------------------------------------------------------------

# Trust policy: allows ECS to assume this role
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# IAM Role used by ECS tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project}-${var.env}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

# Attach the default AWS-managed policy for ECS execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
