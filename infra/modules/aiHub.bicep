@description('Name of the AI Hub (Microsoft Foundry)')
param aiHubName string

@description('Location for the AI Hub')
param location string = resourceGroup().location

@description('Display name for the AI Hub')
param displayName string = 'ZavaStorefront AI Hub'

@description('Description for the AI Hub')
param description string = 'AI Hub for ZavaStorefront application with GPT-4 and Phi models'

@description('Tags to apply to the resource')
param tags object = {}

@description('Storage account ID for the AI Hub')
param storageAccountId string = ''

@description('Key Vault ID for the AI Hub')
param keyVaultId string = ''

@description('Application Insights ID for the AI Hub')
param appInsightsId string = ''

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiHubName
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: displayName
    description: description
    storageAccount: !empty(storageAccountId) ? storageAccountId : null
    keyVault: !empty(keyVaultId) ? keyVaultId : null
    applicationInsights: !empty(appInsightsId) ? appInsightsId : null
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

@description('The resource ID of the AI Hub')
output aiHubId string = aiHub.id

@description('The name of the AI Hub')
output aiHubName string = aiHub.name

@description('The principal ID of the system-assigned managed identity')
output principalId string = aiHub.identity.principalId
