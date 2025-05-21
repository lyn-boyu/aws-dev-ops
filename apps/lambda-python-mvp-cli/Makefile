
export AWS_PAGER=""

TF_DIR=terraform
TF_VARS_FILE=terraform.tfvars
REGION=us-west-1

.PHONY: init plan apply destroy test-basic test-echo logs-basic logs-echo logs-basic-follow

 
# Initialize Terraform (downloads provider, sets up backend, etc.)
init:
	cd ${TF_DIR} && terraform init

# Show the Terraform execution plan
plan:
	cd ${TF_DIR} && terraform plan -var-file=${TF_VARS_FILE}

# Apply all Terraform resources with predefined variables
apply:
	cd ${TF_DIR} && terraform apply -auto-approve -var-file=${TF_VARS_FILE}


# Show deployed Lambda function names
show:
	@echo "📦 Deployed Lambda functions:"
	@terraform -chdir=${TF_DIR} output lambda_function_name
	@terraform -chdir=${TF_DIR} output echo_lambda_function_name

# Deploy all Lambda resources in one step
deploy: init apply show


# Destroy all Terraform-managed infrastructure
destroy:
	cd ${TF_DIR} && terraform destroy -auto-approve -var-file=${TF_VARS_FILE}

# Invoke the default Lambda function defined in handler.py
test-basic:
	@echo "🧪 Invoking default Lambda (handler.py)..."
	@FUNC_NAME=$$(terraform -chdir=${TF_DIR} output -raw lambda_function_name) && \
	aws lambda invoke \
	  --function-name $$FUNC_NAME \
	  --payload '{}' \
	  --region ${REGION} \
	  response.json && cat response.json && echo

# Invoke the echo Lambda function with a name (default: Linjie)

name ?= Linda
test-echo:
	@echo "🧪 Invoking echo Lambda (echo.py) with name=$(name)..."
	@FUNC_NAME=$$(terraform -chdir=${TF_DIR} output -raw echo_lambda_function_name) && \
	NAME="$(name)" && \
	aws lambda invoke \
	  --function-name $$FUNC_NAME \
	  --payload "$$(jq -nc --arg name $$NAME '{"body": {"name": $$name}}')" \
	  --cli-binary-format raw-in-base64-out \
	  --region ${REGION} \
	  response.json && cat response.json && echo


# Show recent logs from basic Lambda function
logs-basic:
	@FUNC_NAME=$$(terraform -chdir=${TF_DIR} output -raw lambda_function_name) && \
	echo "📜 Fetching logs for $$FUNC_NAME..." && \
	LOG_GROUP="/aws/lambda/$$FUNC_NAME" && \
	aws logs describe-log-streams \
	  --log-group-name $$LOG_GROUP \
	  --order-by "LastEventTime" \
	  --descending \
	  --limit 1 \
	  --region ${REGION} \
	  --query "logStreams[0].logStreamName" \
	  --output text | \
	xargs -I {} aws logs get-log-events \
	  --log-group-name $$LOG_GROUP \
	  --log-stream-name {} \
	  --region ${REGION} \
	  --limit 20 \
	  --query "events[*].message" \
	  --output text


# Show recent logs from echo Lambda function
logs-echo:
	@FUNC_NAME=$$(terraform -chdir=${TF_DIR} output -raw echo_lambda_function_name) && \
	echo "📜 Fetching logs for $$FUNC_NAME..." && \
	LOG_GROUP="/aws/lambda/$$FUNC_NAME" && \
	aws logs describe-log-streams \
	  --log-group-name $$LOG_GROUP \
	  --order-by "LastEventTime" \
	  --descending \
	  --limit 1 \
	  --region ${REGION} \
	  --query "logStreams[0].logStreamName" \
	  --output text | \
	xargs -I {} aws logs get-log-events \
	  --log-group-name $$LOG_GROUP \
	  --log-stream-name {} \
	  --region ${REGION} \
	  --limit 20 \
	  --query "events[*].message" \
	  --output text

