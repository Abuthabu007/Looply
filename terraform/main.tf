# Root module - orchestrates all submodules

locals {
  common_labels = merge(
    var.tags,
    {
      environment = var.environment
      region      = var.primary_region
    }
  )
}

# ============================================
# APIs Module - Enable required Google Cloud APIs
# ============================================
module "apis" {
  source = "./modules/apis"

  gcp_project_id = var.gcp_project_id
}

# Service Accounts Module
module "service_accounts" {
  source = "./modules/service_accounts"

  gcp_project_id = var.gcp_project_id
  project_prefix = var.project_prefix
  environment    = var.environment

  tags = local.common_labels

  depends_on = [module.apis]
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  gcp_project_id                    = var.gcp_project_id
  project_prefix                    = var.project_prefix
  primary_region                    = var.primary_region
  secondary_region                  = var.secondary_region
  primary_subnet_cidr               = var.primary_subnet_cidr
  primary_secondary_subnet_cidr     = var.primary_secondary_subnet_cidr
  secondary_subnet_cidr             = var.secondary_subnet_cidr
  secondary_secondary_subnet_cidr   = var.secondary_secondary_subnet_cidr

  tags = local.common_labels

  depends_on = [module.apis]
}

# Compute Module (Cloud Run)
module "compute" {
  source = "./modules/compute"

  gcp_project_id              = var.gcp_project_id
  project_prefix              = var.project_prefix
  primary_region              = var.primary_region
  secondary_region            = var.secondary_region
  artifact_registry_repo      = var.artifact_registry_repo
  cloud_run_service_account   = module.service_accounts.cloud_run_service_account_email
  cloud_run_cpu               = var.cloud_run_cpu
  cloud_run_memory            = var.cloud_run_memory
  cloud_run_timeout           = var.cloud_run_timeout
  cloud_run_max_instances     = var.cloud_run_max_instances

  depends_on = [module.service_accounts, module.apis]
}

# Pub/Sub Module
module "pubsub" {
  source = "./modules/pubsub"

  gcp_project_id                          = var.gcp_project_id
  project_prefix                          = var.project_prefix
  pubsub_message_retention_duration       = var.pubsub_message_retention_duration
  cloud_run_primary_service_url           = module.compute.cloud_run_primary_service_url
  cloud_run_secondary_service_url         = module.compute.cloud_run_secondary_service_url
  cloud_run_service_account_email         = module.service_accounts.cloud_run_service_account_email
  pubsub_service_account_email            = module.service_accounts.pubsub_service_account_email

  tags = local.common_labels

  depends_on = [module.compute, module.service_accounts]
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  gcp_project_id                   = var.gcp_project_id
  project_prefix                   = var.project_prefix
  primary_region                   = var.primary_region
  log_bucket_retention_days        = var.log_bucket_retention_days
  video_bucket_versioning          = var.video_bucket_versioning_enabled
  cloud_run_service_account_email  = module.service_accounts.cloud_run_service_account_email
  storage_service_account_email    = module.service_accounts.storage_service_account_email

  tags = local.common_labels

  depends_on = [module.service_accounts, module.apis]
}

# Databases Module
module "databases" {
  source = "./modules/databases"

  gcp_project_id                    = var.gcp_project_id
  project_prefix                    = var.project_prefix
  firestore_region                  = var.firestore_region
  enable_pitr                       = var.enable_pitr
  bigquery_dataset_location         = var.bigquery_dataset_location
  bigquery_service_account_email    = module.service_accounts.bigquery_service_account_email
  cloud_run_service_account_email   = module.service_accounts.cloud_run_service_account_email

  tags = local.common_labels

  depends_on = [module.service_accounts, module.apis]
}

# Load Balancer Module
module "load_balancer" {
  source = "./modules/load_balancer"

  gcp_project_id            = var.gcp_project_id
  project_prefix            = var.project_prefix
  ssl_certificate           = var.ssl_certificate
  ssl_private_key           = var.ssl_private_key
  storage_bucket_name       = module.storage.videos_bucket_name
  cloud_run_service_urls    = [
    module.compute.cloud_run_primary_service_url,
    module.compute.cloud_run_secondary_service_url
  ]
  vpc_network_name          = module.networking.vpc_network_name
  
  tags = local.common_labels

  depends_on = [module.storage, module.compute, module.networking, module.security, module.apis]
}

