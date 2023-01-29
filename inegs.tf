
# Internet Network Endpoint Groups
resource "google_compute_global_network_endpoint_group" "default" {
  for_each              = local.backend_inegs
  project               = var.project_id
  name                  = "${each.key}-${coalesce(each.value.port, 443)}"
  network_endpoint_type = each.value.fqdn != null ? "INTERNET_FQDN_PORT" : "INTERNET_IP_PORT"
  default_port          = 443
}

# Internet Network Endpoints
resource "google_compute_global_network_endpoint" "default" {
  for_each                      = local.backend_inegs
  project                       = var.project_id
  global_network_endpoint_group = google_compute_global_network_endpoint_group.default[each.key].id
  fqdn                          = each.value.fqdn
  ip_address                    = each.value.fqdn != null || each.value.fqdn != "" ? null : each.value.ip_address
  port                          = each.value.port
}