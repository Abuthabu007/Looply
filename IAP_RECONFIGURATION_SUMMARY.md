# IAP and Load Balancer Reconfiguration Summary

## Overview
The Looply infrastructure has been reconfigured to use:
- **Single Cloud Run Instance** with bundled frontend and backend Docker image
- **Enhanced Load Balancer** with proper HTTPS/HTTP routing and IAP integration
- **Identity-Aware Proxy (IAP)** for authentication and authorization at the load balancer level

---

## Key Changes

### 1. Compute Module Updates (`terraform/modules/compute/`)

#### Changes Made:
- **Removed** separate `backend_primary`, `backend_secondary`, `frontend_primary`, and `frontend_secondary` Cloud Run services
- **Created** single `google_cloud_run_service` named `app` that serves both frontend and backend
  - Uses unified Docker image: `looply-bundled:latest`
  - Runs on primary region (us-central1)
  - Single scaling policy applied

#### New Cloud Run Configuration:
```hcl
resource "google_cloud_run_service" "app" {
  name     = "${var.project_prefix}-app"
  location = var.primary_region
  
  # Bundled container with both frontend and backend
  containers {
    image = "us-central1-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repo}/looply-bundled:latest"
    
    # Environment variables for both frontend and backend
    env {
      name  = "REACT_APP_ENVIRONMENT"
      value = "production"
    }
    # ... additional environment variables
  }
}
```

#### Outputs Updated:
- **Old**: `backend_primary_url`, `backend_secondary_url`, `frontend_primary_url`, `frontend_secondary_url`
- **New**: 
  - `app_url` - Single bundled app URL
  - `app_endpoints` - Map of all available endpoints (health check, API routes, frontend UI)
  - `app_name` - Service name

---

### 2. Load Balancer Module Updates (`terraform/modules/load_balancer/`)

#### Changes Made:
- **Removed** separate NEGs for backend and frontend services (both primary and secondary regions)
- **Created** single serverless NEG for the bundled app service
- **Removed** separate backend services for API and frontend
- **Created** unified backend service with IAP enabled
- **Added** proper HTTPS/TLS configuration
- **Added** HTTP → HTTPS redirect

#### New Load Balancer Architecture:

```
┌─────────────────────────────────────────────────┐
│         Global Static IP (443 + 80)             │
├─────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐   │
│  │ HTTPS Forwarding Rule (Port 443)        │   │
│  │ → HTTPS Proxy → URL Map                 │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │ HTTP Forwarding Rule (Port 80)          │   │
│  │ → HTTP Redirect Proxy → HTTPS Redirect  │   │
│  └─────────────────────────────────────────┘   │
├─────────────────────────────────────────────────┤
│  ┌──────────────────────────────┐              │
│  │ URL Map (single route)       │              │
│  │ All paths → App Backend      │              │
│  └──────────────────────────────┘              │
├─────────────────────────────────────────────────┤
│  ┌──────────────────────────────┐              │
│  │ Backend Service (with IAP)   │              │
│  │ - CDN Policy enabled         │              │
│  │ - IAP enabled                │              │
│  │ - HTTPS protocol             │              │
│  └──────────────────────────────┘              │
├─────────────────────────────────────────────────┤
│  ┌──────────────────────────────┐              │
│  │ Serverless NEG (Cloud Run)   │              │
│  │ Service: ${prefix}-app       │              │
│  │ Region: us-central1          │              │
│  └──────────────────────────────┘              │
└─────────────────────────────────────────────────┘
```

#### Key Features:
- **Single Backend Service** (`app_service`) for all traffic
- **IAP Enabled** at backend service level with OAuth 2.0
- **CDN Policy** for static content caching
- **SSL/TLS Certificate** for HTTPS
- **HTTP to HTTPS Redirect** for secure traffic enforcement
- **Health Check** configured for monitoring

