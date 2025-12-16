# Pub/Sub Module - Variables

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_prefix" {
  description = "Project prefix for resource naming"
  type        = string
}

variable "pubsub_message_retention_duration" {
  description = "Message retention duration (in seconds)"
  type        = string
  default     = "604800s"
}

variable "cloud_run_primary_service_url" {
  description = "Primary region Cloud Run service URL"
  type        = string
}

variable "cloud_run_secondary_service_url" {
  description = "Secondary region Cloud Run service URL"
  type        = string
}

variable "cloud_run_service_account_email" {
  description = "Cloud Run service account email"
  type        = string
}

variable "pubsub_service_account_email" {
  description = "Pub/Sub service account email"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
