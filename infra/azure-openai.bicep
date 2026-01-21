param environmentName string
param location string = resourceGroup().location

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var openAiName = 'azaio${resourceToken}'

resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAiName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openAiName
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

output openAiEndpoint string = openAi.properties.endpoint
