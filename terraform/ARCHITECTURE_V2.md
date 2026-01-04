# Looply Infrastructure Architecture - Updated

## Overview

This document outlines the updated Looply infrastructure with multi-region Cloud Run, IAP-protected load balancer, Eventarc-triggered video transcoding, and Pub/Sub notifications.

## Architecture Components

### 1. **Load Balancer with IAP**
- **Global Load Balancer**: Routes traffic globally with Cloud CDN
- **Identity-Aware Proxy (IAP)**: Authenticates users via OAuth 2.0 before reaching backend
- **SSL/TLS**: HTTPS encryption with custom certificate
- **Cloud CDN**: Caches static assets globally for better performance

```
Internet
  ↓
Global Load Balancer (Port 80/443)
  ↓
HTTP → HTTPS Redirect
  ↓
Identity-Aware Proxy (IAP)
  ↓
Backend Service with Multi-Region NEGs
```

### 2. **Multi-Region Cloud Run**
- **Primary Region**: us-central1
- **Secondary Region**: europe-west1
- **Auto-scaling**: 1-2 instances per region based on demand
- **Firestore Client-Side Access**: Cloud Run instances can directly query Firestore using the service account

#### Environment Variables
- `FIRESTORE_PROJECT`: Project ID for Firestore access
- `FIRESTORE_DB`: Firestore database ID
- `REGION`: Current region
- `VIDEOS_BUCKET`: Cloud Storage bucket for uploads
- `TRANSCODED_BUCKET`: Cloud Storage bucket for transcoded videos
- `VIDEO_UPLOAD_TOPIC`: Pub/Sub topic for upload notifications
- `TRANSCODING_COMPLETE_TOPIC`: Pub/Sub topic for transcoding completion

### 3. **Video Upload & Processing Workflow**

```
User uploads video to Cloud Storage
  ↓
Cloud Storage triggers Eventarc event
  ↓
Eventarc fires Cloud Run service (video processor)
  ↓
Cloud Run service:
  1. Publishes message to VIDEO_UPLOAD_TOPIC
  2. Extracts video metadata
  3. Submits transcoding job to Cloud Transcoder API
  4. Stores job reference in Firestore
  ↓
Cloud Transcoder processes video in parallel
  ↓
Transcoder completes and stores output in transcoded-videos bucket
  ↓
Cloud Run service (or separate job watcher) detects completion
  ↓
Publishes message to TRANSCODING_COMPLETE_TOPIC
  ↓
Frontend receives notification and updates UI
```

### 4. **Cloud Video Transcoder API**

Two presets configured:

#### HLS (Adaptive Bitrate Streaming)
- **Qualities**: 1080p (5 Mbps), 720p (2.5 Mbps), 480p (1 Mbps)
- **Container**: MPEG-TS segments with M3U8 master playlist
- **Use case**: Adaptive streaming for varying network conditions
- **Output**: `transcoded/{video_id}/master.m3u8`

#### MP4 (Single Quality)
- **Quality**: 720p (2.5 Mbps)
- **Container**: MP4
- **Use case**: Fallback or download option
- **Output**: `transcoded/{video_id}/output.mp4`

### 5. **Eventarc Triggers**
- **Trigger Source**: Cloud Storage (`gs://videos-bucket/uploads/`)
- **Trigger Event**: Object finalized (upload complete)
- **File Pattern**: `uploads/*.{mp4,avi,mov,mkv,webm}`
- **Destination**: Cloud Run service in same region
- **Retry Policy**: 5 retries with exponential backoff

### 6. **Pub/Sub Topics**

#### Video Upload Events (`looply-video-upload-events`)
- Published when video is uploaded and Eventarc is triggered
- **Message Schema**:
  ```json
  {
    "bucket": "videos-bucket",
    "name": "uploads/video_id.mp4",
    "size": 1234567,
    "contentType": "video/mp4",
    "timeCreated": "2026-01-03T12:00:00Z"
  }
  ```

