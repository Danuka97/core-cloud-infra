variable "project_id" {
  description = "The GCP project ID to configure Vertex AI Agent Engine prerequisites in"
  type        = string
}

variable "app_name" {
  description = "The application name, used to name the agent's service account"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, uat, prod)"
  type        = string
}
