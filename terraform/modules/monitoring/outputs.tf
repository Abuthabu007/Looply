output "email_notification_channel_id" {
  description = "Primary email notification channel ID"
  value       = google_monitoring_notification_channel.email_primary.id
}

output "email_secondary_notification_channel_id" {
  description = "Secondary email notification channel ID"
  value       = var.alert_email_secondary != "" ? google_monitoring_notification_channel.email_secondary[0].id : null
}

output "slack_notification_channel_id" {
  description = "Slack notification channel ID"
  value       = var.slack_webhook_url != "" ? google_monitoring_notification_channel.slack[0].id : null
}

output "alert_policies_created" {
  description = "List of created alert policies"
  value = {
    cloud_run_cpu_throttle = google_monitoring_alert_policy.cloud_run_cpu_throttle.id
    cloud_run_memory       = length(google_monitoring_alert_policy.cloud_run_memory) > 0 ? google_monitoring_alert_policy.cloud_run_memory[0].id : null
    cloud_run_latency      = google_monitoring_alert_policy.cloud_run_latency.id
    pubsub_backlog         = google_monitoring_alert_policy.pubsub_backlog.id
    firestore_reads        = length(google_monitoring_alert_policy.firestore_reads) > 0 ? google_monitoring_alert_policy.firestore_reads[0].id : null
    bigquery_slots         = length(google_monitoring_alert_policy.bigquery_slots) > 0 ? google_monitoring_alert_policy.bigquery_slots[0].id : null
    storage_size           = google_monitoring_alert_policy.storage_size.id
    uptime_failure         = google_monitoring_alert_policy.uptime_failure.id
  }
}

output "dashboard_id" {
  description = "Monitoring dashboard ID"
  value       = google_monitoring_dashboard.main.id
}

output "notification_channels" {
  description = "All created notification channels"
  value = {
    email_primary   = google_monitoring_notification_channel.email_primary.id
    email_secondary = var.alert_email_secondary != "" ? google_monitoring_notification_channel.email_secondary[0].id : "not-configured"
    slack           = var.slack_webhook_url != "" ? google_monitoring_notification_channel.slack[0].id : "not-configured"
  }
}