#### Outputs Updated:
- **Removed**: `backend_api_service_name`, `frontend_web_service_name`, `backend/frontend_primary/secondary_neg_id`
- **New**:
  - `app_service_name` - Single app backend service name
  - `app_service_id` - Backend service ID
  - `app_neg_id` - Network endpoint group ID
  - `https_proxy_id` - HTTPS proxy ID
  - `ssl_certificate_id` - SSL certificate ID

---

### 3. IAP Module Updates (`terraform/modules/iap/`)

#### Changes Made:
- **Simplified** to single backend service binding instead of multiple service bindings
- **Added** OAuth 2.0 Client Secret storage in Secret Manager
- **Updated** IAM bindings to work with unified service
- **Added** secret accessor role to load balancer service account

#### New IAP Configuration:

```hcl
# OAuth Secret in Secret Manager
resource "google_secret_manager_secret" "oauth_client_secret" {
  secret_id = "${var.project_prefix}-iap-oauth-secret"
  # Auto-replicated across regions
  replication { auto {} }
}

# Single IAP binding for bundled app
resource "google_iap_web_backend_service_iam_binding" "app_iap_binding" {
  web_backend_service = var.app_backend_service_name
  role                = "roles/iap.httpsResourceAccessor"
  members             = concat(
    var.admin_authorized_users,
    var.api_authorized_users,
    var.public_authorized_users
  )
}
```

#### Configuration Points:
- **Single backend service binding** for unified app service
- **Combined authorization** - all user types (admin, API, public) in one binding
- **OAuth secret management** via Google Secret Manager
- **Audit logging** to Cloud Storage
- **KMS encryption** for sensitive data

#### Outputs Updated:
- **Removed**: `admin_iap_binding_role`, `user_mgmt_iap_binding_role`
- **New**: `oauth_secret_name` - Secret Manager secret reference

---

### 4. Service Accounts Module Updates (`terraform/modules/service_accounts/`)

#### Changes Made:
- **Added** new `load_balancer_sa` service account for load balancer operations
- **Granted** Secret Manager accessor role to load balancer service account
- **Added** logging and monitoring permissions

#### New Service Account:
```hcl
resource "google_service_account" "load_balancer_sa" {
  account_id   = "${var.project_prefix}-loadbalancer-sa"
  display_name = "Load Balancer Service Account"
}

# IAM Roles:
# - logging.logWriter
# - monitoring.metricWriter
# - secretmanager.secretAccessor (for OAuth secret)
```

---

### 5. Root Module Updates (`terraform/main.tf`)

#### Changes Made:
- **Updated** compute module call to reference single `app_url` output
- **Updated** load balancer module call to include OAuth secret reference
- **Updated** IAP module call to use `app_backend_service_name`
- **Updated** PubSub module to use single `app_url` for both primary and secondary
- **Updated** Cloud Scheduler to call unified `app_url`

#### Module Dependencies:
```
  Load Balancer → must wait for IAP module initialization
  IAP → must wait for Load Balancer (backend service creation)
```

---

## Docker Image Requirements

Your Docker image must be built to serve:

### Frontend Routes:
- `/` - Serves the React/frontend UI (all routes)
- `/static/*` - Static assets

### Backend Routes:
- `/api/health` - Health check endpoint
- `/api/stream/process` - Stream processing endpoint
- `/api/video/analyze` - Video analytics endpoint
- `/api/users/*` - User management endpoints

### Example Dockerfile Structure:
```dockerfile
FROM node:18 AS builder
# Build frontend
WORKDIR /app/frontend
COPY frontend/ .
RUN npm install && npm run build

FROM node:18
# Copy frontend build
COPY --from=builder /app/frontend/build /app/public

# Backend setup
WORKDIR /app
COPY backend/ .
RUN npm install

# Expose port 8080
EXPOSE 8080

# Start both services (frontend static + backend API)
CMD ["npm", "start"]
```

---

## IAP Setup Instructions

1. **Create OAuth 2.0 Consent Screen** (Organization-level):
   - Go to: GCP Console > APIs & Services > OAuth consent screen
   - Select "External" for User type
   - Fill in application details (Looply - Video Streaming Platform)

