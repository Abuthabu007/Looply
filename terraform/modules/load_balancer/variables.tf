# Load Balancer Module - Variables

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_prefix" {
  description = "Project prefix for resource naming"
  type        = string
}

variable "ssl_certificate" {
  description = "SSL certificate content"
  type        = string
  sensitive   = true
}

variable "ssl_private_key" {
  description = "SSL private key content"
  type        = string
  sensitive   = true
}

variable "storage_bucket_name" {
  description = "Cloud Storage bucket name for CDN"
  type        = string
}

variable "vpc_network_name" {
  description = "VPC network name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "google_oauth_client_id" {
  description = "Google OAuth 2.0 Client ID for IAP"
  type        = string
  default     = ""
}

variable "enable_iap" {
  description = "Enable Identity-Aware Proxy on backend services"
  type        = bool
  default     = true
}
