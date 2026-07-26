provider "google" {
  project = var.project_id
  region  = var.region
}

# Fetch current project details
data "google_project" "current" {}

# 1. Ensure required APIs are enabled
# cloudkms/firebase are needed here (not just on spoke projects) because
# those two APIs bill/check quota against whichever project the Terraform
# provider authenticates as (this seed project, since that's the CI service
# account's own project) rather than the resource's project= argument -
# without these enabled here, google_kms_key_ring/google_firebase_project
# fail with SERVICE_DISABLED against this project even when correctly
# targeting a spoke project.
resource "google_project_service" "services" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudkms.googleapis.com",
    "firebase.googleapis.com",
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

# 2b. Store the org ID in Secret Manager too, so environment projects can be
# created under the org without the ID ever needing to live in a tracked
# tfvars file.
resource "google_secret_manager_secret" "org_id_secret" {
  secret_id = "org-id"

  replication {
    auto {}
  }

  depends_on = [google_project_service.services]
}

resource "google_secret_manager_secret_version" "org_id_secret_version" {
  secret      = google_secret_manager_secret.org_id_secret.id
  secret_data = var.org_id
}

# 3. Construct the repository ID string directly
locals {
  repo_id = google_cloudbuildv2_repository.core_infra_repo.id

  # GCP now requires triggers to use an explicit user-managed service account
  # rather than the legacy default. We reuse the default Compute Engine SA.
  build_service_account = "projects/${data.google_project.current.project_id}/serviceAccounts/${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

# Grant the service account the roles required to run Cloud Build jobs
# when it is explicitly assigned to a trigger.
resource "google_project_iam_member" "build_sa_builder" {
  project = data.google_project.current.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "build_sa_logging" {
  project = data.google_project.current.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

# The pipeline now reads billing_account_id directly from Secret Manager
# (instead of it being passed around as a plaintext variable), so the CI
# service account needs read access to that specific secret.
# NOTE: roles/secretmanager.secretAccessor only grants secretmanager.versions.access
# (reading the payload) - Terraform's google_secret_manager_secret_version data
# source also calls versions.get (metadata), which requires roles/secretmanager.viewer.
resource "google_secret_manager_secret_iam_member" "build_sa_secret_accessor" {
  secret_id = google_secret_manager_secret.billing_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_secret_manager_secret_iam_member" "build_sa_secret_viewer" {
  secret_id = google_secret_manager_secret.billing_secret.id
  role      = "roles/secretmanager.viewer"
  member    = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

# Same read access for the org-id secret.
resource "google_secret_manager_secret_iam_member" "build_sa_org_id_accessor" {
  secret_id = google_secret_manager_secret.org_id_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_secret_manager_secret_iam_member" "build_sa_org_id_viewer" {
  secret_id = google_secret_manager_secret.org_id_secret.id
  role      = "roles/secretmanager.viewer"
  member    = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

# The CI service account needs org-level rights to create new environment
# projects (project_factory's google_project resource), and a billing role
# to attach the billing account to those newly created projects.
resource "google_organization_iam_member" "build_sa_project_creator" {
  org_id = var.org_id
  role   = "roles/resourcemanager.projectCreator"
  member = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_billing_account_iam_member" "build_sa_billing_user" {
  billing_account_id = var.billing_account_id
  role                = "roles/billing.user"
  member              = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
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

  service_account = local.build_service_account

  repository_event_config {
    repository = local.repo_id
    pull_request {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _ACTION      = "plan"
  }

  depends_on = [
    google_cloudbuildv2_repository.core_infra_repo,
    google_project_iam_member.build_sa_builder,
    google_project_iam_member.build_sa_logging,
  ]
}

# 5. Trigger 2: APPLY on Push to Main
resource "google_cloudbuild_trigger" "apps_push_main_trigger" {
  name     = "apply-infra-push-main"
  location = "europe-west2"

  service_account = local.build_service_account

  repository_event_config {
    repository = local.repo_id
    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _ACTION = "apply"
  }

  depends_on = [
    google_cloudbuildv2_repository.core_infra_repo,
    google_project_iam_member.build_sa_builder,
    google_project_iam_member.build_sa_logging,
  ]
}

# GitHub App installation connection (2nd-gen)
resource "google_cloudbuildv2_connection" "github_connection" {
  name     = "github-connection"
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
  name              = "core-cloud-infra"
  location          = "europe-west2"
  parent_connection = google_cloudbuildv2_connection.github_connection.name
  remote_uri        = "https://github.com/Danuka97/core-cloud-infra.git"
}