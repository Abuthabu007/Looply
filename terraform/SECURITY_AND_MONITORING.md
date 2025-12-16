# High-Priority Security & Monitoring Enhancements

## Overview

This document details the three newly implemented high-priority modules that significantly improve the security posture and operational observability of the Looply infrastructure.

---

## 🔒 Security Module

### Purpose
Implement production-grade security controls including DDoS protection, key management, and secret storage.

### Components

#### 1. Cloud Armor (DDoS Protection & WAF)
**What it does**: Protects your Load Balancer from DDoS attacks and common web vulnerabilities.

**Features**:
- Rate limiting (100 requests/minute per IP)
- Geo-blocking support (restrict by country)
- OWASP ModSecurity Core Rule Set protection
- XSS, SQL Injection, RCE, Protocol Attack, Scanner Detection rules
- Custom rule support

**How it works**:
```
User Request → Cloud Armor → Load Balancer → Cloud Run
                    ↓
            (Blocks malicious traffic)
```

**Configuration in `terraform.tfvars`**:
```hcl
# Enable geo-blocking for specific countries
allowed_countries = ["US", "GB", "DE", "FR", "CA", "AU"]

# Start in preview mode (logging only, not blocking)
security_policy_preview_mode = true
```

**Costs**: ~$25/month for Cloud Armor policy

---

#### 2. Cloud KMS (Key Management Service)
**What it does**: Centralized management of encryption keys with automatic rotation and audit logging.

**Keys Created**:
- **Main Key** (`looply-key`) - General purpose encryption
- **Database Key** (`looply-db-key`) - 30-day rotation
- **Storage Key** (`looply-storage-key`) - 90-day rotation

**Key Features**:
- Automatic key rotation
- Audit trail of all key usage
- Hardware Security Module (HSM) backed
- Key versioning and management
- Compliance: FedRAMP, HIPAA, PCI-DSS

**Service Account Access**:
- Cloud Run: Can decrypt/encrypt with all keys
- BigQuery: Can decrypt with database key
- Cloud Storage: Can decrypt/encrypt with storage key

**Costs**: ~$1.68 per key per month + API call costs (~$0.06 per 10k calls)

---

#### 3. Secret Manager
**What it does**: Secure storage for sensitive data like passwords, API keys, and certificates.

**Secrets Managed**:
1. **SSL Certificate** - HTTPS certificate
2. **Database Password** - Firestore access
3. **API Key** - Third-party integrations
4. **OAuth Secret** - OAuth client credentials

**Key Features**:
- Automatic replication across regions
- Access control via IAM
- Automatic secret rotation support
- Audit logging
- Version management

**How to use in Cloud Run**:
```python
# In your Cloud Run code
from google.cloud import secretmanager

def access_secret(secret_id, version_id="latest"):
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/YOUR_PROJECT/secrets/{secret_id}/versions/{version_id}"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")

# Usage
db_password = access_secret("looply-db-password")
api_key = access_secret("looply-api-key")
```

**Costs**: ~$0.06 per secret per month + access costs (~$0.06 per 10k accesses)

---

## 📊 Monitoring Module

### Purpose
Provide comprehensive observability through metrics, logging, dashboards, and alerting.

### Components

#### 1. Alert Policies (9 Critical Alerts)

##### Cloud Run Alerts
- **High Error Rate** (>5%) - Response time: 5 minutes
- **CPU Throttling** (>10%) - Response time: 5 minutes
- **High Memory** (>80%) - Response time: 5 minutes
- **High Latency** (p99 > 2 seconds) - Response time: 5 minutes

##### Pub/Sub Alerts
- **Message Lag** (>1000 messages) - Response time: 5 minutes

##### Firestore Alerts
- **High Read Operations** (>10k/minute) - Response time: 5 minutes

##### BigQuery Alerts
- **High Slot Usage** (>80%) - Response time: 5 minutes

##### Cloud Storage Alerts
- **Abnormal Growth Rate** - Response time: 10 minutes

##### Uptime Monitoring
- **Global API Availability** - 3 region uptime check (USA, EU, APAC)

---

#### 2. Notification Channels

Configure where alerts are sent:

**Email Alerts** (Always enabled)
```hcl
alert_email_primary   = "ops-team@example.com"
alert_email_secondary = "backup-ops@example.com"
```

**Slack Alerts** (Optional)
```hcl
slack_webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
slack_channel_name = "#alerts"
```

**How to add PagerDuty** (future enhancement):
```hcl
# Not yet implemented, but can be added to monitoring module
resource "google_monitoring_notification_channel" "pagerduty" {
  type = "pagerduty"
  labels = {
    service_key = "your-pagerduty-service-key"
  }
}
```

---

#### 3. Custom Dashboard

**Looply - Infrastructure Overview** includes:
- Cloud Run request rate and error rate
- Pub/Sub message lag
- Firestore read/write operations
- Cloud Storage trends
- Real-time metrics visualization

**Accessing the dashboard**:
```bash
# The dashboard URL will be output after terraform apply
# Format: https://console.cloud.google.com/monitoring/dashboards/custom/DASHBOARD_ID
```

---

#### 4. Uptime Checks

**What it monitors**: Global API availability from 3 regions

**Configuration**:
```hcl
api_endpoint = "api.example.com"

# Uptime check details:
# - Health check endpoint: /health
# - Protocol: HTTPS (443)
# - Frequency: Every 60 seconds
# - Regions: USA, Europe, Asia-Pacific
```

