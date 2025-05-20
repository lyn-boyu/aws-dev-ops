.PHONY: init plan apply deploy-infra \
        create-docker-repo build-image push-image login-ecr \
        deploy-app-image whoami

# Load .env if exists
ifneq (,$(wildcard .env))
	include .env
	export
endif

# Default AWS region (can be overridden at runtime)
REGION ?= us-west-1


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
# Auto-load image name from Terraform output
 
# Build local Docker image for linux/amd64 (Fargate-compatible)

build-and-push: login-ecr
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

# Build and push ECR image directly
build-image:
	DOCKER_BUILDKIT=1 docker buildx build \
		--platform linux/amd64 \
		-t $(IMAGE_NAME):$(IMAGE_TAG) .


# Push prebuilt image to ECR
push-image: login-ecr
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $$(terraform -chdir=terraform output -raw ecr_push_url):$(IMAGE_TAG)
	docker push $$(terraform -chdir=terraform output -raw ecr_push_url):$(IMAGE_TAG)

# === Combined Workflow ===

# Create ECR repo, build & push image (tag: latest)
deploy-app-image: create-docker-repo build-and-push
	

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
DESIRED_COUNT ?= 2

start-service:
	aws ecs update-service \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--service $$(terraform -chdir=terraform output -raw ecs_service_name) \
		--desired-count $(DESIRED_COUNT) \
		--region $(REGION)
	@echo "✅ ECS service started with 1 running task."

# Force ECS to restart task (force re-deploy)
ecs-restart:
	aws ecs update-service \
		--cluster $$(terraform -chdir=terraform output -raw ecs_cluster_name) \
		--service $$(terraform -chdir=terraform output -raw ecs_service_name) \
		--force-new-deployment \
		--region $(REGION)


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


# Describe  target task (first in list)
# eg： make checkTask task=arn:aws:ecs:us-west-1:257288818401:task/flask-alb-ecs-api-dev-cluster/4741de94da494e8db27958df4f34d988
checkTask:
	@CLUSTER=$$(terraform -chdir=terraform output -raw ecs_cluster_name | tr -d '\r\n'); \
	echo "Cluster: $$CLUSTER"; \
	aws ecs describe-tasks \
		--cluster $$CLUSTER \
		--tasks $(task) \
		--region $(REGION) --output table

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

 
		
# Get public IP of most recent task (no ALB)
ecs-public-ip:
	@cluster=$$(terraform -chdir=terraform output -raw ecs_cluster_name); \
	service=$$(terraform -chdir=terraform output -raw ecs_service_name); \
	task=$$(aws ecs list-tasks \
		--cluster $$cluster \
		--service-name $$service \
		--region $(REGION) \
		--query 'taskArns[0]' --output text); \
	if [ "$$task" = "None" ]; then \
		echo "❌ No running ECS task found."; exit 1; \
	fi; \
	echo "📦 Task ARN: $$task"; \
	eni=$$(aws ecs describe-tasks \
		--cluster $$cluster \
		--tasks $$task \
		--region $(REGION) \
		--query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
		--output text); \
	echo "🔌 ENI: $$eni"; \
	public_ip=$$(aws ec2 describe-network-interfaces \
		--network-interface-ids $$eni \
		--region $(REGION) \
		--query 'NetworkInterfaces[0].Association.PublicIp' \
		--output text); \
	echo "🌐 ECS Public IP: $$public_ip"; \
	echo "✅ Try: curl http://$$public_ip:5000/health"


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


alb-url:
	@terraform -chdir=terraform output -raw alb_dns_name | xargs -I{} echo "http://{}"


LOG_GROUP_NAME := $(shell terraform -chdir=terraform output -raw log_group_name)

show-logs:
	@log_streams=$$(aws logs describe-log-streams \
		--log-group-name $(LOG_GROUP_NAME) \
		--region $(REGION) \
		--order-by LastEventTime \
		--descending \
		--limit 5 \
		--query "logStreams[*].logStreamName" \
		--output text); \
	for stream in $$log_streams; do \
		echo "📄 === Log Stream: $$stream ==="; \
		aws logs get-log-events \
			--log-group-name $(LOG_GROUP_NAME) \
			--log-stream-name $$stream \
			--region $(REGION) \
			--limit 20 \
			--output text; \
		echo ""; \
	done



log-url:
	@group=$$(terraform -chdir=terraform output -raw log_group_name); \
	encoded=$$(echo $$group | sed 's/\//%2F/g'); \
	echo "🔗 Log Group URL:"; \
	echo "https://console.aws.amazon.com/cloudwatch/home?region=$(REGION)#logsV2:log-groups/log-group/$$encoded"



test-alb:
	@tgroup_arn=$$(terraform -chdir=terraform output -raw target_group_arn); \
	echo "🔗 Target Group ARN: $$tgroup_arn"; \
	aws elbv2 describe-target-health \
		--target-group-arn $$tgroup_arn \
		--region us-west-2 \
		--output json | jq .

check-alb-health:
	@echo "🔎 Checking ALB Target Health..."
	@tg_arn=$$(terraform -chdir=terraform output -raw target_group_arn); \
	echo "🔗 Target Group ARN: $$tg_arn"; \
	aws elbv2 describe-target-health \
		--target-group-arn $$tg_arn \
		--region $(REGION) \
		--query 'TargetHealthDescriptions[*].{IP:Target.Id,Port:Target.Port,Zone:Target.AvailabilityZone,Status:TargetHealth.State,Reason:TargetHealth.Reason,Desc:TargetHealth.Description}' \
		--output table
