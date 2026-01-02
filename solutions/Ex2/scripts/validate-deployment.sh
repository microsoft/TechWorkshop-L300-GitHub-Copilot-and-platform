#!/bin/bash

# Deployment Validation Script for ZavaStorefront
# This script validates that all Azure resources are properly deployed and configured

set -e

echo "🔍 ZavaStorefront Deployment Validation"
echo "========================================"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    echo "   Visit: https://learn.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Please run: az login"
    exit 1
fi

echo "✅ Azure CLI is installed and logged in"
echo ""

# Get current subscription info
ACCOUNT_INFO=$(az account show --query '{name:name, id:id}' -o json)
SUBSCRIPTION_NAME=$(echo "$ACCOUNT_INFO" | jq -r '.name')
SUBSCRIPTION_ID=$(echo "$ACCOUNT_INFO" | jq -r '.id')
echo "📋 Current Subscription: $SUBSCRIPTION_NAME"
echo "   ID: $SUBSCRIPTION_ID"
echo ""

# Prompt for resource group name
read -p "Enter your resource group name (e.g., rg-zavastore-dev-westus3): " RG_NAME

if [ -z "$RG_NAME" ]; then
    echo "❌ Resource group name is required"
    exit 1
fi

# Check if resource group exists
if ! az group show --name "$RG_NAME" &> /dev/null; then
    echo "❌ Resource group '$RG_NAME' not found"
    exit 1
fi

echo "✅ Resource group '$RG_NAME' exists"
echo ""

# Get resource group location
RG_LOCATION=$(az group show --name "$RG_NAME" --query location -o tsv)
echo "📍 Location: $RG_LOCATION"
echo ""

echo "🔍 Validating Resources..."
echo "-------------------------"

# Check Container Registry
echo -n "Container Registry: "
ACR_NAME=$(az acr list --resource-group "$RG_NAME" --query "[0].name" -o tsv)
if [ -n "$ACR_NAME" ]; then
    ACR_LOGIN_SERVER=$(az acr list --resource-group "$RG_NAME" --query "[0].loginServer" -o tsv)
    echo "✅ $ACR_NAME ($ACR_LOGIN_SERVER)"
    
    # Check for images
    IMAGE_COUNT=$(az acr repository list --name "$ACR_NAME" --output tsv 2>/dev/null | wc -l)
    if [ "$IMAGE_COUNT" -gt 0 ]; then
        echo "   ✅ $IMAGE_COUNT container image(s) found"
    else
        echo "   ⚠️  No container images found (may need initial deployment)"
    fi
else
    echo "❌ Not found"
fi

# Check App Service Plan
echo -n "App Service Plan: "
ASP_NAME=$(az appservice plan list --resource-group "$RG_NAME" --query "[0].name" -o tsv)
if [ -n "$ASP_NAME" ]; then
    ASP_SKU=$(az appservice plan list --resource-group "$RG_NAME" --query "[0].sku.name" -o tsv)
    echo "✅ $ASP_NAME (SKU: $ASP_SKU)"
else
    echo "❌ Not found"
fi

# Check Web App
echo -n "Web App: "
WEBAPP_NAME=$(az webapp list --resource-group "$RG_NAME" --query "[0].name" -o tsv)
if [ -n "$WEBAPP_NAME" ]; then
    WEBAPP_URL=$(az webapp show --name "$WEBAPP_NAME" --resource-group "$RG_NAME" --query defaultHostName -o tsv)
    WEBAPP_STATE=$(az webapp show --name "$WEBAPP_NAME" --resource-group "$RG_NAME" --query state -o tsv)
    echo "✅ $WEBAPP_NAME"
    echo "   URL: https://$WEBAPP_URL"
    echo "   State: $WEBAPP_STATE"
    
    # Check managed identity
    IDENTITY=$(az webapp identity show --name "$WEBAPP_NAME" --resource-group "$RG_NAME" --query principalId -o tsv 2>/dev/null)
    if [ -n "$IDENTITY" ]; then
        echo "   ✅ Managed identity configured"
    else
        echo "   ⚠️  Managed identity not found"
    fi
else
    echo "❌ Not found"
fi

# Check Application Insights
echo -n "Application Insights: "
APPINSIGHTS_NAME=$(az monitor app-insights component list --resource-group "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null)
if [ -n "$APPINSIGHTS_NAME" ]; then
    APPINSIGHTS_KEY=$(az monitor app-insights component show --app "$APPINSIGHTS_NAME" --resource-group "$RG_NAME" --query instrumentationKey -o tsv)
    echo "✅ $APPINSIGHTS_NAME"
    echo "   Key: ${APPINSIGHTS_KEY:0:8}..."
else
    echo "❌ Not found"
fi

# Check Azure OpenAI
echo -n "Azure OpenAI: "
OPENAI_NAME=$(az cognitiveservices account list --resource-group "$RG_NAME" --query "[?kind=='OpenAI'].name" -o tsv 2>/dev/null)
if [ -n "$OPENAI_NAME" ]; then
    OPENAI_ENDPOINT=$(az cognitiveservices account show --name "$OPENAI_NAME" --resource-group "$RG_NAME" --query properties.endpoint -o tsv)
    echo "✅ $OPENAI_NAME"
    echo "   Endpoint: $OPENAI_ENDPOINT"
    
    # Check deployments
    DEPLOYMENTS=$(az cognitiveservices account deployment list --name "$OPENAI_NAME" --resource-group "$RG_NAME" --query "[].name" -o tsv 2>/dev/null)
    if [ -n "$DEPLOYMENTS" ]; then
        echo "   ✅ Model deployments:"
        echo "$DEPLOYMENTS" | while read -r deployment; do
            echo "      - $deployment"
        done
    fi
else
    echo "⚠️  Not deployed (optional)"
fi

echo ""
echo "🔍 Checking Role Assignments..."
echo "------------------------------"

if [ -n "$ACR_NAME" ] && [ -n "$IDENTITY" ]; then
    # Check if managed identity has AcrPull role on ACR
    ACR_ID=$(az acr show --name "$ACR_NAME" --resource-group "$RG_NAME" --query id -o tsv)
    ROLE_ASSIGNMENT=$(az role assignment list --assignee "$IDENTITY" --scope "$ACR_ID" --query "[?roleDefinitionName=='AcrPull'].roleDefinitionName" -o tsv 2>/dev/null)
    
    if [ -n "$ROLE_ASSIGNMENT" ]; then
        echo "✅ Web App has AcrPull role on ACR"
    else
        echo "❌ AcrPull role assignment not found"
    fi
fi

echo ""
echo "📊 Resource Summary"
echo "-----------------"
az resource list --resource-group "$RG_NAME" --output table

echo ""
echo "🎉 Validation Complete!"
echo ""

# Test web app endpoint if available
if [ -n "$WEBAPP_URL" ]; then
    echo "🌐 Testing Web App..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$WEBAPP_URL" --max-time 10)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Web App is responding (HTTP $HTTP_CODE)"
        echo ""
        echo "🎯 Your application is available at: https://$WEBAPP_URL"
    else
        echo "⚠️  Web App returned HTTP $HTTP_CODE"
        echo "   (This may be normal if the app is still starting up)"
        echo ""
        echo "💡 Try accessing: https://$WEBAPP_URL"
    fi
fi

echo ""
echo "✨ Next Steps:"
echo "   - View logs: az webapp log tail --name $WEBAPP_NAME --resource-group $RG_NAME"
echo "   - View in portal: https://portal.azure.com/#resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"
echo "   - Deploy updates: azd deploy"
echo "   - View costs: Azure Portal → Cost Management"
echo ""
