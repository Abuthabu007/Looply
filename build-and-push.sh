#!/bin/bash
# Build and push Looply API Docker image to both regions

set -e

PROJECT_ID="looply-480312"
REPO_NAME="looply-docker-repo"
IMAGE_NAME="looply-api"
TAG="latest"

echo "🐳 Building Looply API Docker image..."

# Build the Docker image
docker build -t $IMAGE_NAME:$TAG .

echo "✅ Image built successfully!"
echo ""
echo "📤 Pushing to Artifact Registry (us-central1)..."

# Tag for us-central1
docker tag $IMAGE_NAME:$TAG us-central1-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$TAG

# Push to us-central1
docker push us-central1-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$TAG

echo "✅ Pushed to us-central1!"
echo ""
echo "📤 Pushing to Artifact Registry (europe-west1)..."

# Tag for europe-west1
docker tag $IMAGE_NAME:$TAG europe-west1-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$TAG

# Push to europe-west1
docker push europe-west1-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$TAG

echo "✅ Pushed to europe-west1!"
echo ""
echo "✨ Docker image successfully built and pushed to both regions!"
echo ""
echo "Image URLs:"
echo "  - us-central1: us-central1-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$TAG"
echo "  - europe-west1: europe-west1-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$TAG"
