
# Global URL Map for HTTP
resource "google_compute_url_map" "http" {
  count           = local.is_http && local.is_global && var.http_port != null ? 1 : 0
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
  count           = local.is_http && local.is_regional && var.http_port != null ? 1 : 0
  project         = var.project_id
  name            = "${local.name}-http"
  default_service = null
  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
  region = local.region
}

locals {
  # Try to match the default_backend value to a key on the backend resources
  default_service_id = local.is_global && local.is_http ? try(coalesce(
    lookup(google_compute_backend_service.default, var.default_backend, null),
    lookup(google_compute_region_backend_service.default, var.default_backend, null),
    lookup(google_compute_backend_bucket.default, var.default_backend, null),
    ).id, null) : local.is_regional ? try(coalesce(
    lookup(google_compute_region_backend_service.default, var.default_backend, null)
  ).id, null) : null
}

# Global HTTPS URL MAP
resource "google_compute_url_map" "https" {
  count           = local.is_http && local.is_global && var.https_port != null ? 1 : 0
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
      name = path_matcher.key
      default_service = try(coalesce(
        lookup(google_compute_backend_service.default, coalesce(path_matcher.value.backend, path_matcher.key), null),
        lookup(google_compute_backend_bucket.default, coalesce(path_matcher.value.backend, path_matcher.key), null),
      ).id, local.default_service_id)
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
  count           = local.is_http && local.is_regional && var.https_port != null ? 1 : 0
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
      name = path_matcher.key
      default_service = try(coalesce(
        lookup(google_compute_region_backend_service.default, coalesce(path_matcher.value.backend, path_matcher.key), null),
      ).id, local.default_service_id)
      dynamic "path_rule" {
        for_each = coalesce(path_matcher.value.path_rules, [])
        content {
          paths   = path_rule.value.paths
          service = path_rule.value.backend
        }
      }
    }
  }
  region = local.region
}
