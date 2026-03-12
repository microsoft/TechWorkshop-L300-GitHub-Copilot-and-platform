@description('Name of the App Service Plan')
param planName string

@description('Azure region for App Service Plan')
param location string

@description('SKU for App Service Plan')
param skuName string

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  sku: {
    name: skuName
    tier: 'Basic'
    size: skuName
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

output planResourceId string = appServicePlan.id
output planName string = appServicePlan.name
