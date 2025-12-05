@description('The name of the App Service Plan')
param name string

@description('The location of the App Service Plan')
param location string = resourceGroup().location

@description('The SKU name for the App Service Plan')
param skuName string = 'B1'

@description('The SKU capacity (number of instances)')
@minValue(1)
@maxValue(10)
param skuCapacity int = 1

@description('The kind of App Service Plan (linux for Linux-based plans)')
@allowed(['app', 'linux', 'functionapp'])
param kind string = 'linux'

@description('Reserved flag - must be true for Linux plans')
param reserved bool = true

@description('Tags to apply to the App Service Plan')
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    reserved: reserved
  }
}

@description('The resource ID of the App Service Plan')
output resourceId string = appServicePlan.id

@description('The name of the App Service Plan')
output name string = appServicePlan.name

@description('The location of the App Service Plan')
output location string = appServicePlan.location
