locals {
  backend_inegs = { for k, v in var.backends : k =>
    {
      type       = "sneg"
      fqdn       = v.fqdn
      ip_address = v.ip_address
      port       = coalesce(v.port, 443) # Default to HTTPS since this is going via Interet
    } if v.fqdn != null || v.ip_address != null
  }
}

# Internet Network Endpoint Groups
resource "google_compute_global_network_endpoint_group" "default" {
  for_each              = local.backend_inegs
  project               = var.project_id
  name                  = "${each.key}-${each.value.port}"
  network_endpoint_type = each.value.fqdn != null ? "INTERNET_FQDN_PORT" : "INTERNET_IP_PORT"
  default_port          = 443
}

# Internet Network Endpoints
resource "google_compute_global_network_endpoint" "default" {
  for_each                      = local.backend_inegs
  project                       = var.project_id
  global_network_endpoint_group = google_compute_global_network_endpoint_group.default[each.key].id
  fqdn                          = each.value.fqdn
  ip_address                    = each.value.fqdn != null ? null : each.value.ip_address
  port                          = each.value.port
}