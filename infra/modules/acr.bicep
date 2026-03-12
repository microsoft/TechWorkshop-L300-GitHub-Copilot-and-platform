@description('Globally unique name for Azure Container Registry')
param acrName string

@description('Azure region for the registry')
param location string

@description('Azure Container Registry SKU')
@allowed([
  'Basic'
  'Standard'
])
param sku string

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output acrResourceId string = acr.id
output loginServer string = acr.properties.loginServer
