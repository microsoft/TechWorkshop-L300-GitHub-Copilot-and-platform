targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Name of the Azure AI Services (Foundry) account. Must be globally unique.')
param name string

param location string
param tags object

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// Azure AI Services account — backs Azure AI Foundry for GPT-4 and Phi access
resource aiServices 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    // Allows Entra ID auth; disable local key auth for production
    disableLocalAuth: false
  }
}

// ---------------------------------------------------------------------------
// Model Deployments
// ---------------------------------------------------------------------------

// GPT-4o deployment — replaces deprecated gpt-4 turbo-2024-04-09 (retired 11/14/2025).
// gpt-4o 2024-11-20 is GA and available in westus3.
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: aiServices
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20'
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
}

// Phi-4-mini-instruct deployment — Microsoft SLM available in westus3.
// Uses format 'Microsoft' and GlobalStandard SKU (required for Phi family models).
resource phi4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: aiServices
  name: 'phi-4-mini'
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4-mini-instruct'
      version: '1'
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
  // Deployments must be sequential to avoid capacity conflicts
  dependsOn: [gpt4oDeployment]
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output endpoint string = aiServices.properties.endpoint
output name string = aiServices.name
output id string = aiServices.id
