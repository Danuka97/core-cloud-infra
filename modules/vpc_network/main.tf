# 1. Create the Custom VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# 2. Create the Private Subnet
resource "google_compute_subnetwork" "private_subnet" {
  name                     = "${var.network_name}-subnet"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = var.subnet_cidr

  # This is the magic line that allows access to Artifact Registry without internet!
  private_ip_google_access = true 
}