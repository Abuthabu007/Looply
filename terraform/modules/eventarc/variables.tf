variable "project_prefix" {
  description = "Project prefix for resource naming"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "primary_region" {
  description = "Primary GCP region"
  type        = string
}

variable "secondary_region" {
  description = "Secondary GCP region"
  type        = string
}

variable "enable_secondary_region" {
  description = "Enable secondary region triggers"
  type        = bool
  default     = true
}

variable "videos_bucket_name" {
  description = "Cloud Storage bucket name for videos"
  type        = string
}

variable "cloud_run_service_name" {
  description = "Cloud Run service name (primary region)"
  type        = string
}

variable "cloud_run_service_name_secondary" {
  description = "Cloud Run service name (secondary region)"
  type        = string
}

variable "eventarc_service_account_email" {
  description = "Service account email for Eventarc"
  type        = string
}

variable "tags" {
  description = "Labels for resources"
  type        = map(string)
  default     = {}
}
