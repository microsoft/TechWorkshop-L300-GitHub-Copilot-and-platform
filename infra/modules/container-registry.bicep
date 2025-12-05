// ============================================================================
// Azure Container Registry Module
// ============================================================================
// Purpose: Deploy Azure Container Registry for storing container images
// Security: Admin user disabled, uses managed identity for pulls
// ============================================================================

@description('The name of the Azure Container Registry')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('SKU for the container registry')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Basic'

@description('Tags for the resource')
param tags object = {}

// ============================================================================
// Resources
// ============================================================================

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false // Security: Use managed identity instead
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

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the container registry')
output resourceId string = containerRegistry.id

@description('The name of the container registry')
output name string = containerRegistry.name

@description('The login server URL of the container registry')
output loginServer string = containerRegistry.properties.loginServer
