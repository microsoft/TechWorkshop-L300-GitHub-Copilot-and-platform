// Azure Container Registry Module
// Creates ACR with managed identity authentication (no admin user)

@description('The name of the Azure Container Registry')
param name string

@description('The location for the ACR resource')
param location string = resourceGroup().location

@description('The SKU for the ACR')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Tags to apply to the ACR resource')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false // Enforce managed identity authentication
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
    policies: {
      retentionPolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        status: 'disabled'
      }
    }
  }
}

@description('The name of the ACR')
output name string = acr.name

@description('The login server URL for the ACR')
output loginServer string = acr.properties.loginServer

@description('The resource ID of the ACR')
output id string = acr.id
