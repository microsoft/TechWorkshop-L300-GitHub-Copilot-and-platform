@description('AI Services account name')
param name string

@description('Resource location')
param location string

@description('If true, reference an existing AI Services account')
param useExisting bool = false

@description('SKU for the AI Services account')
param skuName string = 'S0'

// ─── Existing reference ───────────────────────────────────────
resource existing 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = if (useExisting) {
  name: name
}

// ─── New resource ─────────────────────────────────────────────
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = if (!useExisting) {
  name: name
  location: location
  kind: 'AIServices'
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
  }
}

// GPT-4o model deployment (gpt-4 turbo deprecated Nov 2025)
resource gpt4o 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = if (!useExisting) {
  parent: aiServices
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-08-06'
    }
  }
}

// Phi model deployment
resource phi 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = if (!useExisting) {
  parent: aiServices
  name: 'phi-4'
  dependsOn: [gpt4o]
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4'
      version: '2'
    }
  }
}

output id string = useExisting ? existing.id : aiServices.id
output name string = useExisting ? existing.name : aiServices.name
output endpoint string = useExisting ? existing.properties.endpoint : aiServices.properties.endpoint
