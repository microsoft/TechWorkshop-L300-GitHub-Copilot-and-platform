@description('Foundry/OpenAI account name')
param name string

@description('Resource location')
param location string

resource foundry 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

output id string = foundry.id
output endpoint string = foundry.properties.endpoint
