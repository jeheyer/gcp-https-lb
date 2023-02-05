locals {
  default_balancing_mode = local.type == "TCP" ? "CONNECTION" : "UTILIZATION"
  locality_lb_policy     = endswith(local.lb_scheme, "_MANAGED") ? "ROUND_ROBIN" : null
  backend_services = { for k, v in var.backends : k => {
    # Determine backend type by seeing if a key has been created for an INEG or SNEG
    type = coalesce(
      lookup(local.snegs, k, null),
      lookup(local.inegs, k, null),
      { type = "igs" } # assume instance groups
    ).type
    description  = coalesce(v.description, "Backend Service")
    protocol     = lookup(local.snegs, k, null) != null ? null : local.type #upper(coalesce(var.type, coalesce(v.protocol, v.port == 80 ? "http" : "https")))
    timeout      = lookup(local.snegs, k, null) != null ? null : coalesce(v.timeout, var.backend_timeout, 30)
    logging      = coalesce(v.logging, false)
    logging_rate = coalesce(v.logging, false) ? coalesce(v.logging_rate, 1.0) : null
    enable_cdn   = coalesce(v.enable_cdn, false)
    groups = coalesce(
      lookup(local.snegs, k, null) != null ? [google_compute_region_network_endpoint_group.default[k].id] : null,
      local.is_global ? (lookup(local.inegs, k, null) != null ? [google_compute_global_network_endpoint_group.default[k].id] : null) : null,
      coalesce(v.ig_ids, [])
    )
    affinity_type = v.affinity_type
    region        = local.is_regional ? coalesce(v.region, local.region) : null
  } if lookup(local.backend_buckets, k, null) == null && v.bucket_name == null && v.type != "bucket" }
  hc_prefix = "projects/${var.project_id}/${local.is_regional ? "regions/${var.region}" : "global"}/healthChecks"
  backend_options = { for k, v in var.backends : k => {
    capacity_scaler       = endswith(local.lb_scheme, "_MANAGED") ? coalesce(v.capacity_scaler, 1.0) : null
    max_connections       = local.is_global && local.type == "TCP" ? coalesce(v.max_connections, 32768) : null
    max_utilization       = endswith(local.lb_scheme, "_MANAGED") ? coalesce(v.max_utilization, 0.8) : null
    max_rate_per_instance = endswith(local.lb_scheme, "_MANAGED") ? coalesce(v.max_rate_per_instance, 512) : null
    healthcheck_id        = try(coalesce(v.healthcheck_id, "${local.hc_prefix}/${v.healthcheck_name}"), null)
  } if lookup(local.backend_buckets, k, null) == null }
}

# Global Backend Service
resource "google_compute_backend_service" "default" {
  for_each              = local.is_global ? local.backend_services : {}
  project               = var.project_id
  name                  = "${local.name}-${each.key}"
  load_balancing_scheme = local.lb_scheme
  locality_lb_policy    = local.locality_lb_policy
  protocol              = each.value.protocol
  timeout_sec           = each.value.timeout
  health_checks         = each.value.type == "igs" ? [local.backend_options[each.key].healthcheck_id] : null
  session_affinity      = each.value.type == "igs" ? coalesce(each.value.affinity_type, "NONE") : null
  #security_policy = google_compute_security_policy.checkpoint-cloud-armor-policy.id
  dynamic "backend" {
    for_each = each.value.groups
    content {
      group                 = backend.value
      capacity_scaler       = local.backend_options[each.key].capacity_scaler
      balancing_mode        = each.value.type == "ineg" ? null : local.default_balancing_mode
      max_rate_per_instance = each.value.type == "igs" ? local.backend_options[each.key].max_rate_per_instance : null
      max_utilization       = each.value.type == "igs" ? local.backend_options[each.key].max_utilization : null
      max_connections       = each.value.type == "igs" ? local.backend_options[each.key].max_connections : null
    }
  }
  dynamic "log_config" {
    for_each = each.value.logging ? [true] : []
    content {
      enable      = true
      sample_rate = each.value.logging_rate
    }
  }
}

# Regional Backend Service
resource "google_compute_region_backend_service" "default" {
  for_each              = local.is_global ? {} : local.backend_services
  project               = var.project_id
  name                  = "${local.name}-${each.key}"
  load_balancing_scheme = local.lb_scheme
  locality_lb_policy    = local.locality_lb_policy
  description           = each.value.description
  protocol              = each.value.protocol
  timeout_sec           = each.value.timeout
  health_checks         = each.value.type == "igs" ? [local.backend_options[each.key].healthcheck_id] : null
  session_affinity      = each.value.type == "igs" ? coalesce(each.value.affinity_type, "NONE") : null
  #security_policy = google_compute_security_policy.checkpoint-cloud-armor-policy.id
  dynamic "backend" {
    for_each = each.value.groups
    content {
      group                 = backend.value
      capacity_scaler       = local.backend_options[each.key].capacity_scaler
      balancing_mode        = each.value.type == "ineg" ? null : local.default_balancing_mode
      max_rate_per_instance = each.value.type == "igs" ? local.backend_options[each.key].max_rate_per_instance : null
      max_utilization       = each.value.type == "igs" ? local.backend_options[each.key].max_utilization : null
      max_connections       = each.value.type == "igs" ? local.backend_options[each.key].max_connections : null
    }
  }
  dynamic "log_config" {
    for_each = each.value.logging ? [true] : []
    content {
      enable      = true
      sample_rate = each.value.logging_rate
    }
  }
  region = each.value.region
}
