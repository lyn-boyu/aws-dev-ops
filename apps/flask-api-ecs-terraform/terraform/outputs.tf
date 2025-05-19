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