locals {
  # Generate a map of backends that are buckets
  backend_buckets = { for k, v in var.backends : k =>
    {
      type        = "bucket"
      bucket_name = v.bucket_name
      description = v.description
      enable_cdn  = coalesce(v.enable_cdn, false)
    } if v.bucket_name != null
  }
}

# Backend Buckets
resource "google_compute_backend_bucket" "default" {
  for_each    = local.backend_buckets
  project     = var.project_id
  name        = "${local.name}-${each.value.bucket_name}"
  description = each.value.description
  bucket_name = each.value.bucket_name
  enable_cdn  = each.value.enable_cdn
}