#!/bin/bash
# Verification script for Azure Infrastructure deployment
# This script helps verify that all resources are properly deployed and configured

set -e

echo "=========================================="
echo "Azure Infrastructure Verification Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print success messages
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error messages
error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to print warning messages
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print info messages
info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check prerequisites
echo "Checking prerequisites..."
echo ""

# Check Azure CLI
if command -v az &> /dev/null; then
    AZ_VERSION=$(az version --query '"azure-cli"' -o tsv)
    success "Azure CLI installed (version: $AZ_VERSION)"
else
    error "Azure CLI not found. Please install: https://aka.ms/InstallAzureCLIDeb"
    exit 1
fi

# Check AZD
if command -v azd &> /dev/null; then
    AZD_VERSION=$(azd version | head -n 1)
    success "Azure Developer CLI installed ($AZD_VERSION)"
else
    error "Azure Developer CLI not found. Please install: https://aka.ms/install-azd.sh"
    exit 1
fi

# Check if logged in to Azure
if az account show &> /dev/null; then
    SUBSCRIPTION=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    success "Logged in to Azure"
    info "Active subscription: $SUBSCRIPTION"
else
    error "Not logged in to Azure. Run: az login"
    exit 1
fi

echo ""
echo "=========================================="
echo "Bicep Template Validation"
echo "=========================================="
echo ""

# Validate main Bicep template
if az bicep build --file infra/main.bicep &> /dev/null; then
    success "Main Bicep template is valid"
else
    error "Main Bicep template validation failed"
    exit 1
fi

# Validate each module
MODULE_COUNT=0
for module in infra/modules/*.bicep; do
    MODULE_NAME=$(basename "$module")
    if az bicep build --file "$module" &> /dev/null; then
        success "Module $MODULE_NAME is valid"
        ((MODULE_COUNT++))
    else
        error "Module $MODULE_NAME validation failed"
        exit 1
    fi
done

success "All $MODULE_COUNT Bicep modules validated successfully"

echo ""
echo "=========================================="
echo "File Structure Verification"
echo "=========================================="
echo ""

# Check required files
REQUIRED_FILES=(
    "azure.yaml"
    "Dockerfile"
    ".dockerignore"
    "infra/main.bicep"
    "infra/README.md"
    "DEPLOYMENT.md"
    "SUMMARY.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        success "Found: $file"
    else
        error "Missing: $file"
        exit 1
    fi
done

# Check GitHub Actions workflow
if [ -f ".github/workflows/azure-deploy.yml" ]; then
    success "Found: GitHub Actions workflow (azure-deploy.yml)"
else
    warning "GitHub Actions workflow not found"
fi

echo ""
echo "=========================================="
echo "AZD Configuration Check"
echo "=========================================="
echo ""

# Check if AZD is initialized
if [ -d ".azure" ]; then
    info "AZD appears to be initialized (.azure directory exists)"
    
    # List environments
    if [ -d ".azure" ] && [ "$(ls -A .azure 2>/dev/null)" ]; then
        ENVS=$(ls -d .azure/*/ 2>/dev/null | xargs -n 1 basename 2>/dev/null || echo "")
        if [ -n "$ENVS" ]; then
            success "AZD environments found:"
            echo "$ENVS" | while read env; do
                echo "  - $env"
            done
        fi
    fi
else
    info "AZD not yet initialized. Run: azd init"
fi

echo ""
echo "=========================================="
echo "Azure Resource Check (if deployed)"
echo "=========================================="
echo ""

# Prompt for resource group name
read -p "Enter resource group name (or press Enter to skip): " RG_NAME

if [ -n "$RG_NAME" ]; then
    # Check if resource group exists
    if az group show --name "$RG_NAME" &> /dev/null; then
        success "Resource group '$RG_NAME' exists"
        
        # List resources
        echo ""
        info "Resources in '$RG_NAME':"
        az resource list --resource-group "$RG_NAME" --output table --query "[].{Name:name, Type:type, Location:location}"
        
        echo ""
        
        # Check specific resources
        ACR=$(az acr list --resource-group "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null)
        if [ -n "$ACR" ]; then
            success "ACR found: $ACR"
            ACR_LOGIN_SERVER=$(az acr show --name "$ACR" --query loginServer -o tsv)
            info "Login server: $ACR_LOGIN_SERVER"
        else
            warning "ACR not found in resource group"
        fi
        
        APP_SERVICE=$(az webapp list --resource-group "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null)
        if [ -n "$APP_SERVICE" ]; then
            success "App Service found: $APP_SERVICE"
            APP_URL=$(az webapp show --name "$APP_SERVICE" --resource-group "$RG_NAME" --query defaultHostName -o tsv)
            info "URL: https://$APP_URL"
            
            # Check if app is running
            APP_STATE=$(az webapp show --name "$APP_SERVICE" --resource-group "$RG_NAME" --query state -o tsv)
            if [ "$APP_STATE" == "Running" ]; then
                success "App Service is running"
            else
                warning "App Service state: $APP_STATE"
            fi
        else
            warning "App Service not found in resource group"
        fi
        
        APP_INSIGHTS=$(az monitor app-insights component show --resource-group "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null)
        if [ -n "$APP_INSIGHTS" ]; then
            success "Application Insights found: $APP_INSIGHTS"
        else
            warning "Application Insights not found in resource group"
        fi
        
        AI_HUB=$(az ml workspace list --resource-group "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null)
        if [ -n "$AI_HUB" ]; then
            success "AI Hub found: $AI_HUB"
        else
            warning "AI Hub not found in resource group (may require separate installation)"
        fi
        
    else
        warning "Resource group '$RG_NAME' not found. Resources may not be deployed yet."
    fi
else
    info "Skipping Azure resource check"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
success "Infrastructure code validation: PASSED"
success "File structure: COMPLETE"

if [ -n "$RG_NAME" ] && az group show --name "$RG_NAME" &> /dev/null; then
    success "Azure resources: DEPLOYED"
    echo ""
    info "Next steps:"
    echo "  1. Access your application: https://$(az webapp show --name "$APP_SERVICE" --resource-group "$RG_NAME" --query defaultHostName -o tsv 2>/dev/null)"
    echo "  2. View Application Insights in Azure Portal"
    echo "  3. Check logs: az webapp log tail --name $APP_SERVICE --resource-group $RG_NAME"
else
    info "Resources not yet deployed"
    echo ""
    info "To deploy infrastructure:"
    echo "  1. Run: azd init"
    echo "  2. Run: azd up"
    echo "  3. Access your app at the URL provided"
fi

echo ""
info "For detailed deployment instructions, see: DEPLOYMENT.md"
info "For infrastructure details, see: infra/README.md"
info "For a complete summary, see: SUMMARY.md"

echo ""
echo "=========================================="
echo "Verification Complete!"
echo "=========================================="
