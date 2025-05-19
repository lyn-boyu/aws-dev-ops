# 🚀 Flask API on AWS ECS Fargate

This project demonstrates how to deploy a Flask web application to AWS ECS Fargate with:

- ✅ Auto-created ECS cluster and task definition
- ✅ CloudWatch Logs integration
- ✅ Public access via auto-assigned IP
- ✅ Fully bash-scripted deployment

---

## 📁 Project Structure

```
apps/flask-api-ecs/
├── app/
│   ├── app.py                # Flask app entry
│   └── requirements.txt      # Python dependencies
├── deploy/
│   ├── build-and-push-ecr.sh     # Docker build and ECR push
│   ├── create-cluster.sh         # Creates ECS cluster
│   ├── create-vpc-and-subnet.sh  # Creates VPC, subnet, SG
│   ├── register-task.sh          # Registers task definition with logs
│   ├── run-service.sh            # Creates or updates service, logs setup
│   ├── get-task-ip.sh            # Retrieves public IP of the running task
├── Dockerfile                # Gunicorn-based Flask container
├── Makefile                  # Easy command automation
└── .env                      # Stores AWS_REGION, SUBNET_ID, SECURITY_GROUP_ID
```

---

## 🛠 Prerequisites

- ✅ AWS CLI configured with IAM user (needs `ecs`, `iam`, `ec2`, `logs`, `ecr`)
- ✅ Docker + buildx enabled
- ✅ Bash 4+ / Unix-like shell

---

## 🧪 Quick Start

```bash
make generate-key         # (Optional) generate EC2 key pair
make vpc                  # Create VPC, subnet, and security group
make build                # Build multi-arch Docker image
make push                 # Push image to ECR
make register             # Register ECS Task Definition
make cluster              # Create ECS cluster
make run                  # Create or update ECS service
make ip                   # Print public IP of running task
```

Once deployed, access your app via:

```
http://<PUBLIC_IP>:5000
```

Or check CloudWatch logs:

```
https://<region>.console.aws.amazon.com/cloudwatch/home?region=<AWS_REGION>#logsV2:log-groups/log-group=/ecs/flask-api-ecs
```

---

## 📋 Health Check Endpoint

```bash
curl http://<PUBLIC_IP>:5000/health
# → "ok"
```

---

## 🧹 Cleanup

To destroy the entire stack (optional for dev/test environments):

```bash
make destroy
```

---

## 📌 Notes

- This repo uses `FARGATE` launch type and assigns a **public IP** for external access.
- CloudWatch logs are stored under log group: `/ecs/flask-api-ecs`
- Task role: `ecsTaskExecutionRole` must have `logs:PutLogEvents` permission.

---

## 📦 Next Steps

- Add CI/CD via GitHub Actions or Jenkins
- Configure ALB + Apigee for secure API Gateway
- Add HTTPS (via ALB listener or Cloudflare)
