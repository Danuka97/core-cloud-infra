variable "project_id" {
  description = "The GCP project ID to register with Firebase and configure Auth on"
  type        = string
}

variable "app_name" {
  description = "The application name, used as the Firebase web app's display name"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, uat, prod)"
  type        = string
}

variable "secrets_project_id" {
  description = "The GCP project ID (the bootstrap/admin project) where the Firebase web app config gets written as a Secret Manager secret, following the same pattern as billing-account-id/org-id"
  type        = string
}
