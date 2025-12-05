// ============================================================================
// App Service Plan Module
// ============================================================================
// Purpose: Deploy Linux App Service Plan for container hosting
// Configuration: Linux containers require reserved=true and kind='linux'
// ============================================================================

@description('The name of the App Service Plan')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('SKU name for the App Service Plan')
@allowed(['B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1v2', 'P2v2', 'P3v2', 'P1v3', 'P2v3', 'P3v3'])
param skuName string = 'B1'

@description('Tags for the resource')
param tags object = {}

// ============================================================================
// Resources
// ============================================================================

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: skuName
  }
  properties: {
    reserved: true // Required for Linux
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the App Service Plan')
output resourceId string = appServicePlan.id

@description('The name of the App Service Plan')
output name string = appServicePlan.name
