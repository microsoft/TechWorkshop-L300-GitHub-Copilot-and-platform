@description('Name of the Azure AI Services account')
param name string

@description('Location for the resource')
param location string

@description('SKU for the AI Services account')
param sku string = 'S0'

@description('Tags to apply to the resource')
param tags object = {}

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// GPT-4o model deployment
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-08-06'
    }
    raiPolicyName: 'Microsoft.Default'
  }
}

@description('The resource ID of the AI Services account')
output id string = aiServices.id

@description('The name of the AI Services account')
output name string = aiServices.name

@description('The endpoint URL for the AI Services account')
output endpoint string = aiServices.properties.endpoint

@description('The principal ID of the AI Services managed identity')
output principalId string = aiServices.identity.principalId
