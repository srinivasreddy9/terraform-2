//Provider Details
provider "aws" {
  region = "ap-southeast-1"
}

//VPC Details - Data pull readonly
data "aws_vpc" "default" {
  default = "true"
}

//Subnet Details - Data pull read only
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

//Variables
variable "server_port" {
  description = "This variable defines server port"
  type        = number
  default     = 8080
}

variable "ami-webserver" {
  description = "This is the image to use"
  type        = string
  default     = "ami-0c20b8b385217763f"
}

variable "instance-touse" {
  description = "Image type to use"
  type        = string
  default     = "t3a.nano"
}

// Create EC2 Instance
resource "aws_instance" "web-server" {
  ami                    = var.ami-webserver
  instance_type          = "t3a.nano"
  vpc_security_group_ids = [aws_security_group.test-instance-sg.id]
  user_data              = file("userdata.sh")

  tags = {
    Name         = "test-instance"
    created-by   = "Ankit Mehta"
    created-with = "terraform"
  }
}

// Create Launch Configuration
resource "aws_launch_configuration" "webserver-lc" {
  image_id        = var.ami-webserver
  instance_type   = var.instance-touse
  security_groups = [aws_security_group.test-instance-sg.id]
  user_data       = file("userdata.sh")
  lifecycle {
    create_before_destroy = true
  }
}

// Create Autoscaling group
resource "aws_autoscaling_group" "webserver-asg" {
  launch_configuration = aws_launch_configuration.webserver-lc.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  min_size          = 2
  max_size          = 5

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "terraform-asg-example"
  }
}

// Create Security Group
resource "aws_security_group" "test-instance-sg" {
  name = "test-instance-sg"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create Load Balancer
resource "aws_lb" "test-lb" {
  name               = "aws-test-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.test-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page Not Found"
      status_code  = 404
    }
  }
}


// Create Security Group
resource "aws_security_group" "alb" {
  name = "alb security group"
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

resource "aws_lb_target_group" "asg" {
  name     = "asg-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

//Create ALB listener
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

//Outputs
output "public_ip" {
  value       = aws_instance.web-server.public_ip
  description = "Public IP of the instance"
}
output "alb_dns_name" {
  value       = aws_lb.test-lb.dns_name
  description = "loadbalancer domain name"
}