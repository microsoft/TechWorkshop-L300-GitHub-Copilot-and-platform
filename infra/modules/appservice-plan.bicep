@description('App Service Plan name')
param name string

@description('Resource location')
param location string

@description('App Service Plan SKU name')
param skuName string

resource appServicePlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: name
  location: location
  sku: {
    name: skuName
    tier: skuName == 'B1' ? 'Basic' : 'PremiumV3'
    size: skuName
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

output id string = appServicePlan.id
