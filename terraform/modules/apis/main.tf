# APIs Module - Enable required Google Cloud APIs

# List of required APIs for Looply infrastructure
locals {
  required_apis = [
    "artifactregistry.googleapis.com",  # Artifact Registry (Docker images)
    "compute.googleapis.com",           # Compute Engine (VPC, Load Balancer, etc.)
    "run.googleapis.com",               # Cloud Run (Serverless containers)
    "firestore.googleapis.com",         # Cloud Firestore (NoSQL database)
    "bigquery.googleapis.com",          # BigQuery (Data warehouse)
    "pubsub.googleapis.com",            # Cloud Pub/Sub (Messaging)
    "storage-api.googleapis.com",       # Cloud Storage API
    "monitoring.googleapis.com",        # Cloud Monitoring (Alerts, dashboards)
    "logging.googleapis.com",           # Cloud Logging (Log management)
    "secretmanager.googleapis.com",     # Secret Manager (Secret storage)
    "cloudkms.googleapis.com",          # Cloud KMS (Key management)
    "iap.googleapis.com",               # Identity-Aware Proxy (Authentication)
    "identitytoolkit.googleapis.com",   # Identity Platform (OAuth providers, sign-in UI)
    "cloudscheduler.googleapis.com",    # Cloud Scheduler (Scheduled jobs)
    "iam.googleapis.com",               # IAM (Identity and Access Management)
    "serviceusage.googleapis.com",      # Service Usage API (Enable/disable APIs)
    "servicenetworking.googleapis.com", # Service Networking API (VPC peering)
  ]
}

# Enable each required API
resource "google_project_service" "required_apis" {
  for_each = toset(local.required_apis)

  project = var.gcp_project_id
  service = each.value

  # Don't disable API if Terraform is removed
  disable_on_destroy = false

  # Wait for API to be enabled before continuing
  depends_on = [google_project_service.service_usage]
}

# Enable Service Usage API first (it enables other APIs)
resource "google_project_service" "service_usage" {
  project = var.gcp_project_id
  service = "serviceusage.googleapis.com"

  disable_on_destroy = false
}
