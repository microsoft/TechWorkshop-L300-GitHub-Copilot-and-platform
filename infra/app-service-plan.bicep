param environmentName string
param location string = resourceGroup().location

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var appServicePlanName = 'azasp${resourceToken}'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: true // for Linux
  }
}

output appServicePlanId string = appServicePlan.id
output appServicePlanName string = appServicePlan.name