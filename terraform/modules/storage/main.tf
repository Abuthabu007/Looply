# Storage Module - Cloud Storage Buckets

# ============================================
# Videos Bucket
# ============================================

resource "google_storage_bucket" "opentofu-state" {
  bucket = "Opentofu-statelock"
  project       = var.gcp_project_id
  location      = var.primary_region
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = var.video_bucket_versioning
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 365 # 1 year
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = var.tags
}
}


resource "google_storage_bucket" "videos" {
  name          = "${var.project_prefix}-videos-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = var.primary_region
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = var.video_bucket_versioning
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 365 # 1 year
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = var.tags
}

# ============================================
# Transcoded Videos Bucket
# ============================================

resource "google_storage_bucket" "transcoded_videos" {
  name          = "${var.project_prefix}-transcoded-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = var.primary_region
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }

  # Lifecycle policy: Keep transcoded videos for 90 days, then move to cheaper storage
  lifecycle_rule {
    condition {
      age = 30 # 30 days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "STANDARD"
    }
  }

  lifecycle_rule {
    condition {
      age = 90 # 90 days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 180 # 180 days (6 months)
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365 # 1 year
    }
    action {
      type = "Delete"
    }
  }

  labels = var.tags
}

resource "google_storage_bucket" "analytics" {
  name          = "${var.project_prefix}-analytics-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = var.primary_region
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90 # 90 days
    }
    action {
      type = "Delete"
    }
  }

  labels = var.tags
}

# ============================================
# Logs Bucket
# ============================================

resource "google_storage_bucket" "logs" {
  name          = "${var.project_prefix}-logs-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = var.primary_region
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }

  lifecycle_rule {
    condition {
      age = var.log_bucket_retention_days
    }
    action {
      type = "Delete"
    }
  }

  labels = var.tags
}

# ============================================
# Backup Bucket (Cross-region for DR)
# ============================================

resource "google_storage_bucket" "backup" {
  name          = "${var.project_prefix}-backup-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = "US" # Multi-region for redundancy
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

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

  labels = var.tags
}

# ============================================
# Bucket IAM Permissions
# ============================================

# Grant Cloud Run service account access to videos bucket
resource "google_storage_bucket_iam_member" "cloud_run_videos_admin" {
  bucket = google_storage_bucket.videos.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.cloud_run_service_account_email}"
}

# Grant Cloud Run service account access to analytics bucket
resource "google_storage_bucket_iam_member" "cloud_run_analytics_admin" {
  bucket = google_storage_bucket.analytics.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.cloud_run_service_account_email}"
}

# Grant Cloud Run service account access to logs bucket
resource "google_storage_bucket_iam_member" "cloud_run_logs_viewer" {
  bucket = google_storage_bucket.logs.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.cloud_run_service_account_email}"
}

# Grant Cloud Run service account access to transcoded videos bucket
resource "google_storage_bucket_iam_member" "cloud_run_transcoded_videos_admin" {
  bucket = google_storage_bucket.transcoded_videos.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.cloud_run_service_account_email}"
}

# Grant storage service account access
resource "google_storage_bucket_iam_member" "storage_sa_videos_admin" {
  bucket = google_storage_bucket.videos.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.storage_service_account_email}"
}

resource "google_storage_bucket_iam_member" "storage_sa_backup_admin" {
  bucket = google_storage_bucket.backup.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.storage_service_account_email}"
}

# CORS Configuration - inline within the bucket or use google_storage_bucket_cors resource
# Note: CORS can also be configured via lifecycle rules in the bucket definition
