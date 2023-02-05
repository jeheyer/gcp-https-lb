locals {
  address_type = local.is_internal ? "INTERNAL" : "EXTERNAL"
}

# Global static IP
resource "google_compute_global_address" "default" {
  count        = local.is_global ? 1 : 0
  project      = var.project_id
  name         = "${local.name}-${local.is_internal ? "ilb" : "elb"}"
  address_type = local.address_type
  ip_version   = "IPV4"
}

# Locals for regional and/or internal LBs
locals {
  network_tier       = local.lb_scheme == "EXTERNAL_MANAGED" ? "STANDARD" : null
  purpose            = local.lb_scheme == "INTERNAL_MANAGED" ? "SHARED_LOADBALANCER_VIP" : null
  network_name       = coalesce(var.network_name, "default")
  network            = endswith(local.lb_scheme, "_MANAGED") ? local.network_name : null
  network_project_id = coalesce(var.network_project_id, var.project_id) # needed for Shared VPC scenarios
  subnet_prefix      = "projects/${local.network_project_id}/regions"
  subnet_id          = local.is_internal ? "${local.subnet_prefix}/${var.region}/subnetworks/${var.subnet_name}" : null
  subnetwork         = local.is_internal ? local.subnet_id : null
}

# Regional static IP
resource "google_compute_address" "default" {
  count        = local.is_global ? 0 : 1
  project      = var.project_id
  name         = "${local.name}-${local.is_internal ? "ilb" : "elb"}"
  address_type = local.address_type
  region       = local.region
  subnetwork   = local.subnetwork
  network_tier = local.network_tier
  purpose      = local.purpose
}