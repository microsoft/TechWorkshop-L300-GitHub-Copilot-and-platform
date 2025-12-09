@description('Location for the Azure AI Foundry resources')
param location string

@description('Name of the Azure AI Foundry account')
param aiFoundryAccountName string

@description('Tags for the resources')
param tags object = {}

// Azure OpenAI / AI Foundry Account
resource aiFoundryAccount 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: aiFoundryAccountName
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: aiFoundryAccountName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// GPT-4o Deployment (available in westus3)
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: aiFoundryAccount
  name: 'gpt-4o'
  sku: {
    name: 'GlobalStandard'
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

// GPT-4o-mini Deployment (as alternative to Phi, available in westus3)
resource gpt4oMiniDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: aiFoundryAccount
  name: 'gpt-4o-mini'
  sku: {
    name: 'GlobalStandard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
    raiPolicyName: 'Microsoft.Default'
  }
  dependsOn: [
    gpt4oDeployment // Deploy sequentially to avoid conflicts
  ]
}

output accountId string = aiFoundryAccount.id
output accountName string = aiFoundryAccount.name
output endpoint string = aiFoundryAccount.properties.endpoint
output gpt4oDeploymentName string = gpt4oDeployment.name
output gpt4oMiniDeploymentName string = gpt4oMiniDeployment.name
