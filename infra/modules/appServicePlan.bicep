@description('Name of the App Service Plan')
param name string

@description('Location for the resource')
param location string

@description('SKU name for the App Service Plan')
param skuName string = 'B1'

@description('Tags to apply to the resource')
param tags object = {}

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

@description('The resource ID of the App Service Plan')
output id string = appServicePlan.id

@description('The name of the App Service Plan')
output name string = appServicePlan.name
