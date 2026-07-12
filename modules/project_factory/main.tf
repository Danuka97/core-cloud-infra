# 1. Configure the Provider for Administrative Actions
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
  name            = "core-infra-${var.environment}"
  project_id      = "core-infra-${var.environment}-${random_id.suffix.hex}"
  org_id          = data.google_secret_manager_secret_version.org_id.secret_data
  billing_account = data.google_secret_manager_secret_version.billing_account.secret_data
}

# 5. Enable Required APIs (Optional but recommended)
resource "google_project_service" "compute_api" {
  project = google_project.env_project.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}