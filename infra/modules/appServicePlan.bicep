// App Service Plan module
param location string
param environment string

resource plan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'zavastoreplan${environment}'
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

output planId string = plan.id
