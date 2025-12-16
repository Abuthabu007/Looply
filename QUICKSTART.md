# Looply Infrastructure - Quick Start Guide

## Current Status: ✅ 90% Deployed

Your infrastructure is **live** on GCP! Most services are deployed. Just need Docker images and a few final configs.

---

## 🔴 URGENT: Push Docker Images

**Status:** Cloud Run services are waiting for Docker images

### Step 1: Authenticate with Artifact Registry

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### Step 2: Build & Push Images

For each of your microservices (Stream Processor, Video Analytics, User Management):

```bash
# Example for Stream Processor
docker build -t us-central1-docker.pkg.dev/looply-480312/looply-docker-repo/stream-processor:latest ./stream-processor
docker push us-central1-docker.pkg.dev/looply-480312/looply-docker-repo/stream-processor:latest
```

Repeat for:
- `video-analytics`
- `user-management`

Once pushed, Cloud Run will automatically detect and deploy the images!

---

## ⚙️ Configuration Checklist

- [ ] **Push Docker images** (see above)
- [ ] **Update SSL Certificate** - Edit `terraform/main.tf` line ~220
- [ ] **Set Secret Values** in Secret Manager:
  - `looply-db-password`
  - `looply-api-key`
  - `looply-oauth-secret`
- [ ] **Wait 10 minutes** for monitoring metrics
- [ ] **Enable alert policies** in GCP Console (if metrics exist)
- [ ] **Configure IAP** (if using OAuth authentication)
- [ ] **Test load balancer** URL

---

## 📍 Find Your Endpoints

```bash
cd terraform

# Get all important outputs
tofu output

# Or specific outputs:
tofu output load_balancer.load_balancer_url
tofu output load_balancer.global_ip_address
tofu output compute.cloud_run_primary_url
```

---

## 🔧 Update Secrets

Use GCP Console or gcloud:

```bash
# Update database password
echo -n "your-new-password" | gcloud secrets versions add looply-db-password --data-file=-

# Update API key
echo -n "your-api-key" | gcloud secrets versions add looply-api-key --data-file=-

# Update OAuth secret
echo -n "your-oauth-secret" | gcloud secrets versions add looply-oauth-secret --data-file=-
```

---

## 🧪 Test Your Deployment

```bash
# Get load balancer URL
LB_URL=$(tofu output -json load_balancer.load_balancer_url | tr -d '"')

# Test health check
curl https://$LB_URL/health

# Test Cloud Run services
curl https://$LB_URL/stream-processor
curl https://$LB_URL/video-analytics
curl https://$LB_URL/user-management
```

---

## 📊 Monitor Your Services

```bash
# View Cloud Run service status
gcloud run services list

# View recent logs
gcloud logging read "resource.type=cloud_run_revision" --limit 50

# View resource usage
gcloud monitoring time-series list --filter="resource.type = 'cloud_run_revision'"
```

---

## 🚨 Common Issues

| Issue | Solution |
|-------|----------|
| Cloud Run service not deploying | Push Docker image to Artifact Registry |
| Load balancer returns 503 | Check Cloud Run services are healthy |
| Can't access services | Check firewall rules and Cloud Armor settings |
| Metrics not showing | Wait 10 minutes after service starts, then refresh |
| Secrets not loading | Verify secret values exist in Secret Manager |

---

## 💾 Backup & Disaster Recovery

```bash
# Backup Terraform state
cp terraform/terraform.tfstate terraform/terraform.tfstate.backup

# Export infrastructure config
gcloud compute instances list > instances-backup.txt
gcloud storage buckets list > buckets-backup.txt
```

---

## 🔐 Security Setup (Optional but Recommended)

```bash
# Enable Compute Engine security scanning
gcloud container analyze images

# Review IAM bindings
gcloud projects get-iam-policy looply-480312

# Check firewall rules
gcloud compute firewall-rules list
```

---

## 📈 Scale Your Services

When ready to handle more traffic:

```bash
# Increase Cloud Run max instances
terraform apply -var="cloud_run_max_instances=500"

# Increase Cloud Scheduler frequency
# Edit terraform/main.tf line ~250 (analytics_aggregation job)
```

---

## 🧹 Cleanup (When No Longer Needed)

```bash
cd terraform

# Destroy all resources (WARNING: irreversible)
tofu destroy -auto-approve

# This will:
# - Delete all Cloud Run services
# - Delete databases and storage
# - Remove all VPC resources
# - Disable APIs
# - Keep encrypted secrets (safety feature)
```

---

## 📞 Support Resources

- [Looply Documentation](./README.md)
- [Deployment Status](./DEPLOYMENT_STATUS.md)
- [GCP Cloud Run Docs](https://cloud.google.com/run/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

---

**Your infrastructure is ready!** 🎉
Next: Push those Docker images and start deploying!
