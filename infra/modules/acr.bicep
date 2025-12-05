@description('Location for Azure Container Registry')
param location string

@description('Name of the Azure Container Registry')
param acrName string

@description('Tags to apply to resources')
param tags object = {}

@description('SKU for the Azure Container Registry')
param sku string = 'Basic'

@description('Enable admin user')
param adminUserEnabled bool = false

// Azure Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
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
      exportPolicy: {
        status: 'enabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
  }
}

// Outputs
output loginServer string = containerRegistry.properties.loginServer
output name string = containerRegistry.name
output resourceId string = containerRegistry.id
