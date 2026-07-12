provider "google" {
  project = var.project_id
  region  = var.region
}

module "env" {
  source              = "../../../modules/environment"
  environment         = "prod"
  billing_account_id  = var.billing_account_id
  region              = var.region
  network_name        = var.network_name
  subnet_cidr         = var.subnet_cidr
}
