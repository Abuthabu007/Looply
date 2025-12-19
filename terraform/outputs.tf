# Outputs for the root module

output "service_accounts" {
  value = {
    cloud_run_sa_email         = module.service_accounts.cloud_run_service_account_email
    pubsub_sa_email            = module.service_accounts.pubsub_service_account_email
    bigquery_sa_email          = module.service_accounts.bigquery_service_account_email
    firestore_sa_email         = module.service_accounts.firestore_service_account_email
    storage_sa_email           = module.service_accounts.storage_service_account_email
    cloud_scheduler_sa_email   = module.service_accounts.cloud_scheduler_service_account_email
    artifact_registry_sa_email = module.service_accounts.artifact_registry_service_account_email
  }
  description = "Service account emails"
}

output "networking" {
  value = {
    vpc_network_id        = module.networking.vpc_network_id
    vpc_network_name      = module.networking.vpc_network_name
    primary_subnet_id     = module.networking.primary_subnet_id
    secondary_subnet_id   = module.networking.secondary_subnet_id
    primary_router_id     = module.networking.primary_router_id
    secondary_router_id   = module.networking.secondary_router_id
  }
  description = "Networking resources"
}

output "compute" {
  value = {
    backend_primary_url   = module.compute.backend_primary_url
    backend_secondary_url = module.compute.backend_secondary_url
    frontend_primary_url  = module.compute.frontend_primary_url
    frontend_secondary_url = module.compute.frontend_secondary_url
    backend_api_endpoints = module.compute.backend_api_endpoints
    frontend_endpoints    = module.compute.frontend_endpoints
  }
  description = "Cloud Run service URLs for backend and frontend"
}

output "pubsub" {
  value = {
    events_topic_name          = module.pubsub.events_topic_name
    video_processing_topic     = module.pubsub.video_processing_topic_name
    user_events_topic          = module.pubsub.user_events_topic_name
    events_subscription_primary   = module.pubsub.events_subscription_primary_name
    events_subscription_secondary = module.pubsub.events_subscription_secondary_name
  }
  description = "Pub/Sub resources"
}

output "storage" {
  value = {
    videos_bucket        = module.storage.videos_bucket_name
    analytics_bucket     = module.storage.analytics_bucket_name
    logs_bucket          = module.storage.logs_bucket_name
  }
  description = "Cloud Storage buckets"
}

output "databases" {
  value = {
    firestore_database_id = module.databases.firestore_database_id
    bigquery_dataset_id   = module.databases.bigquery_dataset_id
  }
  description = "Database resources"
}

output "load_balancer" {
  value = {
    global_ip_address = module.load_balancer.global_ip_address
    load_balancer_url = "https://${module.load_balancer.global_ip_address}"
  }
  description = "Load Balancer details"
}

output "artifact_registry" {
  value = {
    repository_id = google_artifact_registry_repository.main.repository_id
    repository_url = "${var.primary_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.main.repository_id}"
  }
  description = "Artifact Registry details"
}
# ============================================================================
# Security Module Outputs
# ============================================================================

output "security" {
  value = {
    cloud_armor_policy_id      = module.security.cloud_armor_policy_id
    cloud_armor_policy_name    = module.security.cloud_armor_policy_name
    kms_keyring_id             = module.security.kms_keyring_id
    kms_main_key_id            = module.security.kms_main_key_id
    kms_database_key_id        = module.security.kms_database_key_id
    kms_storage_key_id         = module.security.kms_storage_key_id
    secrets_created            = module.security.secrets_created
  }
  description = "Security resources (Cloud Armor, KMS, Secret Manager)"
}

# ============================================================================
# Monitoring Module Outputs
# ============================================================================

output "monitoring" {
  value = {
    primary_notification_channel = module.monitoring.email_notification_channel_id
    alert_policies               = module.monitoring.alert_policies_created
    dashboard_id                 = module.monitoring.dashboard_id
  }
  description = "Monitoring resources (alerting, dashboards)"
}

# ============================================================================
# IAP Module Outputs
# ============================================================================

output "iap" {
  value = {
    oauth_client_id             = module.iap.iap_client_id
    iap_brand_name              = module.iap.iap_brand_name
    admin_iap_binding_role      = module.iap.admin_iap_binding_role
    user_mgmt_iap_binding_role  = module.iap.user_mgmt_iap_binding_role
    analytics_iap_binding_role  = module.iap.analytics_iap_binding_role
    iap_logs_sink_name          = module.iap.iap_logs_sink_name
    iap_logs_destination        = module.iap.iap_logs_destination
    alert_policy_name           = module.iap.iap_monitoring_alert_policy_name
  }
  description = "IAP (Identity-Aware Proxy) resources and OAuth configuration"
  sensitive   = false
}