#### Transcoding Complete Events (`looply-transcoding-complete`)
- Published when transcoding job completes
- **Message Schema**:
  ```json
  {
    "jobId": "transcoder-job-12345",
    "videoId": "video_id",
    "status": "SUCCESS|FAILED",
    "outputPath": "gs://transcoded-videos/video_id/",
    "qualities": ["480p", "720p", "1080p"],
    "completedAt": "2026-01-03T12:15:30Z"
  }
  ```

## Service Accounts & IAM

### Cloud Run Service Account (`looply-cloudrun-sa`)
**Permissions**:
- `roles/datastore.user` - Firestore read/write access
- `roles/storage.admin` - Cloud Storage access (videos & transcoded buckets)
- `roles/pubsub.publisher` - Publish to Pub/Sub topics
- `roles/pubsub.subscriber` - Subscribe to events
- `roles/logging.logWriter` - Write logs
- `roles/monitoring.metricWriter` - Custom metrics
- `roles/cloudkms.cryptoKeyEncrypterDecrypter` - Encryption key access
- `roles/secretmanager.secretAccessor` - Access secrets (API keys, etc.)

### Eventarc Service Account (`looply-eventarc-sa`)
**Permissions**:
- `roles/run.invoker` - Invoke Cloud Run services
- `roles/logging.logWriter` - Write logs
- `roles/monitoring.metricWriter` - Custom metrics

### Load Balancer Service Account (`looply-loadbalancer-sa`)
**Permissions**:
- `roles/secretmanager.secretAccessor` - Access SSL certificates
- `roles/logging.logWriter` - Write access logs
- `roles/monitoring.metricWriter` - LB metrics

## Cloud Storage Structure

```
videos-bucket/
├── uploads/
│   ├── video_1.mp4
│   ├── video_2.avi
│   └── ...
└── temp/
    └── (scratch space for processing)

transcoded-videos-bucket/
├── transcoded/
│   ├── video_1/
│   │   ├── master.m3u8 (HLS playlist)
│   │   ├── 480p.m3u8
│   │   ├── 720p.m3u8
│   │   ├── 1080p.m3u8
│   │   └── segments/
│   │       ├── segment_1.ts
│   │       └── ...
│   ├── video_2/
│   │   ├── output.mp4 (MP4 output)
│   │   └── metadata.json
│   └── ...
└── temp/
    └── (working directory)
```

## Firestore Collections

### `videos` Collection
```
{
  "id": "video_1",
  "userId": "user_123",
  "title": "My Video",
  "description": "...",
  "originalSize": 1234567,
  "status": "processing|completed|failed",
  "createdAt": Timestamp,
  "uploadedAt": Timestamp,
  "processingStartedAt": Timestamp,
  "processingCompletedAt": Timestamp,
  "transcodingJobId": "transcoder-job-12345",
  "qualities": ["480p", "720p", "1080p"],
  "hlsUrl": "gs://transcoded-videos/transcoded/video_1/master.m3u8",
  "mp4Url": "gs://transcoded-videos/transcoded/video_1/output.mp4",
  "metadata": {
    "duration": 120,
    "width": 1920,
    "height": 1080,
    "fps": 30,
    "format": "mp4"
  },
  "error": null
}
```

### `transcodingJobs` Collection
```
{
  "jobId": "transcoder-job-12345",
  "videoId": "video_1",
  "status": "processing|completed|failed",
  "templateUsed": "hls_adaptive",
  "createdAt": Timestamp,
  "completedAt": Timestamp,
  "duration": 845, // seconds
  "outputPath": "gs://transcoded-videos/transcoded/video_1/",
  "error": null
}
```

## Environment Setup

### Prerequisites
1. GCP Project with billing enabled
2. Cloud Run, Cloud Video Transcoder, Firestore, Pub/Sub, Eventarc APIs enabled
3. Service accounts created and roles assigned
4. Cloud Storage buckets created (`videos-bucket`, `transcoded-videos-bucket`)
5. Docker image pushed to Artifact Registry

