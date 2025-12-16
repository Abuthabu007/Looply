# Docker Image Build & Push Instructions

## Prerequisites
- Docker installed and running
- gcloud CLI authenticated with access to GCP project `looply-480312`
- Artifact Registry repository already created: `looply-docker-repo`

## Build Instructions

### Option 1: Using the Build Script (Recommended)

**On Windows:**
```powershell
cd d:\GCP-Project\Looply\Looply
.\build-and-push.bat
```

**On Linux/Mac:**
```bash
cd /path/to/Looply
chmod +x build-and-push.sh
./build-and-push.sh
```

### Option 2: Manual Build & Push

**Step 1: Build the Docker image**
```bash
cd d:\GCP-Project\Looply\Looply
docker build -t looply-api:latest .
```

**Step 2: Configure Docker authentication for Artifact Registry**
```bash
# For us-central1
gcloud auth configure-docker us-central1-docker.pkg.dev

# For europe-west1
gcloud auth configure-docker europe-west1-docker.pkg.dev
```

**Step 3: Tag the image for both regions**
```bash
# US Region
docker tag looply-api:latest us-central1-docker.pkg.dev/looply-480312/looply-docker-repo/looply-api:latest

# EU Region
docker tag looply-api:latest europe-west1-docker.pkg.dev/looply-480312/looply-docker-repo/looply-api:latest
```

**Step 4: Push to both regions**
```bash
# US Region
docker push us-central1-docker.pkg.dev/looply-480312/looply-docker-repo/looply-api:latest

# EU Region
docker push europe-west1-docker.pkg.dev/looply-480312/looply-docker-repo/looply-api:latest
```

## Verify Images Uploaded

```bash
# List images in us-central1
gcloud artifacts docker images list us-central1-docker.pkg.dev/looply-480312/looply-docker-repo

# List images in europe-west1
gcloud artifacts docker images list europe-west1-docker.pkg.dev/looply-480312/looply-docker-repo
```

## Verify Cloud Run Services

Once the images are pushed, the Cloud Run services will become Ready:

```bash
# Check primary region
gcloud run services describe looply-api --region=us-central1 --project=looply-480312

# Check secondary region
gcloud run services describe looply-api-eu --region=europe-west1 --project=looply-480312
```

Look for `Ready: true` in the output.

## Test the API

Once services are Ready, test the API:

```bash
# Get the service URL
gcloud run services describe looply-api --region=us-central1 --project=looply-480312 --format='value(status.url)'

# Test health endpoint
curl https://<service-url>/api/health

# Expected response:
# {
#   "status": "healthy",
#   "environment": "production",
#   "region": "us-central1",
#   "timestamp": "2025-12-16T...",
#   "version": "1.0.0"
# }
```

## Troubleshooting

### Image not found after pushing
- Wait 30 seconds for the image to be indexed
- Verify the image was actually pushed: `gcloud artifacts docker images list <registry>`

### Cloud Run service still shows Ready:False after image push
- Check Cloud Run logs: `gcloud run logs read looply-api --region=us-central1`
- Verify image URL in Cloud Run service matches the pushed image
- Ensure the service account has pull access to Artifact Registry

### Authentication error when pushing
- Re-authenticate: `gcloud auth login`
- Configure Docker: `gcloud auth configure-docker us-central1-docker.pkg.dev`
- Try pushing again

## What Happens Next

1. **Image Upload** (~2-5 minutes)
   - Docker image is built and pushed to Artifact Registry in both regions

2. **Cloud Run Service Update** (~1-2 minutes)
   - Terraform-managed Cloud Run services automatically detect the new image
   - Services pull the image and start containers

3. **Service Ready** (~2-3 minutes)
   - Cloud Run performs health checks
   - Services become `Ready: true`

4. **Load Balancer Active** (Immediate once services are Ready)
   - NEGs (Network Endpoint Groups) become healthy
   - Load balancer routes traffic to both regions
   - API is live at the global IP

## Total Time to Production

**Total: 5-10 minutes from image push to fully deployed system**

- Image build: 2-3 minutes
- Image push: 1-2 minutes
- Cloud Run service update: 1-2 minutes
- Health checks: 1-2 minutes
- Load balancer healthy: 1 minute
