locals {
  default_container = {
    name            = "nginx1"
    container_image = "marketplace.gcr.io/google/nginx1"
    container_port  = 80
  }
}

# Cloud Run Services
resource "google_cloud_run_service" "default" {
  for_each = { for k, v in local.backend_snegs : k => v if v.container_image != null }
  project  = var.project_id
  name     = each.value.name
  location = each.value.region
  template {
    spec {
      containers {
        image = each.value.container_image
        ports {
          name           = "http1"
          container_port = each.value.container_port
        }
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}

#
resource "google_cloud_run_service_iam_member" "default" {
  for_each = { for k, v in local.backend_snegs : k => v if v.container_image != null }
  project  = var.project_id
  service  = google_cloud_run_service.default[each.key].name
  location = google_cloud_run_service.default[each.key].location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Serverless Network Endpoint Group 
resource "google_compute_region_network_endpoint_group" "default" {
  for_each              = local.backend_snegs
  project               = var.project_id
  name                  = each.value.name
  network_endpoint_type = each.value.psc_target != null ? "PRIVATE_SERVICE_CONNECT" : "SERVERLESS"
  region                = each.value.region
  psc_target_service    = each.value.psc_target
  dynamic "cloud_run" {
    for_each = each.value.container_image != null ? [true] : []
    content {
      service = google_cloud_run_service.default[each.key].name
    }
  }
}

