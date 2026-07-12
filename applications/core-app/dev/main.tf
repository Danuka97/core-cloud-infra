provider "google" {
  project = var.project_id
  region  = var.region
}

# Project Creation (if you are managing projects via terraform)
module "dev_project" {
  source             = "../modules/project_factory"
  environment        = "dev"
  billing_account_id = var.billing_account_id
  region             = var.region
}

# The VPC network relies on the project being created first
module "dev_network" {
  source       = "../modules/vpc_network"
  # Use the output from the project module, ensuring dependency order
  project_id   = module.dev_project.project_id
  network_name = var.network_name
  region       = var.region
  subnet_cidr  = var.subnet_cidr
}