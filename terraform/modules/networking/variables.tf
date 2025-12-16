# Networking Module - Variables

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

variable "primary_subnet_cidr" {
  description = "CIDR block for primary region subnet"
  type        = string
}

variable "primary_secondary_subnet_cidr" {
  description = "Secondary CIDR for primary region (for proxy)"
  type        = string
}

variable "secondary_subnet_cidr" {
  description = "CIDR block for secondary region subnet"
  type        = string
}

variable "secondary_secondary_subnet_cidr" {
  description = "Secondary CIDR for secondary region (for proxy)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
