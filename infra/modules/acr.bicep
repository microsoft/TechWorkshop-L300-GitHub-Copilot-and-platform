// Azure Container Registry (ACR) module
param name string
param location string
param sku string = 'Basic'
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
  }
}
output acrId string = acr.id
output acrLoginServer string = acr.properties.loginServer
