output "address" {
  value = local.is_global ? one(google_compute_global_address.default).address : one(google_compute_address.default).address
}
output "backends" {
  value = { for k, v in merge(local.backend_services, local.backend_buckets) : k => v.type }
}
output "name" { value = local.name }
output "type" { value = local.type }
output "is_global" { value = local.is_global }
output "is_regional" { value = local.is_regional }
output "is_classic" { value = local.is_classic }
output "is_internal" { value = local.is_internal }
output "is_http" { value = local.is_http }
output "lb_scheme" { value = local.lb_scheme }
