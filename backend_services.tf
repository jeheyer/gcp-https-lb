locals {
  backend_services = merge(local.backend_snegs, local.backend_inegs, local.backend_igs)
  #  merge(v, try(lookup(var.backends, k, null)), {})
  #}
  capacity_scaler       = local.lb_scheme == "EXTERNAL_MANAGED" ? 1.0 : null
  balancing_mode        = local.lb_scheme == "INTERNAL_MANAGED" ? "UTILIZATION" : "CONNECTION"
  max_utilization       = local.balancing_mode == "UTILIZATION" ? 0.8 : null
  max_rate_per_instance = local.balancing_mode == "RATE" ? 1024 : null
  max_connections       = local.lb_scheme == "EXTERNAL_MANAGED" ? 32768 : null
}

# Global Backend Service
resource "google_compute_backend_service" "default" {
  for_each              = local.is_global ? local.backend_services : local.backend_services #{}
  project               = var.project_id
  name                  = "${local.name}-${each.key}"
  protocol              = "HTTPS"
  load_balancing_scheme = local.lb_scheme
  timeout_sec           = each.value.type == "sneg" ? null : coalesce(each.value.timeout, var.backend_timeout)
  dynamic "backend" {
    for_each = each.value.type == "igs" ? [local.backend_igs] : []
    content {
      group                 = backend.value
      balancing_mode        = local.balancing_mode
      max_rate_per_instance = local.max_rate_per_instance
      capacity_scaler       = local.capacity_scaler
      max_utilization       = local.max_utilization
      max_connections       = local.max_connections
    }
  }
  dynamic "backend" {
    for_each = each.value.type == "sneg" ? [true] : []
    content {
      group           = google_compute_region_network_endpoint_group.default[each.key].id
      capacity_scaler = local.capacity_scaler
    }
  }
  dynamic "backend" {
    for_each = each.value.type == "ineg" ? [true] : []
    content {
      group           = google_compute_global_network_endpoint_group.default[each.key].id
      capacity_scaler = local.capacity_scaler
    }
  }
  dynamic "log_config" {
    for_each = each.value.logging ? [true] : []
    content {
      enable      = true
      sample_rate = each.value.logging_rate
    }
  }
  #security_policy = google_compute_security_policy.checkpoint-cloud-armor-policy.id
}

/* Regional Backend Service
resource "google_compute_region_backend_service" "default" {
  for_each              = local.is_global ? {} : local.backend_services
  project               = var.project_id
  name                  = "${local.name}-${each.key}"
  protocol              = "HTTPS"
  load_balancing_scheme = local.lb_scheme
  timeout_sec           = each.value.timeout
  dynamic "backend" {
    for_each = each.value.type == "igs" ? [local.backend_igs] : []
    content {
      group                 = backend.value
      balancing_mode        = local.balancing_mode
      max_rate_per_instance = local.max_rate_per_instance
      capacity_scaler       = local.capacity_scaler
      max_utilization       = local.max_utilization
      max_connections       = local.max_connections
    }
  }
  dynamic "backend" {
    for_each = each.value.type == "sneg" ? [true] : []
    content {
      group           = google_compute_region_network_endpoint_group.default[each.key].id
      capacity_scaler = local.capacity_scaler
    }
  }
  dynamic "log_config" {
    for_each = each.value.logging ? [true] : []
    content {
      enable      = true
      sample_rate = each.value.logging_rate
    }
  }
  region = local.region
  #security_policy = google_compute_security_policy.checkpoint-cloud-armor-policy.id
}
*/
