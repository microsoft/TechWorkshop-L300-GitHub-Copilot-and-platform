// AI Foundry Module
// Provisions Azure AI Foundry Hub and Project with GPT-4 and Phi model deployments

@description('Name of the Azure AI Foundry Hub')
param aiHubName string

@description('Name of the Azure AI Project')
param aiProjectName string

@description('Name of the Azure AI Services (Cognitive Services) account')
param aiServicesName string

@description('Azure region - must support GPT-4 and Phi models (westus3 recommended)')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Azure AI Services (multi-service account backing Foundry)
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: aiServicesName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    customSubDomainName: aiServicesName
  }
}

// GPT-4o deployment
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
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

// Phi-4 deployment
resource phi4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: aiServices
  name: 'Phi-4'
  dependsOn: [gpt4Deployment]
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

// AI Foundry Hub
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-07-01-preview' = {
  name: aiHubName
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    friendlyName: aiHubName
    publicNetworkAccess: 'Enabled'
  }
}

// AI Foundry Project
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-07-01-preview' = {
  name: aiProjectName
  location: location
  tags: tags
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    friendlyName: aiProjectName
    hubResourceId: aiHub.id
    publicNetworkAccess: 'Enabled'
  }
}

output aiServicesId string = aiServices.id
output aiServicesEndpoint string = aiServices.properties.endpoint
output aiHubId string = aiHub.id
output aiProjectId string = aiProject.id
