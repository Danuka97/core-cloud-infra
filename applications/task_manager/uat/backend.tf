terraform {
  backend "gcs" {
    bucket = "core-infra-seed-8274-tf-state"
    prefix = "terraform/state/task_manager/uat"
  }
}
