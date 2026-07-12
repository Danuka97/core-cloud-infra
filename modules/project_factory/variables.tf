variable "environment" {
  description = "The environment name (e.g., dev, prod, uat)"
  type        = string
}

variable "region" {
  description = "The region to deploy resources into"
  type        = string
  default     = "europe-west2"
}

variable "billing_account_id" {
  description = "The GCP billing account ID"
  type        = string
}

# variable "org_id" {
#   description = "The GCP Organization ID"
#   type        = string
# }