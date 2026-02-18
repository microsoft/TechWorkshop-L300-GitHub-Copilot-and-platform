@description('The name of the Cognitive Services account')
param name string

@description('The location of the Cognitive Services account')
param location string

@description('Tags to apply to the Cognitive Services account')
param tags object = {}

@description('The SKU of the Cognitive Services account')
param sku string = 'S0'

// Azure OpenAI / Cognitive Services Account
resource cognitiveService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// GPT-4 deployment
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: cognitiveService
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0613'
    }
  }
}

// Phi model deployment (using gpt-35-turbo as Phi might not be directly available)
resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: cognitiveService
  name: 'phi-3'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '0613'
    }
  }
  dependsOn: [
    gpt4Deployment
  ]
}

output id string = cognitiveService.id
output name string = cognitiveService.name
output endpoint string = cognitiveService.properties.endpoint
output key string = cognitiveService.listKeys().key1
