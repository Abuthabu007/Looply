# IAP Module - Identity-Aware Proxy

This module provides comprehensive Identity-Aware Proxy (IAP) setup for the Looply platform, enabling OAuth 2.0-based authentication and authorization for protected backend services.

## Overview

Identity-Aware Proxy (IAP) is a Google Cloud service that intercepts web requests sent to your backend applications and verifies user identity and context before granting access. It provides:

- **OAuth 2.0 Authentication**: Secure user verification
- **Fine-grained Access Control**: Role-based authorization
- **Audit Logging**: Complete access trail
- **Multi-factor Authentication Ready**: Supports MFA enforcement
- **Session Management**: Automatic session handling

## What This Module Creates

### 1. OAuth 2.0 Configuration
- **IAP Client**: OAuth 2.0 client for authentication
- **IAP Brand**: OAuth consent screen configuration
- **Credentials**: Client ID and secret for OAuth flow

### 2. Backend Service Protection
- **Admin Panel IAP**: Protects admin backend service
- **User Management API IAP**: Protects user management service
- **Analytics Dashboard IAP**: Protects analytics backend service

### 3. Access Control
- **IAM Bindings**: User/group authorization per service
- **Role Assignments**: IAP HTTPS Resource Accessor roles
- **Public Access (Optional)**: Support for public IAP access if needed

### 4. Monitoring & Logging
- **Authentication Logging**: Track all IAP access events
- **Failed Auth Alerts**: Alert on high authentication failure rates
- **Audit Logging**: Complete audit trail for compliance

### 5. Security
- **KMS Encryption**: Client secrets encrypted with Cloud KMS
- **Secure Secret Storage**: Sensitive credentials properly managed

## Usage

### Basic Configuration

```hcl
module "iap" {
  source = "./modules/iap"

  gcp_project_id                       = var.gcp_project_id
  project_prefix                       = var.project_prefix
  support_email                        = "security@example.com"
  
  # Backend services to protect
  admin_backend_service_name           = "admin-backend"
  user_management_backend_service_name = "user-api-backend"
  analytics_backend_service_name       = "analytics-backend"
  
  # Authorized users
  admin_authorized_users = [
    "user:admin@example.com",
    "group:admins@example.com"
  ]
  
  user_management_authorized_users = [
    "group:backend-team@example.com"
  ]
  
  analytics_authorized_users = [
    "user:analyst@example.com",
    "group:data-team@example.com"
  ]
  
  # Configuration
  enable_public_iap_access = false
  enable_iap_alerts        = true
  failed_auth_threshold    = 50
  
  # Dependencies
  logs_bucket_name         = module.storage.logs_bucket_name
  notification_channel_ids = module.monitoring.notification_channel_ids
  service_account_email    = module.service_accounts.iap_service_account_email
  kms_crypto_key_id        = module.security.kms_crypto_key_id
  
  tags = var.tags
}
```

## Key Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `gcp_project_id` | string | - | GCP project ID |
| `project_prefix` | string | - | Prefix for resource naming |
| `support_email` | string | - | Support email for OAuth consent screen |
| `application_title` | string | "Looply - Video Streaming Platform" | App title for OAuth |
| `admin_backend_service_name` | string | - | Admin backend service name |
| `user_management_backend_service_name` | string | - | User management backend name |
| `analytics_backend_service_name` | string | - | Analytics backend name |
| `admin_authorized_users` | list(string) | [] | Admin users (e.g., user:admin@domain.com) |
| `user_management_authorized_users` | list(string) | [] | User management API authorized users |
| `analytics_authorized_users` | list(string) | [] | Analytics dashboard authorized users |
| `public_authorized_users` | list(string) | [] | Public IAP access users |
| `enable_public_iap_access` | bool | false | Enable public IAP access |
| `enable_iap_alerts` | bool | true | Enable authentication failure alerts |
| `failed_auth_threshold` | number | 50 | Failed auth alert threshold |
| `logs_bucket_name` | string | - | Cloud Storage bucket for logs |
| `notification_channel_ids` | list(string) | [] | Monitoring notification channels |
| `service_account_email` | string | - | Service account email |
| `iap_service_account_email` | string | - | IAP service account email |
| `kms_crypto_key_id` | string | - | KMS crypto key for encryption |

## Outputs

| Output | Description |
|--------|-------------|
| `iap_client_id` | OAuth 2.0 client ID |
| `iap_client_secret` | OAuth 2.0 client secret (sensitive) |
| `iap_brand_name` | IAP brand name |
| `admin_iap_binding_role` | IAM role for admin backend |
| `user_mgmt_iap_binding_role` | IAM role for user management |
| `analytics_iap_binding_role` | IAM role for analytics |
| `iap_logs_sink_name` | Cloud Logging sink name |
| `iap_logs_destination` | Logs destination bucket |
| `iap_monitoring_alert_policy_name` | Alert policy name |
| `iap_oauth_setup_info` | OAuth configuration details |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Internet Users                        │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              Load Balancer (HTTPS)                       │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│    Identity-Aware Proxy (IAP) - OAuth Verification      │
│                                                          │
│  ✓ User Identity Check                                  │
│  ✓ OAuth Token Validation                               │
│  ✓ Authorization Enforcement                            │
└─────────────────────────────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         ▼                  ▼                   ▼
    ┌─────────┐        ┌──────────┐       ┌─────────────┐
    │ Admin   │        │ User     │       │  Analytics  │
    │ Panel   │        │ Management│      │  Dashboard  │
    └─────────┘        └──────────┘       └─────────────┘
    Cloud Run          Cloud Run           Cloud Run
