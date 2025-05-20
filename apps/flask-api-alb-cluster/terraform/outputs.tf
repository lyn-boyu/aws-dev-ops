output "ecr_push_url" {
  description = "Docker 镜像推送地址"
  value       = aws_ecr_repository.flask_api.repository_url
}

# Step2: 创建 ECS Cluster
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "availability_zones" {
  value = data.aws_availability_zones.available.names
}
 
output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

#  ALB DNS name to access the Flask service
output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}


# Target Group ARN (for diagnostics and CLI access)
output "target_group_arn" {
  description = "ARN of the ALB Target Group"
  value       = aws_lb_target_group.app.arn
}


# CloudWatch Log Group name
output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.flask_api.name
}

output "container_name" {
  description = "Name of the ECS container used by task definition and service"
  value       = var.container_name
}


output "project" {
  value       = var.project
  description = "Project name"
}