# Storage Module - Cloud Storage Buckets
# Manages all storage buckets for Looply platform with proper lifecycle management

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Local Variables for Lifecycle Management
# ============================================

locals {
  bucket_base_name = "${var.project_prefix}-${var.gcp_project_id}"
  
  standard_labels = merge(
    var.tags,
    {
      managed-by = "terraform"
    }
  )
  
  # Lifecycle rules that expire data
  expire_rule = [
    {
      action        = "Delete"
      age_days      = 365
      num_versions  = null
    }
  ]
  
  # Versioning kept lifecycle rule
  archive_rule = [
    {
      action        = "SetStorageClass"
      age_days      = 365
      storage_class = "COLDLINE"
      num_versions  = null
    }
  ]
}

# ============================================
# Videos Bucket (Raw uploads)
# ============================================

resource "google_storage_bucket" "videos" {
  name          = "${local.bucket_base_name}-videos"
  project       = var.gcp_project_id
  location      = var.primary_region
  force_destroy = false
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = var.video_bucket_versioning
  }

  # Delete old versions
  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  # Archive to cheaper storage after 1 year
  dynamic "lifecycle_rule" {
    for_each = local.archive_rule
    content {
      condition {
        age = lifecycle_rule.value.age_days
      }
      action {
        type          = lifecycle_rule.value.action
        storage_class = lookup(lifecycle_rule.value, "storage_class", null)
      }
    }
  }

  labels = local.standard_labels
}

# ============================================
# Transcoded Videos Bucket
# ============================================

resource "google_storage_bucket" "transcoded_videos" {
  name          = "${local.bucket_base_name}-transcoded"
  project       = var.gcp_project_id
  location      = var.primary_region
  force_destroy = false
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }

  # Move to cheaper storage over time
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "STANDARD"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 180
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  labels = local.standard_labels
}

# ============================================
# Analytics Data Bucket
# ============================================

resource "google_storage_bucket" "analytics" {
  name          = "${local.bucket_base_name}-analytics"
  project       = var.gcp_project_id
  location      = var.primary_region
  force_destroy = false
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  # Delete after 90 days
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  labels = local.standard_labels
}

# ============================================
# Access Logs Bucket
# ============================================

resource "google_storage_bucket" "logs" {
  name          = "${local.bucket_base_name}-logs"
  project       = var.gcp_project_id
  location      = var.primary_region
  force_destroy = false
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }

  # Delete logs after retention period
  lifecycle_rule {
    condition {
      age = var.log_bucket_retention_days
    }
    action {
      type = "Delete"
    }
  }

  labels = local.standard_labels
}

# ============================================
# Backup Bucket (Multi-region for DR)
# ============================================

resource "google_storage_bucket" "backup" {
  name          = "${local.bucket_base_name}-backup"
  project       = var.gcp_project_id
  location      = "US"  # Multi-region for redundancy
  force_destroy = false
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  # Archive strategy for backups
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = local.standard_labels
}

# ============================================
# Bucket IAM Access Control
# ============================================

# Cloud Run service account access
resource "google_storage_bucket_iam_member" "cloud_run_videos_admin" {
  bucket = google_storage_bucket.videos.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.cloud_run_service_account_email}"
}

resource "google_storage_bucket_iam_member" "cloud_run_transcoded_admin" {
  bucket = google_storage_bucket.transcoded_videos.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.cloud_run_service_account_email}"
}

resource "google_storage_bucket_iam_member" "cloud_run_analytics_admin" {
  bucket = google_storage_bucket.analytics.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.cloud_run_service_account_email}"
}

resource "google_storage_bucket_iam_member" "cloud_run_logs_viewer" {
  bucket = google_storage_bucket.logs.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.cloud_run_service_account_email}"
}

# Storage service account access
resource "google_storage_bucket_iam_member" "storage_sa_videos_admin" {
  bucket = google_storage_bucket.videos.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.storage_service_account_email}"
}

resource "google_storage_bucket_iam_member" "storage_sa_backup_admin" {
  bucket = google_storage_bucket.backup.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.storage_service_account_email}"
}
