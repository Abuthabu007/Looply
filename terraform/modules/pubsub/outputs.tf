# Pub/Sub Module - Outputs

output "events_topic_name" {
  value       = google_pubsub_topic.events.name
  description = "Events topic name"
}

output "video_upload_events_topic" {
  value       = google_pubsub_topic.video_upload_events.name
  description = "Video upload events topic name"
}

output "transcoding_complete_topic" {
  value       = google_pubsub_topic.transcoding_complete_events.name
  description = "Transcoding complete events topic name"
}

output "events_subscription_primary_name" {
  value       = google_pubsub_subscription.events_subscription_primary.name
  description = "Primary events subscription name"
}

output "events_subscription_secondary_name" {
  value       = google_pubsub_subscription.events_subscription_secondary.name
  description = "Secondary events subscription name"
}
