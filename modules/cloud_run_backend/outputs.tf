output "service_url" {
  value = google_cloud_run_v2_service.backend.uri
}

output "service_name" {
  value = google_cloud_run_v2_service.backend.name
}

output "artifact_registry_repository_url" {
  description = "Docker push/pull URL prefix for this environment's Artifact Registry repo, e.g. <region>-docker.pkg.dev/<project>/<repo>"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.backend.repository_id}"
}
