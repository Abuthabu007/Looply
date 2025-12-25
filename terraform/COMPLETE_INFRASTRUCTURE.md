# Complete Infrastructure Overview

**Last Updated**: December 16, 2025  
**Status**: ✅ Production-Ready

---

## 🏗️ Architecture Layers

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SECURITY LAYER                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐   │
│  │ Cloud Armor  │  │  Cloud KMS   │  │  Secret Manager          │   │
│  │ (DDoS+WAF)   │  │ (Encryption) │  │ (Secrets)                │   │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │    Identity-Aware Proxy (IAP)                                │   │
│  │    OAuth 2.0 · RBAC · Audit Logging                          │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│                        DELIVERY LAYER                               │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │         Global Load Balancer + Cloud CDN                     │   │
│  │  (HTTPS · Geo-routing · Video Cache · Analytics Cache)       │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                    ↓                          ↓
        ┌───────────────────┐        ┌───────────────────┐
        │   Cloud Storage   │        │   VPC Network     │
        │  (Video Files)    │        │  (Security)       │
        └───────────────────┘        └───────────────────┘
                    ↓                          │
        ┌───────────────────┐                  │
        │   Cloud CDN       │                  ↓
        │  (Edge Cache)     │        ┌───────────────────┐
        └───────────────────┘        │   Cloud Run       │
                                     │  (Serverless)     │
                                     │  Multi-region     │
                                     └───────────────────┘
                                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                        MESSAGING LAYER                              │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │         Cloud Pub/Sub (Event-driven)                         │   │
│  │  ┌────────────────┐  ┌──────────────┐  ┌──────────────────┐ │   │
│  │  │ events topic   │  │ video_proc   │  │ user_events      │ │   │
│  │  └────────────────┘  └──────────────┘  └──────────────────┘ │   │
│  │           ↓                  ↓                   ↓            │   │
│  │  ┌────────────────┐  ┌──────────────┐  ┌──────────────────┐ │   │
│  │  │ subscriptions  │  │  subscr.     │  │  subscriptions   │ │   │
│  │  │ (primary)      │  │ (with DLQ)   │  │  (processing)    │ │   │
│  │  └────────────────┘  └──────────────┘  └──────────────────┘ │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA LAYER                                  │
│  ┌──────────────────────────┐     ┌──────────────────────────────┐  │
│  │  Firestore               │     │  BigQuery                    │  │
│  │ (Real-time NoSQL)        │     │ (Analytics Warehouse)        │  │
│  │ - Users                  │     │ - stream_events table        │  │
│  │ - Streams                │     │ - user_analytics table       │  │
│  │ - Sessions               │     │ - stream_quality table       │  │
│  │ - Multi-region           │     │ - Scheduled queries          │  │
│  │ - PITR enabled           │     │ - BI/Analytics ready         │  │
│  └──────────────────────────┘     └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│                     OBSERVABILITY LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐   │
│  │ Cloud Logging│  │ Cloud Monitor│  │  Alert Policies          │   │
│  │ (Logs→CS)    │  │ (Metrics)    │  │ (10 critical alerts)     │   │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐   │
│  │ Dashboards   │  │ Uptime Checks│  │  Notification Channels   │   │
│  │ (Real-time)  │  │ (3 regions)  │  │ (Email + Slack)          │   │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ IAP Audit Logging                                            │   │
│  │ - Failed auth attempts  - Access logs  - Token events        │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📦 All Modules (9 Total)

### Core Infrastructure Modules

#### 1. **Service Accounts** ✅
- 8 service accounts created
- 25+ IAM role bindings
- Least-privilege principle
- Per-service isolation

**SA List**:
- Cloud Run SA
- Pub/Sub SA
- BigQuery SA
- Firestore SA
- Cloud Storage SA
- Cloud Scheduler SA
- Artifact Registry SA
- Cloud Logging SA

---

#### 2. **Networking** ✅
- Global VPC with multi-region setup
- 4 subnets (2 per region)
- Cloud NAT for outbound
- Firewall rules
- VPC Flow Logs
- Health check rules

---

#### 3. **Compute** ✅
- 3 Cloud Run services
- 2 regions (primary + secondary)
- Auto-scaling 0-100 instances
- HTTPS only
- Memory/CPU configured
- Health checks

**Services**:
- Stream Processor
- Video Analytics
- User Management

---

#### 4. **Pub/Sub** ✅
- 4 topics created
- 5+ subscriptions
- Dead Letter Queues
- Message retention (7 days)
- Push subscriptions to Cloud Run

**Topics**:
- events
- video_processing
- user_events
- stream_quality

---

#### 5. **Storage** ✅
- 4 Cloud Storage buckets
- Versioning on videos bucket
- Lifecycle policies (30/90 days)
- CORS enabled
- IAM bindings
- CDN ready

**Buckets**:
- videos (versioning + CDN)
- analytics (90-day retention)
- logs (90-day retention)
- backup (multi-region)

---

#### 6. **Databases** ✅
- Firestore (multi-region, PITR)
- BigQuery (analytics dataset)
- 3 BigQuery tables pre-configured
- Indexes ready
- Schema optimized

