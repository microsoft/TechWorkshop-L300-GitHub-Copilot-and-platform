@description('Azure AI Foundry/Azure OpenAI resource name.')
param name string

@description('Resource location.')
param location string

resource foundry 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: toLower(name)
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

output id string = foundry.id
output endpoint string = foundry.properties.endpoint
