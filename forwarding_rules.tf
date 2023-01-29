
# Global External static IP 
resource "google_compute_global_address" "default" {
  count        = local.is_global ? 1 : 0
  project      = var.project_id
  name         = "${local.name}-https-elb"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}
# Regional External static IP
resource "google_compute_address" "default" {
  count        = local.is_global ? 0 : 1
  project      = var.project_id
  name         = "${local.name}-elb"
  address_type = "EXTERNAL"
  region       = local.region
}

# Global HTTP Forwarding rule
resource "google_compute_global_forwarding_rule" "http" {
  count                 = local.is_global ? 1 : 0
  project               = var.project_id
  name                  = "${local.name}-http"
  port_range            = var.http_port
  target                = one(google_compute_target_http_proxy.default).id
  ip_address            = one(google_compute_global_address.default).id
  load_balancing_scheme = local.lb_scheme
}
# Regional HTTP Forwarding rule
resource "google_compute_forwarding_rule" "http" {
  count                 = local.is_global ? 0 : 1
  project               = var.project_id
  name                  = "${local.name}-http"
  port_range            = var.http_port
  target                = one(google_compute_region_target_http_proxy.default).id
  ip_address            = one(google_compute_address.default).id
  load_balancing_scheme = local.lb_scheme
  region                = local.region
}

# Global HTTPS Forwarding Rule
resource "google_compute_global_forwarding_rule" "https" {
  count                 = local.is_global ? 1 : 0
  project               = var.project_id
  name                  = "${local.name}-https"
  port_range            = var.https_port
  target                = one(google_compute_target_https_proxy.default).id
  ip_address            = one(google_compute_global_address.default).id
  load_balancing_scheme = local.lb_scheme
}
# Regional HTTPS Forwarding Rule
resource "google_compute_forwarding_rule" "https" {
  count                 = local.is_global ? 0 : 1
  project               = var.project_id
  name                  = "${local.name}-https"
  port_range            = var.https_port
  target                = one(google_compute_region_target_https_proxy.default).id
  ip_address            = one(google_compute_address.default).id
  load_balancing_scheme = local.lb_scheme
  region                = local.region
}

