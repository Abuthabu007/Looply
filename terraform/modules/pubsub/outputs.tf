# Pub/Sub Module - Outputs

output "events_topic_name" {
  value       = google_pubsub_topic.events.name
  description = "Events topic name"
}

output "video_processing_topic_name" {
  value       = google_pubsub_topic.video_processing.name
  description = "Video processing topic name"
}

output "user_events_topic_name" {
  value       = google_pubsub_topic.user_events.name
  description = "User events topic name"
}

output "stream_quality_topic_name" {
  value       = google_pubsub_topic.stream_quality.name
  description = "Stream quality topic name"
}

output "events_subscription_primary_name" {
  value       = google_pubsub_subscription.events_subscription_primary.name
  description = "Primary events subscription name"
}

output "events_subscription_secondary_name" {
  value       = google_pubsub_subscription.events_subscription_secondary.name
  description = "Secondary events subscription name"
}

output "video_processing_subscription_name" {
  value       = google_pubsub_subscription.video_processing_subscription.name
  description = "Video processing subscription name"
}

output "user_events_subscription_name" {
  value       = google_pubsub_subscription.user_events_subscription.name
  description = "User events subscription name"
}

output "stream_quality_subscription_name" {
  value       = google_pubsub_subscription.stream_quality_subscription.name
  description = "Stream quality subscription name"
}