### Required Environment Variables (in Cloud Run)
```bash
PROJECT_ID=looply-482917
REGION=us-central1
ENVIRONMENT=production
FIRESTORE_PROJECT=looply-482917
FIRESTORE_DB=(default)
PUBSUB_PROJECT=looply-482917
VIDEOS_BUCKET=looply-videos-looply-482917
TRANSCODED_BUCKET=looply-transcoded-looply-482917
TRANSCODER_TEMPLATE_HLS=projects/looply-482917/locations/us-central1/videoJobTemplates/hls_adaptive
VIDEO_UPLOAD_TOPIC=looply-video-upload-events
TRANSCODING_COMPLETE_TOPIC=looply-transcoding-complete
```

## Monitoring & Logging

### Logs
- Cloud Run logs: `resource.type="cloud_run_revision"`
- Eventarc logs: `resource.type="audit_log" AND protoPayload.resourceName=~"eventarc"`
- Transcoder logs: `resource.type="api"`

### Metrics
- Cloud Run: Latency, CPU, Memory, Request count
- Transcoder: Job success rate, processing duration
- Pub/Sub: Queue depth, processing latency

### Alerts (Configured in monitoring module)
- Cloud Run latency exceeds 5s
- Cloud Run error rate > 5%
- Transcoder job failure rate > 10%
- Storage usage exceeds threshold

## Deployment

### Apply Infrastructure
```bash
cd terraform
tofu init
tofu plan
tofu apply
```

### Deploy Application
```bash
# Build and push Docker image
docker build -t us-central1-docker.pkg.dev/looply-482917/looply-docker-repo/looply-bundled:latest .
docker push us-central1-docker.pkg.dev/looply-482917/looply-docker-repo/looply-bundled:latest

# Trigger Cloud Run deployment (auto-scales)
gcloud run deploy looply-app \
  --image us-central1-docker.pkg.dev/looply-482917/looply-docker-repo/looply-bundled:latest \
  --region us-central1 \
  --service-account looply-cloudrun-sa@looply-482917.iam.gserviceaccount.com
```

## Cost Optimization

- **Cloud Run**: Pay per request, scales to zero
- **Cloud Video Transcoder**: Pay per minute of video processed
- **Cloud CDN**: Caches content globally, reduces egress costs
- **Cloud Storage**: Use lifecycle policies to move old transcoded videos to cheaper storage tiers
- **Firestore**: Use on-demand billing for variable workloads

## Security Considerations

1. **IAP**: OAuth 2.0 authentication before any backend access
2. **Service Accounts**: Least-privilege IAM roles
3. **Encryption**: KMS-managed keys for sensitive data at rest
4. **Network**: Private service networking for Firestore connections
5. **Audit Logging**: All access logged to Cloud Logging
6. **Secrets**: Database passwords, API keys in Secret Manager

## Troubleshooting

### Video not transcoding
1. Check Eventarc trigger configuration and logs
2. Verify Cloud Run service has `roles/datastore.user` IAM role
3. Check Transcoder API is enabled: `gcloud services list | grep transcoder`
4. Review Cloud Transcoder job status: `gcloud video-intelligent-transcoder jobs list`

### IAP showing 401 error
1. Verify OAuth client ID is configured on backend service
2. Check user is authorized: `gcloud iap web get-iam-policy --resource-type=backend-services --service=looply-app-service`
3. Test with identity token: `gcloud auth print-identity-token`

### Firestore access errors from Cloud Run
1. Verify service account email in Cloud Run configuration
2. Check Firestore IAM binding: `gcloud firestore databases get-iam-policy`
3. Test service account credentials: `gcloud --impersonate-service-account=looply-cloudrun-sa@looply-482917.iam.gserviceaccount.com firestore documents list`

---

**Last Updated**: 2026-01-03  
**Architecture Version**: 2.0 (Multi-Region with Eventarc)
