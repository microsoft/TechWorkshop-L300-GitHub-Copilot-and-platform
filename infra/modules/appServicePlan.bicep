@description('App Service Plan (Linux)')
param name string
param location string = resourceGroup().location
param skuName string = 'B1'
param skuTier string = 'Basic'

resource plan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: name
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    reserved: true // for Linux
  }
}

output serverFarmId string = plan.id
