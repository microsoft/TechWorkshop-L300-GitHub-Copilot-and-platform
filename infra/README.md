# ZavaStorefront Infrastructure (Dev)

This folder contains Bicep modules and deployment instructions for provisioning the ZavaStorefront dev environment in Azure (eastus).

## Modules
- **ACR**: Azure Container Registry (Basic SKU)
- **App Service Plan**: Linux, Basic SKU
- **Web App**: Linux App Service (Web App for Containers), managed identity, pulls from ACR
- **Application Insights**: Monitoring
- **Microsoft Foundry**: GPT-4/Phi access (dev SKU)
- **Role Assignment**: AcrPull for managed identity

## Deployment Workflow
1. Install [Azure Developer CLI (azd)](https://aka.ms/azure-dev/install)
2. Run `azd init` and select this template
3. Run `azd up` to provision and deploy all resources
4. Use `az acr build` or GitHub Actions for container builds (no local Docker required)

## Notes
- All resources are parameterized for environment, region, and SKU
- App Service uses managed identity for ACR pulls (no passwords)
- Application Insights is wired for monitoring
- Microsoft Foundry is provisioned in eastus (ensure quota)
- See `main.bicep` for orchestration and module usage

## Cost
- All SKUs are minimal-cost, dev-appropriate

## CI/CD
- Example GitHub Actions workflow provided for cloud-based builds

---
For more details, see each module and the main Bicep template.