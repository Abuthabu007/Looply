# Infrastructure Redesign - Progress Summary

## Completed ✅

### Module Updates
1. **Load Balancer Module** - Updated to support multi-region
   - Added secondary region NEG (europe-west1)
   - Updated backend service to include both regions with balancing_mode = UTILIZATION
   - Added IAP configuration with OAuth client secret support
   - File: `terraform/modules/load_balancer/main.tf`, `terraform/modules/load_balancer/variables.tf`

2. **Service Accounts Module** - Added Eventarc and Transcoder service accounts
   - Created `looply-eventarc-sa` with `roles/run.invoker` and `roles/pubsub.publisher`
   - Created `looply-transcoder-sa` with `roles/transcoder.admin` and `roles/storage.admin`
   - Added Transcoder permissions to Cloud Run SA
   - File: `terraform/modules/service_accounts/main.tf`, `terraform/modules/service_accounts/outputs.tf`

3. **Storage Module** - Added Transcoded Videos Bucket
   - Created `looply-transcoded-looply-482917` bucket with lifecycle policies
   - Auto-transitions: 30d → STANDARD, 90d → NEARLINE, 180d → COLDLINE, 365d → DELETE
   - Added IAM bindings for Cloud Run service account
   - File: `terraform/modules/storage/main.tf`, `terraform/modules/storage/outputs.tf`

4. **Compute Module** - Enhanced for multi-region with environment variables
   - Refactored Cloud Run to support primary and secondary regions (count-based)
   - Added 10 new environment variables for:
     - Firestore access (`FIRESTORE_PROJECT`, `FIRESTORE_DB`)
     - Storage buckets (`VIDEOS_BUCKET`, `TRANSCODED_BUCKET`)
     - Transcoder integration (`TRANSCODER_TEMPLATE_HLS`)
     - Pub/Sub topics (`VIDEO_UPLOAD_TOPIC`, `TRANSCODING_COMPLETE_TOPIC`)
   - File: `terraform/modules/compute/main.tf`, `terraform/modules/compute/variables.tf`

5. **Transcoder Module** - Created video transcoding templates
   - HLS adaptive bitrate template: 1080p (5Mbps), 720p (2.5Mbps), 480p (1Mbps)
   - MP4 single-quality template: 720p (2.5Mbps)
   - API service enablement
   - File: `terraform/modules/transcoder/main.tf`, `terraform/modules/transcoder/variables.tf`, `terraform/modules/transcoder/outputs.tf`

6. **Eventarc Module** - Created video upload triggers
   - Primary and secondary region triggers for Cloud Storage uploads
   - Filters: bucket name + file pattern (*.{mp4,avi,mov,mkv,webm})
   - Routes to Cloud Run with 5-retry policy
   - File: `terraform/modules/eventarc/main.tf`, `terraform/modules/eventarc/variables.tf`, `terraform/modules/eventarc/outputs.tf`

7. **Root main.tf** - Module instantiation with dependencies
   - Instantiated 13 modules with proper variable passing
   - Configured module dependencies to avoid circular references
   - File: `terraform/main.tf`

8. **Root variables.tf** - Added new variables
   - `enable_secondary_region` (bool, default: true)
   - `firestore_database_id` (string, default: "(default)")
   - File: `terraform/variables.tf`

9. **Architecture Documentation** - Created comprehensive guide
   - System overview with component diagrams
   - Video processing workflow documentation
   - Firestore collection schemas
   - Service account & IAM configuration
   - Environment setup and deployment instructions
   - File: `terraform/ARCHITECTURE_V2.md`

## In Progress 🟡

### Pub/Sub Module Refactoring
- **Issue**: pubsub/main.tf has syntax errors preventing `tofu init`
- **Status**: Need to clean up file with incomplete resource definitions
- **Solution**: Simplify to just video_upload_events and transcoding_complete_events topics
- **File**: `terraform/modules/pubsub/main.tf`, `terraform/modules/pubsub/variables.tf`, `terraform/modules/pubsub/outputs.tf`

### Cloud Run Handler Documentation
- Need to create guide for handling Eventarc events
- Include code examples for:
  1. Receiving Eventarc Cloud Storage event
  2. Extracting video metadata
  3. Submitting Transcoder job
  4. Publishing to Pub/Sub
  5. Storing metadata in Firestore
  6. Error handling and retry logic

## Next Steps (Pending)

### 1. Fix Pub/Sub Module Syntax
The pubsub/main.tf file has incomplete resource blocks. Need to:
- Remove broken video_processing, user_events, stream_quality topics
- Keep only: events, video_upload_events, transcoding_complete_events topics
- Add proper subscriptions with push configs
- Add IAM bindings for service accounts

