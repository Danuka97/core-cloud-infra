# 1. Configure the Provider for Administrative Actions
provider "google" {
  region = "europe-west2"
}

# 2. Generate a Random Suffix for Global Uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

# 3. Create the Development Project
resource "google_project" "dev_project" {
  name            = "core-infra-dev"
  project_id      = "core-infra-dev-${random_id.suffix.hex}"
  org_id          = var.org_id
  billing_account = var.billing_account_id
}