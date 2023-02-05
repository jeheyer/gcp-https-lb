variable "project_id" {
  description = "GCP Project ID"
  type        = string
}
variable "name" {
  description = "Name for this Load Balancer"
  type        = string
  validation {
    condition     = var.name != null ? length(var.name) < 58 : true
    error_message = "Name cannot exceed 57 characters."
  }
}
variable "classic" {
  description = "Create Classic Load Balancer (or instead use envoy-based platform)"
  type        = bool
  default     = false
}
variable "region" {
  description = "GCP Region Name (regional LB only)"
  type        = string
  default     = null
}
variable "ssl_policy_name" {
  description = "Name of pre-existing SSL Policy to Use for Frontend"
  type        = string
  default     = null
}
variable "tls_profile" {
  description = "If creating SSL profile, the Browser Profile to use"
  type        = string
  default     = "MODERN"
}
variable "min_tls_version" {
  description = "If creating SSL profile, the Minimum TLS Version to allow"
  type        = string
  default     = "TLS_1_2"
}
variable "ssl_certificates" {
  description = "Map of SSL Certificates to upload to Google Certificate Manager"
  type        = map(object({ certificate = string, private_key = string }))
  default     = {}
}
variable "key_algorithm" {
  description = "For self-signed cert, the Algorithm for the Private Key"
  type        = string
  default     = "RSA"
}
variable "key_bits" {
  description = "For self-signed cert, the number for bits for the private key"
  type        = number
  default     = 2048
}
variable "default_service_id" {
  type    = string
  default = null
}
variable "network_name" {
  type    = string
  default = null
}
variable "subnet_name" {
  type    = string
  default = null
}
variable "network_project_id" {
  type    = string
  default = null
}
variable "type" {
  type    = string
  default = null
}
variable "port_range" {
  type    = string
  default = null
}
variable "ports" {
  type    = list(number)
  default = null
}
variable "all_ports" {
  type    = bool
  default = false
}
variable "http_port" {
  description = "HTTP port for LB Frontend"
  type        = number
  default     = 80
}
variable "https_port" {
  description = "HTTPS port for LB Frontend"
  type        = number
  default     = 443
}
variable "allow_global_access" {
  type    = bool
  default = false
}
variable "backend_timeout" {
  description = "Default timeout for all backends in seconds (can be overridden)"
  type        = number
  default     = 30
}
variable "default_backend" {
  description = "Default backend"
  type        = string
  default     = null
}
variable "routing_rules" {
  description = "Route rules to send different hostnames/paths to different backends"
  type = map(object({
    hosts   = list(string)
    backend = optional(string)
    path_rules = optional(list(object({
      paths   = list(string)
      backend = string
    })))
  }))
  default = {}
}
variable "backends" {
  description = "Map of all backend services & buckets"
  type = map(object({
    type                  = optional(string) # We'll try and figure it out automatically
    description           = optional(string)
    region                = optional(string)
    regions               = optional(list(string)) # For deploying serverless to multiple regions
    bucket_name           = optional(string)
    ig_ids                = optional(list(string))
    healthcheck           = optional(string)
    healthcheck_id        = optional(string)
    healthcheck_name      = optional(string)
    cloud_run_name        = optional(string) # Cloud run service name
    container_image       = optional(string) # Default to GCR if not full URL
    docker_image          = optional(string) # Pulls image from docker.io
    container_port        = optional(number)
    psc_target            = optional(string)
    fqdn                  = optional(string)
    ip_address            = optional(string)
    port                  = optional(number)
    protocol              = optional(string)
    enable_cdn            = optional(bool)
    cdn_cache_mode        = optional(string)
    timeout               = optional(number)
    logging               = optional(bool)
    logging_rate          = optional(number)
    affinity_type         = optional(string)
    cloudarmor_policy     = optional(string)
    capacity_scaler       = optional(number)
    max_utilization       = optional(number)
    max_rate_per_instance = optional(number)
    max_connections       = optional(number)
  }))
  default = {}
}