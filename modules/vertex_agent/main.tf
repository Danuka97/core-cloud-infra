# There is no Terraform resource for Vertex AI Agent Engine (the "Reasoning
# Engine" API) at this repo's pinned provider version (~> 5.0) - the
# google_vertex_ai_reasoning_engine resource only exists from provider
# v7.6.0+, a two-major-version jump this repo hasn't taken. Creating/
# deploying the actual agent has to happen outside Terraform for now (via
# the google-cloud-aiplatform Python SDK or gcloud), once there's real agent
# code to deploy.
#
# What Terraform CAN and does manage today: the project-level prerequisites
# the agent will need regardless of how it's ultimately deployed - the
# Vertex AI API (enabled by project_factory's for_each already) and a
# dedicated service account with least-privilege access, so the deploy step
# has an identity to run as without granting it broad project-Editor rights.

resource "google_service_account" "agent" {
  project      = var.project_id
  account_id   = "${var.app_name}-${var.environment}-agent"
  display_name = "${var.app_name} ${var.environment} - Vertex AI agent identity"
}

# Lets the agent call Vertex AI (model inference, sessions, etc.). Scoped to
# this one service account, not a broad project-level grant to a shared SA.
resource "google_project_iam_member" "agent_vertex_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.agent.email}"
}
