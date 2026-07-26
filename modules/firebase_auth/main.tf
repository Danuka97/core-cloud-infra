# google_firebase_project / google_firebase_web_app are beta-only resources
# at this provider version (no GA equivalent yet) - google-beta is required
# specifically for these two, everything else in this module is plain google.
resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id
}

# Identity Platform / Firebase Auth sign-in configuration. GA on the plain
# google provider. Starts with email/password enabled; other providers
# (Sign in with Apple, Google, etc.) can be added here later via
# google_identity_platform_default_supported_idp_config.
resource "google_identity_platform_config" "default" {
  project = var.project_id

  sign_in {
    email {
      enabled           = true
      password_required = true
    }
  }

  depends_on = [google_firebase_project.default]
}

# Register a web app so the website has a Firebase app to authenticate
# against. The iOS app registers separately (google_firebase_apple_app,
# also beta) once there's a real bundle ID to register - left out for now
# since none exists yet; add it the same way when ready.
resource "google_firebase_web_app" "default" {
  provider     = google-beta
  project      = var.project_id
  display_name = "${var.app_name}-${var.environment}-web"

  depends_on = [google_firebase_project.default]
}

data "google_firebase_web_app_config" "default" {
  provider   = google-beta
  web_app_id = google_firebase_web_app.default.app_id
  project    = var.project_id
}

# The web app config (including its API key) is written to Secret Manager
# rather than left as a plain Terraform output, following the same
# secrets-never-in-tracked-files pattern used for billing-account-id/org-id.
resource "google_secret_manager_secret" "firebase_web_config" {
  project   = var.secrets_project_id
  secret_id = "firebase-web-config-${var.app_name}-${var.environment}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "firebase_web_config" {
  secret = google_secret_manager_secret.firebase_web_config.id
  secret_data = jsonencode({
    apiKey            = data.google_firebase_web_app_config.default.api_key
    authDomain        = data.google_firebase_web_app_config.default.auth_domain
    projectId         = var.project_id
    appId             = google_firebase_web_app.default.app_id
    messagingSenderId = data.google_firebase_web_app_config.default.messaging_sender_id
  })
}
