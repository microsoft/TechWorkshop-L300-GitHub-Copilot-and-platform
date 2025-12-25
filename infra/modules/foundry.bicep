// Azure AI Foundry resource (CognitiveServices account with AIServices kind)
param location string
param environment string

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'zavastorefoundry${environment}'
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

var foundryKeys = listKeys(resourceId('Microsoft.CognitiveServices/accounts', foundryAccount.name), '2023-10-01-preview')

output foundryId string = foundryAccount.id
output foundryName string = foundryAccount.name
output foundryEndpoint string = foundryAccount.properties.endpoint
output foundryPrimaryKey string = foundryKeys.key1
