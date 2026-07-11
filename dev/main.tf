provider "google" {
  project = "project-178eec10-8102-4697-a53"
  region  = "europe-west2"
}

module "dev_network" {
  source       = "../modules/vpc_network"
  project_id   = "project-178eec10-8102-4697-a53"
  network_name = "dev-vpc"
  region       = "europe-west2"
  subnet_cidr  = "10.0.1.0/24"
}