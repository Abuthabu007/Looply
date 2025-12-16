# Pub/Sub Module - Topics and Subscriptions

# ============================================
# Main Events Topic and Subscriptions
# ============================================

resource "google_pubsub_topic" "events" {
  name                       = "${var.project_prefix}-events"
  project                    = var.gcp_project_id
  message_retention_duration = var.pubsub_message_retention_duration

  labels = var.tags
}

# Subscription for Primary Region Cloud Run
resource "google_pubsub_subscription" "events_subscription_primary" {
  name             = "${var.project_prefix}-events-sub-primary"
  topic            = google_pubsub_topic.events.name
  project          = var.gcp_project_id
  ack_deadline_seconds = 60

  push_config {
    push_endpoint = var.cloud_run_primary_service_url

    oidc_token {
      service_account_email = var.cloud_run_service_account_email
    }
  }

  labels = var.tags
}

# Subscription for Secondary Region Cloud Run
resource "google_pubsub_subscription" "events_subscription_secondary" {
  name             = "${var.project_prefix}-events-sub-secondary"
  topic            = google_pubsub_topic.events.name
  project          = var.gcp_project_id
  ack_deadline_seconds = 60

  push_config {
    push_endpoint = var.cloud_run_secondary_service_url

    oidc_token {
      service_account_email = var.cloud_run_service_account_email
    }
  }

  labels = merge(
    var.tags,
    { region = "secondary" }
  )
}

# ============================================
# Video Processing Topic
# ============================================

resource "google_pubsub_topic" "video_processing" {
  name                       = "${var.project_prefix}-video-processing"
  project                    = var.gcp_project_id
  message_retention_duration = var.pubsub_message_retention_duration

  labels = var.tags
}

resource "google_pubsub_subscription" "video_processing_subscription" {
  name             = "${var.project_prefix}-video-processing-sub"
  topic            = google_pubsub_topic.video_processing.name
  project          = var.gcp_project_id
  ack_deadline_seconds = 300

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.video_processing_dlq.id
    max_delivery_attempts = 5
  }

  labels = var.tags
}

# Dead Letter Queue for Video Processing
resource "google_pubsub_topic" "video_processing_dlq" {
  name    = "${var.project_prefix}-video-processing-dlq"
  project = var.gcp_project_id

  labels = var.tags
}

# ============================================
# User Events Topic
# ============================================

resource "google_pubsub_topic" "user_events" {
  name                       = "${var.project_prefix}-user-events"
  project                    = var.gcp_project_id
  message_retention_duration = var.pubsub_message_retention_duration

  labels = var.tags
}

resource "google_pubsub_subscription" "user_events_subscription" {
  name             = "${var.project_prefix}-user-events-sub"
  topic            = google_pubsub_topic.user_events.name
  project          = var.gcp_project_id
  ack_deadline_seconds = 60

  labels = var.tags
}

# ============================================
# Stream Quality Topic
# ============================================

resource "google_pubsub_topic" "stream_quality" {
  name                       = "${var.project_prefix}-stream-quality"
  project                    = var.gcp_project_id
  message_retention_duration = var.pubsub_message_retention_duration

  labels = var.tags
}

resource "google_pubsub_subscription" "stream_quality_subscription" {
  name             = "${var.project_prefix}-stream-quality-sub"
  topic            = google_pubsub_topic.stream_quality.name
  project          = var.gcp_project_id
  ack_deadline_seconds = 60

  labels = var.tags
}

# ============================================
# Pub/Sub Service Account Permissions
# ============================================

resource "google_pubsub_topic_iam_member" "events_publisher" {
  topic  = google_pubsub_topic.events.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${var.pubsub_service_account_email}"
}

resource "google_pubsub_topic_iam_member" "events_subscriber" {
  topic  = google_pubsub_topic.events.name
  role   = "roles/pubsub.subscriber"
  member = "serviceAccount:${var.cloud_run_service_account_email}"
}

resource "google_pubsub_topic_iam_member" "video_processing_publisher" {
  topic  = google_pubsub_topic.video_processing.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${var.pubsub_service_account_email}"
}

resource "google_pubsub_topic_iam_member" "user_events_publisher" {
  topic  = google_pubsub_topic.user_events.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${var.cloud_run_service_account_email}"
}

resource "google_pubsub_topic_iam_member" "stream_quality_publisher" {
  topic  = google_pubsub_topic.stream_quality.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${var.cloud_run_service_account_email}"
}
