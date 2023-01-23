# Custom SSL/TLS Policy 
resource "google_compute_ssl_policy" "default" {
  count           = var.ssl_policy_name == null ? 1 : 0
  project         = var.project_id
  name            = local.name
  profile         = var.tls_profile
  min_tls_version = var.min_tls_version
}

# Global HTTP Target Proxy
resource "google_compute_target_http_proxy" "http" {
  count   = local.is_global ? 1 : 0
  project = var.project_id
  name    = "${local.name}-http"
  url_map = one(google_compute_url_map.http).id
}
# Regional HTTP Target Proxy
resource "google_compute_region_target_http_proxy" "http" {
  count   = local.is_global ? 0 : 1
  project = var.project_id
  name    = "${local.name}-http"
  url_map = one(google_compute_region_url_map.http).id
  region  = local.region
}

# Global HTTPS Target Proxy
resource "google_compute_target_https_proxy" "https" {
  count            = local.is_global ? 1 : 0
  project          = var.project_id
  name             = "${local.name}-https"
  url_map          = one(google_compute_url_map.https).id
  ssl_certificates = local.use_self_signed_cert ? [google_compute_ssl_certificate.default["localhost"].name] : [for k, v in var.ssl_certificates : google_compute_ssl_certificate.default[k].id]
  ssl_policy       = coalesce(var.ssl_policy_name, one(google_compute_ssl_policy.default).id)
}
# Regional HTTPS Target Proxy
resource "google_compute_region_target_https_proxy" "default" {
  count            = local.is_global ? 0 : 1
  project          = var.project_id
  name             = "${local.name}-https"
  url_map          = one(google_compute_region_url_map.https).id
  ssl_certificates = local.use_self_signed_cert ? [google_compute_ssl_certificate.default["localhost"].name] : [for k, v in var.ssl_certificates : google_compute_ssl_certificate.default[k].id]
  region           = local.region
  # SSL policy support is currently beta
  #ssl_policy       = coalesce(var.ssl_policy_name, one(google_compute_ssl_policy.default).id)
}