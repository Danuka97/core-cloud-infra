output "project_id" {
  value = module.project.project_id
}

output "backend_url" {
  value = module.backend.service_url
}

output "artifact_registry_repository_url" {
  value = module.backend.artifact_registry_repository_url
}

output "firebase_web_app_id" {
  value = module.firebase.web_app_id
}

output "firebase_web_config_secret_id" {
  value = module.firebase.web_config_secret_id
}

output "agent_service_account_email" {
  value = module.vertex_agent.agent_service_account_email
}
