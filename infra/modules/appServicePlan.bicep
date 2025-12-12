@description('Name of the App Service Plan')
param appServicePlanName string

@description('Location for the App Service Plan')
param location string

@description('SKU for the App Service Plan (e.g., B1, P1v2, P1v3)')
param skuName string = 'B1'

@description('Environment name for tagging')
param environmentName string

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: skuName
  }
  properties: {
    reserved: true // Required for Linux
  }
  tags: {
    'azd-env-name': environmentName
  }
}

@description('The resource ID of the App Service Plan')
output id string = appServicePlan.id

@description('The name of the App Service Plan')
output name string = appServicePlan.name
