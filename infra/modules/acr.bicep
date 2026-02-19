@description('Name of the Azure Container Registry')
param acrName string

@description('Location for the Azure Container Registry')
param location string = resourceGroup().location

@description('SKU for the Azure Container Registry (Basic, Standard, or Premium)')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Tags to apply to the resource')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false // Use RBAC instead of admin credentials
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
  }
}

@description('The name of the Azure Container Registry')
output acrName string = acr.name

@description('The login server of the Azure Container Registry')
output acrLoginServer string = acr.properties.loginServer

@description('The resource ID of the Azure Container Registry')
output acrId string = acr.id
