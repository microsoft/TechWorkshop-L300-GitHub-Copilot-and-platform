// Azure Container Registry (ACR) module
param resourceGroupName string
param location string
param sku string
param environment string

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'acr${uniqueString(resourceGroup().id, environment)}'
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
  }
}

output loginServer string = acr.properties.loginServer
output acrResourceId string = acr.id
