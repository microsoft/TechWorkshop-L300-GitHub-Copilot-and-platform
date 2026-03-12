# ZavaStorefront Infrastructure

This folder contains Bicep templates for a development deployment of ZavaStorefront in a single Azure resource group.

## Resources

- Azure Container Registry (ACR)
- Log Analytics workspace
- Application Insights
- Linux App Service Plan
- Linux Web App for Containers with system-assigned managed identity
- AcrPull role assignment for the Web App identity
- Azure AI Foundry (Azure OpenAI account)

## Key Security Choices

- ACR admin user is disabled
- Anonymous image pulls are disabled
- Web App uses managed identity to pull from ACR (`acrUseManagedIdentityCreds`)
- AcrPull role assigned using RBAC (no password credentials)
- Application Insights local auth is disabled

## Deploy

From the infra folder:

```bash
cd infra
azd provision --preview
azd up
```

## Build and Push Container Without Local Docker

Use ACR cloud build:

```bash
az acr build \
  --registry <acr-name> \
  --image zavastorefront:latest \
  --file src/Dockerfile \
  src
```

After the image push, run:

```bash
azd deploy
```

## Notes

- Region defaults to `westus3` in `main.parameters.json`.
- Foundry/OpenAI quotas are subscription-dependent. Validate quota before deployment.
