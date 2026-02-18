# Azure Infrastructure Deployment Guide

This project uses Azure Developer CLI (azd) and Bicep to provision and deploy the ZavaStorefront application to Azure.

## Prerequisites

- [Azure Developer CLI (azd)](https://aka.ms/azd-install)
- Azure subscription
- Docker (optional - Azure Container Registry can build images in the cloud)

## Infrastructure Components

The infrastructure provisions the following Azure resources:

1. **Resource Group** - Single resource group for all resources in `westus3` region
2. **Container Registry** - Azure Container Registry for Docker images
3. **App Service Plan** - Linux-based Basic (B1) tier
4. **App Service** - Web app configured for Docker containers
5. **Application Insights** - Monitoring and telemetry
6. **Log Analytics Workspace** - Log storage for Application Insights
7. **Azure AI Foundry (Cognitive Services)** - OpenAI services for GPT-4 and Phi models

## Key Features

- **RBAC Authentication**: App Service uses managed identity to pull images from Container Registry (no passwords)
- **Docker Deployment**: Application is containerized and deployed from ACR
- **Infrastructure as Code**: All resources defined in Bicep templates
- **Monitoring**: Application Insights integrated for observability
- **AI Integration**: Azure OpenAI with GPT-4 and Phi model deployments

## Deployment Steps

### 1. Initialize Azure Developer CLI

```bash
azd init
```

When prompted:
- Environment name: Choose a name (e.g., `zavastorefront-dev`)
- This will be used to generate unique resource names

### 2. Login to Azure

```bash
azd auth login
```

### 3. Provision Infrastructure

```bash
azd provision
```

This will:
- Create all Azure resources defined in the Bicep templates
- Configure App Service with managed identity
- Set up RBAC permissions for ACR access
- Deploy Application Insights

### 4. Build and Deploy the Application

```bash
azd deploy
```

This will:
- Build the Docker image from the Dockerfile
- Push the image to Azure Container Registry
- Update the App Service to use the new image

### 5. Access the Application

After deployment, get the application URL:

```bash
azd show
```

Or check the outputs:

```bash
az deployment sub show -n <environment-name> --query properties.outputs
```

## Manual Deployment (Alternative)

If you prefer to deploy manually without azd:

### 1. Build and Push Docker Image

```bash
# Login to ACR
az acr login --name <registry-name>

# Build and push image
docker build -t <registry-name>.azurecr.io/zava-storefront:latest .
docker push <registry-name>.azurecr.io/zava-storefront:latest
```

### 2. Update App Service

```bash
az webapp config container set \
  --name <app-service-name> \
  --resource-group <resource-group-name> \
  --docker-custom-image-name <registry-name>.azurecr.io/zava-storefront:latest
```

## Configuration

### Environment Variables

The App Service is configured with:
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - For Application Insights monitoring
- `DOCKER_REGISTRY_SERVER_URL` - Container Registry URL
- `DOCKER_ENABLE_CI` - Enable continuous deployment

### AI Foundry Models

The following models are deployed:
- **GPT-4** (gpt-4:0613) - 10K tokens per minute capacity
- **Phi-3** (gpt-35-turbo:0613) - 10K tokens per minute capacity

Note: Phi model uses gpt-35-turbo as a placeholder. Update the model deployment if Phi-specific models become available.

## Resource Naming Convention

Resources follow this naming pattern:
- Resource Group: `rg-{environment-name}`
- Container Registry: `cr{environment-name}` (hyphens removed)
- App Service Plan: `asp-{environment-name}`
- App Service: `app-{environment-name}`
- Application Insights: `appi-{environment-name}`
- Cognitive Services: `cog-{environment-name}`

## Security

- **Managed Identity**: App Service uses system-assigned managed identity
- **RBAC**: Least-privilege access with AcrPull role
- **HTTPS**: App Service configured for HTTPS only
- **TLS**: Minimum TLS version 1.2
- **No Admin Credentials**: Container Registry admin user is disabled

## Monitoring

Application Insights is configured to collect:
- Request telemetry
- Dependency tracking
- Exception logging
- Performance metrics
- Custom events and metrics

Access monitoring data in Azure Portal under the Application Insights resource.

## Cleanup

To delete all resources:

```bash
azd down
```

Or manually:

```bash
az group delete --name rg-{environment-name} --yes
```

## Troubleshooting

### Common Issues

1. **Container fails to pull**: Ensure managed identity has AcrPull role assignment
2. **App Service doesn't start**: Check Application Insights logs for errors
3. **Build fails**: Verify Dockerfile is in the correct location and syntax is valid

### Logs

View application logs:

```bash
az webapp log tail --name <app-service-name> --resource-group <resource-group-name>
```

View deployment logs:

```bash
az webapp log deployment show --name <app-service-name> --resource-group <resource-group-name>
```

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Azure Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)
- [Application Insights Documentation](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
