// App Service Plan module
param resourceGroupName string
param location string
param sku string
param environment string

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-${environment}'
  location: location
  sku: {
    name: sku
    tier: 'Basic'
  }
  properties: {
    reserved: true // Linux
  }
}

output appServicePlanId string = appServicePlan.id
