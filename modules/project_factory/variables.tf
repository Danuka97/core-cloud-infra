variable "environment" {
  description = "The environment name (e.g., dev, prod, uat)"
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

# variable "org_id" {
#   description = "The GCP Organization ID"
#   type        = string
# }