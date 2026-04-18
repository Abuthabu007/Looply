# Load Balancer Module - Variables

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_prefix" {
  description = "Project prefix for resource naming"
  type        = string
}

variable "primary_region" {
  description = "Primary GCP region for resources"
  type        = string
}

variable "secondary_region" {
  description = "Secondary GCP region for multi-region deployment"
  type        = string
}

variable "enable_secondary_region" {
  description = "Enable secondary region for multi-region deployment"
  type        = bool
  default     = true
}

variable "certificate_domains" {
  description = "List of domains for Google-managed SSL certificate"
  type        = list(string)
  default     = []
}

variable "google_oauth_client_id" {
  description = "Google OAuth 2.0 Client ID for IAP"
  type        = string
  default     = ""
  sensitive   = false
}

variable "google_oauth_client_secret" {
  description = "Google OAuth 2.0 Client Secret for IAP"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_iap" {
  description = "Enable Identity-Aware Proxy on backend services"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}