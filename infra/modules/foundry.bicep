// Microsoft Foundry module for AI model hosting
@description('The Azure region for the resource')
param location string

@description('The name of the Microsoft Foundry resource')
param foundryName string

@description('Tags to apply to the resource')
param tags object = {}

@description('The SKU for the AI Foundry project')
param sku string = 'Basic'

// Create Azure AI Foundry Hub
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: '${foundryName}-hub'
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    description: 'AI Foundry Hub for ZavaStorefront - provides access to GPT-4 and Phi models'
    friendlyName: 'ZavaStorefront AI Hub'
    publicNetworkAccess: 'Enabled'
  }
}

// Create Azure AI Foundry Project
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: foundryName
  location: location
  tags: tags
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    description: 'AI Foundry Project for ZavaStorefront application'
    friendlyName: 'ZavaStorefront AI Project'
    hubResourceId: aiHub.id
    publicNetworkAccess: 'Enabled'
  }
}

// Outputs
output aiHubId string = aiHub.id
output aiHubName string = aiHub.name
output aiProjectId string = aiProject.id
output aiProjectName string = aiProject.name
output foundryName string = aiProject.name
output foundryEndpoint string = aiProject.properties.discoveryUrl
