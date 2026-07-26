output "web_app_id" {
  value = google_firebase_web_app.default.app_id
}

output "web_config_secret_id" {
  description = "Secret Manager secret ID holding the Firebase web app config (JSON). Read via a data source, never via tfvars."
  value       = google_secret_manager_secret.firebase_web_config.secret_id
}
