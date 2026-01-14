// App Service Plan Bicep Module
param location string
param environment string

resource plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-${environment}'
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  kind: 'linux'
}

output planId string = plan.id
