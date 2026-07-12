#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./scaffold_app.sh <app-name>"
  echo "Example: ./scaffold_app.sh data-warehouse"
  exit 1
fi

APP_NAME=$1
BASE_DIR="applications/${APP_NAME}"
STATE_BUCKET="project-178eec10-8102-4697-a53-tf-state"
BILLING_ID="REDACTED-BILLING-ACCOUNT-ID"
REGION="europe-west2"
PROJECT_ID="project-178eec10-8102-4697-a53" # Authenticating project

echo "Scaffolding new application: ${APP_NAME}..."

ENVIRONMENTS=("dev" "uat" "prod")

for ENV in "${ENVIRONMENTS[@]}"; do
  ENV_DIR="${BASE_DIR}/${ENV}"
  mkdir -p "${ENV_DIR}"

  # 1. backend.tf - Industry Standard: Strict State Isolation
  cat <<EOF > "${ENV_DIR}/backend.tf"
terraform {
  backend "gcs" {
    bucket = "${STATE_BUCKET}"
    prefix = "terraform/state/${APP_NAME}/${ENV}"
  }
}
EOF

  # 2. versions.tf - Industry Standard: Provider/Version Pinning
  cat <<EOF > "${ENV_DIR}/versions.tf"
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
EOF

  # 3. main.tf - Industry Standard: Thin Composition Layer
  cat <<EOF > "${ENV_DIR}/main.tf"
provider "google" {
  project = var.project_id
  region  = var.region
}

module "env" {
  source              = "../../../modules/environment"
  environment         = "${ENV}"
  billing_account_id  = var.billing_account_id
  region              = var.region
  network_name        = var.network_name
  subnet_cidr         = var.subnet_cidr
}
EOF

  # 4. variables.tf - Industry Standard: Strict Typing & Descriptions
  cat <<EOF > "${ENV_DIR}/variables.tf"
variable "project_id" {
  description = "The GCP project ID used to authenticate the provider"
  type        = string
}

variable "region" {
  description = "The region to deploy resources into"
  type        = string
  default     = "${REGION}"
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
EOF

  # 5. terraform.tfvars - Generates pseudo-random non-overlapping CIDRs 
  # to prevent networking clashes out-of-the-gate.
  if [ "$ENV" == "dev" ]; then CIDR="10.10.1.0/24"; fi
  if [ "$ENV" == "uat" ]; then CIDR="10.20.1.0/24"; fi
  if [ "$ENV" == "prod" ]; then CIDR="10.30.1.0/24"; fi

  cat <<EOF > "${ENV_DIR}/terraform.tfvars"
project_id         = "${PROJECT_ID}"
region             = "${REGION}"
network_name       = "${APP_NAME}-${ENV}-vpc"
subnet_cidr        = "${CIDR}"
billing_account_id = "${BILLING_ID}"
EOF

  echo "Created ${ENV_DIR}"
done

echo "Scaffolding complete for ${APP_NAME}!"
echo "Please review the CIDR ranges in ${BASE_DIR}/*/terraform.tfvars to ensure no environment overlaps."
