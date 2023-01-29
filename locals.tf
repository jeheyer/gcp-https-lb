locals {
  name                 = lower(var.name)
  is_global            = var.region == null ? true : false
  is_classic           = var.classic == true ? true : false
  use_self_signed_cert = var.ssl_certificates == null || length(var.ssl_certificates) < 1 ? true : false
  lb_scheme            = local.is_classic ? "EXTERNAL" : "EXTERNAL_MANAGED"
  region               = coalesce(var.region, "us-central1")
  backend_igs = { for k, v in var.backends : k => merge({
    type   = "igs"
    ig_ids = coalece(to_set(v.ig_ids), [])
  }, v) if v.ig_ids != null }
  backend_buckets = { for k, v in var.backends : k => merge({
    type = "bucket"
  }, v) if v.bucket_name != null }
  backend_snegs = { for k, v in var.backends : k => merge({
    type   = "snegs"
    name   = coalesce(v.container_name, k)
    region = coalesce(v.container_location, var.region, "us-central1")
  }, v) if v.container_name != null || v.container_image != null }
  backend_inegs = { for k, v in var.backends : k => merge({
    type = "ineg"
    port = coalesce(v.port, 443) # Default to HTTPS since this is going via Interet
  }, v) if v.fqdn != null || v.ip_address != null }
}
