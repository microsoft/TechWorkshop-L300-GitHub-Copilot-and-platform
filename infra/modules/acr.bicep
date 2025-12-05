// =========================================================================
// Azure Container Registry Module
// =========================================================================

@description('Name of the Azure Container Registry')
param name string

@description('Azure region for the ACR')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('SKU for the container registry')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Basic'

@description('Enable admin user for the registry')
param adminUserEnabled bool = false

// -------------------------------------------------------------------------
// Resource - Azure Container Registry
// -------------------------------------------------------------------------

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Enabled'
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
  }
}

// -------------------------------------------------------------------------
// Outputs
// -------------------------------------------------------------------------

@description('The name of the container registry')
output name string = containerRegistry.name

@description('The resource ID of the container registry')
output resourceId string = containerRegistry.id

@description('The login server URL of the container registry')
output loginServer string = containerRegistry.properties.loginServer
