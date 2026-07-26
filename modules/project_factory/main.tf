# 1. Configure the Provider for Administrative Actions
# (touch: verifying CI pipeline processes all environments end-to-end)
provider "google" {
  region = var.region
}

# 2. Generate a Random Suffix for Global Uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

# 3. Fetch the billing account ID directly from Secret Manager instead of
# accepting it as a plaintext variable/tfvars value.
data "google_secret_manager_secret_version" "billing_account" {
  secret  = "billing-account-id"
  project = var.secrets_project_id
}

# 3b. Fetch the org ID from Secret Manager the same way, so it never needs
# to be stored in a tracked tfvars file.
data "google_secret_manager_secret_version" "org_id" {
  secret  = "org-id"
  project = var.secrets_project_id
}

# 4. Create the New Environment Project
resource "google_project" "env_project" {
  name            = "${var.app_name}-${var.environment}"
  project_id      = "${var.app_name}-${var.environment}-${random_id.suffix.hex}"
  org_id          = data.google_secret_manager_secret_version.org_id.secret_data
  billing_account = data.google_secret_manager_secret_version.billing_account.secret_data

  # auto_create_network defaults to true, which creates a legacy "default"
  # VPC with permissive built-in firewall rules. This project's networking
  # is defined explicitly by modules/vpc_network instead, so the default
  # network is unwanted attack surface, not a convenience.
  auto_create_network = false
}

# 5. Enable Required APIs (Optional but recommended)
resource "google_project_service" "compute_api" {
  project            = google_project.env_project.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# Audit logging must be explicitly configured per-service (Admin Activity
# logs are always on and can't be disabled, but Data Access logs for reads
# and writes are opt-in). ALLOW_ALL covers Data Access logging for every
# service on this project.
resource "google_project_iam_audit_config" "all_services" {
  project = google_project.env_project.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}