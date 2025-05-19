# Makefile at project root

REGION ?= us-east-1
KEY_NAME ?= devops-ec2-key-0518
IP_FILE ?= $(HOME)/.ec2-hosts/flask-api-ip.txt
DOCKER_APP_NAME ?= flask-api

.PHONY: generate-key create-ec2 build-docker deploy terminate destroy

# Generate SSH key pair and store in ~/.ssh/
generate-key:
	KEY_NAME=$(KEY_NAME) bash deploy/generate-keypair.script.sh

# Create EC2 instance and save its public IP
create-ec2:
	KEY_NAME=$(KEY_NAME) IP_FILE=$(IP_FILE) bash deploy/create-ec2.script.sh

# Build Docker image for Flask API
build-docker:
	docker build -t $(DOCKER_APP_NAME) -f deploy/Dockerfile app

# Build, push Docker image and deploy Flask API to EC2
deploy:
	DOCKER_APP_NAME=$(DOCKER_APP_NAME) REGION=$(REGION) KEY_NAME=$(KEY_NAME) IP_FILE=$(IP_FILE) bash deploy/deploy-flask-app.script.sh

# Terminate EC2 instance
destroy:
	DOCKER_APP_NAME=$(DOCKER_APP_NAME) REGION=$(REGION) IP_FILE=$(IP_FILE) bash deploy/terminate-ec2.script.sh