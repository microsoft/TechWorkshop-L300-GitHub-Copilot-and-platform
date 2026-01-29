@description('The location for the Microsoft Foundry resource')
param location string = resourceGroup().location

@description('The name of the Microsoft Foundry resource')
param foundryName string

@description('The SKU for the Microsoft Foundry resource')
param skuName string = 'S0'

@description('AI model deployments to create (empty array to skip model deployments)')
param modelDeployments array = []

@description('Tags to apply to the resource')
param tags object = {}

resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: foundryName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: foundryName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// Only create deployments if array is not empty
resource deployments 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for (deployment, i) in modelDeployments: if (length(modelDeployments) > 0) {
  parent: cognitiveServices
  name: deployment.name
  sku: deployment.sku
  properties: {
    model: deployment.model
  }
}]

@description('The resource ID of the Microsoft Foundry resource')
output foundryId string = cognitiveServices.id

@description('The name of the Microsoft Foundry resource')
output foundryName string = cognitiveServices.name

@description('The endpoint of the Microsoft Foundry resource')
output foundryEndpoint string = cognitiveServices.properties.endpoint
