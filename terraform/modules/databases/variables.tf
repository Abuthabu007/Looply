# Databases Module - Variables

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_prefix" {
  description = "Project prefix for resource naming"
  type        = string
}

variable "firestore_region" {
  description = "Firestore database region"
  type        = string
}

variable "enable_pitr" {
  description = "Enable point-in-time recovery for Firestore"
  type        = bool
  default     = true
}

variable "bigquery_dataset_location" {
  description = "BigQuery dataset location"
  type        = string
  default     = "US"
}

variable "bigquery_service_account_email" {
  description = "BigQuery service account email"
  type        = string
}

variable "cloud_run_service_account_email" {
  description = "Cloud Run service account email"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
