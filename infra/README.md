# Infrastructure

This folder contains AZD-compatible Bicep infrastructure for ZavaStorefront.

## Resources
- Azure Container Registry (ACR)
- Linux App Service Plan + Web App for Containers
- Log Analytics Workspace
- Application Insights (workspace-based)
- Azure OpenAI account for AI Foundry scenarios
- AcrPull role assignment for Web App managed identity

## Usage
1. Initialize/login with Azure CLI and AZD.
2. Run `azd provision --preview`.
3. Run `azd up`.

## Notes
- ACR admin user is disabled; image pulls use managed identity + RBAC.
- Model deployments (GPT-4/Phi) are not included by default because they depend on subscription quota and model availability.
