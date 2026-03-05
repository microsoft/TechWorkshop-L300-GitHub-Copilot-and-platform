@description('Name of the Azure Container Registry')
param name string

@description('Location for the resource')
param location string

@description('SKU for the container registry')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Basic'

@description('Tags to apply to the resource')
param tags object = {}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    policies: {
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
    }
  }
}

@description('The resource ID of the container registry')
output id string = containerRegistry.id

@description('The name of the container registry')
output name string = containerRegistry.name

@description('The login server URL of the container registry')
output loginServer string = containerRegistry.properties.loginServer
