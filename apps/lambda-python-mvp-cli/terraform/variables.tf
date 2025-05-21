# ------------------------------------------------------------
# ✅ Input Variables
# ------------------------------------------------------------

# The project name, used in naming AWS resources.
# Recommended to keep globally unique across stages (e.g., lambda-python-mvp).
variable "project" {
  default = "lambda-python-mvp-cli"
}

# The environment name, such as dev, stg, or prod.
variable "env" {
  default = "test"
}

# AWS region where resources will be created.
# Make sure this matches your AWS CLI or Console settings.
variable "region" {
  default = "us-west-1"
}
