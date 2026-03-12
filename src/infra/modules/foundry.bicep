@description('Microsoft Foundry (AIServices) resource name.')
param foundryName string

@description('Azure location for Foundry resource.')
param location string

@description('SKU for Foundry resource.')
param skuName string = 'S0'

@description('Disable public network access when true.')
param disablePublicNetworkAccess bool = false

resource foundry 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: foundryName
  location: location
  kind: 'AIServices'
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: foundryName
    disableLocalAuth: true
    publicNetworkAccess: disablePublicNetworkAccess ? 'Disabled' : 'Enabled'
  }
}

output id string = foundry.id
output endpoint string = foundry.properties.endpoint
