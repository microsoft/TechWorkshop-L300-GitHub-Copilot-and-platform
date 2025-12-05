// ============================================================================
// Azure Container Registry Module
// Provides container image storage with managed identity access
// ============================================================================

@description('Name of the Azure Container Registry')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('SKU for the Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Basic'

@description('Enable admin user for the registry')
param adminUserEnabled bool = false

@description('Enable anonymous pull access')
param anonymousPullEnabled bool = false

// Deploy Azure Container Registry using Azure Verified Module
module containerRegistry 'br/public:avm/res/container-registry/registry:0.8.0' = {
  name: 'acrDeployment'
  params: {
    name: name
    location: location
    tags: tags
    acrSku: skuName
    acrAdminUserEnabled: adminUserEnabled
    anonymousPullEnabled: anonymousPullEnabled
  }
}

// Outputs
@description('The resource ID of the Container Registry')
output resourceId string = containerRegistry.outputs.resourceId

@description('The name of the Container Registry')
output name string = containerRegistry.outputs.name

@description('The login server of the Container Registry')
output loginServer string = containerRegistry.outputs.loginServer
