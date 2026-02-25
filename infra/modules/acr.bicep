targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Name of the Azure Container Registry. Must be globally unique, 5-50 alphanumeric characters.')
@minLength(5)
@maxLength(50)
param name string

param location string
param tags object

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    // No password-based admin access — managed identity (AcrPull) is used instead
    adminUserEnabled: false
    anonymousPullEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output loginServer string = acr.properties.loginServer
output name string = acr.name
output id string = acr.id
