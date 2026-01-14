// Azure Container Registry (ACR) Bicep Module
param location string

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'acrawilson2026'
  location: location
  sku: {
    name: 'Basic'
  }
}

output acrName string = acr.name
output loginServer string = acr.properties.loginServer
