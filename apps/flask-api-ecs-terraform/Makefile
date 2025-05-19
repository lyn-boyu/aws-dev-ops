.PHONY: init plan apply deploy-infra \
        create-docker-repo build-image push-image login-ecr \
        deploy-app-image whoami

# Load .env if exists
ifneq (,$(wildcard .env))
	include .env
	export
endif

# Default AWS region (can be overridden at runtime)
REGION ?= us-west-2

# === Terraform Commands ===

init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply -auto-approve

# Provision all infra (includes ECR repo)
deploy-infra: apply

create-docker-repo: deploy-infra

# === Docker Image Commands ===

# Build local Docker image for linux/amd64 (Fargate-compatible)
build-image:
	DOCKER_BUILDKIT=1 docker buildx build \
		--platform linux/amd64 \
		-t flask-api \
		.

# Build and push ECR image directly
build-and-push:
	DOCKER_BUILDKIT=1 docker buildx build \
		--platform linux/amd64 \
		-t $$(terraform -chdir=terraform output -raw ecr_push_url):latest \
		--push \
		.

# Authenticate Docker to AWS ECR
login-ecr:
	@host=$$(terraform -chdir=terraform output -raw ecr_push_url | cut -d/ -f1); \
	echo "🔐 Logging in to ECR at $$host (region=$(REGION))..."; \
	aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $$host

# Push prebuilt image to ECR
push-image: login-ecr
	docker tag flask-api:latest $$(terraform -chdir=terraform output -raw ecr_push_url):latest
	docker push $$(terraform -chdir=terraform output -raw ecr_push_url):latest

# === Combined Workflow ===

# Create ECR repo, build & push image (tag: latest)
deploy-app-image: create-docker-repo build-and-push

# Debug current AWS identity
whoami:
	aws sts get-caller-identity --region $(REGION)


# === ECS Service / Task Commands ===

# 👋 Scale down ECS service to 0 tasks
stop-service:
	aws ecs update-service \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--service $$(terraform -chdir=terraform output -raw ecs_service_name) \
		--desired-count 0 \
		--region $(REGION)
	@echo "✅ ECS service has been scaled to 0 (stopped)."



# 🚀 Start ECS service by scaling it back up

# default desired count if not set externally
DESIRED_COUNT ?= 1

start-service:
	aws ecs update-service \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--service $$(terraform -chdir=terraform output -raw ecs_service_name) \
		--desired-count $(DESIRED_COUNT) \
		--region $(REGION)
	@echo "✅ ECS service started with 1 running task."


# ❌ Delete ECS service completely (use with caution)
delete-service:
	aws ecs delete-service \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--service $$(terraform -chdir=terraform output -raw ecs_service_name) \
		--region $(REGION) \
		--force
	@echo "⚠️  ECS service deleted forcefully."

# ☠️ Destroys all provisioned infrastructure
destroy:
	cd terraform && terraform destroy -auto-approve



# Print current running ECS service info
ecs-status:
	aws ecs describe-services \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--services $$(terraform -chdir=terraform output -raw ecs_service_name) \
		--region $(REGION) \
		--output json | jq '.services[0] | {status, desiredCount, runningCount, taskDefinition, deployments}'

# List currently running task ARNs
ecs-list-tasks:
	aws ecs list-tasks \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--service-name $$(terraform -chdir=terraform output -raw ecs_service_name) \
		--region $(REGION)

# Describe most recent task (first in list)
ecs-describe-task:
	@task=$$(aws ecs list-tasks \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--service-name $$(terraform -chdir=terraform output -raw ecs_service_name) \
		--region $(REGION) \
		--output text \
		--query 'taskArns[0]'); \
	echo "📦 Task ARN: $$task"; \
	aws ecs describe-tasks \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--tasks $$task \
		--region $(REGION) \
		--output json | jq '.tasks[0] | {taskArn, lastStatus, stoppedReason}'


# Force ECS to restart task (force re-deploy)
ecs-redeploy:
	aws ecs update-service \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--service $$(terraform -chdir=terraform output -raw ecs_service_name) \
		--force-new-deployment \
		--region $(REGION)

# Get public IP of most recent task (no ALB)
ecs-public-ip:
	@task=$$(aws ecs list-tasks \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--service-name $$(terraform -chdir=terraform output -raw ecs_service_name) \
		--region $(REGION) --query 'taskArns[0]' --output text); \
	eni=$$(aws ecs describe-tasks \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--tasks $$task \
		--region $(REGION) --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text); \
	aws ec2 describe-network-interfaces \
		--network-interface-ids $$eni \
		--region $(REGION) \
		--query 'NetworkInterfaces[0].Association.PublicIp' \
		--output text

ecs-public-ip:
	@task=$$(aws ecs list-tasks \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--service-name $$(terraform -chdir=terraform output -raw ecs_service_name) \
		--region $(REGION) --query 'taskArns[0]' --output text); \
	eni=$$(aws ecs describe-tasks \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--tasks $$task \
		--region $(REGION) --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text); \
	ip=$$(aws ec2 describe-network-interfaces \
		--network-interface-ids $$eni \
		--region $(REGION) --query 'NetworkInterfaces[0].Association.PublicIp' --output text); \
	echo "🌐 Public IP: $$ip"; \
	echo "✅ Try: curl http://$$ip:5000/health"


test-health:
	@echo "🚀 Fetching running ECS task IP and testing /health endpoint..."; \
	task=$$(aws ecs list-tasks \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--service-name $$(terraform -chdir=terraform output -raw ecs_service_name) \
		--region $(REGION) \
		--query 'taskArns[0]' \
		--output text); \
	eni=$$(aws ecs describe-tasks \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--tasks $$task \
		--region $(REGION) \
		--query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
		--output text); \
	ip=$$(aws ec2 describe-network-interfaces \
		--network-interface-ids $$eni \
		--region $(REGION) \
		--query 'NetworkInterfaces[0].Association.PublicIp' \
		--output text); \
	echo "🌐 Public IP: $$ip"; \
	echo "🔍 Curl: http://$$ip:5000/health"; \
	curl --connect-timeout 5 --retry 2 --retry-delay 2 http://$$ip:5000/health || echo "❌ request failed"