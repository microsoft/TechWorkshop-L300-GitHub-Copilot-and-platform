@description('Name of the App Service Plan.')
param name string

@description('Azure region for the plan.')
param location string

@description('Resource tags.')
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: name
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  properties: {
    reserved: true  // Required for Linux plans
  }
}

@description('Resource ID of the App Service Plan.')
output id string = appServicePlan.id

@description('Name of the App Service Plan.')
output name string = appServicePlan.name
