variable "project_id" {
  type        = string
  description = "The target GCP project ID"
}

variable "network_name" {
  type        = string
  description = "The name of the VPC network"
}

variable "region" {
  type        = string
  description = "The GCP region for the subnet"
}

variable "subnet_cidr" {
  type        = string
  description = "The IP address range for the subnet in CIDR block format"
}