**Data**:
- Firestore: Real-time user data
- BigQuery: Historical analytics

---

#### 7. **Load Balancer** ✅
- Global static IP
- HTTPS/SSL termination
- Cloud CDN integration
- URL-based routing
- Health checks
- HTTP→HTTPS redirect

---

#### 8. **Identity-Aware Proxy (IAP)** ✅ (NEW)
- OAuth 2.0 authentication
- Backend service bindings
- User/Group authorization
- Role-based access control (RBAC)
- Audit logging (Cloud Logging)
- Cloud Monitoring alerts
- KMS encryption for secrets

**Features**:
- Admin panel protection
- User management API protection
- Analytics dashboard protection
- Public access options
- Failed auth alerts
- Integration with load balancer

**Configuration**:
- Admin users: 5 authorized accounts
- User management: 3 authorized accounts
- Analytics: 3 authorized accounts
- Public access: Disabled (restrictive)
- Alerts: Enabled for failed auth
- Failed auth threshold: 50 in 5 minutes

**OAuth Setup** (requires manual GCP Console config):
```
1. Create OAuth consent screen
2. Create OAuth 2.0 Client ID (Web Application)
3. Add authorized redirect URIs
4. Copy client ID and secret to terraform.tfvars
5. Add to authorized users list
6. Deploy with terraform apply
```

**Status**: ✅ Configured in infrastructure  
⚠️ **Activation**: Requires `google_oauth_client_id` in terraform.tfvars

---

### Security & Observability Modules (NEW)

#### 8. **Security** ✨ (NEW)
- Cloud Armor (DDoS+WAF)
- Cloud KMS (3 encryption keys)
- Secret Manager (4 secrets)
- IAM bindings
- Key rotation policies
- Automatic secret replication
- IAP Secret Encryption (KMS-managed)

**Security Features**:
- Rate limiting
- Geo-blocking
- OWASP protection
- Key management
- Secret rotation
- OAuth secret protection (KMS encrypted)
- IAP service account permissions

---

#### 9. **Monitoring** ✨ (NEW)
- Cloud Monitoring (metrics)
- Cloud Logging (log management)
- 9 alert policies (including IAP auth failures)
- Notification channels
- Custom dashboards
- Uptime checks
- Log sinks (including IAP logs)

**Alerts**:
- Cloud Run metrics
- Pub/Sub lag
- Database performance
- Storage growth
- API availability
- ⭐ IAP Failed Authentication
- Load Balancer status

**IAP Monitoring**:
- Failed auth attempt logging
- Alert when threshold exceeded (50 failures/5 min)
- Access logs to Cloud Storage
- Real-time metrics dashboard

---

#### 10. **Monitoring** ✨ (NEW - DUPLICATE REMOVED)

---

## 📊 Resource Count Summary

| Category | Count |
|----------|-------|
| Service Accounts | 8 |
| Subnets | 4 |
| Cloud Run Services | 3 |
| Pub/Sub Topics | 4 |
| Pub/Sub Subscriptions | 5+ |
| Cloud Storage Buckets | 4 |
| Firestore Collections | 3 |
| BigQuery Tables | 3 |
| KMS Keys | 3 |
| Secrets (SM) | 4 |
| Alert Policies | 9 |
| Notification Channels | 2+ |
| **IAP Components** | **4** |
| IAP Backend Service Bindings | 2 |
| IAP Admin Role Bindings | 1 |
| IAP Log Sinks | 1 |
| **TOTAL** | **~75+** |

---

## 🔄 Data Flow Example: Video Upload

```
1. User uploads video
   ↓
2. Load Balancer receives request (HTTPS)
   ↓
3. Cloud Armor checks security
   ↓
4. Cloud Run (User Management) validates user
   ↓
5. Cloud Run generates signed URL
   ↓
6. User uploads to Cloud Storage (videos bucket)
   ↓
7. Cloud Storage triggers Cloud Pub/Sub event
   ↓
8. Cloud Run (Stream Processor) receives event
   ↓
9. Processes video metadata
   ↓
10. Writes to Firestore (real-time)
    ↓
11. Publishes to video_processing topic
    ↓
12. Cloud Run (Video Analytics) processes
    ↓
13. Writes analytics to BigQuery
    ↓
14. User sees video via CDN (cached)
```

---

## 🔐 Security Flow

```
User Request
    ↓
HTTPS/TLS (SSL cert from Secret Manager)
    ↓
Cloud Armor (DDoS protection + WAF)
    ↓
Identity-Aware Proxy (IAP)
    ├─ OAuth 2.0 authentication
    ├─ Token verification
    ├─ Role-based authorization (RBAC)
    └─ Audit logging
    ↓
IAM Authentication (Service Account)
    ↓
Cloud KMS (Decrypt sensitive data)
    ↓
Secret Manager (Access secrets)
    ↓
VPC Network (Private networking)
    ↓
Cloud Run Service
    ↓
Firestore + BigQuery (Encrypted data)
```

---

## 🔐 IAP Access Control Matrix

