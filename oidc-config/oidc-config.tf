variable "DIRECTORY_ID" {}
variable "APPLICATION_ID" {}
variable "SECRET_NAME" {}

data "http" "openid-conf" {
  url = join("", ["https://login.microsoftonline.com/", var.DIRECTORY_ID, "/v2.0/.well-known/openid-configuration"])

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  config_dump = jsondecode(data.http.openid-conf.body)
}

data "aws_secretsmanager_secret" "get-oidc-secret" {
  name = var.SECRET_NAME
}

data "aws_secretsmanager_secret_version" "secret-version" {
  secret_id = data.aws_secretsmanager_secret.get-oidc-secret.id
}



output "config" {
  value = {
    "token_endpoint" : lookup(local.config_dump, "token_endpoint", "ERROR"),
    "issuer" : lookup(local.config_dump, "issuer", "ERROR"),
    "authorization_endpoint" : lookup(local.config_dump, "authorization_endpoint", "ERROR"),
    "userinfo_endpoint" : lookup(local.config_dump, "userinfo_endpoint", "ERROR"),
    "client_secret" : jsondecode(data.aws_secretsmanager_secret_version.secret-version.secret_string)["client_secret"],
    "client_id" : var.APPLICATION_ID
  }
}
