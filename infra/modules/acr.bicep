@description('Name of the Azure Container Registry.')
param name string

@description('Azure region for the registry.')
param location string

@description('Resource tags.')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false   // RBAC-only pulls; no password-based access
    anonymousPullEnabled: false
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

@description('Login server URL for the registry (e.g. myregistry.azurecr.io).')
output loginServer string = acr.properties.loginServer

@description('Resource ID of the registry.')
output id string = acr.id

@description('Name of the registry.')
output name string = acr.name
