# Compute Module - Variables

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_prefix" {
  description = "Project prefix for resource naming"
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

variable "artifact_registry_repo" {
  description = "Artifact Registry repository name"
  type        = string
}

variable "cloud_run_service_account" {
  description = "Service account email for Cloud Run services"
  type        = string
}

variable "cloud_run_cpu" {
  description = "CPU allocation for Cloud Run services"
  type        = string
  default     = "1"
}

variable "cloud_run_memory" {
  description = "Memory allocation for Cloud Run services"
  type        = string
  default     = "256Mi"
}

variable "cloud_run_timeout" {
  description = "Timeout in seconds for Cloud Run services"
  type        = number
  default     = 3600
}

variable "cloud_run_max_instances" {
  description = "Maximum number of instances for Cloud Run services"
  type        = number
  default     = 2
}

variable "enable_secondary_region" {
  description = "Enable secondary region Cloud Run deployment"
  type        = bool
  default     = true
}

variable "firestore_database_id" {
  description = "Firestore database ID"
  type        = string
}

variable "videos_bucket_name" {
  description = "Cloud Storage bucket name for video uploads"
  type        = string
}

variable "transcoded_bucket_name" {
  description = "Cloud Storage bucket name for transcoded videos"
  type        = string
}

variable "transcoder_hls_template" {
  description = "Transcoder HLS job template ID"
  type        = string
}

variable "video_upload_topic" {
  description = "Pub/Sub topic for video upload events"
  type        = string
}

variable "transcoding_complete_topic" {
  description = "Pub/Sub topic for transcoding completion events"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
