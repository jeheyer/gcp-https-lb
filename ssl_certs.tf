# If required, create a private key
resource "tls_private_key" "default" {
  count     = local.use_self_signed_cert ? 1 : 0
  algorithm = var.key_algorithm
  rsa_bits  = var.key_bits
}

# If required, generate a self-signed cert off the private key
resource "tls_self_signed_cert" "default" {
  count           = local.use_self_signed_cert ? 1 : 0
  private_key_pem = one(tls_private_key.default).private_key_pem
  subject {
    common_name  = "localhost.localdomain"
    organization = "Honest Achmed's Used Cars and Certificates"
  }
  validity_period_hours = 24 * 365
  allowed_uses          = ["key_encipherment", "digital_signature", "server_auth"]
}

# Upload SSL Certs
resource "google_compute_ssl_certificate" "default" {
  for_each    = local.is_global ? (local.use_self_signed_cert ? { localhost = {} } : var.ssl_certificates) : {}
  project     = var.project_id
  name        = local.use_self_signed_cert ? null : each.key
  name_prefix = local.use_self_signed_cert ? local.name : null
  private_key = local.use_self_signed_cert ? one(tls_private_key.default).private_key_pem : file("${path.module}/${each.value.private_key}")
  certificate = local.use_self_signed_cert ? one(tls_self_signed_cert.default).cert_pem : file("${path.module}/${each.value.certificate}")
  lifecycle {
    create_before_destroy = true
  }
}
resource "google_compute_region_ssl_certificate" "default" {
  for_each    = local.is_global ? {} : (local.use_self_signed_cert ? { localhost = {} } : var.ssl_certificates)
  project     = var.project_id
  name        = local.use_self_signed_cert ? null : each.key
  name_prefix = local.use_self_signed_cert ? local.name : null
  private_key = local.use_self_signed_cert ? one(tls_private_key.default).private_key_pem : file("${path.module}/${each.value.private_key}")
  certificate = local.use_self_signed_cert ? one(tls_self_signed_cert.default).cert_pem : file("${path.module}/${each.value.certificate}")
  lifecycle {
    create_before_destroy = true
  }
  region = local.region
}

# Google-Managed SSL certificates (Global only)
resource "google_compute_managed_ssl_certificate" "default" {
  count = local.is_global ? 1 : 0
  name  = local.name
  managed {
    domains = ["gcp.whamola.net"]
  }
  project = var.project_id
}