output "cloud_armor_policy_id" {
  description = "Cloud Armor security policy ID"
  value       = google_compute_security_policy.cloud_armor.id
}

output "cloud_armor_policy_name" {
  description = "Cloud Armor security policy name"
  value       = google_compute_security_policy.cloud_armor.name
}

output "kms_keyring_id" {
  description = "KMS Key Ring ID"
  value       = google_kms_key_ring.main.id
}

output "kms_keyring_name" {
  description = "KMS Key Ring name"
  value       = google_kms_key_ring.main.name
}

output "kms_main_key_id" {
  description = "Main KMS Crypto Key ID"
  value       = google_kms_crypto_key.looply_key.id
}

output "kms_database_key_id" {
  description = "Database KMS Crypto Key ID"
  value       = google_kms_crypto_key.database_key.id
}

output "kms_storage_key_id" {
  description = "Storage KMS Crypto Key ID"
  value       = google_kms_crypto_key.storage_key.id
}

output "secret_ssl_cert_id" {
  description = "SSL Certificate Secret ID"
  value       = google_secret_manager_secret.ssl_certificate.id
}

output "secret_db_password_id" {
  description = "Database Password Secret ID"
  value       = google_secret_manager_secret.db_password.id
}

output "secret_api_key_id" {
  description = "API Key Secret ID"
  value       = google_secret_manager_secret.api_key.id
}

output "secret_oauth_secret_id" {
  description = "OAuth Secret ID"
  value       = google_secret_manager_secret.oauth_secret.id
}

output "secrets_created" {
  description = "List of all created secrets"
  value = [
    google_secret_manager_secret.ssl_certificate.secret_id,
    google_secret_manager_secret.db_password.secret_id,
    google_secret_manager_secret.api_key.secret_id,
    google_secret_manager_secret.oauth_secret.secret_id
  ]
}

output "kms_keys_created" {
  description = "List of all created KMS keys"
  value = {
    main     = google_kms_crypto_key.looply_key.id
    database = google_kms_crypto_key.database_key.id
    storage  = google_kms_crypto_key.storage_key.id
  }
}
