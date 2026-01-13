// App Service Plan (Linux) module
param name string
param location string = resourceGroup().location
param skuName string = 'B1'
param skuTier string = 'Basic'

resource plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: 'linux'
}

output planId string = plan.id
output planName string = plan.name
