# ------------------------------------------------------------
# ✅ Terraform AWS Provider
# ------------------------------------------------------------
# This block configures the AWS provider.
# You must have `aws configure` set up or environment variables like AWS_ACCESS_KEY_ID.
provider "aws" {
  region = var.region
}

# ------------------------------------------------------------
# ✅ IAM Role for Lambda Execution
# ------------------------------------------------------------
# AWS Lambda needs permission to assume a role in order to:
# - Write logs to CloudWatch Logs
# - (Later) Access other AWS services (e.g., S3, DynamoDB)
#
# 📘 API: sts:AssumeRole
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project}-${var.env}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# ------------------------------------------------------------
# ✅ Attach CloudWatch Logs Policy to IAM Role
# ------------------------------------------------------------
# Grants basic logging permission to the Lambda function.
# This is a managed AWS policy.
#
# 📘 Policy ARN: arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ------------------------------------------------------------
# ✅ Package Lambda Code as a ZIP file
# ------------------------------------------------------------
# Terraform will automatically package all files in /src as lambda_function.zip.
#
# 📘 archive_file is a Terraform data source, not an AWS resource.
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/lambda_function.zip"
}

# ------------------------------------------------------------
# ✅ Define the AWS Lambda Function
# ------------------------------------------------------------
# Creates the actual Lambda function using the packaged ZIP file.
#
# 📘 AWS API: aws_lambda_function
resource "aws_lambda_function" "basic_lambda" {
  function_name    = "${var.project}-${var.env}-basic-lambda"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "handler.handler"     # file: handler.py, function: handler
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
}


# ------------------------------------------------------------
# ✅ Define the Second AWS Lambda Function (echo.handler)
# ------------------------------------------------------------
# This function takes a name input and responds with a message.
# Uses echo.py → def handler(event, context)
#
# 📘 AWS API: aws_lambda_function
resource "aws_lambda_function" "echo_lambda" {
  function_name    = "${var.project}-${var.env}-echo-lambda"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "echo.handler"                    # file: echo.py, function: handler
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
}