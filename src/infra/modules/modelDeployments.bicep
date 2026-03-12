@description('Name of the Azure AI Services (Foundry) account.')
param accountName string

@description('Deployment name for GPT model.')
param gptDeploymentName string = 'gpt-4o'

@description('OpenAI model name for GPT deployment.')
param gptModelName string = 'gpt-4o'

@description('OpenAI model version for GPT deployment.')
param gptModelVersion string = '2024-11-20'

@description('Deployment SKU for GPT model.')
@allowed([
  'Standard'
  'GlobalStandard'
  'DataZoneStandard'
  'GlobalProvisioned'
  'Provisioned'
  'ProvisionedManaged'
  'GlobalProvisionedManaged'
  'DataZoneProvisionedManaged'
])
param gptSkuName string = 'Standard'

@description('Deployment capacity for GPT model.')
param gptCapacity int = 10

@description('Deployment name for Phi model.')
param phiDeploymentName string = 'phi-4'

@description('Microsoft model name for Phi deployment.')
param phiModelName string = 'Phi-4'

@description('Microsoft model version for Phi deployment.')
param phiModelVersion string = '7'

@description('Deployment SKU for Phi model. In this account, GlobalStandard is available.')
@allowed([
  'GlobalStandard'
])
param phiSkuName string = 'GlobalStandard'

@description('Deployment capacity for Phi model.')
param phiCapacity int = 1

@description('Responsible AI policy name.')
param raiPolicyName string = 'Microsoft.DefaultV2'

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: accountName
}

resource gptDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: account
  name: gptDeploymentName
  sku: {
    name: gptSkuName
    capacity: gptCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gptModelName
      version: gptModelVersion
    }
    raiPolicyName: raiPolicyName
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: account
  name: phiDeploymentName
  sku: {
    name: phiSkuName
    capacity: phiCapacity
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: phiModelName
      version: phiModelVersion
    }
    raiPolicyName: raiPolicyName
  }
  dependsOn: [
    gptDeployment
  ]
}

output gptDeploymentId string = gptDeployment.id
output phiDeploymentId string = phiDeployment.id
