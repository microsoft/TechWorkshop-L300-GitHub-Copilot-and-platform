# Deploy ZavaStorefront to Azure
# This script builds the container image and deploys it to App Service

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ZavaStorefront Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get environment values
Write-Host "Reading environment values..." -ForegroundColor Yellow
$acrName = azd env get-value AZURE_CONTAINER_REGISTRY_NAME
$appName = azd env get-value AZURE_APP_SERVICE_NAME
$rgName = azd env get-value AZURE_RESOURCE_GROUP

if (-not $acrName -or -not $appName -or -not $rgName) {
    Write-Host "ERROR: Could not retrieve environment values. Have you run 'azd provision'?" -ForegroundColor Red
    exit 1
}

Write-Host "  ACR: $acrName" -ForegroundColor Gray
Write-Host "  App Service: $appName" -ForegroundColor Gray
Write-Host "  Resource Group: $rgName" -ForegroundColor Gray
Write-Host ""

# Step 1: Build and push container image
Write-Host "Step 1: Building and pushing container image to ACR..." -ForegroundColor Cyan
Write-Host "  This may take a few minutes..." -ForegroundColor Gray

az acr build `
    --registry $acrName `
    --image zavastore:latest `
    --image "zavastore:$(git rev-parse --short HEAD 2>$null)" `
    --file src/Dockerfile `
    ./src

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to build container image" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  [OK] Container image built and pushed successfully!" -ForegroundColor Green
Write-Host ""

# Step 2: Deploy to App Service
Write-Host "Step 2: Deploying container to App Service..." -ForegroundColor Cyan

az webapp config container set `
    --name $appName `
    --resource-group $rgName `
    --docker-custom-image-name "$acrName.azurecr.io/zavastore:latest" `
    --docker-registry-server-url "https://$acrName.azurecr.io"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to configure App Service" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  [OK] App Service configured successfully!" -ForegroundColor Green
Write-Host ""

# Step 3: Restart App Service to pull new image
Write-Host "Step 3: Restarting App Service to apply changes..." -ForegroundColor Cyan

az webapp restart `
    --name $appName `
    --resource-group $rgName

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "WARNING: Failed to restart App Service" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "  [OK] App Service restarted successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Get the app URL
$appUrl = az webapp show --name $appName --resource-group $rgName --query defaultHostName -o tsv

Write-Host "Application Details:" -ForegroundColor Cyan
Write-Host "  URL: https://$appUrl" -ForegroundColor Green
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  View logs: az webapp log tail --name $appName --resource-group $rgName" -ForegroundColor Gray
Write-Host "  Browse app: start https://$appUrl" -ForegroundColor Gray
Write-Host ""
