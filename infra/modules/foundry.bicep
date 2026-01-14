// Microsoft Foundry Bicep Module (placeholder, update with actual resource type/SKU)
param location string
param environment string

resource foundry 'microsoft.cognitiveservices/accounts@2025-06-01'= {
  name: 'foundry-zavastorefront-${environment}-awilson2026'
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    allowProjectManagement: true
  }
  // Enable system-assigned managed identity for Foundry
  identity: {
    type: 'SystemAssigned'
  }
}

output foundryName string = foundry.name
output foundryId string = foundry.id
