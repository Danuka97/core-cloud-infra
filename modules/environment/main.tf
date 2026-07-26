# Composite module: wraps project creation + networking for a single environment.
# Adding a new environment should only require calling this module with new
# values, not duplicating project/network resource definitions.
#
# Note: billing_account_id is intentionally NOT a variable here - project_factory
# fetches it directly from Secret Manager (secrets_project_id) to avoid ever
# having the real billing account ID pass through tfvars/variables/git.

module "project" {
  source             = "../project_factory"
  environment        = var.environment
  app_name           = var.app_name
  region             = var.region
  secrets_project_id = var.secrets_project_id
}

module "network" {
  source       = "../vpc_network"
  project_id   = module.project.project_id
  network_name = var.network_name
  region       = var.region
  subnet_cidr  = var.subnet_cidr
}

module "backend" {
  source             = "../cloud_run_backend"
  project_id         = module.project.project_id
  region             = var.region
  app_name           = var.app_name
  environment        = var.environment
  container_image    = var.container_image
  network_id         = module.network.network_id
  vpc_connector_cidr = var.vpc_connector_cidr
}

module "firebase" {
  source             = "../firebase_auth"
  project_id         = module.project.project_id
  app_name           = var.app_name
  environment        = var.environment
  secrets_project_id = var.secrets_project_id
}

module "vertex_agent" {
  source      = "../vertex_agent"
  project_id  = module.project.project_id
  app_name    = var.app_name
  environment = var.environment
}
