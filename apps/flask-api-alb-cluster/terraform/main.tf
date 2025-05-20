provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "flask_api" {
  name = var.ecr_name
  force_delete = true # ✅ 允许 Terraform 自动删除所有镜像
}