// Azure OpenAI Service with model deployments
@description('The name of the Azure OpenAI resource')
param openAiName string

@description('The location for the Azure OpenAI resource')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('The SKU for Azure OpenAI')
param sku string = 'S0'

@description('Deploy GPT-4 model')
param deployGpt4 bool = true

@description('GPT-4 deployment name')
param gpt4DeploymentName string = 'gpt-4o'

@description('GPT-4 model name')
param gpt4ModelName string = 'gpt-4o'

@description('GPT-4 model version')
param gpt4ModelVersion string = '2024-11-20'

@description('GPT-4 deployment capacity (TPM in thousands)')
param gpt4Capacity int = 10

@description('Deploy Phi-4 model')
param deployPhi bool = true

@description('Phi deployment name')
param phiDeploymentName string = 'Phi-4'

@description('Phi model name')
param phiModelName string = 'Phi-4'

@description('Phi model version')
param phiModelVersion string = '7'

@description('Phi deployment capacity')
param phiCapacity int = 1

resource openAiAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: openAiName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = if (deployGpt4) {
  parent: openAiAccount
  name: gpt4DeploymentName
  sku: {
    name: 'Standard'
    capacity: gpt4Capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gpt4ModelName
      version: gpt4ModelVersion
    }
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = if (deployPhi) {
  parent: openAiAccount
  name: phiDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: phiCapacity
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: phiModelName
      version: phiModelVersion
    }
  }
  dependsOn: [
    gpt4Deployment // Ensure sequential deployment to avoid conflicts
  ]
}

@description('The resource ID of the Azure OpenAI account')
output openAiId string = openAiAccount.id

@description('The endpoint of the Azure OpenAI account')
output openAiEndpoint string = openAiAccount.properties.endpoint

@description('The name of the Azure OpenAI account')
output openAiName string = openAiAccount.name

@description('The GPT-4 deployment name')
output gpt4DeploymentName string = deployGpt4 ? gpt4DeploymentName : ''

@description('The Phi deployment name')
output phiDeploymentName string = deployPhi ? phiDeploymentName : ''
