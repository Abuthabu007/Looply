# Monitoring Module - Cloud Monitoring, Logging, Alerts
# Purpose: Observability, alerting, and incident response

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# Notification Channels
# ============================================================================

resource "google_monitoring_notification_channel" "email_primary" {
  display_name = "Email - Primary Alerts"
  type         = "email"
  labels = {
    email_address = var.alert_email_primary
  }
  enabled = true
}

resource "google_monitoring_notification_channel" "email_secondary" {
  count        = var.alert_email_secondary != "" ? 1 : 0
  display_name = "Email - Secondary Alerts"
  type         = "email"
  labels = {
    email_address = var.alert_email_secondary
  }
  enabled = true
}

resource "google_monitoring_notification_channel" "slack" {
  count        = var.slack_webhook_url != "" ? 1 : 0
  display_name = "Slack - Critical Alerts"
  type         = "slack"
  labels = {
    channel_name = var.slack_channel_name
  }
  user_labels = {
    severity = "critical"
  }
  enabled = true
}

# ============================================================================
# Cloud Run Alerts
# ============================================================================

# Alert: Cloud Run CPU throttling
resource "google_monitoring_alert_policy" "cloud_run_cpu_throttle" {
  display_name = "Cloud Run - CPU Throttling"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "CPU throttling detected"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 100

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = concat(
    [google_monitoring_notification_channel.email_primary.id],
    var.alert_email_secondary != "" ? [google_monitoring_notification_channel.email_secondary[0].id] : [],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].id] : []
  )

  alert_strategy {
    auto_close = "1800s"
  }
}

# Alert: Cloud Run memory
resource "google_monitoring_alert_policy" "cloud_run_memory" {
  count        = 0  # Disabled - metric not available until service has traffic
  display_name = "Cloud Run - High Memory Usage"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Memory > 80%"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/container_memory_utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = concat(
    [google_monitoring_notification_channel.email_primary.id],
    var.alert_email_secondary != "" ? [google_monitoring_notification_channel.email_secondary[0].id] : [],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].id] : []
  )

  alert_strategy {
    auto_close = "1800s"
  }
}

# Alert: Cloud Run request latency
resource "google_monitoring_alert_policy" "cloud_run_latency" {
  display_name = "Cloud Run - High Request Latency (>2s)"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "p99 Latency > 2s"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_latencies\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 2000

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }
    }
  }

  notification_channels = concat(
    [google_monitoring_notification_channel.email_primary.id],
    var.alert_email_secondary != "" ? [google_monitoring_notification_channel.email_secondary[0].id] : [],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].id] : []
  )

  alert_strategy {
    auto_close = "1800s"
  }
}

# ============================================================================
# BigQuery Alerts
# ============================================================================

# Alert: BigQuery slots allocation
resource "google_monitoring_alert_policy" "bigquery_slots" {
  count        = 0  # Disabled - metric not available until queries run
  display_name = "BigQuery - Slots Overutilization"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Slots > 80% allocated"

    condition_threshold {
      filter          = "resource.type = \"bigquery_project\" AND metric.type = \"bigquery.googleapis.com/slots/total_allocated\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = concat(
    [google_monitoring_notification_channel.email_primary.id],
    var.alert_email_secondary != "" ? [google_monitoring_notification_channel.email_secondary[0].id] : [],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].id] : []
  )

  alert_strategy {
    auto_close = "1800s"
  }
}

# ============================================================================
# Cloud Storage Alerts
# ============================================================================

# Alert: Storage bucket size growth
resource "google_monitoring_alert_policy" "storage_size" {
  display_name = "Cloud Storage - High Usage"
  combiner     = "OR"
  enabled      = false

  conditions {
    display_name = "Storage > 80GB"

    condition_threshold {
      filter          = "resource.type = \"gcs_bucket\" AND metric.type = \"storage.googleapis.com/storage/total_bytes\""
      duration        = "600s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.storage_growth_threshold

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = concat(
    [google_monitoring_notification_channel.email_primary.id],
    var.alert_email_secondary != "" ? [google_monitoring_notification_channel.email_secondary[0].id] : [],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].id] : []
  )

  alert_strategy {
    auto_close = "1800s"
  }
}

# ============================================================================
# Firestore Alerts
# ============================================================================

# Alert: Firestore document reads
resource "google_monitoring_alert_policy" "firestore_reads" {
  count        = 0  # Disabled - metric not available until reads occur
  display_name = "Firestore - High Read Operations"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Firestore reads > 100/sec"

    condition_threshold {
      filter          = "resource.type = \"firestore_instance\" AND metric.type = \"firestore.googleapis.com/document/read_operations\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 100

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_primary.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

# ============================================================================
# Pub/Sub Alerts
# ============================================================================

# Alert: Pub/Sub message backlog
resource "google_monitoring_alert_policy" "pubsub_backlog" {
  display_name = "Pub/Sub - Message Backlog"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Backlog > 1000 messages"

    condition_threshold {
      filter          = "resource.type = \"pubsub_subscription\" AND metric.type = \"pubsub.googleapis.com/subscription/num_undelivered_messages\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 1000

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = concat(
    [google_monitoring_notification_channel.email_primary.id],
    var.alert_email_secondary != "" ? [google_monitoring_notification_channel.email_secondary[0].id] : [],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].id] : []
  )

  alert_strategy {
    auto_close = "1800s"
  }
}

# ============================================================================
# Uptime Checks
# ============================================================================

# Alert: Uptime check failure
resource "google_monitoring_alert_policy" "uptime_failure" {
  display_name = "API Uptime - Global Availability"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Uptime check down"

    condition_threshold {
      filter          = "resource.type = \"uptime_url\" AND metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\""
      duration        = "120s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_FRACTION_TRUE"
      }
    }
  }

  notification_channels = concat(
    [google_monitoring_notification_channel.email_primary.id],
    var.alert_email_secondary != "" ? [google_monitoring_notification_channel.email_secondary[0].id] : [],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].id] : []
  )

  alert_strategy {
    auto_close = "1800s"
  }
}

# ============================================================================
# Cloud Monitoring Dashboard
# ============================================================================

resource "google_monitoring_dashboard" "main" {
  dashboard_json = jsonencode({
    displayName = "Looply - Main Monitoring Dashboard"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          xPos   = 0
          yPos   = 0
          width  = 6
          height = 4
          widget = {
            title = "Cloud Run Request Rate"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_count\""
                      aggregation = {
                        alignmentPeriod  = "60s"
                        perSeriesAligner = "ALIGN_RATE"
                      }
                    }
                  }
                }
              ]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 0
          width  = 6
          height = 4
          widget = {
            title = "Cloud Run Instance Count"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/instance_count\""
                      aggregation = {
                        alignmentPeriod  = "60s"
                        perSeriesAligner = "ALIGN_MEAN"
                      }
                    }
                  }
                }
              ]
            }
          }
        }
      ]
    }
  })
}
