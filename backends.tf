locals {
  backend_services = { for k, v in merge(local.backend_snegs, local.backend_inegs) : k =>
    merge(v, try(lookup(var.backends, k, null)), {})
  }
}

# Global Backend Service
resource "google_compute_backend_service" "default" {
  for_each              = local.is_global ? local.backend_services : {}
  project               = var.project_id
  name                  = "${local.name}-${each.key}"
  protocol              = "HTTPS"
  load_balancing_scheme = local.lb_scheme
  timeout_sec           = each.value.type == "sneg" ? null : each.value.timeout
  dynamic "backend" {
    for_each = each.value.type == "instance_group" ? [true] : []
    content {
      group           = each.value.instance_group_id
      capacity_scaler = local.capacity_scaler
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

# Regional Backend Service
resource "google_compute_region_backend_service" "default" {
  for_each              = local.is_global ? {} : local.backend_services
  project               = var.project_id
  name                  = "${local.name}-${each.key}"
  protocol              = "HTTPS"
  load_balancing_scheme = local.lb_scheme
  timeout_sec           = each.value.timeout
  dynamic "backend" {
    for_each = each.value.type == "instance_group" ? [true] : []
    content {
      group           = each.value.instance_group_id
      capacity_scaler = local.capacity_scaler
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