# Custom SSL/TLS Policy 
resource "google_compute_ssl_policy" "default" {
  count           = var.ssl_policy_name == null && local.is_http ? 1 : 0
  project         = var.project_id
  name            = local.name_prefix
  profile         = var.tls_profile
  min_tls_version = var.min_tls_version
}

# Global TCP Proxy
resource "google_compute_target_tcp_proxy" "default" {
  count           = local.is_global && !local.is_http ? 1 : 0
  project         = var.project_id
  name            = "${local.name_prefix}-${lower(local.type)}"
  backend_service = try(lookup(google_compute_backend_service.default, var.default_backend, null).id, null)
}

# Global HTTP Target Proxy
resource "google_compute_target_http_proxy" "default" {
  count   = local.is_global && local.is_http && var.http_port != null ? 1 : 0
  project = var.project_id
  name    = "${local.name_prefix}-http"
  url_map = one(google_compute_url_map.http).id
}
# Regional HTTP Target Proxy
resource "google_compute_region_target_http_proxy" "default" {
  count   = local.is_regional && local.is_http && var.http_port != null ? 1 : 0
  project = var.project_id
  name    = "${local.name_prefix}-http"
  url_map = one(google_compute_region_url_map.http).id
  region  = local.region
}

# Global HTTPS Target Proxy
resource "google_compute_target_https_proxy" "default" {
  count   = local.is_global && local.is_http && var.https_port != null ? 1 : 0
  project = var.project_id
  name    = "${local.name_prefix}-https"
  url_map = one(google_compute_url_map.https).id
  ssl_certificates = local.use_ssc ? [google_compute_ssl_certificate.default["self_signed"].name] : coalesce(
    var.ssl_cert_names,
    [for k, v in local.certs_to_upload : google_compute_ssl_certificate.default[k].id]
  )
  ssl_policy = coalesce(var.ssl_policy_name, one(google_compute_ssl_policy.default).id)
}

# Regional HTTPS Target Proxy
resource "google_compute_region_target_https_proxy" "default" {
  count   = local.is_regional && local.is_http && var.https_port != null ? 1 : 0
  project = var.project_id
  name    = "${local.name_prefix}-https"
  url_map = one(google_compute_region_url_map.https).id
  ssl_certificates = local.use_ssc ? [google_compute_region_ssl_certificate.default["self_signed"].name] : [
    for k, v in local.certs_to_upload : google_compute_region_ssl_certificate.default[k].id
  ]
  region = local.region
  #ssl_policy       = coalesce(var.ssl_policy_name, one(google_compute_ssl_policy.default).id)  # in beta
}
