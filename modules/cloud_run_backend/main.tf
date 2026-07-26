# Customer-managed encryption key for the Artifact Registry repo below
# (Checkov CKV_GCP_84) - Google's default encryption-at-rest already
# protects the data, but CMEK gives this project control over the key
# itself (rotation, revocation) rather than relying solely on Google-
# managed keys.
resource "google_kms_key_ring" "backend" {
  project  = var.project_id
  name     = "${var.app_name}-${var.environment}-registry"
  location = var.region
}

resource "google_kms_crypto_key" "backend" {
  name            = "${var.app_name}-${var.environment}-registry-key"
  key_ring        = google_kms_key_ring.backend.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

# Artifact Registry's own service agent needs to be able to use the key to
# encrypt/decrypt on the repo's behalf - without this binding, creating a
# CMEK-backed repository fails at the API level.
resource "google_project_service_identity" "artifactregistry" {
  provider = google-beta
  project  = var.project_id
  service  = "artifactregistry.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "artifactregistry_encrypter" {
  crypto_key_id = google_kms_crypto_key.backend.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.artifactregistry.email}"
}

# Where the app-delivery pipeline (a separate Cloud Build trigger/file from
# the Terraform pipeline that provisions this module) pushes built backend
# images to. One repo per environment, matching this repo's per-environment-
# project isolation pattern rather than a single shared registry.
resource "google_artifact_registry_repository" "backend" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.app_name}-${var.environment}"
  format        = "DOCKER"
  kms_key_name  = google_kms_crypto_key.backend.id

  depends_on = [google_kms_crypto_key_iam_member.artifactregistry_encrypter]
}

# Serverless VPC Access connector - lets the Cloud Run service reach
# resources on the environment's private VPC (e.g. Vertex AI over private
# networking, or anything else on this project's subnet).
resource "google_vpc_access_connector" "connector" {
  name          = "${var.app_name}-${var.environment}-conn"
  project       = var.project_id
  region        = var.region
  network       = var.network_id
  ip_cidr_range = var.vpc_connector_cidr
}

# The shared backend API that both the iOS app and the website call.
# Ingress is restricted (not "all") and invocation requires IAM auth by
# default (no allUsers binding here) - callers authenticate via Firebase-
# issued tokens at the application layer, and/or an explicit IAM invoker
# binding is granted separately per caller as needed.
resource "google_cloud_run_v2_service" "backend" {
  name     = "${var.app_name}-${var.environment}-backend"
  project  = var.project_id
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = var.container_image
    }

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }
  }
}
