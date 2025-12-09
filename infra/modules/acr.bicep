@description('Location for the Container Registry')
param location string

@description('Name of the Container Registry')
param containerRegistryName string

@description('SKU for the Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Tags for the resource')
param tags object = {}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false // Using RBAC instead
    publicNetworkAccess: 'Enabled'
    policies: {
      retentionPolicy: {
        status: 'disabled'
      }
    }
  }
}

output containerRegistryId string = containerRegistry.id
output containerRegistryName string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