```

## Access Control Examples

### Grant Admin Access to a User

```hcl
iap_admin_authorized_users = [
  "user:john.doe@company.com",
  "user:jane.smith@company.com"
]
```

### Grant Admin Access to a Group

```hcl
iap_admin_authorized_users = [
  "group:platform-admins@company.com"
]
```

### Mixed Users and Groups

```hcl
iap_admin_authorized_users = [
  "user:lead.admin@company.com",
  "group:admins@company.com",
  "group:on-call@company.com"
]
```

## OAuth 2.0 Setup

After applying this module, configure your application's OAuth 2.0 redirects:

1. **Redirect URI**: `https://iap.googleapis.com/google_cloud_iap/web/oauth2/callback`
2. **Scopes**: `openid`, `email`, `profile`
3. **Grant Types**: `authorization_code`

## Security Considerations

### 1. Client Secret Protection
- Stored in Cloud KMS encrypted format
- Never exposed in logs or Terraform state
- Rotated regularly

### 2. Access Control
- Use service accounts for API access
- Group-based access for organizational units
- Time-limited access when possible

### 3. Audit Trail
- All access attempts logged
- Failed authentication attempts tracked
- Alerts for suspicious activity

### 4. Multi-Factor Authentication
- IAP integrates with Cloud Identity for MFA
- Enable MFA policies at organization level
- Enforce for sensitive roles (admins, analysts)

## Monitoring & Alerts

### Failed Authentication Alerts
Alerts trigger when authentication failures exceed the threshold:

```
Resource: IAP Protected Services
Metric: Failed Authentication Rate
Threshold: 50+ failures in 5 minutes
Action: Email notification + Cloud Logging
```

### Access Logs
All IAP access attempts logged to:
- **Destination**: Cloud Storage bucket
- **Filter**: Automatically captures IAP logs
- **Retention**: Configurable (default: 90 days)

### Viewing Logs

```bash
# Check IAP logs
gcloud logging read "resource.type=http_load_balancer" \
  --format=json --limit=50
```

## Troubleshooting

### OAuth Consent Screen Error
**Problem**: "OAuth consent screen not configured"
**Solution**: 
```bash
gcloud iap oauth-brands create \
  --application_title="Looply" \
  --support_email=security@looply.io
```

### Access Denied Error
**Problem**: User gets 403 "Access Denied" when accessing IAP-protected service
**Solution**: 
1. Verify user is added to `iap_*_authorized_users` list
2. Check IAM roles: User must have `roles/iap.httpsResourceAccessor`
3. Wait 5-10 minutes for IAM changes to propagate

### Missing Client ID
**Problem**: OAuth client ID not found
**Solution**: Ensure IAP brand is created first, then apply module

## Best Practices

### 1. Use Google Groups
```hcl
iap_admin_authorized_users = [
  "group:admins@company.com"  # Preferred over individual users
]
```

### 2. Principle of Least Privilege
- Only grant necessary access
- Use role-based groups
- Rotate access regularly

### 3. Enable MFA
```bash
gcloud identity groups memberships describe user@company.com
# Enable MFA through Cloud Identity admin console
```

### 4. Monitor Access
```bash
# Check who accessed what and when
gcloud logging read "resource.type=http_load_balancer AND jsonPayload.enforcedSecurityPolicy.name=~'.*'" \
  --format=json --limit=100
```

### 5. Backup OAuth Credentials
- Store client secret securely
- Use Secret Manager for secrets
- Enable rotation policies

## Integration with Other Modules

### With Monitoring Module
```hcl
notification_channel_ids = module.monitoring.notification_channel_ids
```
Enables alert notifications for failed authentication.

### With Storage Module
```hcl
logs_bucket_name = module.storage.logs_bucket_name
```
Centralized logging to Cloud Storage.

### With Security Module
```hcl
kms_crypto_key_id = module.security.kms_crypto_key_id
```
Client secrets encrypted with Cloud KMS.

## Compliance & Compliance

This IAP module supports:
- **SOC 2 Compliance**: Complete audit trail
- **GDPR Compliance**: User access logging
- **ISO 27001**: Identity and access management
- **HIPAA**: Encryption and audit controls

## Cost Estimation

### Pricing Components
- **IAP**: No additional charge (comes with Cloud Load Balancer)
- **OAuth/OpenID Connect**: No charge
- **Logging**: ~$0.50 per GB (varies by region)
- **Monitoring Alerts**: No charge for first 100 notification channels
- **KMS**: ~$6/month per key + $0.06/10K operations

### Sample Monthly Cost (100GB logs)
- IAP: $0
- Logging: $50
- Monitoring: $0
- KMS: ~$6
- **Total**: ~$56/month

## Next Steps

1. **Configure OAuth Users/Groups**
   - Add admin users/groups
   - Add API users/groups
   - Add analyst users/groups

2. **Enable Monitoring**
   - Setup email alerts
   - Configure Slack notifications
   - Create dashboards

3. **Enable MFA**
   - Configure Cloud Identity policies
   - Enforce MFA for admins
   - Test MFA flows

4. **Deploy Protected Services**
   - Update Cloud Run services
   - Configure backend services
   - Test IAP access

## Support & Documentation

- [Google Cloud IAP Documentation](https://cloud.google.com/iap/docs)
- [IAP Best Practices](https://cloud.google.com/iap/docs/best-practices)
- [OAuth 2.0 Setup Guide](https://cloud.google.com/iap/docs/app-engine-tutorial)
- [Troubleshooting IAP](https://cloud.google.com/iap/docs/troubleshooting)

---

**Module Version**: 1.0.0
**Last Updated**: 2025-12-16
**Maintained By**: Platform Team
