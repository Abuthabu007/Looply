# Terraform Modules Migration Guide - Google Standards Compliance

This guide documents the conversion of Looply's Terraform modules to use official Google Terraform modules and follow Google Cloud best practices.

## Summary of Changes

### ✅ Completed Module Conversions

#### 1. **Networking Module** (CONVERTED)
- **Status**: ✅ Converted to use `terraform-google-modules/network/google`
- **Changes**:
  - Uses official Google network module v7.0+
  - Simplified subnet management with module abstraction
  - Centralized firewall rule definition
  - Added VPC Flow Logs support
  - Updated outputs to reference module outputs
  
**Key Benefits**:
- Follows Google Cloud best practices for VPC design
- Automatic security group and firewall management
- Better separation of concerns
- Easier to maintain and update

**Module Source**: `terraform-google-modules/network/google`

---

#### 2. **Compute Module** (REFACTORED)
- **Status**: ✅ Refactored for Google standards
- **Changes**:
  - Migrated from legacy `google_cloud_run_service` to `google_cloud_run_v2_service`
  - Environment variables centralized in local variables
  - Added health probes (startup and liveness)
  - Improved resource scaling configuration
  - Better label and tag management
  
**Key Improvements**:
- Uses Cloud Run v2 API (current generation)
- Cleaner environment variable management
- Native health check support
- Better auto-scaling configuration (min/max instances)
- added max concurrency settings

**Note**: Make sure your `artifact_registry_repo` and `gcp_project_id` are correctly configured.

---

#### 3. **Storage Module** (REFACTORED)
- **Status**: ✅ Refactored with improved organization
- **Changes**:
  - Consolidated bucket naming with `local.bucket_base_name`
  - Centralized lifecycle rules via local variables
  - Added consistent labeling with `local.standard_labels`
  - Improved IAM role assignments (using `objectAdmin` instead of generic `admin`)
  - Removed unnecessary IAM resource duplication
  - Set `force_destroy = false` for production safety
  
**Bucket Structure**:
```
- videos: Raw video uploads (STANDARD, versioned)
- transcoded: Transcoded videos (STANDARD → NEARLINE → COLDLINE → DELETE)
- analytics: Analytics data (STANDARD, 90-day retention)
- logs: Access logs (STANDARD, configurable retention)
- backup: DR backups (US multi-region, versioned)
```

**Improved Lifecycle Management**:
- Cost optimization through class transitions
- Automatic deletion after retention periods
- Version management for important data

---

#### 4. **Load Balancer Module** (REFACTORED)
- **Status**: ✅ Refactored with Google-managed SSL
- **Changes**:
  - Replaced self-signed cert with `google_compute_managed_ssl_certificate`
  - Automatic certificate provisioning and renewal
  - Added custom request headers support
  - Improved backend utilization settings
  - Better frontend/backend separation
  - HTTP → HTTPS redirect built-in
  
**Benefits**:
- Google manages SSL certificate renewal automatically
- Supports multiple domains
- Production-ready HTTPS configuration
- Better observability with logging enabled
- Proper health check implementation

**SSL Certificate Management**:
- Uses Google-managed SSL certificates (automatic renewal)
- Supports multiple domains via `certificate_domains` variable
- Built-in HTTP to HTTPS redirect

---

## Remaining Modules - Implementation Guide

### 5. **Service Accounts Module** (RECOMMENDED REFACTORING)

**Recommended Changes**:
```hcl
# Instead of individual role assignments,
# consider using google_project_iam_member with dynamic for_each

module "service_accounts" {
  source = "./modules/service_accounts"
  
  service_accounts = {
    cloud_run = {
      display_name   = "Cloud Run Service Account"
      description    = "Service account for Cloud Run services"
      roles          = ["roles/logging.logWriter", "roles/datastore.user", ...]
    }
    pubsub = {
      display_name   = "Pub/Sub Service Account"
      roles          = ["roles/pubsub.editor", ...]
    }
    bigquery = {
      display_name   = "BigQuery Service Account"
      roles          = ["roles/bigquery.admin", ...]
    }
  }
}
```

**Key Improvements**:
- Use dynamic resources to reduce boilerplate
- Clearer role definitions per service account
- Easier to audit and manage permissions
- Support for custom roles

---

### 6. **Databases Module** (NO OFFICIAL MODULE AVAILABLE)

**Status**: ✅ Can remain as-is (follows Google patterns)
- Firestore: No official module, raw resources are fine
- BigQuery: No official module, consider moving to SQL managed via terraform-google-modules/sql-db
- Tables: Keep as raw resources with proper schema definitions