# Security Module (Cloud Armor, KMS, Secret Manager)
module "security" {
  source = "./modules/security"

  
  project_prefix            = var.project_prefix
  primary_region            = var.primary_region
  ssl_certificate           = var.ssl_certificate
  db_password               = var.db_password
  api_key                   = var.api_key
  oauth_client_secret       = var.oauth_client_secret
  cloud_run_sa_email        = module.service_accounts.cloud_run_service_account_email
  scheduler_sa_email        = module.service_accounts.cloud_scheduler_service_account_email
  bigquery_sa_email         = module.service_accounts.bigquery_service_account_email
  storage_sa_email          = module.service_accounts.storage_service_account_email
  allowed_countries         = var.allowed_countries
  security_policy_preview_mode = var.security_policy_preview_mode

  tags = local.common_labels

  depends_on = [module.service_accounts, module.apis]
}

# Monitoring Module (Cloud Monitoring, Alerting, Dashboards)
module "monitoring" {
  source = "./modules/monitoring"

  
  project_prefix             = var.project_prefix
  alert_email_primary        = var.alert_email_primary
  alert_email_secondary      = var.alert_email_secondary
  slack_webhook_url          = var.slack_webhook_url
  slack_channel_name         = var.slack_channel_name
  storage_growth_threshold   = var.storage_growth_threshold
  api_endpoint               = var.api_endpoint
  storage_bucket_logs        = module.storage.logs_bucket_name
  log_filter                 = var.log_filter

  tags = local.common_labels

  depends_on = [module.storage, module.apis]
}

# IAP Module (Identity-Aware Proxy)
module "iap" {
  source = "./modules/iap"

  gcp_project_id                           = var.gcp_project_id
  project_prefix                           = var.project_prefix
  support_email                            = var.iap_support_email
  application_title                        = var.iap_application_title
  admin_backend_service_name               = var.iap_admin_backend_service
  user_management_backend_service_name     = var.iap_user_mgmt_backend_service
  analytics_backend_service_name           = var.iap_analytics_backend_service
  admin_authorized_users                   = var.iap_admin_authorized_users
  user_management_authorized_users         = var.iap_user_mgmt_authorized_users
  analytics_authorized_users               = var.iap_analytics_authorized_users
  public_authorized_users                  = var.iap_public_authorized_users
  enable_public_iap_access                 = var.iap_enable_public_access
  enable_iap_alerts                        = var.iap_enable_alerts
  failed_auth_threshold                    = var.iap_failed_auth_threshold
  logs_bucket_name                         = module.storage.logs_bucket_name
  notification_channel_ids                 = [module.monitoring.email_notification_channel_id]
  service_account_email                    = module.service_accounts.iap_service_account_email
  iap_service_account_email                = module.service_accounts.iap_service_account_email
  kms_crypto_key_id                        = module.security.kms_main_key_id

  tags = local.common_labels

  depends_on = [module.storage, module.monitoring, module.service_accounts, module.security]
}

# Artifact Registry
resource "google_artifact_registry_repository" "main" {
  location      = var.primary_region
  repository_id = var.artifact_registry_repo
  description   = "Docker repository for Looply services"
  format        = "DOCKER"
  project       = var.gcp_project_id

  labels = local.common_labels
}

# Cloud Logging Sink
resource "google_logging_project_sink" "main_sink" {
  name        = "${var.project_prefix}-main-sink"
  destination = "storage.googleapis.com/${module.storage.logs_bucket_name}"
  project     = var.gcp_project_id
  filter      = "severity >= WARNING"

  unique_writer_identity = true
}

resource "google_storage_bucket_iam_member" "log_bucket_writer" {
  bucket = module.storage.logs_bucket_name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.main_sink.writer_identity
}

# Cloud Scheduler Job
resource "google_cloud_scheduler_job" "analytics_aggregation" {
  name             = "${var.project_prefix}-analytics-aggregation"
  description      = "Aggregates analytics data daily"
  schedule         = "0 2 * * *"
  time_zone        = "UTC"
  attempt_deadline = "600s"
  region           = var.primary_region
  project          = var.gcp_project_id

  http_target {
    http_method = "POST"
    uri         = module.compute.cloud_run_primary_service_url

    headers = {
      "Content-Type" = "application/json"
    }

    body = base64encode(jsonencode({
      job_type = "analytics_aggregation"
    }))

    oidc_token {
      service_account_email = module.service_accounts.cloud_scheduler_service_account_email
      audience              = module.compute.cloud_run_primary_service_url
    }
  }

  depends_on = [module.compute, module.service_accounts]
}
