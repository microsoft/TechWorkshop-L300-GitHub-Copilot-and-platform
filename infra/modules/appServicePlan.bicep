param name string
param location string
param sku string = 'B1'
param tags object = {}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: name
  location: location
  kind: 'linux'
  sku: {
    name: sku
    tier: startsWith(sku, 'P') ? 'PremiumV3' : startsWith(sku, 'S') ? 'Standard' : 'Basic'
    size: sku
    capacity: 1
  }
  tags: tags
  properties: {
    reserved: true
  }
}

output id string = plan.id
output name string = plan.name
