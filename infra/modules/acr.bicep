// Azure Container Registry (ACR) module
param location string

var acrNameClean = 'zavasacr${uniqueString(resourceGroup().id)}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrNameClean
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

output acrName string = acr.name
output acrId string = acr.id
output acrLoginServer string = acr.properties.loginServer
