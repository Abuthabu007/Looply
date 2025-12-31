# Databases Module - Firestore and BigQuery

# ============================================
# Firestore Database (Multi-Region)
# ============================================

resource "google_firestore_database" "main" {
  project                           = var.gcp_project_id
  name                              = "(default)"
  location_id                       = var.firestore_region
  type                              = "FIRESTORE_NATIVE"
  concurrency_mode                  = "OPTIMISTIC"
  point_in_time_recovery_enablement = var.enable_pitr ? "POINT_IN_TIME_RECOVERY_ENABLED" : "POINT_IN_TIME_RECOVERY_DISABLED"


}

# ============================================
# BigQuery Dataset
# ============================================

resource "google_bigquery_dataset" "analytics" {
  dataset_id                  = "looply_analytics"
  friendly_name               = "Looply Analytics"
  description                 = "Analytics data for Looply streaming platform"
  project                     = var.gcp_project_id
  location                    = var.bigquery_dataset_location
  default_table_expiration_ms = 7776000000 # 90 days

  labels = var.tags
}

# ============================================
# BigQuery Tables
# ============================================

# Stream Events Table
resource "google_bigquery_table" "stream_events" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "stream_events"
  project    = var.gcp_project_id

  schema = jsonencode([
    {
      name        = "event_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique event identifier"
    },
    {
      name        = "event_timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "When the event occurred"
    },
    {
      name        = "user_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "User identifier"
    },
    {
      name        = "stream_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Stream identifier"
    },
    {
      name        = "event_type"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Type of event (play, pause, stop, quality_change, etc.)"
    },
    {
      name        = "region"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Geographic region"
    },
    {
      name        = "device_type"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Device type (web, mobile, desktop)"
    },
    {
      name        = "bitrate"
      type        = "INT64"
      mode        = "NULLABLE"
      description = "Stream bitrate in kbps"
    }
  ])

  labels = var.tags

  depends_on = [google_bigquery_dataset.analytics]
}

# User Analytics Table
resource "google_bigquery_table" "user_analytics" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "user_analytics"
  project    = var.gcp_project_id

  schema = jsonencode([
    {
      name        = "user_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "User identifier"
    },
    {
      name        = "total_watch_time"
      type        = "INT64"
      mode        = "NULLABLE"
      description = "Total watch time in seconds"
    },
    {
      name        = "streams_watched"
      type        = "INT64"
      mode        = "NULLABLE"
      description = "Number of streams watched"
    },
    {
      name        = "last_active"
      type        = "TIMESTAMP"
      mode        = "NULLABLE"
      description = "Last activity timestamp"
    },
    {
      name        = "preferred_quality"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "User's preferred stream quality"
    },
    {
      name        = "average_bitrate"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Average bitrate preference"
    }
  ])

  labels = var.tags

  depends_on = [google_bigquery_dataset.analytics]
}

# Stream Quality Table
resource "google_bigquery_table" "stream_quality" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "stream_quality"
  project    = var.gcp_project_id

  schema = jsonencode([
    {
      name        = "quality_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique quality measurement identifier"
    },
    {
      name        = "timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Measurement timestamp"
    },
    {
      name        = "stream_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Stream identifier"
    },
    {
      name        = "user_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "User identifier"
    },
    {
      name        = "region"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Geographic region"
    },
    {
      name        = "bitrate"
      type        = "INT64"
      mode        = "NULLABLE"
      description = "Current bitrate in kbps"
    },
    {
      name        = "latency_ms"
      type        = "INT64"
      mode        = "NULLABLE"
      description = "Latency in milliseconds"
    },
    {
      name        = "buffer_duration_ms"
      type        = "INT64"
      mode        = "NULLABLE"
      description = "Buffer duration in milliseconds"
    },
    {
      name        = "packet_loss_percent"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Packet loss percentage"
    }
  ])

  labels = var.tags

  depends_on = [google_bigquery_dataset.analytics]
}

# ============================================
# BigQuery Service Account Permissions
# ============================================

resource "google_bigquery_dataset_iam_member" "bigquery_sa_admin" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  role       = "roles/bigquery.admin"
  member     = "serviceAccount:${var.bigquery_service_account_email}"
}

resource "google_bigquery_table_iam_member" "stream_events_editor" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = google_bigquery_table.stream_events.table_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.cloud_run_service_account_email}"
}

resource "google_bigquery_table_iam_member" "user_analytics_editor" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = google_bigquery_table.user_analytics.table_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.cloud_run_service_account_email}"
}

resource "google_bigquery_table_iam_member" "stream_quality_editor" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = google_bigquery_table.stream_quality.table_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.cloud_run_service_account_email}"
}
