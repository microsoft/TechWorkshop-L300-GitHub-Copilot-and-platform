param resourceName string
param location string

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: resourceName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

output id string = plan.id