**Expected Health Check Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-12-16T10:30:00Z",
  "services": {
    "stream_processor": "up",
    "video_analytics": "up",
    "user_management": "up"
  }
}
```

---

#### 5. Log Sinks

Logs are automatically sent to Cloud Storage buckets:

- **All logs** (WARNING and above) → `logs_bucket`
- **Error logs only** (ERROR and above) → `logs_bucket`

**Log retention**: 90 days (configured in storage module)

---

## 🔧 Configuration Guide

### Step 1: Update terraform.tfvars

```hcl
# Security settings
db_password        = "YourSecurePassword123!@#"
api_key            = "your-api-key-here"
oauth_client_secret = "your-oauth-secret"

# Geo-blocking (optional)
allowed_countries = ["US", "GB", "DE", "FR", "CA", "AU"]

# Preview mode (set to false in production)
security_policy_preview_mode = true

# Monitoring
alert_email_primary   = "your-email@example.com"
alert_email_secondary = "backup@example.com"
slack_webhook_url = "https://hooks.slack.com/services/xxx/yyy/zzz"

api_endpoint = "your-api.example.com"
```

### Step 2: Deploy

```bash
cd terraform
terraform plan
terraform apply
```

### Step 3: Verify Deployment

```bash
# Check Cloud Armor policy
terraform output security

# Check alert policies
terraform output monitoring
```

### Step 4: Configure Slack (Optional)

1. Create Slack App: https://api.slack.com/apps
2. Enable Incoming Webhooks
3. Create webhook for #alerts channel
4. Update `slack_webhook_url` in terraform.tfvars

---

## 🚀 Deployment Checklist

- [ ] Update all variables in `terraform.tfvars`
- [ ] Set strong passwords for `db_password`
- [ ] Configure alert email addresses
- [ ] (Optional) Setup Slack webhook
- [ ] Review `security_policy_preview_mode` setting
- [ ] Run `terraform plan` and review changes
- [ ] Apply Terraform: `terraform apply`
- [ ] Verify alert channels are working
- [ ] Test Cloud Armor with blocked request
- [ ] Check dashboard in Cloud Console

---

## 📊 Cost Estimate

### Monthly Costs:

| Component | Cost | Notes |
|-----------|------|-------|
| Cloud Armor | $25 | DDoS protection |
| KMS (3 keys) | $5.04 | Key management |
| Secret Manager | $0.18 | Secret storage |
| Monitoring (alerts) | $0 | Included in GCP |
| Logging | Varies | Based on volume |
| Uptime Checks | $1.00 | 3 regions × $0.33 |
| **Total** | **~$31.22** | Baseline monthly |

---

## 🔐 Security Best Practices

### 1. Rotate Secrets Regularly
```bash
# Update secret in Secret Manager
echo -n "new-password" | gcloud secrets versions add looply-db-password --data-file=-
```

### 2. Audit Key Usage
```bash
# View Cloud KMS audit logs
gcloud logging read \
  'resource.type="cloudkms.googleapis.com/CryptoKey" AND severity="NOTICE"' \
  --limit 50
```

### 3. Monitor Secret Access
```bash
# View Secret Manager access logs
gcloud logging read \
  'resource.type="secretmanager.googleapis.com/Secret"' \
  --limit 50
```

### 4. Review Alert Policies
- [ ] Test alert channels monthly
- [ ] Review alert thresholds quarterly
- [ ] Update contact list as team changes

### 5. Security Policy Stages
- **Stage 1 (Preview)**: Monitor threats, don't block
- **Stage 2 (Testing)**: Block in test environment first
- **Stage 3 (Production)**: Enable blocking after validation

---

## 🐛 Troubleshooting

### Cloud Armor not blocking traffic?
1. Check if `security_policy_preview_mode = true` (preview mode doesn't block)
2. Verify policy is attached to load balancer
3. Check logs: `gcloud logging read 'resource.type="http_load_balancer"'`

### Alerts not arriving?
1. Verify notification channel is enabled: `gcloud alpha monitoring channels list`
2. Check email is in allow list in Secret Manager
3. Test alert manually in Cloud Console

### KMS key access denied?
1. Verify IAM binding: `gcloud projects get-iam-policy PROJECT_ID`
2. Check service account has `roles/cloudkms.cryptoKeyEncrypterDecrypter`

### Secrets not accessible from Cloud Run?
1. Verify service account IAM binding: `gcloud secrets get-iam-policy SECRET_ID`
2. Cloud Run SA needs `roles/secretmanager.secretAccessor`

---

## 📚 Related Documentation

- [Cloud Armor Overview](https://cloud.google.com/armor/docs)
- [Cloud KMS Best Practices](https://cloud.google.com/kms/docs/best-practices)
- [Secret Manager Guide](https://cloud.google.com/secret-manager/docs)
- [Cloud Monitoring Docs](https://cloud.google.com/monitoring/docs)
- [Creating Alert Policies](https://cloud.google.com/monitoring/alerts/best-practices)

---

## 🔄 Next Steps

1. **Deploy these modules** - Implement in your environment
2. **Test alerts** - Verify all notification channels work
3. **Monitor costs** - Track actual costs vs estimates
4. **Customize thresholds** - Adjust alert thresholds based on your metrics
5. **Implement CI/CD** - Add Cloud Build pipeline (separate module)

---

## Questions?

Refer to the main [README.md](../README.md) or [ARCHITECTURE.md](../ARCHITECTURE.md) for comprehensive infrastructure documentation.
