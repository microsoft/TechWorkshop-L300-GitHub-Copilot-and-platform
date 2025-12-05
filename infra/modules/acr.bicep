// Azure Container Registry Module
// For storing container images with managed identity access

@description('The name of the Container Registry (must be globally unique, alphanumeric only)')
param name string

@description('The location for the resource')
param location string = resourceGroup().location

@description('Tags for the resource')
param tags object = {}

@description('The SKU for the Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Standard'

@description('Enable admin user for the registry')
param adminUserEnabled bool = false

@description('Enable public network access')
param publicNetworkAccess string = 'Enabled'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: publicNetworkAccess
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
    networkRuleBypassOptions: 'AzureServices'
  }
}

@description('The resource ID of the Container Registry')
output id string = containerRegistry.id

@description('The name of the Container Registry')
output name string = containerRegistry.name

@description('The login server URL for the Container Registry')
output loginServer string = containerRegistry.properties.loginServer