**Recommended Enhancement**:
```hcl
# Add more structured table definitions
# Use jsonencode for schema (already doing this - good!)
# Consider BigQuery dataset permissions with IAM
```

---

### 7. **Pub/Sub Module** (RECOMMENDED REFACTORING)

**Recommended Structure**:
```hcl
# Use maps for topic definitions
topics = {
  video_upload = {
    name       = "video-upload-events"
    retention  = "604800s"  # 7 days
  }
  transcoding_complete = {
    name       = "transcoding-complete"
    retention  = "604800s"
  }
}

# Dynamic topic creation
resource "google_pubsub_topic" "topics" {
  for_each = local.topics
  
  name                       = "${var.project_prefix}-${each.value.name}"
  message_retention_duration = each.value.retention
  project                    = var.gcp_project_id
  labels                     = var.tags
}
```

---

### 8. **IAP Module** (REFACTORING RECOMMENDED)

**Current Implementation**:
- Secret Manager integration ✅
- IAM bindings management ✅
- Log sink configuration ✅

**Improvements Needed**:
- Better separation of OAuth config from IAP bindings
- Support for multiple service accounts
- Clearer documentation of OAuth setup flow

---

### 9. **Monitoring Module** (REFACTORING RECOMMENDED)

**Suggested Improvements**:
- Use `terraform-google-modules/monitoring/google` if available
- Consolidate alert policies into a data structure
- Dynamic notification channel creation
- Better alert threshold management

---

### 10. **Other Modules** (Status Check)

**Identity Platform**: ✅ Keep as custom (small module)
**Eventarc**: ✅ Keep as custom (no official module)
**Transcoder**: ✅ Keep as custom (specialized)
**APIs**: ✅ Keep as custom (simple enablement module)
**Security**: ✅ Keep as custom (organization-specific)

---

## Migration Checklist

### Phase 1: Completed ✅
- [x] Convert Networking to terraform-google-modules/network
- [x] Refactor Compute to Cloud Run v2
- [x] Refactor Storage with improved lifecycle management
- [x] Refactor Load Balancer with managed SSL certificates

### Phase 2: Testing Required
- [ ] Run `terraform plan` to validate all changes
- [ ] Test multi-region failover scenarios
- [ ] Verify SSL certificate provisioning
- [ ] Test IAP authentication flows

### Phase 3: Deployment
- [ ] Create feature branch with changes
- [ ] Review module output compatibility
- [ ] Update root main.tf if needed
- [ ] Plan and apply terraform changes

---

## Best Practices Applied

### Naming Conventions
✅ Consistent naming with `project_prefix` variable
✅ Regional naming for multi-region resources
✅ Descriptive labels for resource identification

### Security
✅ IAM principle of least privilege
✅ Service account segmentation
✅ Encrypted secrets in Secret Manager
✅ HTTPS-only load balancer

### Resilience
✅ Multi-region deployment support
✅ Automated backup (Cloud Storage)
✅ Health checks on all services
✅ Auto-scaling configuration

### Maintainability
✅ Modular terraform modules
✅ Centralized variable definitions
✅ Clear output documentation
✅ Consistent code formatting

---

## Next Steps

1. **Validate Configuration**:
   ```bash
   cd terraform
   terraform init
   terraform plan
   ```

2. **Test Deployment**:
   ```bash
   terraform apply -auto-approve -var-file=terraform.tfvars
   ```

3. **Verify Services**:
   - Check Cloud Run deployments
   - Verify Load Balancer health
   - Test IAP authentication
   - Monitor SSL certificate status

4. **Update Documentation**:
   - Document any custom variables
   - Update deployment runbooks
   - Record lesson learned

---

## References

- [terraform-google-modules/network](https://github.com/terraform-google-modules/terraform-google-network)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google)
- [Google Cloud Best Practices](https://cloud.google.com/docs/terraform/best-practices)

---

## Support & Troubleshooting

### Common Issues

**1. Certificate Chain Validation**:
- Google-managed certificates require proper DNS setup
- Verify domain DNS points to load balancer IP
- Allow 15-20 minutes for certificate provisioning

**2. Service Account Permissions**:
- Run `gcloud projects get-iam-policy <PROJECT_ID>` to verify
- Use service account UI in Google Cloud Console

**3. Cloud Run Health Checks**:
- Ensure `/api/health` endpoint returns 200 status
- Check Cloud Run logs for startup/liveness probe failures

---

**Document Version**: 1.0  
**Last Updated**: 2026-04-18  
**Migration Status**: In Progress
