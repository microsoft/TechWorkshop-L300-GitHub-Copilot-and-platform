param resourceName string
param location string

resource aiAccount 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: resourceName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: resourceName
    publicNetworkAccess: 'Enabled'
  }
}

output id string = aiAccount.id
output endpoint string = aiAccount.properties.endpoint
