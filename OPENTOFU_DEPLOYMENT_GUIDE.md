# 🚀 Complete OpenTofu Infrastructure Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Deployment Order & Dependencies](#deployment-order--dependencies)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Resource Creation Details](#resource-creation-details)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### 1. **Required Tools**
- [ ] **OpenTofu** (or Terraform) - [Install](https://opentofu.org/docs/intro/install/)
  ```powershell
  # Verify installation
  opentofu version
  # OR
  terraform version
  ```

- [ ] **Google Cloud SDK (gcloud)** - [Install](https://cloud.google.com/sdk/docs/install)
  ```powershell
  # Verify installation
  gcloud --version
  
  # Authenticate with GCP
  gcloud auth login
  ```

- [ ] **Docker** (for later image builds) - [Install](https://www.docker.com/products/docker-desktop)
  ```powershell
  docker ps  # Verify Docker is running
  ```

### 2. **GCP Project Setup**
```powershell
# Set your GCP project ID
$PROJECT_ID = "looply-dev-481412"

# Set as default project
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable iap.googleapis.com
```

### 3. **Service Account Permissions**
Your user account needs these roles:
- `roles/editor` (or more specific roles)
- `roles/compute.admin`
- `roles/iam.securityAdmin`
- `roles/resourcemanager.projectIamAdmin`

### 4. **Prepare Configuration Files**
Update these files with your actual values:

#### 4a. **terraform.tfvars** - Critical Configuration
```hcl
gcp_project_id = "looply-dev-481412"  # ⚠️ REQUIRED
project_prefix = "looply"
environment    = "prod"
primary_region = "us-central1"
secondary_region = "europe-west1"

# Update with your actual values
db_password = "your-secure-password-here"
api_key = "your-api-key"
oauth_client_secret = "your-oauth-secret"

# Email addresses for alerts
alert_email_primary = "your-email@example.com"
alert_email_secondary = "backup-email@example.com"

# SSL Certificate (for later - HTTPS support)
ssl_certificate = "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
ssl_private_key = "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"

# Google OAuth (optional - for IAP)
google_oauth_client_id = ""
google_oauth_client_secret = ""
```

#### 4b. **Generate SSL Certificate** (if needed)
```powershell
# For self-signed certificate (testing only)
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes

# Extract certificate content
Get-Content cert.pem -Raw  # Copy to terraform.tfvars
Get-Content key.pem -Raw   # Copy to terraform.tfvars
```

---

## Architecture Overview

### Component Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                    Internet Users                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│         Global Load Balancer (HTTPS/HTTP)                   │
│    IP: Managed by GCP (shared across regions)               │
└─────────────────────────────────────────────────────────────┘
         │                   │                    │
         ▼                   ▼                    ▼
    ┌─────────┐         ┌──────────┐        ┌──────────────┐
    │ Frontend │         │  Backend │        │ CDN Cache    │
    │Cloud Run │         │Cloud Run │        │ (Static)     │
    │us-central│         │us-central│        │              │
    └─────────┘         └──────────┘        └──────────────┘
         │                   │
         ▼                   ▼
    ┌──────────────────────────────────────────────────────┐
    │             Databases & Storage                      │
    ├──────────────────────────────────────────────────────┤
    │ ✓ Firestore (NoSQL)      ✓ BigQuery (Analytics)      │
    │ ✓ Cloud Storage          ✓ Cloud Pub/Sub             │
    └──────────────────────────────────────────────────────┘
```

### Module Dependency Tree
```
apis (Enable Google Cloud APIs)
  │
  ├─→ service_accounts
  │     ├─→ Identity Platform
  │     ├─→ networking
  │     ├─→ compute (Cloud Run)
  │     ├─→ storage
  │     ├─→ databases
  │     ├─→ pubsub
  │     ├─→ security
  │     ├─→ monitoring
  │     └─→ iap
  │
  ├─→ networking
  │     └─→ load_balancer
  │
  ├─→ storage
  │     ├─→ load_balancer
  │     └─→ monitoring
  │
  └─→ compute
        └─→ pubsub
```

---

## Deployment Order & Dependencies

### Phase 1: Foundation (5 min)
**Order**: 1 → 2 → 3 → 4

| # | Module | Resources | Dependencies | Purpose |
|---|--------|-----------|--------------|---------|
| **1** | **apis** | Enable 15+ GCP APIs | None | Foundation for all other resources |
| **2** | **service_accounts** | 8 service accounts + 25 IAM roles | apis | Identity and access control |
| **3** | **identity_platform** | OAuth 2.0 configuration | apis | User authentication |
| **4** | **networking** | VPC, subnets, NAT, firewalls | apis | Network infrastructure |

### Phase 2: Data & Messaging (5 min)
**Order**: 5 → 6 → 7 (can be parallel)

| # | Module | Resources | Dependencies | Purpose |
|---|--------|-----------|--------------|---------|
| **5** | **storage** | 4 Cloud Storage buckets | service_accounts, apis | File storage & CDN |
| **6** | **databases** | Firestore + BigQuery | service_accounts, apis | Data persistence |
| **7** | **pubsub** | Topics & subscriptions | service_accounts, apis, compute | Event streaming |

### Phase 3: Compute & Security (5 min)
**Order**: 8 → 9 → 10 → 11

| # | Module | Resources | Dependencies | Purpose |
|---|--------|-----------|--------------|---------|
| **8** | **compute** | Cloud Run services (2 regions) | service_accounts, apis | Application runtime |
| **9** | **security** | KMS, Cloud Armor, Secrets | service_accounts, apis | Encryption & protection |
| **10** | **monitoring** | Dashboards & alerts | storage, apis | Observability |
| **11** | **load_balancer** | Global LB + CDN | networking, storage, compute, security | Public access point |

### Phase 4: Access Control (1 min)
**Order**: 12

| # | Module | Resources | Dependencies | Purpose |
|---|--------|-----------|--------------|---------|
| **12** | **iap** | IAP OAuth bindings | storage, monitoring, service_accounts, security | Secured access |

---

## Step-by-Step Deployment

### Step 1: Navigate to Terraform Directory
```powershell
cd d:\GCP-Project\Looply\Looply\terraform

# Verify you're in the right location
Get-Location
# Should show: D:\GCP-Project\Looply\Looply\terraform
```

### Step 2: Initialize OpenTofu
```powershell
# Initialize Terraform/OpenTofu (creates .terraform directory)
terraform init

# Expected output:
# - Initializing the backend...
# - Initializing modules...
# - Initializing provider plugins...
# - Terraform has been successfully configured!
```

**What it does:**
- Downloads provider plugins (Google Cloud)
- Initializes modules
- Sets up local state management

### Step 3: Format & Validate Configuration
```powershell
# Format all Terraform files
terraform fmt -recursive

# Validate configuration syntax
terraform validate

# Expected output:
# Success! The configuration is valid.
```

### Step 4: Create Terraform Plan
```powershell
# Generate execution plan
terraform plan -out=tfplan

# Review output to verify:
# - Resource count (should be 180+)
# - No errors or warnings
# - Correct regions (us-central1 and europe-west1)
```

**Important**: Read through the plan output carefully to ensure:
- ✓ All expected resources are being created
- ✓ No resources are being destroyed
- ✓ Regions are correct
- ✓ Service account emails are generated

### Step 5: Apply Infrastructure (⏱️ 15-20 minutes)
```powershell
# Apply the infrastructure
# This is where resources are actually created in GCP
terraform apply tfplan

# This will:
# 1. Create all GCP resources
# 2. Configure IAM roles
# 3. Set up networking
# 4. Initialize databases
# 5. Create Cloud Run services
# ⏳ TOTAL TIME: ~15-20 minutes
```

**Progress Indicators:**
- Minutes 0-2: Creating service accounts
- Minutes 2-4: Setting up networking
- Minutes 4-7: Creating storage & databases
- Minutes 7-10: Initializing Cloud Run
- Minutes 10-15: Configuring load balancer
- Minutes 15-20: Final IAM configuration

### Step 6: Verify Deployment
```powershell
# Output all created resource information
terraform output

# Key outputs to verify:
# - load_balancer_ip
# - cloud_run_service_urls
# - service_account_emails
# - database_ids
# - storage_bucket_names
```

### Step 7: Verify in GCP Console
```powershell
# Check Cloud Run services
gcloud run services list --region=us-central1 --project=looply-dev-481412

# Check Cloud Storage buckets
gcloud storage buckets list

# Check Firestore database
gcloud firestore databases list

# Check load balancer
gcloud compute forwarding-rules list --global
```

---

## Resource Creation Details

### Phase 1: APIs Module
**File**: `terraform/modules/apis/main.tf`

**Resources Created** (15 APIs):
- compute.googleapis.com
- run.googleapis.com
- firestore.googleapis.com
- pubsub.googleapis.com
- storage.googleapis.com
- bigquery.googleapis.com
- monitoring.googleapis.com
- logging.googleapis.com
- iam.googleapis.com
- artifactregistry.googleapis.com
- cloudkms.googleapis.com
- secretmanager.googleapis.com
- iap.googleapis.com
- cloudscheduler.googleapis.com
- cloudfunctions.googleapis.com

**Time**: 2 minutes | **Critical**: YES (blocks all other modules)

---

### Phase 2: Service Accounts Module
**File**: `terraform/modules/service_accounts/main.tf`

**Resources Created** (8 service accounts):
1. **cloud-run-sa** (looply-cloud-run@...)
2. **pubsub-sa** (looply-pubsub@...)
3. **bigquery-sa** (looply-bigquery@...)
4. **firestore-sa** (looply-firestore@...)
5. **storage-sa** (looply-storage@...)
6. **scheduler-sa** (looply-scheduler@...)
7. **artifact-registry-sa** (looply-artifact-registry@...)
8. **iap-sa** (looply-iap@...)

**IAM Roles Assigned** (25+ bindings):
- `roles/run.invoker` - Cloud Run
- `roles/pubsub.publisher` - Pub/Sub
- `roles/pubsub.subscriber` - Pub/Sub
- `roles/bigquery.dataEditor` - BigQuery
- `roles/firestore.serviceAgent` - Firestore
- `roles/storage.admin` - Cloud Storage
- `roles/cloudkms.cryptoKeyEncrypterDecrypter` - KMS
- `roles/iap.admin` - IAP
- And 17 more...

**Time**: 3 minutes | **Critical**: YES (required by all other modules)

---

### Phase 3: Networking Module
**File**: `terraform/modules/networking/main.tf`

**Resources Created**:
- 1 VPC Network (`looply-vpc`)
- 4 Subnets:
  - `looply-primary-subnet` (us-central1, 10.0.0.0/20)
  - `looply-primary-proxy-subnet` (us-central1, 10.0.16.0/24)
  - `looply-secondary-subnet` (europe-west1, 10.1.0.0/20)
  - `looply-secondary-proxy-subnet` (europe-west1, 10.1.16.0/24)
- 2 Cloud Routers (one per region)
- 2 Cloud NAT instances (one per region)
- 4 Firewall Rules:
  - Allow internal VPC communication
  - Allow HTTPS/HTTP from internet
  - Allow health checks
  - Allow GCP services
- 1 Private Service Connection

**Configuration**:
- Private Google Access: Enabled
- VPC Flow Logs: Enabled
- Multi-region: us-central1 + europe-west1

**Time**: 2 minutes | **Critical**: YES (required for load balancer)

---

### Phase 4: Storage Module
**File**: `terraform/modules/storage/main.tf`

**Resources Created** (4 Cloud Storage Buckets):

1. **Videos Bucket** (`looply-videos-*)
   - Purpose: Store uploaded video files
   - Versioning: Enabled
   - Lifecycle: Delete after 90 days
   - CDN: Enabled

2. **Logs Bucket** (`looply-logs-*)
   - Purpose: Application and infrastructure logs
   - Retention: 90 days (configurable)
   - Logging: Enabled

3. **Backups Bucket** (`looply-backups-*)
   - Purpose: Database backups
   - Versioning: Enabled
   - Lifecycle: Archive after 30 days

4. **Terraform State Bucket** (optional)
   - Purpose: Remote state management
   - Versioning: Enabled

**Access Control**:
- Cloud Run SA: Full access
- Storage SA: Management permissions
- Public access: Disabled (security best practice)

**Time**: 1 minute | **Critical**: Medium (needed for CDN)

---

### Phase 5: Databases Module
**File**: `terraform/modules/databases/main.tf`

**Resources Created**:

1. **Firestore Database** (Native mode)
   - Location: us-central1
   - PITR (Point-in-time recovery): Enabled
   - Backups: Automated

2. **BigQuery Dataset** (`looply_analytics`)
   - Location: US
   - Default TTL: 90 days
   - Encryption: GCP-managed

**Indexes Created**:
- User → timestamp (for queries)
- Video → status (for filtering)
- Analytics → event_type (for reporting)

**Service Accounts**:
- BigQuery SA: Editor role
- Cloud Run SA: Data editor role
- Firestore SA: Admin role

**Time**: 2 minutes | **Critical**: Medium

---

### Phase 6: Pub/Sub Module
**File**: `terraform/modules/pubsub/main.tf`

**Resources Created** (4 Topics + 5 Subscriptions):

**Topics**:
1. `looply-video-events` - Video upload/processing events
2. `looply-user-events` - User activity events
3. `looply-analytics-events` - Analytics data events
4. `looply-system-events` - System notifications

**Subscriptions**:
1. `looply-video-processor-sub` → Cloud Run endpoint
2. `looply-analytics-sub` → BigQuery
3. `looply-user-activity-sub` → Firestore
4. `looply-system-alerts-sub` → Email/Slack
5. `looply-dlq-sub` - Dead Letter Queue

**Configuration**:
- Message retention: 7 days
- Acknowledgement deadline: 60 seconds
- Max retry duration: 600 seconds
- Dead Letter Topic: Auto-enabled

**Service Accounts**:
- Pub/Sub SA: Publisher/Subscriber roles

**Time**: 1 minute | **Critical**: Low (can be added later)

---

### Phase 7: Compute Module
**File**: `terraform/modules/compute/main.tf`

**Resources Created** (Cloud Run Services - Multi-region):

1. **Primary Service** (us-central1)
   ```
   Service: looply-api
   Region: us-central1
   Image: (from Artifact Registry)
   CPU: 2 cores
   Memory: 512MB
   Timeout: 3600 seconds
   Max Instances: 2
   ```

2. **Secondary Service** (europe-west1)
   ```
   Service: looply-api-eu
   Region: europe-west1
   Image: (from Artifact Registry)
   CPU: 2 cores
   Memory: 512MB
   Timeout: 3600 seconds
   Max Instances: 2
   ```

**Environment Variables**:
- `ENVIRONMENT=prod`
- `REGION=us-central1` (or europe-west1)
- Database connection strings
- API keys (from Secret Manager)

**Service Account**: Cloud Run SA (with all permissions)

**Health Check**: `/api/health` endpoint

⚠️ **IMPORTANT**: Services won't be Ready until Docker image is built and pushed to Artifact Registry

**Time**: 2 minutes setup, 10+ minutes for image deployment | **Critical**: YES

---

### Phase 8: Security Module
**File**: `terraform/modules/security/main.tf`

**Resources Created**:

1. **Cloud KMS (Key Management Service)**
   - 1 Keyring: `looply-keyring`
   - 3 Crypto Keys:
     - `looply-main-key` (databases)
     - `looply-secrets-key` (Secret Manager)
     - `looply-backup-key` (database backups)

2. **Cloud Armor Security Policy**
   - DDoS protection
   - Geo-blocking (if configured)
   - Rate limiting: 100 req/sec per IP
   - SQL injection filtering: Enabled

3. **Secret Manager**
   - Stores: DB password, API keys, OAuth secrets
   - Encryption: KMS-managed
   - Rotation: 90-day policy
   - Access: Limited to service accounts only

4. **IAM Encryption Bindings**
   - Grant service accounts access to KMS keys

**Time**: 2 minutes | **Critical**: YES (needed for data encryption)

---

### Phase 9: Monitoring Module
**File**: `terraform/modules/monitoring/main.tf`

**Resources Created**:

1. **Cloud Monitoring Dashboard**
   - Service metrics (request rate, latency, errors)
   - Database metrics (read/write operations)
   - Storage metrics (disk usage, growth)
   - Network metrics (bandwidth, errors)

2. **Alert Policies** (7 total):
   - High error rate (>5%)
   - High latency (>2 seconds)
   - Database throttling
   - Storage near capacity
   - Cloud Run out of instances
   - Failed authentication (IAP)
   - System health check failures

3. **Notification Channels**:
   - Email notifications to alert addresses
   - Slack integration (if configured)
   - SMS (optional)

4. **Uptime Checks**:
   - Health endpoint checks every 60 seconds
   - 3+ locations for geographic redundancy
   - Alert if service is down

**Time**: 1 minute | **Critical**: Medium (for ops)

---

### Phase 10: Load Balancer Module
**File**: `terraform/modules/load_balancer/main.tf`

**Resources Created**:

1. **Global Static IP Address**
   - Name: `looply-global-lb-ip`
   - Type: Premium (global)
   - IPv4 address (assigned by GCP)

2. **Serverless Network Endpoint Groups (NEG)** (4 total):
   - Primary backend NEG (us-central1)
   - Primary frontend NEG (us-central1)
   - Secondary backend NEG (europe-west1)
   - Secondary frontend NEG (europe-west1)

3. **Backend Services** (2 total):
   - Backend API service (for `/api/*` routes)
   - Frontend web service (for static content)
   - CDN enabled with 3600s TTL
   - Logging enabled (1% sample rate)

4. **URL Map** (Request routing):
   - Host-based routing: looply.co.in
   - Path-based routing:
     - `/api/*` → Backend service
     - `/*` → Frontend service

5. **SSL Certificate** (if configured):
   - Self-signed or valid certificate
   - HTTPS termination at load balancer

6. **HTTP Proxy** (for HTTP):
   - Listens on port 80
   - Redirects to HTTPS (port 443)

7. **Global Forwarding Rule**:
   - Maps global IP → HTTP proxy
   - Listens on ports 80 & 443

8. **Firewall Rules**:
   - Allow health checks from GCP
   - Allow HTTPS/HTTP from internet

9. **IAP Bindings** (if enabled):
   - Backend service IAP binding
   - Frontend service IAP binding
   - Requires OAuth client ID

**Time**: 3 minutes | **Critical**: YES (public access point)

---

### Phase 11: IAP Module
**File**: `terraform/modules/iap/main.tf`

**Resources Created**:

1. **IAP Web Backend Service IAM Bindings** (2):
   - Backend API service
   - Frontend service
   - Role: `roles/iap.httpsResourceAccessor`
   - Members: Authorized users/groups

2. **IAP Admin Role**:
   - Service account: `roles/iap.admin`
   - Permissions to manage IAP

3. **Cloud Logging for IAP**:
   - Log sink to Cloud Storage
   - Captures all IAP access logs
   - Retention: 90 days

4. **Cloud Monitoring Alerts** (if enabled):
   - Failed authentication alerts
   - Threshold: 50 failures in 5 minutes

5. **KMS Encryption**:
   - IAP service account access to KMS keys
   - For OAuth secret encryption

⚠️ **IMPORTANT**: Requires `google_oauth_client_id` in terraform.tfvars to be active

**Time**: 1 minute | **Critical**: Low (optional security feature)

---

## Troubleshooting

### Common Issues & Solutions

#### 1. **"Error: google_compute_network.vpc: googleapi: Error 403: Insufficient Permission"**
```
CAUSE: Missing IAM permissions
SOLUTION:
  1. Verify your user has Editor or Compute Admin role
  2. Ask project owner to grant: roles/editor or roles/compute.admin
  3. Ensure you're authenticated: gcloud auth login
```

#### 2. **"Error: error creating resource: ... operation failed. Try setting enable_iap to false"**
```
CAUSE: IAP module failing due to missing OAuth config
SOLUTION: In terraform.tfvars, set google_oauth_client_id = ""
```

#### 3. **"Error 409: Conflict. Bucket exists: looply-videos-*"**
```
CAUSE: Bucket already exists from previous run
SOLUTION:
  1. Check if bucket is needed: gcloud storage buckets list
  2. Either delete the old bucket or use a different project_prefix
  3. Or apply with target: terraform apply -target='module.storage'
```

#### 4. **"Timeout waiting for service to become Ready"**
```
CAUSE: Docker image not built/pushed
SOLUTION:
  1. Build and push Docker image: ./build-and-push.bat
  2. Cloud Run will automatically detect new image
  3. Service will become Ready within 5-10 minutes
```

#### 5. **"Error: Error reading Firestore Database: googleapi: Error 404"**
```
CAUSE: Firestore database not enabled
SOLUTION:
  1. Enable Firestore API: gcloud services enable firestore.googleapis.com
  2. Create database in GCP Console (if necessary)
  3. Run terraform apply again
```

#### 6. **"terraform plan shows 300+ resources (too many)"**
```
CAUSE: Previous state exists, deleting everything
SOLUTION:
  1. Verify terraform.tfvars matches your project
  2. Back up state: cp terraform.tfstate terraform.tfstate.backup
  3. Run: terraform plan -out=tfplan (review carefully)
  4. Check if state is from different project
```

### Useful Debug Commands

```powershell
# See what Terraform thinks exists
terraform state list

# See detailed resource state
terraform state show 'module.compute.google_cloud_run_service.backend_primary'

# Refresh state from GCP
terraform refresh

# See resource details
terraform show

# Check for specific errors in a module
terraform plan -target='module.load_balancer'

# Apply only specific module
terraform apply -target='module.security'
```

### Getting Help

**Check logs for service**:
```powershell
# Cloud Run logs
gcloud run logs read looply-api --region=us-central1 --limit=50

# General project logs
gcloud logging read "resource.type=cloud_run_revision" --limit=20 --format=json
```

**Verify resource exists in GCP**:
```powershell
# Check if service account exists
gcloud iam service-accounts list --filter="looply"

# Check if Firestore database created
gcloud firestore databases list

# Check Cloud Run services
gcloud run services list --region=us-central1
```

---

## Next Steps After Deployment

### 1. **Build and Push Docker Image**
```powershell
cd d:\GCP-Project\Looply\Looply
.\build-and-push.bat
```

### 2. **Configure IAP (Optional)**
- Add Google OAuth 2.0 credentials to terraform.tfvars
- Update authorized users list
- Rerun: `terraform apply`

### 3. **Set Up Custom Domain**
- Update DNS to point to global load balancer IP
- Update SSL certificate if using custom domain

### 4. **Monitor Deployment**
- Visit Cloud Console > Monitoring > Dashboards
- Check alert policies are working
- Review logs in Cloud Logging

### 5. **Test API Endpoints**
```powershell
# Get load balancer IP
$LB_IP = gcloud compute addresses describe looply-global-lb-ip --global --format='value(address)'

# Test health endpoint
curl -k https://$LB_IP/api/health

# Test API
curl -k -X GET https://$LB_IP/api/users/list
```

---

## Summary

| Phase | Duration | Resources | Status |
|-------|----------|-----------|--------|
| 1️⃣ APIs | 2 min | 15 APIs | ✅ Foundation |
| 2️⃣ Service Accounts | 3 min | 8 SAs + 25 IAM | ✅ Identity |
| 3️⃣ Networking | 2 min | VPC + Subnets | ✅ Infrastructure |
| 4️⃣ Storage | 1 min | 4 Buckets | ✅ Data |
| 5️⃣ Databases | 2 min | Firestore + BQ | ✅ Persistence |
| 6️⃣ Pub/Sub | 1 min | 4 Topics + Subs | ✅ Messaging |
| 7️⃣ Compute | 2 min | 2 Cloud Run | ⏳ Pending image |
| 8️⃣ Security | 2 min | KMS + Armor | ✅ Protection |
| 9️⃣ Monitoring | 1 min | Dashboards + Alerts | ✅ Observability |
| 🔟 Load Balancer | 3 min | Global LB + CDN | ✅ Public access |
| 1️⃣1️⃣ IAP | 1 min | OAuth bindings | ✅ Access control |
| **TOTAL** | **20 min** | **180+ resources** | **Ready** |

🎉 Your Looply infrastructure will be production-ready!
