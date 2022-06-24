data "aws_caller_identity" "current" {}

data "aws_region" "current" {}




variable "DeploymentRegion" {
  default = "eu-central-1"
  type    = string
}

variable "DeploymentName" {
  default = "ALB-OIDC"
  type    = string
}

variable "VPCID" {
  default = "vpc-changeme"
  type    = string
}

variable "SubnetsID" {
  default = ["subnet-changeme", "subnet-changeme", "subnet-changeme"]
  type    = list(string)
}

variable "FQDN" {
  default = "alb-via-oidc.radkowski.cloud"
  type    = string
}


variable "CERTARN" {
  default = "arn:aws:acm:changeme"
  type    = string
}

variable "APPLICATION_ID" {
  default = "changeme"
  type    = string
}

variable "DIRECTORY_ID" {
  default = "changeme"
  type    = string
}


variable "SECRET_NAME" {
  default = "changeme"
  type    = string
}
