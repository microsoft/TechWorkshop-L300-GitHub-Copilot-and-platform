// Azure Container Registry for storing Docker images
@description('The name of the Azure Container Registry')
param acrName string

@description('The location for the Azure Container Registry')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('The SKU of the Azure Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
  }
}

@description('The resource ID of the Azure Container Registry')
output acrId string = containerRegistry.id

@description('The login server of the Azure Container Registry')
output loginServer string = containerRegistry.properties.loginServer

@description('The name of the Azure Container Registry')
output acrName string = containerRegistry.name
