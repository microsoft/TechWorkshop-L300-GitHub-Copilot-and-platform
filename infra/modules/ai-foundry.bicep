targetScope = 'resourceGroup'

@description('Name of the Azure AI Services account')
param name string

@description('Name of the AI Foundry Hub')
param hubName string

@description('Name of the AI Foundry Project')
param projectName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('GPT-4 model deployment capacity')
param gpt4Capacity int = 10

@description('Phi model deployment capacity')
param phiCapacity int = 10

// Azure AI Services account (multi-service)
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
  }
}

// GPT-4o model deployment
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'gpt-4o'
  sku: {
    name: 'GlobalStandard'
    capacity: gpt4Capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-08-06'
    }
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}

// Phi-4 model deployment (deployed after GPT-4o to avoid conflicts)
resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'Phi-4'
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
    raiPolicyName: 'Microsoft.DefaultV2'
  }
  dependsOn: [
    gpt4Deployment
  ]
}

// AI Foundry Hub
resource hub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: hubName
  location: location
  tags: tags
  kind: 'Hub'
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'ZavaStorefront AI Hub'
    description: 'AI Foundry Hub for ZavaStorefront application'
  }
}

// AI Foundry Hub connection to AI Services
resource hubConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-10-01' = {
  parent: hub
  name: '${name}-connection'
  properties: {
    category: 'AIServices'
    authType: 'AAD'
    isSharedToAll: true
    target: aiServices.properties.endpoint
    metadata: {
      ApiType: 'Azure'
      ResourceId: aiServices.id
    }
  }
}

// AI Foundry Project
resource project 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: projectName
  location: location
  tags: tags
  kind: 'Project'
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'ZavaStorefront AI Project'
    description: 'AI Foundry Project for ZavaStorefront application'
    hubResourceId: hub.id
  }
}

output aiServicesEndpoint string = aiServices.properties.endpoint
output aiServicesName string = aiServices.name
output hubName string = hub.name
output projectName string = project.name
