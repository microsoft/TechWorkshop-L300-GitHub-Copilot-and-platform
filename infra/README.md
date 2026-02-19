# Azure Deployment Guide (Issue #1)

This repository includes AZD + Bicep infrastructure to deploy `ZavaStorefront` in `westus3` with:
- Linux App Service (container-based)
- Azure Container Registry (ACR)
- User-assigned managed identity + `AcrPull` RBAC for image pulls
- Application Insights + Log Analytics
- Azure OpenAI resource for Foundry-based GPT/Phi integration

## Prerequisites
- Azure CLI (`az`)
- Azure Developer CLI (`azd`)
- Access to an Azure subscription with permissions to create RBAC assignments

## Files
- `azure.yaml`: AZD app + service mapping
- `infra/main.bicep`: infrastructure definition
- `infra/main.parameters.json`: parameter values using AZD env placeholders
- `src/Dockerfile`: image build for App Service container

## Deploy
From repository root:

1. Sign in and create environment
   - `az login`
   - `azd auth login`
   - `azd env new dev`
   - `azd env set AZURE_LOCATION westus3`

2. Validate infrastructure preview
   - `azd provision --preview`

3. Provision + deploy
   - `azd up`

## Validate ACR Pull Uses RBAC
- Confirm App Service has the user-assigned identity attached in Azure Portal.
- Confirm identity has `AcrPull` role assignment scoped to the ACR.
- Confirm Web App container settings reference ACR login server and managed identity pull settings.

## Validate GPT-4 and Phi Availability in westus3
Use Azure CLI to list model support for your Azure OpenAI account:

- `az cognitiveservices account list-models --name <openai-account-name> --resource-group <resource-group>`

If your desired model/version is unavailable in `westus3`, update model parameters in `infra/main.parameters.json` and re-run:
- `azd up`

## Optional: Enable Model Deployment Creation in IaC
By default, model deployment resources are disabled to avoid failures when model versions are unavailable.

To enable:
- Set `deployModelDeployments` to `true` in `infra/main.parameters.json`
- Adjust `gpt4ModelName`, `gpt4ModelVersion`, `phiModelName`, and `phiModelVersion` as needed.
