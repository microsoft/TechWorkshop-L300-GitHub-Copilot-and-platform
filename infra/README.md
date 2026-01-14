# ZavaStorefront Dev Infrastructure

This directory contains Bicep modules and configuration for provisioning the ZavaStorefront development environment on Azure using Azure Developer CLI (azd).

## Structure
- `main.bicep`: Orchestrates all modules
- `modules/`: Contains modular Bicep files for each resource
- `azd.yaml`: Maps the provision/deploy workflow for azd

## Resources Provisioned
- Resource Group (westus3)
- Azure Container Registry (ACR)
- Linux App Service Plan
- Web App for Containers (with managed identity)
- Application Insights
- Microsoft Foundry (GPT-4/Phi access)
- AcrPull role assignment for Web App

## Deployment Workflow
1. Install [Azure Developer CLI (azd)](https://aka.ms/azure-dev/cli)
2. Run `azd init` and `azd provision` in this directory
3. Build and push container images using `az acr build` or GitHub Actions (no local Docker required)
4. Deploy app using `azd deploy`

## Cost Notes
- All resources use minimal-cost SKUs suitable for development

## Notes
- Ensure your subscription/region supports Microsoft Foundry and required models
- See `azd.yaml` and Bicep files for parameterization
