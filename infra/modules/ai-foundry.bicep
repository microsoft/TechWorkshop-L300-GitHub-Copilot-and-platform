// Azure AI Foundry (Cognitive Services / AI Services)
// Supports GPT-4 and Phi model deployments in westus3

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

@description('Name of the Azure AI Services account')
param aiServicesName string

// Azure AI Services (multi-service account supporting OpenAI models)
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: aiServicesName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// GPT-4o model deployment (current generation, available in westus3)
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'gpt-4o'
  sku: {
    name: 'GlobalStandard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20'
    }
  }
}

// Phi-4 model deployment (Microsoft format for westus3)
resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'phi-4'
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4'
      version: '7'
    }
  }
  dependsOn: [
    gpt4oDeployment // Serial deployment to avoid conflicts
  ]
}

// Outputs
output endpoint string = aiServices.properties.endpoint
output aiServicesName string = aiServices.name
output aiServicesId string = aiServices.id
