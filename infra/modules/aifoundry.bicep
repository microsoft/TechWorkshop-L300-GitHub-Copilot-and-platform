@description('Azure AI Foundry hub name')
param aiHubName string

@description('Azure AI Foundry project name')
param aiProjectName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Log Analytics workspace resource ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources')
param tags object = {}

// Storage account required by AI Foundry hub
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

// Key Vault required by AI Foundry hub
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv${uniqueString(resourceGroup().id)}'
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

// AI Foundry Hub (Machine Learning Workspace kind: Hub)
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiHubName
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiHubName
    storageAccount: storage.id
    keyVault: keyVault.id
  }
}

// AI Foundry Project (Machine Learning Workspace kind: Project)
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiProjectName
  location: location
  tags: tags
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiProjectName
    hubResourceId: aiHub.id
  }
}

// GPT-4 model deployment via AIServices
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: '${aiHubName}-aiservices'
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: '${aiHubName}-aiservices'
    publicNetworkAccess: 'Enabled'
  }
}

resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
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
      version: '2024-11-20'
    }
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: aiServices
  name: 'phi-4'
  dependsOn: [gpt4Deployment]
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4'
      version: '2'
    }
  }
}

// ── Diagnostic Settings ──────────────────────────────────────────────────────
// Uses categoryGroup 'allLogs' to dynamically capture every available log
// category without hardcoding names that may vary by region or API version.

// AI Hub diagnostics
resource aiHubDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${aiHubName}-diagnostics'
  scope: aiHub
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { categoryGroup: 'allLogs', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}

// AI Project diagnostics
resource aiProjectDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${aiProjectName}-diagnostics'
  scope: aiProject
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { categoryGroup: 'allLogs', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}

// AI Services (Cognitive Services) diagnostics
resource aiServicesDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${aiHubName}-aiservices-diagnostics'
  scope: aiServices
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { categoryGroup: 'allLogs',  enabled: true }
      { categoryGroup: 'audit',    enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}

output aiHubId string = aiHub.id
output aiProjectId string = aiProject.id
output aiServicesEndpoint string = aiServices.properties.endpoint
output aiServicesId string = aiServices.id
