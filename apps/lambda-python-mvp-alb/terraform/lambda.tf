# IAM role that allows Lambda service to assume and run this function
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

# Attach the basic CloudWatch Logs execution policy to the Lambda role
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach the VPC access execution policy to the Lambda role
resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Security group for the Lambda function (allows all outbound traffic)
resource "aws_security_group" "lambda_sg" {
  name   = "lambda-sg"
  vpc_id = module.vpc_network.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Package the Lambda source code from the src/ folder into a zip file
# Used as input for aws_lambda_function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../src"
  output_path = "../dist/lambda.zip"
}

# Create the Lambda function for ALB integration
resource "aws_lambda_function" "alb_target" {
  function_name = "lambda-python-mvp-alb"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 5
  filename      = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = module.vpc_network.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

