# Looply Infrastructure - Quick Start Guide

## What Has Been Created

A complete, **production-ready OpenTofu/Terraform infrastructure** for Looply video streaming platform with:

✅ **7 Modular Components**:
- Service Accounts (8 accounts with proper IAM roles)
- Networking (Multi-region VPC, NAT, firewalls)
- Compute (Cloud Run - 3 services, 2 regions)
- Pub/Sub (4 topics, 5 subscriptions, DLQ)
- Storage (4 buckets, CDN, versioning, lifecycle policies)
- Databases (Firestore NoSQL + BigQuery Analytics)
- Load Balancer (Global LB, Cloud CDN, SSL/TLS)

✅ **Multi-Region High Availability**:
- Primary: us-central1
- Secondary: europe-west1
- Auto-failover capabilities

✅ **Event-Driven Architecture**:
- Cloud Pub/Sub message queue
- Stream processing pipeline
- Analytics aggregation

## File Structure

```
terraform/
├── providers.tf                    # GCP provider config
├── variables.tf                    # All variables (50+)
├── main.tf                         # Root module orchestration
├── outputs.tf                      # Root outputs
├── terraform.tfvars               # ⚠️ UPDATE THIS FILE
├── .gitignore                     # Git ignore patterns
├── README.md                      # Comprehensive documentation
├── ARCHITECTURE.md                # Detailed architecture guide
│
└── modules/
    ├── service_accounts/          # 8 service accounts
    ├── networking/                # VPC + multi-region networking
    ├── compute/                   # Cloud Run (3 services)
    ├── pubsub/                    # Pub/Sub (4 topics)
    ├── storage/                   # Cloud Storage (4 buckets)
    ├── databases/                 # Firestore + BigQuery
    └── load_balancer/             # Global LB + CDN
```

## Setup Instructions

### Step 1: Update Configuration
Edit `terraform/terraform.tfvars`:

```hcl
gcp_project_id = "your-gcp-project-id"        # REQUIRED
environment    = "prod"

# SSL Certificate (generate or use existing)
ssl_certificate = "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
ssl_private_key = "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
```

### Step 2: Generate SSL Certificate (if needed)

**Self-signed certificate (testing only)**:
```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
cat cert.pem  # Copy to terraform.tfvars
cat key.pem   # Copy to terraform.tfvars
```

### Step 3: Initialize Terraform

```bash
cd terraform
terraform init
```

Expected output:
```
Initializing the backend...
Initializing modules...
Initializing provider plugins...
Terraform has been successfully configured!
```

### Step 4: Validate Configuration

```bash
terraform validate
terraform fmt -recursive
```

### Step 5: Plan Infrastructure

```bash
terraform plan -out=tfplan
```

Review the plan output showing all resources to be created.

### Step 6: Apply Infrastructure

```bash
terraform apply tfplan
```

**Time to deploy**: ~10-15 minutes

### Step 7: Verify Deployment

```bash
terraform output
```

View outputs including:
- Service account emails
- Cloud Run service URLs
- Load balancer IP address
- Pub/Sub topic names
- Database IDs

## Important Resources Created

### Service Accounts (8 total)
1. **cloud-run-sa** → Runs Cloud Run services
2. **pubsub-sa** → Pub/Sub operations
3. **bigquery-sa** → BigQuery analytics
4. **firestore-sa** → Firestore database
5. **storage-sa** → Cloud Storage management
6. **scheduler-sa** → Cloud Scheduler jobs
7. **artifact-registry-sa** → Container images
8. **Primary** → Multiple services

**IAM Bindings**: 25+ role assignments

### Cloud Run Services (3 services × 2 regions)
1. **stream-processor** (Primary + Secondary)
   - Processes video stream events
   - Consumes Pub/Sub messages
   - URL: `https://{service}.run.app`

2. **video-analytics** (Primary)
   - Analyzes quality metrics
   - Writes to BigQuery

3. **user-management** (Primary)
   - User CRUD operations
   - Firestore integration

### Pub/Sub (4 Topics)
1. **events** → Main event bus (7-day retention)
2. **video_processing** → Processing tasks (with DLQ)
3. **user_events** → User activities
4. **stream_quality** → Quality metrics

### Storage (4 Buckets)
1. **videos** → Video content (CDN-enabled)
2. **analytics** → Daily analytics data
3. **logs** → Application logs (90-day retention)
4. **backup** → Multi-region backup

### Networking
- **VPC**: `looply-vpc` (global routing)
- **Subnets**:
  - Primary: 10.0.0.0/20 (us-central1)
  - Secondary: 10.1.0.0/20 (europe-west1)
- **Cloud NAT**: Outbound internet access
- **Firewall Rules**: 4 rules for traffic control

### Load Balancer
- **Global IP**: Static IPv4 address
- **Backend**: Cloud Run + CDN
- **SSL/TLS**: HTTPS enforcement
- **CDN Policy**: 1-hour caching

