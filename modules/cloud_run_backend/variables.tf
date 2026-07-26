variable "project_id" {
  description = "The GCP project ID to deploy the Cloud Run service into"
  type        = string
}

variable "region" {
  description = "The region to deploy the Cloud Run service into"
  type        = string
}

variable "app_name" {
  description = "The application name, used to name the Cloud Run service"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, uat, prod)"
  type        = string
}

variable "container_image" {
  description = "The container image to deploy. Defaults to a public placeholder so terraform apply succeeds before any real backend image has been built and pushed."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "network_id" {
  description = "The self-link or ID of the VPC network the Cloud Run service should reach private resources through"
  type        = string
}

variable "vpc_connector_cidr" {
  description = "A /28 CIDR range, distinct from the environment's main subnet, dedicated to the Serverless VPC Access connector"
  type        = string
}
