variable "org_id" {
  type        = string
  description = "REDACTED-ORG-ID"
}

variable "billing_account_id" {
  type        = string
  description = "REDACTED-BILLING-ACCOUNT-ID"
}

variable "github_app_installation_id" {
  type        = string
  description = "The installation ID of the Google Cloud Build GitHub App on the target GitHub repo/org."
}

variable "github_oauth_token_secret_version" {
  type        = string
  description = "The Secret Manager secret version resource name holding the GitHub OAuth token, e.g. projects/<num>/secrets/<name>/versions/<ver>."
}