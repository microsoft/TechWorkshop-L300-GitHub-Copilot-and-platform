@description('Name of the Azure Container Registry')
param acrName string

@description('Location for the ACR')
param location string = resourceGroup().location

@description('SKU for the ACR')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Tags to apply to the ACR')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
  }
}

@description('The name of the ACR')
output acrName string = acr.name

@description('The resource ID of the ACR')
output acrId string = acr.id

@description('The login server of the ACR')
output acrLoginServer string = acr.properties.loginServer
