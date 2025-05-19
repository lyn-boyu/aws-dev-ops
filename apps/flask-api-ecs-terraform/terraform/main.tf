provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "flask_api" {
  name = var.ecr_name
}