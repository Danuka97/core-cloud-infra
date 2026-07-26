# Serverless VPC Access connector - lets the Cloud Run service reach
# resources on the environment's private VPC (e.g. Vertex AI over private
# networking, or anything else on this project's subnet).
resource "google_vpc_access_connector" "connector" {
  name          = "${var.app_name}-${var.environment}-conn"
  project       = var.project_id
  region        = var.region
  network       = var.network_id
  ip_cidr_range = var.vpc_connector_cidr
}

# The shared backend API that both the iOS app and the website call.
# Ingress is restricted (not "all") and invocation requires IAM auth by
# default (no allUsers binding here) - callers authenticate via Firebase-
# issued tokens at the application layer, and/or an explicit IAM invoker
# binding is granted separately per caller as needed.
resource "google_cloud_run_v2_service" "backend" {
  name     = "${var.app_name}-${var.environment}-backend"
  project  = var.project_id
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = var.container_image
    }

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }
  }
}
