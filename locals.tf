locals {
  name                 = lower(var.name)
  is_global            = var.region == null ? true : false
  is_classic           = var.classic == true ? true : false
  use_self_signed_cert = var.ssl_certificates == null || length(var.ssl_certificates) < 1 ? true : false
  lb_scheme            = local.is_classic ? "EXTERNAL" : "EXTERNAL_MANAGED"
  capacity_scaler      = local.lb_scheme == "EXTERNAL_MANAGED" ? 1.0 : null
  region               = coalesce(var.region, "us-central1")
}
