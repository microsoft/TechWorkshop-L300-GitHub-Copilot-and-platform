// App Service Plan module
@description('Name of the App Service Plan')
param name string

@description('Location for the App Service Plan')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('SKU for the App Service Plan')
param sku object = {
  name: 'B1'
  tier: 'Basic'
  size: 'B1'
  family: 'B'
  capacity: 1
}

@description('Kind of App Service Plan')
param kind string = 'linux'

@description('Reserved for Linux')
param reserved bool = true

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  kind: kind
  properties: {
    reserved: reserved
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