| Service | Admin | User Mgmt | Analytics | Public |
|---------|-------|-----------|-----------|--------|
| **Backend API** | ✅ Binding | ✅ Binding | ✅ Binding | ❌ No |
| **Frontend Web** | ✅ Binding | ✅ Binding | ✅ Binding | ❌ No |
| **OAuth Required** | Yes | Yes | Yes | No |
| **Role Verification** | Yes | Yes | Yes | No |
| **Audit Logging** | ✅ Enabled | ✅ Enabled | ✅ Enabled | N/A |
| **Status** | ✅ Ready* | ✅ Ready* | ✅ Ready* | ⏳ Optional |

**Ready* = Requires OAuth Client ID in terraform.tfvars**

---

## 📈 Monitoring Flow

```
Cloud Run logs
    ↓
Cloud Logging
    ↓
┌─────────────────────────────┐
│   Log Sinks                 │
├─────────────────────────────┤
│ → Cloud Storage (all logs)  │
│ → Cloud Logging (real-time) │
└─────────────────────────────┘
    ↓
Cloud Monitoring (metrics)
    ↓
┌─────────────────────────────┐
│   Alert Policies            │
├─────────────────────────────┤
│ → Error Rate                │
│ → Latency                   │
│ → Resource Usage            │
│ → Availability              │
└─────────────────────────────┘
    ↓
┌─────────────────────────────┐
│   Notifications             │
├─────────────────────────────┤
│ → Email (primary)           │
│ → Email (secondary)         │
│ → Slack (critical only)     │
└─────────────────────────────┘
```

---

## 🚀 Deployment Commands

### Prerequisites
```bash
# Install Terraform
brew install terraform

# Authenticate with GCP
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### Deploy
```bash
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply (deploy infrastructure)
terraform apply tfplan

# Get outputs
terraform output
```

---

## 📋 Configuration Checklist

### Before Deployment
- [ ] Set `gcp_project_id` in terraform.tfvars
- [ ] Generate SSL certificate and private key
- [ ] Update `alert_email_primary`
- [ ] (Optional) Configure `slack_webhook_url`
- [ ] Review `allowed_countries` for geo-blocking
- [ ] Set strong passwords for secrets

### IAP Configuration (Optional but Recommended)
- [ ] Create OAuth 2.0 consent screen in GCP Console
- [ ] Create OAuth 2.0 Client ID (Web Application type)
- [ ] Add authorized redirect URIs
- [ ] Copy `google_oauth_client_id` to terraform.tfvars
- [ ] Copy `google_oauth_client_secret` to terraform.tfvars
- [ ] Add authorized user emails to:
  - `iap_admin_authorized_users`
  - `iap_user_mgmt_authorized_users`
  - `iap_analytics_authorized_users`
- [ ] Set `iap_enable_alerts = true`
- [ ] (Optional) Configure public access: `iap_enable_public_access = true`

### After Deployment
- [ ] Verify Cloud Armor policy in console
- [ ] Test alert channels (send test alert)
- [ ] Check KMS keys are created
- [ ] Verify secrets in Secret Manager
- [ ] View dashboard in Cloud Console
- [ ] Check uptime check status
- [ ] **[NEW]** Verify IAP bindings are active (if OAuth configured)
- [ ] **[NEW]** Test IAP authentication flow
- [ ] **[NEW]** Check IAP audit logs in Cloud Logging

---

## 💾 Backup & Recovery

### Firestore
- Point-in-Time Recovery (PITR): Enabled
- Backup retention: 35 days
- Recovery: Via Cloud Console

### Cloud Storage
- Backup bucket (multi-region)
- Versioning (videos bucket)
- Lifecycle: Transition to Coldline after 90 days

### BigQuery
- Snapshots via dataset copies
- Scheduled queries for aggregation
- No automatic backup (query history available)

---

## 📞 Support & Documentation

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Main reference |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System design |
| [QUICKSTART.md](QUICKSTART.md) | Getting started |
| [GAP_ANALYSIS.md](GAP_ANALYSIS.md) | Gap identification |
| [SECURITY_AND_MONITORING.md](SECURITY_AND_MONITORING.md) | Detailed guides |
| [COMPLETION_CHECKLIST.md](COMPLETION_CHECKLIST.md) | Validation |
| [INDEX.md](INDEX.md) | Navigation |

---

## 🎯 Next Steps

1. **Deploy Infrastructure**
   - [ ] Run `terraform apply`
   - [ ] Verify all resources created

2. **Configure Applications**
   - [ ] Build Docker images
   - [ ] Push to Artifact Registry
   - [ ] Deploy to Cloud Run

3. **Test & Validate**
   - [ ] Test alert channels
   - [ ] Verify Cloud Armor blocking
   - [ ] Check dashboard metrics
   - [ ] Run uptime checks

4. **Monitor & Optimize**
   - [ ] Watch metrics for 1-2 days
   - [ ] Adjust alert thresholds
   - [ ] Optimize Cloud Run sizing
   - [ ] Review costs

---

**Status**: ✅ Infrastructure is production-ready for deployment

