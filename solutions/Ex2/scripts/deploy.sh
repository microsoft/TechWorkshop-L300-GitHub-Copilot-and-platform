#!/bin/bash

# Deploy Script for ZavaStorefront
# This script builds and deploys the application to Azure Web App

set -e

echo "🚀 ZavaStorefront Deployment Script"
echo "===================================="
echo ""

# Check if required tools are installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Please run: az login"
    exit 1
fi

echo "✅ Prerequisites verified"
echo ""

# Get parameters from azd environment or prompt user
if command -v azd &> /dev/null && azd env list &> /dev/null 2>&1; then
    echo "📦 Using azd environment..."
    ACR_NAME=$(azd env get-value AZURE_CONTAINER_REGISTRY_NAME 2>/dev/null || echo "")
    WEBAPP_NAME=$(azd env get-value AZURE_WEBAPP_NAME 2>/dev/null || echo "")
    RG_NAME=$(azd env get-value AZURE_RESOURCE_GROUP 2>/dev/null || echo "")
fi

# Prompt if not set
if [ -z "$ACR_NAME" ]; then
    read -p "Enter your Azure Container Registry name: " ACR_NAME
fi

if [ -z "$WEBAPP_NAME" ]; then
    read -p "Enter your Web App name: " WEBAPP_NAME
fi

if [ -z "$RG_NAME" ]; then
    read -p "Enter your Resource Group name: " RG_NAME
fi

echo ""
echo "📋 Deployment Configuration"
echo "  ACR: $ACR_NAME"
echo "  Web App: $WEBAPP_NAME"
echo "  Resource Group: $RG_NAME"
echo ""

# Confirm deployment
read -p "Continue with deployment? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

echo ""
echo "🔨 Building container image in Azure Container Registry..."
echo "  (This is a cloud-based build - no local Docker required)"
echo ""

# Validate source directory exists
if [ ! -d "./src" ]; then
    echo "❌ Source directory './src' not found"
    echo "   Please run this script from the repository root directory"
    exit 1
fi

if [ ! -f "./Dockerfile" ]; then
    echo "❌ Dockerfile not found in current directory"
    echo "   Please run this script from the repository root directory"
    exit 1
fi

# Build and push image using ACR
IMAGE_TAG=$(date +%Y%m%d-%H%M%S)
az acr build \
    --registry "$ACR_NAME" \
    --image "zavastore:$IMAGE_TAG" \
    --image "zavastore:latest" \
    --file Dockerfile \
    ./src

if [ $? -ne 0 ]; then
    echo "❌ Image build failed"
    exit 1
fi

echo ""
echo "✅ Image built and pushed successfully"
echo ""
echo "🔄 Updating Web App configuration..."

# Update Web App to use the new image
az webapp config container set \
    --name "$WEBAPP_NAME" \
    --resource-group "$RG_NAME" \
    --docker-custom-image-name "$ACR_NAME.azurecr.io/zavastore:$IMAGE_TAG" \
    --output none

if [ $? -ne 0 ]; then
    echo "❌ Failed to update Web App configuration"
    exit 1
fi

echo "✅ Web App configuration updated"
echo ""
echo "♻️  Restarting Web App..."

# Restart the web app
az webapp restart \
    --name "$WEBAPP_NAME" \
    --resource-group "$RG_NAME" \
    --output none

if [ $? -ne 0 ]; then
    echo "❌ Failed to restart Web App"
    exit 1
fi

echo "✅ Web App restarted"
echo ""

# Get the web app URL
WEBAPP_URL=$(az webapp show --name "$WEBAPP_NAME" --resource-group "$RG_NAME" --query defaultHostName -o tsv)

echo "🎉 Deployment Complete!"
echo ""
echo "🌐 Your application is available at: https://$WEBAPP_URL"
echo ""
echo "💡 Next steps:"
echo "   - View logs: az webapp log tail --name $WEBAPP_NAME --resource-group $RG_NAME"
echo "   - Monitor: https://portal.azure.com/#resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME/providers/Microsoft.Web/sites/$WEBAPP_NAME"
echo ""
