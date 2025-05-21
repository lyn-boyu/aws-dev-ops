# ------------------------------------------------------------
# ✅ Outputs for handler Lambda function
# ------------------------------------------------------------

# The name of the deployed Lambda function
output "lambda_function_name" {
  value = aws_lambda_function.basic_lambda.function_name
}

# The ARN (Amazon Resource Name) of the Lambda function
# This can be used by other modules (e.g., ALB, API Gateway) to invoke it
output "lambda_function_arn" {
  value = aws_lambda_function.basic_lambda.arn
}


# ------------------------------------------------------------
# ✅ Output for echo Lambda function
# ------------------------------------------------------------

# The name of the echo Lambda function (from echo.py)
output "echo_lambda_function_name" {
  value = aws_lambda_function.echo_lambda.function_name
}

# The ARN of the echo Lambda function
output "echo_lambda_arn" {
  value = aws_lambda_function.echo_lambda.arn
}
