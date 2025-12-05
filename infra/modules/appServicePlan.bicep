// ============================================================================
// App Service Plan Module
// Provides Linux hosting plan for containerized web applications
// ============================================================================

@description('Name of the App Service Plan')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('SKU name for the App Service Plan')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
  'P1v3'
  'P2v3'
  'P3v3'
])
param skuName string = 'B1'

@description('Number of workers for the App Service Plan')
param skuCapacity int = 1

// Deploy App Service Plan using Azure Verified Module
module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'appServicePlanDeployment'
  params: {
    name: name
    location: location
    tags: tags
    skuName: skuName
    skuCapacity: skuCapacity
    kind: 'linux'
    reserved: true // Required for Linux
    zoneRedundant: false // Dev environment
  }
}

// Outputs
@description('The resource ID of the App Service Plan')
output resourceId string = appServicePlan.outputs.resourceId

@description('The name of the App Service Plan')
output name string = appServicePlan.outputs.name
