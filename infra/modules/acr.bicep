@description('Azure Container Registry name')
param name string

@description('Resource location')
param location string

@description('ACR SKU')
param sku string

resource acr 'Microsoft.ContainerRegistry/registries@2025-03-01-preview' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output id string = acr.id
output name string = acr.name
output loginServer string = acr.properties.loginServer