2. **Create OAuth 2.0 Client Credentials**:
   - Go to: GCP Console > APIs & Services > Credentials
   - Create OAuth 2.0 Client ID (type: Web application)
   - Authorized redirect URIs:
     - `https://iap.googleapis.com/google_cloud_iap/web/oauth2/callback`
   - Note the Client ID and Client Secret

3. **Store Client Secret in Secret Manager**:
   ```bash
   echo -n "YOUR_CLIENT_SECRET" | \
     gcloud secrets versions add "${PROJECT_PREFIX}-iap-oauth-secret" \
     --data-file=-
   ```

4. **Enable IAP**:
   - Go to: GCP Console > Security > Identity-Aware Proxy
   - Enable IAP for the load balancer backend service
   - Provide the OAuth Client ID

5. **Configure Access** (via Terraform):
   - Update `terraform.tfvars`:
     ```hcl
     iap_admin_authorized_users = ["user:admin@looply.co.in"]
     iap_user_mgmt_authorized_users = ["user:api@looply.co.in"]
     iap_public_authorized_users = ["group:users@looply.co.in"]
     ```

---

## Deployment Steps

### 1. Build Docker Image
```bash
# Build bundled image with frontend + backend
docker build -t us-central1-docker.pkg.dev/${PROJECT_ID}/looply-repo/looply-bundled:latest .
docker push us-central1-docker.pkg.dev/${PROJECT_ID}/looply-repo/looply-bundled:latest
```

### 2. Plan Terraform Changes
```bash
cd terraform/
terraform init
terraform plan -out=tfplan
```

### 3. Review Plan
- Verify that the old Cloud Run services will be destroyed
- Confirm single new Cloud Run service will be created
- Check load balancer changes

### 4. Apply Configuration
```bash
terraform apply tfplan
```

### 5. Verify Deployment
```bash
# Check Cloud Run service
gcloud run services list

# Check load balancer
gcloud compute backend-services list
gcloud compute forwarding-rules list

# Test endpoint (may require IAP authentication)
curl -I https://YOUR_LB_IP
```

---

## Important Notes

### Architecture Improvements:
✅ Single Cloud Run service reduces operational complexity
✅ Unified Docker build process - no separate frontend/backend builds
✅ IAP at load balancer level - transparent to application
✅ HTTP → HTTPS redirect for security
✅ CDN policy for static content optimization
✅ Simplified monitoring and debugging

### Breaking Changes:
⚠️ Old Cloud Run service URLs will no longer work
⚠️ Docker image must serve both frontend and backend
⚠️ All routes go through single Cloud Run instance
⚠️ Need to configure OAuth 2.0 credentials

### Migration Checklist:
- [ ] Build new bundled Docker image
- [ ] Create/configure OAuth 2.0 credentials
- [ ] Store client secret in Secret Manager
- [ ] Review and update `terraform.tfvars`
- [ ] Run `terraform plan` and review changes
- [ ] Apply Terraform configuration
- [ ] Verify IAP is protecting the application
- [ ] Test all API endpoints through load balancer
- [ ] Monitor Cloud Run metrics and logs

---

## Troubleshooting

### IAP Access Denied
- Verify user is in authorized users list
- Check Secret Manager secret has correct OAuth client secret
- Confirm OAuth consent screen is properly configured

### Load Balancer Health Check Fails
- Verify Cloud Run service responds to `/api/health`
- Check Cloud Run logs: `gcloud run logs list`
- Verify firewall allows internal health checks

### SSL Certificate Issues
- Ensure SSL certificate and private key are valid
- Certificate must match your domain
- Check certificate expiration

### Docker Image Issues
- Verify bundled image serves both frontend and backend
- Check port 8080 is correctly exposed
- Review container logs in Cloud Run console

---

## References
- [Identity-Aware Proxy Documentation](https://cloud.google.com/iap/docs)
- [Cloud Run Deployment Guide](https://cloud.google.com/run/docs/deploying)
- [Load Balancer Configuration](https://cloud.google.com/load-balancing/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
