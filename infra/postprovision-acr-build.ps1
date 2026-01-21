# Post-provisioning: Build and push Docker image to ACR for App Service

# This script should be run after azd provision completes successfully.
# It uses az acr build to build and push the image referenced by your webapp.bicep file.

$acrName = "acrmxe36chfff5wk"
$imageName = "zavastorefront:latest"
$contextPath = "src"

Write-Host "Building and pushing image $acrName.azurecr.io/$imageName using az acr build..."
az acr build --registry $acrName --image $imageName $contextPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "Image $acrName.azurecr.io/$imageName built and pushed successfully."
} else {
    Write-Host "Image build or push failed. Check the output above for errors."
    exit 1
}
