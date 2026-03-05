param location string
param tags object = {}

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: 'aif-zava-${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    publicNetworkAccess: 'Enabled'
    customSubDomainName: 'aif-zava-${uniqueString(resourceGroup().id)}'
  }
  tags: tags
}

resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'gpt-4o'
  sku: {
    name: 'GlobalStandard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20'
    }
  }
}


output aiServicesEndpoint string = aiServices.properties.endpoint
output aiServicesName string = aiServices.name
