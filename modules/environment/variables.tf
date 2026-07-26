variable "environment" {
  description = "The environment name (e.g., dev, uat, prod)"
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

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR range for the private subnet"
  type        = string
}

variable "container_image" {
  description = "The backend container image to deploy to Cloud Run. Defaults to a public placeholder so terraform apply succeeds before any real backend image has been built and pushed."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "vpc_connector_cidr" {
  description = "A /28 CIDR range, distinct from subnet_cidr, dedicated to the Serverless VPC Access connector"
  type        = string
}
