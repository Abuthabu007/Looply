# Storage Module - Variables

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_prefix" {
  description = "Project prefix for resource naming"
  type        = string
}

variable "primary_region" {
  description = "Primary GCP region for bucket location"
  type        = string
}

variable "log_bucket_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 90
}

variable "video_bucket_versioning" {
  description = "Enable versioning for videos bucket"
  type        = bool
  default     = true
}

variable "cloud_run_service_account_email" {
  description = "Cloud Run service account email"
  type        = string
}

variable "storage_service_account_email" {
  description = "Storage service account email"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
