output "address" {
  value = local.is_global ? one(google_compute_global_address.default).address : one(google_compute_address.default).address
}
