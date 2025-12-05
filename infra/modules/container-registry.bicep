targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Base name for all resources')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('The SKU of the Container Registry')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Basic'

@description('Enable admin user for the Container Registry')
param adminUserEnabled bool = false

// ============================================================================
// VARIABLES
// ============================================================================

var resourceSuffix = take(uniqueString(subscription().id, resourceGroup().name, name), 6)
// ACR names must be alphanumeric only, 5-50 characters
var containerRegistryName = 'acr${replace(name, '-', '')}${resourceSuffix}'

// ============================================================================
// CONTAINER REGISTRY
// ============================================================================

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: containerRegistryName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Enabled'
    policies: {
      retentionPolicy: {
        status: 'disabled'
        days: 7
      }
      trustPolicy: {
        status: 'disabled'
        type: 'Notary'
      }
      quarantinePolicy: {
        status: 'disabled'
      }
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The name of the Container Registry')
output name string = containerRegistry.name

@description('The login server of the Container Registry')
output loginServer string = containerRegistry.properties.loginServer

@description('The resource ID of the Container Registry')
output resourceId string = containerRegistry.id
