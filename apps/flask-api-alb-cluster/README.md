
# 📘 ALB Configuration Guide for ECS Fargate

This document describes how our infrastructure uses **AWS Application Load Balancer (ALB)** to route external traffic to ECS Fargate containers.

---

## 📦 Components Overview

| Component               | Description |
|------------------------|-------------|
| `aws_lb`               | Application Load Balancer (ALB) |
| `aws_security_group.alb` | Security group to allow public HTTP access |
| `aws_lb_target_group`  | Target group for ECS IPs (port 5000) |
| `aws_lb_listener`      | HTTP listener on port 80 |
| `aws_ecs_service`      | Fargate service registered in ALB |
| `aws_subnet.public_*`  | Public subnets with Internet Gateway |
| `aws_security_group.ecs` | Allows ALB to access ECS tasks (port 5000) |

---

## 🛠 ALB Configuration Details

### 1. Subnets

- **Two public subnets**, across two AZs (e.g. `us-west-1a` and `us-west-1b`)
- Must have `map_public_ip_on_launch = true`
- Must be attached to a **public route table** with `0.0.0.0/0` → `aws_internet_gateway`

```hcl
subnet_id = aws_subnet.public_a.id
subnet_id = aws_subnet.public_b.id
````

---

### 2. ALB (Application Load Balancer)

```hcl
resource "aws_lb" "app" {
  name               = "${var.project}-${var.env}-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.alb.id]
}
```

* ALB is deployed in **public subnets**
* Receives HTTP (port 80) traffic from the internet

---

### 3. Security Group for ALB

```hcl
resource "aws_security_group" "alb" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

* Allows inbound HTTP traffic
* Outbound fully open to forward requests to ECS

---

### 4. Target Group

```hcl
resource "aws_lb_target_group" "app" {
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }
}
```

* Registers **ECS task private IPs** on port 5000
* Health check ensures only healthy tasks receive traffic

---

### 5. Listener

```hcl
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

* Forwards HTTP requests to registered targets

---

## 🔄 ECS Service Integration

In `aws_ecs_service`, make sure to:

```hcl
load_balancer {
  target_group_arn = aws_lb_target_group.app.arn
  container_name   = var.container_name
  container_port   = 5000
}

network_configuration {
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
  assign_public_ip = false
  security_groups  = [aws_security_group.ecs.id]
}
```

---

## 🔐 ECS Security Group

```hcl
resource "aws_security_group" "ecs" {
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
}
```

* **Restrict ECS access** to only traffic from ALB

---

## ✅ Validation Checklist

* [ ] ALB subnets are in **different AZs**
* [ ] ALB SG allows port 80 from 0.0.0.0/0
* [ ] ECS SG allows port 5000 **only from ALB SG**
* [ ] Target group uses **target\_type = "ip"**
* [ ] ECS tasks are in subnets that allow **outbound internet access** (via IGW or NAT)
* [ ] Health check endpoint `/health` returns HTTP 200

---

## 📄 Related Files

| File                 | Purpose                             |
| -------------------- | ----------------------------------- |
| `network.tf`         | Subnets, route tables, NAT, IGW, SG |
| `alb.tf`             | ALB, Target Group, Listener         |
| `service.tf`         | ECS Service + Load Balancer         |
| `task_definition.tf` | Container + port + log config       |

---

## 📘 Example Health Check Response

```bash
curl http://<alb_dns_name>/health
# Should return: ok
```

---

## 💡 Tips

* Use `terraform output alb_dns_name` to get ALB endpoint
* Use `make ecs-list-tasks` to list cluster pods
* Use `make checkTask task=arn:aws:ecs:us-west-1:257288818401xxxxxxxxxx` to inspect target pod
* Ensure your ECS task image is built and pushed correctly

 