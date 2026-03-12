# ZavaStorefront Infrastructure

This folder contains AZD-compatible Bicep templates for issue #1.

## What Gets Provisioned

- Azure Container Registry with admin disabled
- Log Analytics workspace
- Application Insights linked to the workspace
- Linux App Service Plan and Linux Web App for container hosting
- AcrPull role assignment from the Web App managed identity to ACR
- Microsoft Foundry compatible AIServices resource
- GPT deployment (`gpt-4o`, OpenAI format, version `2024-11-20`)
- Phi deployment (`Phi-4`, Microsoft format, version `7`)

## Notes and Gotchas

- ACR pulls are identity-based (no registry username/password).
- `acrUseManagedIdentityCreds` is enabled on the Web App.
- Model deployments are included with defaults verified against this account in `westus3`.
- If quotas change, adjust deployment SKU and capacity in `infra/main.bicep` parameters.
- For builds without local Docker, use `az acr build` or a GitHub Actions workflow that builds in Azure.
