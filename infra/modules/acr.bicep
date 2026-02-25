@description('Azure Container Registry name. Must be lowercase alphanumeric.')
param name string

@description('Resource location.')
param location string

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: name
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output id string = acr.id
output loginServer string = acr.properties.loginServer
