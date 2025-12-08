@description('ACR module')
param name string
param location string = resourceGroup().location
param sku string = 'Standard'

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
  }
}

output registryId string = acr.id
output loginServer string = acr.properties.loginServer
