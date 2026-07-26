# core-app / uat environment
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "env" {
  source              = "../../../modules/environment"
  environment         = "uat"
  app_name            = "core-app"
  secrets_project_id  = var.project_id
  region              = var.region
  network_name        = var.network_name
  subnet_cidr         = var.subnet_cidr
  vpc_connector_cidr  = var.vpc_connector_cidr
}
