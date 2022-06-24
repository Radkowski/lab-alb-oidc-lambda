module "OIDC-CONFIG" {
  source         = "./oidc-config"
  DIRECTORY_ID   = var.DIRECTORY_ID
  APPLICATION_ID = var.APPLICATION_ID
  SECRET_NAME    = var.SECRET_NAME
}


module "LAMBDA-ALB" {
  source         = "./lambda-alb"
  DeploymentName = var.DeploymentName
}


module "ALB" {
  depends_on     = [module.LAMBDA-ALB]
  source         = "./alb"
  DeploymentName = var.DeploymentName
  LAMBDA         = module.LAMBDA-ALB.lambda_info
  CERTARN        = var.CERTARN
  VPCID          = var.VPCID
  SUBNETSID      = var.SubnetsID
  OIDC-CONFIG    = module.OIDC-CONFIG.config
  FQDN           = var.FQDN
}
