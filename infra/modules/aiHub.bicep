@description('The name of the AI Hub (Machine Learning Workspace)')
param name string

@description('The location for the AI Hub')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('The resource ID of the storage account')
param storageAccountId string

@description('The resource ID of the Key Vault')
param keyVaultId string

@description('The resource ID of Application Insights')
param applicationInsightsId string

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'Hub'
  properties: {
    friendlyName: name
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: applicationInsightsId
    publicNetworkAccess: 'Enabled'
  }
}

output id string = aiHub.id
output name string = aiHub.name
output principalId string = aiHub.identity.principalId