### 2. Verify API Enablement
Check and update `terraform/modules/apis/main.tf` to ensure all required APIs are enabled:
- ✅ compute.googleapis.com (likely enabled)
- ✅ run.googleapis.com (likely enabled)
- ❓ eventarc.googleapis.com (need to verify)
- ❓ transcoder.googleapis.com (added in transcoder module)
- ✅ pubsub.googleapis.com (likely enabled)
- ✅ firestore.googleapis.com (likely enabled)
- ✅ storage-api.googleapis.com (likely enabled)
- ✅ cloudkms.googleapis.com (likely enabled)
- ✅ secretmanager.googleapis.com (likely enabled)

### 3. Run Terraform Validation
```bash
cd terraform
tofu init -upgrade
tofu plan
```

### 4. Review Variables Configuration
Ensure all variables are properly configured in `terraform.tfvars`:
- gcp_project_id = "looply-482917"
- project_prefix = "looply"
- primary_region = "us-central1"
- secondary_region = "europe-west1"
- firestore_database_id = "(default)"
- enable_secondary_region = true
- google_oauth_client_id = "983194304282-qqci8hl50b7uegtmmpvhctevang2gn6j.apps.googleusercontent.com"
- google_oauth_client_secret = (from GCP Console or Secret Manager)
- ssl_certificate = (from GCP Console or Secret Manager)
- ssl_private_key = (from GCP Console or Secret Manager)

### 5. Deploy Infrastructure
```bash
cd terraform
tofu apply
```

### 6. Test Event Workflow
1. Upload test video to looply-videos-looply-482917/uploads/
2. Verify Eventarc trigger fires (check Cloud Logging)
3. Verify Cloud Run service is invoked
4. Verify Transcoder job is submitted
5. Verify Pub/Sub messages are published
6. Verify Firestore documents are created

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer (Global)                   │
│            IAP ← OAuth 2.0 Client + User Auth               │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
┌───────▼─────────┐           ┌──────────▼──────────┐
│   Cloud Run     │           │   Cloud Run         │
│  Primary Region │           │  Secondary Region   │
│  (us-central1)  │           │  (europe-west1)     │
└───────┬─────────┘           └──────────┬──────────┘
        │                                 │
        ├─Firestore ─────────────────────┤
        │ (Multi-region, Default)         │
        │                                 │
        │ • Read/write video metadata     │
        │ • Store transcoding job status  │
        │                                 │
        └─────────────────┬───────────────┘
                          │
        ┌─────────────────┴──────────────┐
        │                                │
┌───────▼────────────┐      ┌───────────▼──────┐
│ Cloud Storage      │      │  Cloud Pub/Sub   │
│ (Videos & Trans.)  │      │                  │
│                    │      │  • video-upload  │
│ • videos/uploads/  │      │  • transcoding-  │
│ • transcoded/      │      │    complete      │
│ • temp/            │      │  • subscriptions │
└───────┬────────────┘      └──────────────────┘
        │
        └──Event: object.finalized ─→ Eventarc Trigger
                                            │
                                    Invoke Cloud Run
                                            │
                                    ┌───────▼────────────┐
                                    │ Cloud Transcoder   │
                                    │                    │
                                    │ • HLS Adaptive     │
                                    │ • MP4 Single       │
                                    │                    │
                                    └────────────────────┘
```

## Files Modified

1. `terraform/modules/load_balancer/main.tf` - Added secondary region NEG and IAP config
2. `terraform/modules/load_balancer/variables.tf` - Added multi-region variables
3. `terraform/modules/service_accounts/main.tf` - Added Eventarc and Transcoder SAs
4. `terraform/modules/service_accounts/outputs.tf` - Exported new SA emails
5. `terraform/modules/storage/main.tf` - Added transcoded-videos bucket
6. `terraform/modules/storage/outputs.tf` - Exported bucket names
7. `terraform/modules/compute/main.tf` - Multi-region Cloud Run with env vars
8. `terraform/modules/compute/variables.tf` - Added new variables
9. `terraform/modules/transcoder/main.tf` - NEW: Transcoder templates
10. `terraform/modules/transcoder/variables.tf` - NEW: Transcoder variables
11. `terraform/modules/transcoder/outputs.tf` - NEW: Template outputs
12. `terraform/modules/eventarc/main.tf` - Removed Pub/Sub topics
13. `terraform/modules/eventarc/outputs.tf` - Removed topic outputs
14. `terraform/modules/pubsub/main.tf` - NEEDS FIX: Clean up syntax errors
15. `terraform/modules/pubsub/variables.tf` - Added new variables
16. `terraform/modules/pubsub/outputs.tf` - Updated outputs
17. `terraform/main.tf` - Module instantiation and dependencies
18. `terraform/variables.tf` - Added enable_secondary_region, firestore_database_id
19. `terraform/ARCHITECTURE_V2.md` - NEW: Comprehensive architecture documentation

---

**Current Blockers:**
- Pub/Sub module main.tf has syntax errors that prevent `tofu init` from completing
- Need to fix broken resource definitions before proceeding to plan/apply

**Recommended Next Action:**
Fix the pubsub/main.tf file syntax and run `tofu plan` for full validation.
