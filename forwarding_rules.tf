locals {
  service_id = local.is_global && !local.is_http ? try(coalesce(
    lookup(google_compute_backend_service.default, var.default_backend, null),
    ).id, null) : local.is_regional ? try(coalesce(
    lookup(google_compute_region_backend_service.default, var.default_backend, null)
  ).id, null) : null
  target_id = local.type == "TCP" || local.type == "SSL" ? try(coalesce(
    local.is_global ? one(google_compute_target_tcp_proxy.default) : null
  ).id, null) : null
}

# Global Forwarding rule for TCP or SSL Proxy
resource "google_compute_global_forwarding_rule" "default" {
  count                 = local.is_global && !local.is_http ? length(local.ports) : 0
  project               = var.project_id
  name                  = "${local.name}-${local.ports[count.index]}"
  port_range            = local.ports[count.index]
  target                = local.target_id
  ip_address            = one(google_compute_global_address.default).id
  load_balancing_scheme = local.lb_scheme
  ip_protocol           = local.type
}

# Global Forwarding rule for HTTP
resource "google_compute_global_forwarding_rule" "http" {
  count                 = local.is_global && local.is_http ? 1 : 0
  project               = var.project_id
  name                  = "${local.name}-http"
  port_range            = var.http_port
  target                = one(google_compute_target_http_proxy.default).id
  ip_address            = one(google_compute_global_address.default).id
  load_balancing_scheme = local.lb_scheme
}

# Global Forwarding Rule for HTTPS
resource "google_compute_global_forwarding_rule" "https" {
  count                 = local.is_global && local.is_http ? 1 : 0
  project               = var.project_id
  name                  = "${local.name}-https"
  port_range            = var.https_port
  target                = one(google_compute_target_https_proxy.default).id
  ip_address            = one(google_compute_global_address.default).id
  load_balancing_scheme = local.lb_scheme
}

locals {
  ports     = length(coalesce(var.ports, [])) > 0 ? var.ports : null
  all_ports = var.all_ports && local.ports == null && var.port_range == null ? true : false
}

# Regional Forwarding rule for Network or TCP/UDP LB
resource "google_compute_forwarding_rule" "default" {
  count                 = local.is_regional && !local.is_http ? 1 : 0
  project               = var.project_id
  name                  = "${local.name}-lb"
  port_range            = var.port_range
  ports                 = local.ports
  all_ports             = local.all_ports
  backend_service       = local.service_id
  target                = null #local.target_id #"smtp" #one(google_compute_target_http_proxy.default).id
  ip_address            = one(google_compute_address.default).id
  load_balancing_scheme = local.lb_scheme
  region                = local.region
  network               = local.network
  subnetwork            = local.subnetwork
  network_tier          = local.network_tier
}

# Regional Forwarding rule for HTTP
resource "google_compute_forwarding_rule" "http" {
  count                 = local.is_regional && local.is_http && var.http_port != null ? 1 : 0
  project               = var.project_id
  name                  = "${local.name}-http"
  port_range            = var.http_port
  target                = one(google_compute_region_target_http_proxy.default).id
  ip_address            = one(google_compute_address.default).id
  load_balancing_scheme = local.lb_scheme
  region                = local.region
  network               = local.network
  subnetwork            = local.subnetwork
  network_tier          = local.network_tier
}

# Regional Forwarding Rule for HTTPS
resource "google_compute_forwarding_rule" "https" {
  count                 = local.is_regional && local.is_http && var.https_port != null ? 1 : 0
  project               = var.project_id
  name                  = "${local.name}-https"
  port_range            = var.https_port
  target                = one(google_compute_region_target_https_proxy.default).id
  ip_address            = one(google_compute_address.default).id
  load_balancing_scheme = local.lb_scheme
  region                = local.region
  network               = endswith(local.lb_scheme, "_MANAGED") ? local.network_name : null
  subnetwork            = startswith(local.lb_scheme, "INTERNAL") ? local.subnet_id : null
  network_tier          = local.lb_scheme == "EXTERNAL_MANAGED" ? "STANDARD" : null
}
