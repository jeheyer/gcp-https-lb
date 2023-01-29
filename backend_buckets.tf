
# Backend Buckets
resource "google_compute_backend_bucket" "default" {
  for_each    = local.backend_buckets
  project     = var.project_id
  name        = "${local.name}-${each.value.bucket_name}"
  description = each.value.description
  bucket_name = each.value.bucket_name
  enable_cdn  = each.value.enable_cdn
}