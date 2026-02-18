@description('The name of the App Service Plan')
param name string

@description('The location for the App Service Plan')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('The SKU for the App Service Plan')
param sku object = {
  name: 'B1'
  tier: 'Basic'
}

@description('The kind of App Service Plan (linux or windows)')
param kind string = 'linux'

@description('Whether the App Service Plan is reserved (true for Linux)')
param reserved bool = true

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    reserved: reserved
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
