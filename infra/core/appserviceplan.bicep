@description('The name of the App Service Plan')
param name string

@description('The location of the App Service Plan')
param location string

@description('Tags to apply to the App Service Plan')
param tags object = {}

@description('The kind of App Service Plan')
@allowed([
  'linux'
  'windows'
])
param kind string = 'linux'

@description('The SKU of the App Service Plan')
param sku object = {
  name: 'B1'
  tier: 'Basic'
  capacity: 1
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    reserved: kind == 'linux' ? true : false
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
