# ------------------------------------------------------------
# ✅ terraform.tfvars: Input values for variables.tf
# ------------------------------------------------------------

# Project name used to name resources uniquely
# This will appear in Lambda function name, IAM role name, etc.
project = "lambda-python-mvp-cli"

# Deployment environment (e.g., dev, stg, prod, local)
# Useful for logical grouping and CI/CD automation
env = "test"

# AWS region to deploy the Lambda function into
# Make sure your AWS CLI is configured to this region too
region = "us-west-1"
