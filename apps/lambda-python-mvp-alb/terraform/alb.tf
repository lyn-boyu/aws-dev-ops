# Create an Application Load Balancer (ALB) to route HTTP traffic to Lambda
resource "aws_lb" "main" {
  name               = "lambda-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc_network.public_subnet_ids
}

# ALB security group to allow inbound HTTP (port 80) and all outbound
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = module.vpc_network.vpc_id

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

# Target group that points to the Lambda function
resource "aws_lb_target_group" "lambda_tg" {
  name         = "lambda-tg"
  target_type  = "lambda"
}

# HTTP listener on port 80 that forwards requests to Lambda target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda_tg.arn
  }
}
# ------------------------------------------------------------------------------