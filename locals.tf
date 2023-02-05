locals {
  name           = lower(var.name)
  is_global      = var.region == null ? true : false
  is_regional    = local.is_global ? false : true
  is_classic     = local.is_global && var.classic == true ? true : false
  type           = var.ports != null || var.all_ports || var.allow_global_access ? "TCP" : "HTTP"
  is_tcp         = local.type == "TCP" ? true : false
  is_http        = local.is_classic || startswith(local.type, "HTTP") || var.routing_rules != {} && !local.is_tcp ? true : false
  is_internal    = var.subnet_name != null ? true : false
  use_ssc        = local.is_http && var.ssl_certificates == null || length(var.ssl_certificates) < 1 ? true : false
  lb_scheme      = local.is_http ? local.http_lb_scheme : (local.is_internal ? "INTERNAL" : "EXTERNAL")
  http_lb_scheme = local.is_internal ? "INTERNAL_MANAGED" : (local.is_classic ? "EXTERNAL" : "EXTERNAL_MANAGED")
  region         = coalesce(var.region, "us-central1") # Need a region for SNEGs even if backend is global
}
