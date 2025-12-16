# Looply Infrastructure as Code - OpenTofu/Terraform

Complete infrastructure setup for Looply video streaming platform using Google Cloud Platform (GCP), implemented with a modular Terraform/OpenTofu structure.

## Architecture Overview

The Looply infrastructure follows a **multi-region, serverless-first design** with:

- **Compute**: Cloud Run (auto-scaling, serverless containers)
- **Messaging**: Cloud Pub/Sub (event-driven architecture)
- **Databases**: Firestore (NoSQL) and BigQuery (Data Warehouse)
- **Storage**: Cloud Storage (videos, analytics, logs)
- **Networking**: VPC with multi-region setup
- **CDN & Load Balancing**: Global Load Balancer with Cloud CDN
- **Logging & Monitoring**: Cloud Logging and Cloud Monitoring

## Directory Structure

```
terraform/
├── main.tf                          # Root module main configuration
├── variables.tf                     # Root module variables
├── outputs.tf                       # Root module outputs
├── providers.tf                     # Provider configuration
├── terraform.tfvars                 # Variable values (UPDATE REQUIRED)
│
└── modules/
    ├── service_accounts/            # IAM service accounts and roles
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── networking/                  # VPC, subnets, routers, NAT, firewall
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── compute/                     # Cloud Run services (multi-region)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── pubsub/                      # Pub/Sub topics and subscriptions
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── storage/                     # Cloud Storage buckets
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── databases/                   # Firestore and BigQuery
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── load_balancer/               # Global LB, CDN, SSL/TLS
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Module Descriptions

### 1. Service Accounts Module
Creates and manages all service accounts required for the infrastructure:

- **Cloud Run SA**: Permissions for Pub/Sub, Firestore, Cloud Storage, Logging
- **Pub/Sub SA**: Publisher and subscriber roles
- **BigQuery SA**: Data analytics and table management
- **Firestore SA**: Database operations
- **Cloud Storage SA**: Bucket management
- **Cloud Scheduler SA**: Job invocation
- **Artifact Registry SA**: Container image management

**Resources Created**:
- 8 service accounts
- 25+ IAM role bindings

### 2. Networking Module
Establishes the network backbone with multi-region support:

**Features**:
- Single VPC with regional subnets (Primary: us-central1, Secondary: europe-west1)
- Private Google access enabled
- Cloud NAT for outbound traffic (both regions)
- Firewall rules:
  - Internal VPC communication
  - HTTPS/HTTP from internet
  - Health checks
- VPC Flow Logs enabled
- Private service connection for Cloud services

**Resources Created**:
- 1 VPC network
- 4 subnets (2 per region + proxy subnets)
- 2 Cloud NAT/Router pairs
- 4 firewall rules
- 1 private service connection

### 3. Compute Module
Multi-region Cloud Run services with auto-scaling:

**Services Deployed**:
1. **Stream Processor** (Primary + Secondary)
   - Processes video streams
   - Handles Pub/Sub events
   - Auto-scales from 0 to 100 instances

2. **Video Analytics** (Primary)
   - Analyzes stream quality metrics
   - Writes to BigQuery

3. **User Management** (Primary)
   - Manages user profiles and preferences
   - Firestore integration

**Configuration per Service**:
- CPU: 2 vCPU (configurable)
- Memory: 512 Mi (configurable)
- Timeout: 3600 seconds (1 hour)
- Max instances: 100
- Environment variables: PROJECT_ID, REGION

### 4. Pub/Sub Module
Event-driven messaging backbone with 4 topics:

**Topics & Subscriptions**:

1. **events** (Main topic)
   - Push subscriptions to Cloud Run (primary + secondary)
   - 7-day retention
   - For stream events and general platform events

2. **video_processing**
   - Dead-letter queue with 5 max delivery attempts
   - 300-second acknowledgement deadline
   - For video encoding and processing tasks

3. **user_events**
   - User activity events (logins, follows, etc.)
   - 7-day retention

4. **stream_quality**
   - Quality metrics and monitoring data
   - Analytics integration

**Features**:
- Message retention: 7 days (default)
- OIDC token authentication for push subscriptions
- Dead-letter queue for failed messages
- Service account-based permissions

### 5. Storage Module
Cloud Storage with optimized bucket configurations:

**Buckets**:

1. **Videos Bucket**
   - Multi-region storage for video content
   - Versioning enabled
   - Lifecycle: Delete older versions (keep 5 latest)
   - Auto-archive to Coldline after 1 year
   - CORS enabled for streaming

2. **Analytics Bucket**
   - Raw analytics data
   - 90-day retention
   - Used for BigQuery exports

3. **Logs Bucket**
   - Application and system logs
   - Configurable retention (default: 90 days)
   - Automatic deletion of old logs

4. **Backup Bucket**
   - US multi-region (cross-region redundancy)
   - Versioning enabled
   - Automatic tiering: Nearline after 30 days, Coldline after 90 days

**IAM Permissions**:
- Cloud Run: Admin access to videos and analytics
- Storage SA: Admin access to all buckets

### 6. Databases Module
Data persistence and analytics infrastructure:

**Firestore (NoSQL Database)**:
- Multi-region setup (configurable location)
- OPTIMISTIC concurrency mode
- Point-in-time recovery enabled
- Collections for:
  - User profiles
  - Stream metadata
  - Session data
  - Preferences

**BigQuery (Data Warehouse)**:
- Location: US (configurable)
- 3 main tables:
  1. **stream_events**: Event log with user, stream, quality data
  2. **user_analytics**: User metrics (watch time, streams, activity)
  3. **stream_quality**: Quality metrics (bitrate, latency, buffer, packet loss)

- Default table expiration: 90 days
- Cloud Run service can write/edit data
- BigQuery SA has full admin access

### 7. Load Balancer Module
Global load balancing and CDN:

**Components**:

1. **Global Static IP**
   - Single entry point for all traffic

2. **Backend Services**
   - Cloud Run services for API
   - Cloud Storage bucket for video CDN

3. **Cloud CDN**
   - Caches static video content
   - Client TTL: 1 hour
   - Default TTL: 1 hour
   - Max TTL: 24 hours
   - Negative caching for 404s

4. **URL Mapping**
   - Videos subdomain → CDN backend bucket
   - API paths → Cloud Run backend

5. **SSL/TLS**
   - HTTPS enforcement
   - Configurable certificate (self-signed in terraform.tfvars)

6. **HTTP Redirect**
   - Automatic HTTP to HTTPS redirect

## Prerequisites

1. **GCP Project**
   - Active GCP project with billing enabled
   - Required APIs enabled:
     - Compute Engine API
     - Cloud Run API
     - Pub/Sub API
     - Firestore API
     - BigQuery API
     - Cloud Storage API
     - Cloud Logging API
     - Artifact Registry API

2. **Terraform/OpenTofu**
   - Terraform >= 1.0 or OpenTofu >= 1.6
   - Google provider >= 5.0
   - Service account with appropriate permissions

3. **SSL Certificate**
   - Valid SSL certificate and private key (or generate self-signed for testing)

## Configuration

### 1. Update terraform.tfvars

```hcl
# terraform.tfvars
gcp_project_id = "your-gcp-project-id"
project_prefix = "looply"
environment    = "prod"

