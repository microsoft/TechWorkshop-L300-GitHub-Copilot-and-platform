@description('Name of the Azure Container Registry')
param acrName string

@description('Location for the Azure Container Registry')
param location string = resourceGroup().location

@description('SKU for the Azure Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Enable admin user for ACR')
param adminUserEnabled bool = true

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Enabled'
  }
}

output acrLoginServer string = acr.properties.loginServer
output acrName string = acr.name
output acrId string = acr.id
