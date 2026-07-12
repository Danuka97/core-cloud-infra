variable "project_id" {
  description = "The GCP project ID for this environment"
  type        = string
}

variable "region" {
  description = "The region to deploy resources into"
  type        = string
  default     = "europe-west2"
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR range for the private subnet"
  type        = string
}

variable "billing_account_id" {
  description = "The GCP billing account ID"
  type        = string
}