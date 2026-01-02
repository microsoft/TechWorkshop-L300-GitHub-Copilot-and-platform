// Microsoft Foundry (Azure AI Services) Module
@description('Name of the Foundry resource')
param aiFoundryName string

@description('Name of the Foundry project')
param aiProjectName string

@description('Location for the Foundry resource')
param location string = resourceGroup().location

@description('Tags for the resource')
param tags object = {}

@description('Deployments to create')
param deployments array = []

resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-10-01-preview' = {
  name: aiFoundryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  tags: tags
  properties: {
    customSubDomainName: aiFoundryName
    publicNetworkAccess: 'Enabled'
    allowProjectManagement: true
    defaultProject: aiProjectName
    associatedProjects: [
      aiProjectName
    ]
  }
}

resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-10-01-preview' = {
  name: aiProjectName
  parent: aiFoundry
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2025-10-01-preview' = [for item in deployments: {
  parent: aiFoundry
  name: item.name
  sku: {
    name: item.sku
    capacity: item.capacity
  }
  properties: {
    model: {
      format: item.format
      name: item.model
      version: item.version
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    raiPolicyName: 'Microsoft.DefaultV2'
    currentCapacity: item.capacity
  }
  dependsOn: [
    aiProject
  ]
}]

@description('The endpoint of the Azure Foundry resource')
output endpoint string = aiFoundry.properties.endpoint

@description('The resource ID of the Azure Foundry resource')
output foundryId string = aiFoundry.id

@description('The name of the Azure Foundry resource')
output foundryName string = aiFoundry.name
