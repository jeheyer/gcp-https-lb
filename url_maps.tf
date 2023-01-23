locals {
  default_service_id = local.is_global ? try(coalesce(
     lookup(google_compute_backend_service.default, var.default_backend, null),
     lookup(google_compute_backend_bucket.default, var.default_backend, null),
  ).id, null) : null
}

# Global URL Map for HTTP
resource "google_compute_url_map" "http" {
  count           = local.is_global ? 1 : 0
  project         = var.project_id
  name            = "${local.name}-http"
  default_service = null
  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}
# Regional URL Map for HTTP
resource "google_compute_region_url_map" "http" {
  count           = local.is_global ? 0 : 1
  project         = var.project_id
  name            = "${local.name}-http"
  default_service = null
  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
  region = local.region
}

# Global HTTPS URL MAP
resource "google_compute_url_map" "https" {
  count           = local.is_global ? 1 : 0
  project         = var.project_id
  name            = "${local.name}-https"
  default_service = local.default_service_id
  dynamic "host_rule" {
    for_each = coalesce(var.routing_rules, {})
    content {
      path_matcher = host_rule.key
      hosts        = host_rule.value.hosts
    }
  }
  dynamic "path_matcher" {
    for_each = coalesce(var.routing_rules, {})
    content {
      name            = path_matcher.key
      default_service = local.default_service_id
      dynamic "path_rule" {
        for_each = coalesce(path_matcher.value.path_rules, [])
        content {
          paths   = path_rule.value.paths
          service = path_rule.value.backend
        }
      }
    }
  }
}
# Regional HTTPS URL MAP
resource "google_compute_region_url_map" "https" {
  count   = local.is_global ? 0 : 1
  project = var.project_id
  name    = "${local.name}-https"
  #default_service = coalesce(var.default_service_id, google_compute_backend_service.default[var.default_backend].id)
  default_service = google_compute_backend_bucket.default[var.default_backend].id
  region          = local.region
}
