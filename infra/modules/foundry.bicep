@description('Name of the Azure AI Foundry resource')
param foundryName string

@description('Location for Azure AI Foundry')
param location string = resourceGroup().location

@description('SKU for Azure AI Foundry')
param sku string = 'S0'

@description('Tags to apply to Azure AI Foundry')
param tags object = {}

resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: foundryName
  location: location
  tags: tags
  kind: 'CognitiveServices'
  sku: {
    name: sku
  }
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
    customSubDomainName: foundryName
    publicNetworkAccess: 'Enabled'
  }
}

@description('The name of Azure AI Foundry')
output foundryName string = cognitiveServices.name

@description('The resource ID of Azure AI Foundry')
output foundryId string = cognitiveServices.id

@description('The endpoint of Azure AI Foundry')
output foundryEndpoint string = cognitiveServices.properties.endpoint