# Regions
primary_region   = "us-central1"
secondary_region = "europe-west1"

# SSL Certificate (replace with actual certificate)
ssl_certificate = "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
ssl_private_key = "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
```

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

### 3. Plan Infrastructure

```bash
terraform plan -out=tfplan
```

### 4. Apply Configuration

```bash
terraform apply tfplan
```

## Deployment Architecture Flow

```
Internet Traffic
    ↓
Global Load Balancer (IP: xxx.xxx.xxx.xxx)
    ├─ HTTPS (443) → Cloud Run Services (API)
    ├─ HTTP (80) → Redirect to HTTPS
    └─ Videos subdomain → Cloud Storage CDN
    ↓
Multi-Region Cloud Run
├─ Primary (us-central1)
│   ├─ Stream Processor
│   ├─ Video Analytics
│   └─ User Management
└─ Secondary (europe-west1)
    └─ Stream Processor
    ↓
Event-Driven via Pub/Sub
├─ events (main topic)
├─ video_processing (with DLQ)
├─ user_events
└─ stream_quality
    ↓
Data Layer
├─ Firestore (user data, sessions)
├─ BigQuery (analytics warehouse)
└─ Cloud Storage (video content, logs)
    ↓
Networking
├─ VPC (10.0.0.0/20, 10.1.0.0/20)
├─ Cloud NAT (outbound internet)
└─ Cloud Routers (traffic management)
```

## Multi-Region Setup

The infrastructure is designed for **multi-region high availability**:

### Primary Region: us-central1
- Main Cloud Run services
- Video Analytics
- User Management
- Primary database
- Load Balancer entry point

### Secondary Region: europe-west1
- Cloud Run stream processor (replication)
- Pub/Sub subscriptions
- Disaster recovery

**Key Multi-Region Resources**:
- Firestore: Multi-region configuration
- Pub/Sub: Global message distribution
- Cloud Storage: Versioning for backup
- Load Balancer: Routes to both regions

## Service Account Permissions Summary

| Service Account | Roles | Purpose |
|---|---|---|
| Cloud Run SA | logging.logWriter, monitoring.metricWriter, pubsub.{publisher,subscriber}, datastore.user, storage.admin | Container execution |
| Pub/Sub SA | pubsub.editor, logging.logWriter | Event publishing |
| BigQuery SA | bigquery.admin, logging.logWriter | Data warehouse |
| Firestore SA | datastore.user, logging.logWriter | NoSQL database |
| Storage SA | storage.admin, logging.logWriter | Bucket management |
| Cloud Scheduler SA | run.invoker | Job scheduling |
| Artifact Registry SA | artifactregistry.admin | Image management |

## Costs & Optimization

### Cost-Saving Features
- **Cloud Run**: Pay-per-use (invocations, vCPU-seconds, memory-GB-seconds)
- **Cloud NAT**: Only charges for processed data
- **BigQuery**: Flat-rate vs on-demand pricing options
- **Lifecycle policies**: Auto-archive to cheaper storage tiers
- **Cloud CDN**: Only ingress charges, egress to CDN is free

### High-Availability Features
- Multi-region deployment
- Auto-scaling Cloud Run
- Load balancing across regions
- Pub/Sub message queuing
- Firestore replication
- Backup buckets with versioning

## Monitoring & Logging

All services automatically ship logs to:
- **Cloud Logging**: Application and system logs
- **Cloud Monitoring**: Metrics and alerting
- **BigQuery**: Analytics queries
- **Cloud Storage**: Archived logs

Sink configuration in main.tf routes WARNING+ level logs to Cloud Storage.

## Troubleshooting

### Cloud Run services won't scale
- Check artifact registry image existence
- Verify service account permissions
- Check Pub/Sub subscription configuration

### Pub/Sub subscription issues
- Verify OIDC token service account
- Check Cloud Run IAM roles
- Review dead-letter queue for failures

### Database connection issues
- Ensure Firestore is initialized
- Check VPC private service connection
- Verify service account permissions

## Cleanup

To destroy the entire infrastructure:

```bash
terraform destroy
```

**Note**: This will delete:
- Cloud Run services
- All Cloud Storage buckets (if force_destroy = true)
- Firestore database
- BigQuery datasets
- All networking resources

## Support & Documentation

- [Google Cloud Terraform Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)
- [Firestore Documentation](https://cloud.google.com/firestore/docs)

## License

This infrastructure code is part of the Looply project.
