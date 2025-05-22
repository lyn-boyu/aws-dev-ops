.PHONY: init plan apply destroy deploy alb-url logs-basic

# === General Variables ===
TF_DIR=terraform

# === Terraform Commands ===
init:
	terraform -chdir=$(TF_DIR) init

plan:
	terraform -chdir=$(TF_DIR) plan

apply:
	terraform -chdir=$(TF_DIR) apply -auto-approve

destroy:
	terraform -chdir=$(TF_DIR) destroy -auto-approve

# === Output ===
alb-url:
	terraform -chdir=$(TF_DIR) output -raw alb_dns_name

# === Logs (Lambda) ===
logs-basic:
	@FUNC_NAME=$$(terraform -chdir=$(TF_DIR) output -raw lambda_function_name) && \
	LOG_GROUP="/aws/lambda/$$FUNC_NAME" && \
	aws logs describe-log-streams \
	  --log-group-name $$LOG_GROUP \
	  --order-by "LastEventTime" \
	  --descending \
	  --limit 1 \
	  --region $$(terraform -chdir=$(TF_DIR) output -raw region) \
	  --query "logStreams[0].logStreamName" \
	  --output text | \
	xargs -I {} aws logs get-log-events \
	  --log-group-name $$LOG_GROUP \
	  --log-stream-name {} \
	  --region $$(terraform -chdir=$(TF_DIR) output -raw region) \
	  --limit 50

# === Full workflow ===
deploy: init plan apply alb-url
