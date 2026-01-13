// Microsoft Foundry module
param name string
param location string = resourceGroup().location
param sku string = 'Standard'

resource foundry 'Microsoft.Foundry/accounts@2023-01-01-preview' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    // Add model configuration as needed
  }
}

output foundryId string = foundry.id
output foundryName string = foundry.name
