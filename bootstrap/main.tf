provider "google" {
  project = "project-178eec10-8102-4697-a53"
  region  = "europe-west2"
}

# Fetch current project details
data "google_project" "current" {}

# 1. Ensure required APIs are enabled
resource "google_project_service" "services" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ])
  service            = each.value
  disable_on_destroy = false
}

# 2. Create the Secret Manager Secret
resource "google_secret_manager_secret" "billing_secret" {
  secret_id = "billing-account-id"
  
  replication {
    auto {}
  }
  
  depends_on = [google_project_service.services]
}

resource "google_secret_manager_secret_version" "billing_secret_version" {
  secret      = google_secret_manager_secret.billing_secret.id
  secret_data = var.billing_account_id
}

# 3. Construct the repository ID string directly
locals {
  repo_id = google_cloudbuildv2_repository.core_infra_repo.id
}

# Preserve the state of the old dev trigger since we're restructuring
# We will migrate it to the new "push-main" generic trigger
moved {
  from = google_cloudbuild_trigger.dev_trigger
  to   = google_cloudbuild_trigger.apps_push_main_trigger
}

# 4. Trigger 1: PLAN on Pull Requests
resource "google_cloudbuild_trigger" "apps_pr_plan_trigger" {
  name     = "plan-infra-prs"
  location = "europe-west2"

  repository_event_config {
    repository = local.repo_id
    pull_request {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  # Only trigger if changes happen in the applications/ directory
  included_files = ["applications/**"]

  substitutions = {
    _ACTION      = "plan"
  }

  depends_on = [google_cloudbuildv2_repository.core_infra_repo]
}

# 5. Trigger 2: APPLY on Push to Main
resource "google_cloudbuild_trigger" "apps_push_main_trigger" {
  name     = "apply-infra-push-main"
  location = "europe-west2"

  repository_event_config {
    repository = local.repo_id
    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  # Only trigger if changes happen in the applications/ directory
  included_files = ["applications/**"]

  substitutions = {
    _ACTION = "apply"
  }

  depends_on = [google_cloudbuildv2_repository.core_infra_repo]
}

# GitHub App installation connection (2nd-gen)
resource "google_cloudbuildv2_connection" "github_connection" {
  name     = "GitHub-dw"
  location = "europe-west2"

  github_config {
    app_installation_id = var.github_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = var.github_oauth_token_secret_version
    }
  }

  depends_on = [google_project_service.services]
}

resource "google_cloudbuildv2_repository" "core_infra_repo" {
  name              = "Danuka97-core-cloud-infra"
  location          = "europe-west2"
  parent_connection = google_cloudbuildv2_connection.github_connection.name
  remote_uri        = "https://github.com/Danuka97/core-cloud-infra.git"
}