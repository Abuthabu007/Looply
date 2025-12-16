@echo off
REM Build and push Looply API Docker image to both regions

setlocal enabledelayedexpansion

set PROJECT_ID=looply-480312
set REPO_NAME=looply-docker-repo
set IMAGE_NAME=looply-api
set TAG=latest

echo.
echo Building Looply API Docker image...
echo.

docker build -t %IMAGE_NAME%:%TAG% .

if errorlevel 1 (
    echo Error: Docker build failed
    exit /b 1
)

echo.
echo Image built successfully!
echo.
echo Pushing to Artifact Registry (us-central1)...
echo.

docker tag %IMAGE_NAME%:%TAG% us-central1-docker.pkg.dev/%PROJECT_ID%/%REPO_NAME%/%IMAGE_NAME%:%TAG%
docker push us-central1-docker.pkg.dev/%PROJECT_ID%/%REPO_NAME%/%IMAGE_NAME%:%TAG%

if errorlevel 1 (
    echo Error: Failed to push to us-central1
    exit /b 1
)

echo.
echo Pushed to us-central1!
echo.
echo Pushing to Artifact Registry (europe-west1)...
echo.

docker tag %IMAGE_NAME%:%TAG% europe-west1-docker.pkg.dev/%PROJECT_ID%/%REPO_NAME%/%IMAGE_NAME%:%TAG%
docker push europe-west1-docker.pkg.dev/%PROJECT_ID%/%REPO_NAME%/%IMAGE_NAME%:%TAG%

if errorlevel 1 (
    echo Error: Failed to push to europe-west1
    exit /b 1
)

echo.
echo Pushed to europe-west1!
echo.
echo Docker image successfully built and pushed to both regions!
echo.
echo Image URLs:
echo   - us-central1: us-central1-docker.pkg.dev/%PROJECT_ID%/%REPO_NAME%/%IMAGE_NAME%:%TAG%
echo   - europe-west1: europe-west1-docker.pkg.dev/%PROJECT_ID%/%REPO_NAME%/%IMAGE_NAME%:%TAG%
echo.

endlocal
