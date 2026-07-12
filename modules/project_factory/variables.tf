variable "environment" {
  description = "The environment name (e.g., dev, prod, uat)"
  type        = string
}

variable "app_name" {
  description = "The application name, used to scope the project name/ID (e.g., core-app, task-manager)"
  type        = string
}

variable "region" {
  description = "The region to deploy resources into"
  type        = string
  default     = "europe-west2"
}

variable "secrets_project_id" {
  description = "The GCP project ID where the 'billing-account-id' Secret Manager secret lives (the bootstrap/admin project)"
  type        = string
}