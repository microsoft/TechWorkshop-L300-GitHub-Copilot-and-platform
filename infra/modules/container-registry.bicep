// Azure Container Registry (ACR)
// Basic SKU for dev environment

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

@description('Name of the Container Registry (alphanumeric only, globally unique)')
param containerRegistryName string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false // No admin credentials — use RBAC only
    publicNetworkAccess: 'Enabled'
  }
}

// Outputs
output name string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
output id string = containerRegistry.id