### Databases
- **Firestore**: Multi-region NoSQL (with PITR)
- **BigQuery**: Analytics dataset with 3 tables
  - stream_events
  - user_analytics
  - stream_quality

## Next Steps

### 1. Deploy Docker Images
Build and push Cloud Run images to Artifact Registry:

```bash
# Enable Artifact Registry
gcloud services enable artifactregistry.googleapis.com

# Build and push
docker build -t stream-processor .
docker tag stream-processor us-central1-docker.pkg.dev/PROJECT/looply-docker-repo/stream-processor:latest
docker push us-central1-docker.pkg.dev/PROJECT/looply-docker-repo/stream-processor:latest
```

### 2. Deploy Cloud Run Service Code
Update image references in Cloud Run services:

```bash
gcloud run deploy stream-processor \
  --image us-central1-docker.pkg.dev/PROJECT/looply-docker-repo/stream-processor:latest \
  --region us-central1 \
  --service-account looply-cloudrun-sa@PROJECT.iam.gserviceaccount.com
```

### 3. Configure Firestore Security Rules
Set up Firestore security rules for authentication:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId=**} {
      allow read, write: if request.auth.uid == userId;
    }
    match /streams/{streamId=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == resource.data.creator_id;
    }
  }
}
```

### 4. Set Up Monitoring Alerts
Create alerts for critical metrics:
- Cloud Run error rate > 5%
- Pub/Sub subscription lag > 10 minutes
- Firestore latency p99 > 5 seconds

### 5. Configure Custom Domain
Point your domain to the load balancer IP:

```bash
# Get the IP
terraform output load_balancer.global_ip_address

# Add DNS A record
looply.com -> {IP_ADDRESS}
```

### 6. Set Up CI/CD Pipeline
Integrate with your CI/CD for automated deployments:

```yaml
# Deploy on push to main
- name: Deploy Cloud Run
  run: |
    gcloud run deploy stream-processor \
      --image $IMAGE_URL \
      --region us-central1 \
      --no-traffic  # Blue-green deployment
```

## Monitoring & Management

### View Logs
```bash
# Cloud Run logs
gcloud logging read "resource.type=cloud_run_revision" --limit 50

# Pub/Sub metrics
gcloud monitoring time-series list \
  --filter='metric.type="pubsub.googleapis.com/subscription/push_request_latencies"'
```

### Check Service Status
```bash
# List Cloud Run services
gcloud run services list --region us-central1

# View service details
gcloud run services describe stream-processor --region us-central1

# Check Pub/Sub subscriptions
gcloud pubsub subscriptions list
```

### Query Analytics
```bash
# BigQuery streaming inserts count
bq query --use_legacy_sql=false '
  SELECT COUNT(*) as event_count
  FROM `project.looply_analytics.stream_events`
  WHERE event_timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
'
```

## Common Commands

### Terraform Operations
```bash
# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Show state
terraform state list
terraform state show module.compute
```

### Update Specific Module
```bash
# Only update Cloud Run
terraform apply -target=module.compute

# Only update Pub/Sub
terraform apply -target=module.pubsub
```

### Import Existing Resources
```bash
# Import existing Firestore
terraform import module.databases.google_firestore_database.main my-project-id:(default)

# Import existing bucket
terraform import module.storage.google_storage_bucket.videos existing-bucket-name
```

## Troubleshooting

### Cloud Run service not starting
```bash
# Check service details
gcloud run services describe stream-processor --region us-central1

# View recent deployments
gcloud run releases list --service stream-processor --region us-central1

# Check logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=stream-processor" --limit 50
```

### Pub/Sub push delivery not working
```bash
# Check subscription
gcloud pubsub subscriptions describe looply-events-sub-primary

# Test push manually
curl -X POST https://stream-processor-HASH.run.app \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)"
```

### Firestore connection issues
```bash
# Verify database exists
gcloud firestore databases describe

# Check service account permissions
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:looply-firestore-sa*"
```

## Cost Estimation

| Component | Est. Monthly Cost | Notes |
|-----------|-------------------|-------|
| Cloud Run | $50-200 | Depends on request volume |
| Pub/Sub | $0-50 | First 100GB free |
| Firestore | $0-100 | Multi-region premium |
| BigQuery | $50-200 | On-demand pricing |
| Cloud Storage | $20-100 | Lifecycle policies help |
| Load Balancer | $18-40 | Forwarding rule + rules |
| **Total Estimate** | **$150-700** | Very cost-effective |

## Documentation

- **README.md**: Complete infrastructure documentation
- **ARCHITECTURE.md**: Detailed architecture guide with flows
- **Variables.tf**: All configuration options documented
- **Module outputs**: Available via `terraform output`

## Support

For issues:
1. Check logs: `gcloud logging read`
2. Review ARCHITECTURE.md for component interactions
3. Run `terraform plan` to spot configuration issues
4. Check GCP console for resource status

---

**Infrastructure Version**: 1.0  
**Created**: 2024-12-16  
**Status**: Ready for deployment  
**Maintenance**: Modular, easy to update individual components
