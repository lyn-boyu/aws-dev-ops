# Outputs for the ALB and Lambda function
output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

# Output the function name for use in logs or curl tests
output "lambda_function_name" {
  value       = aws_lambda_function.alb_target.function_name
  description = "Name of the Lambda function"
}
