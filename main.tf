module "resource_group" {
  source       = "./modules/resource_group"
  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

module "networking" {
  source              = "./modules/networking"
  vpc_cidr            = var.vpc_cidr
  subnet_cidrs        = var.subnet_cidrs
  availability_zone   = var.availability_zone
  availability_zone_b = var.availability_zone_b
  project_name        = var.project_name
  environment         = var.environment
}

module "log_analytics" {
  source         = "./modules/log_analytics"
  log_group_name = var.log_group_name
  project_name   = var.project_name
  environment    = var.environment
}

module "ecr" {
  source           = "./modules/acr"
  repository_names = concat([for app in var.apps : app.name], ["orchestrator"])
  project_name     = var.project_name
  environment      = var.environment
}

module "key_vault" {
  source        = "./modules/key_vault"
  secret_prefix = var.secret_prefix
  project_name  = var.project_name
  environment   = var.environment
}

module "openai" {
  source       = "./modules/openai"
  project_name = var.project_name
  environment  = var.environment

  vpc_id        = module.networking.vpc_id
  subnet_id     = module.networking.workload_subnet_id
  app_role_name = module.key_vault.role_name
  model_id      = var.model_id
}

module "container_apps_env" {
  source       = "./modules/container_apps_env"
  vpc_id       = module.networking.vpc_id
  project_name = var.project_name
  environment  = var.environment
}

module "container_apps" {
  source       = "./modules/container_apps"
  project_name = var.project_name
  environment  = var.environment

  cluster_name   = module.container_apps_env.cluster_name
  vpc_id         = module.networking.vpc_id
  subnet_ids     = [module.networking.container_subnet_id, module.networking.container_subnet_id_b]
  namespace_id   = module.container_apps_env.namespace_id
  namespace_name = module.container_apps_env.namespace_name

  app_role_arn   = module.key_vault.role_arn
  log_group_name = module.log_analytics.log_group_name

  bedrock_endpoint = module.openai.endpoint
  model_id         = module.openai.model_id

  apps               = var.apps
  orchestrator_image = "851725205521.dkr.ecr.us-east-1.amazonaws.com/secure-agent-dev-orchestrator:v7"
}