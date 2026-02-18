// Microsoft Foundry Module
// Creates Azure AI Foundry workspace with GPT-4 and Phi model deployments

@description('The name of the Foundry workspace')
param name string

@description('The location for the Foundry workspace')
param location string = 'westus3'

@description('Tags to apply to the resources')
param tags object = {}

@description('The name of the storage account for Foundry')
param storageAccountName string

@description('The name of the Key Vault for Foundry')
param keyVaultName string

@description('The Application Insights resource ID')
param appInsightsId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
  }
}

resource foundryWorkspace 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  kind: 'Hub'
  properties: {
    friendlyName: name
    storageAccount: storageAccount.id
    keyVault: keyVault.id
    applicationInsights: appInsightsId
    publicNetworkAccess: 'Enabled'
    description: 'Azure AI Foundry workspace for ZavaStorefront with GPT-4 and Phi models'
  }
}

// Note: Model deployments (GPT-4, Phi) are typically created through Azure AI Studio
// or using the Azure ML SDK/REST API after the workspace is provisioned

@description('The resource ID of the Foundry workspace')
output id string = foundryWorkspace.id

@description('The name of the Foundry workspace')
output name string = foundryWorkspace.name

@description('The discovery URL for the Foundry workspace')
output discoveryUrl string = foundryWorkspace.properties.discoveryUrl

@description('The principal ID of the Foundry managed identity')
output principalId string = foundryWorkspace.identity.principalId
