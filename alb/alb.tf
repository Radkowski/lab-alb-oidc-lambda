variable "DeploymentName" {}
variable "VPCID" {}
variable "SUBNETSID" {}
variable "LAMBDA" {}
variable "CERTARN" {}
variable "OIDC-CONFIG" {}
variable "FQDN" {}



resource "aws_security_group" "alb-sg" {
  name        = "http and https only SG"
  description = "Allow http(s)"
  vpc_id      = var.VPCID

  ingress = [
    {
      description      = "https traffic"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "http traffic"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  egress = [
    {
      description      = "Default rule"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}


resource "aws_lambda_permission" "alb-perms" {
  statement_id  = "AllowExecutionFromlb"
  action        = "lambda:InvokeFunction"
  function_name = var.LAMBDA.id
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.target-group.arn
}

resource "aws_lb_target_group_attachment" "lambda-attach" {
  depends_on       = [aws_lambda_permission.alb-perms]
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = var.LAMBDA.arn
}



resource "aws_lb_target_group" "target-group" {
  name        = join("", [var.DeploymentName, "-target-group"])
  target_type = "lambda"
}


resource "aws_lb" "eap-dns-alb" {
  name               = join("", [var.DeploymentName, "-ALB"])
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [for subnet in var.SUBNETSID : subnet]

  enable_deletion_protection = false
  tags = {
    Environment = "production"
  }
}


resource "aws_lb_listener" "eap-alb-listener" {
  load_balancer_arn = aws_lb.eap-dns-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.CERTARN

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "There is no spoon..."  
      status_code  = "501"
    }
  }
}



resource "aws_lb_listener_rule" "oidc" {
  listener_arn = aws_lb_listener.eap-alb-listener.arn
  condition {
    host_header {
      values = [var.FQDN]
    }
  }
  action {
    type = "authenticate-oidc"

    authenticate_oidc {
      authorization_endpoint = var.OIDC-CONFIG.authorization_endpoint
      client_id              = var.OIDC-CONFIG.client_id
      client_secret          = var.OIDC-CONFIG.client_secret
      issuer                 = var.OIDC-CONFIG.issuer
      token_endpoint         = var.OIDC-CONFIG.token_endpoint
      user_info_endpoint     = var.OIDC-CONFIG.userinfo_endpoint
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}




output "ALB_TG" {
  value = aws_lb_target_group.target-group
}
