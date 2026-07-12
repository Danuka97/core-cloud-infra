terraform {
  backend "gcs" {
    bucket = "project-178eec10-8102-4697-a53-tf-state"
    prefix = "terraform/state/task_manager/dev"
  }
}
