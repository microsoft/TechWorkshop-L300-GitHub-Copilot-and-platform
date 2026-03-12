@description('Name of the AI Foundry Hub workspace.')
param hubName string

@description('Name of the AI Foundry Project workspace.')
param projectName string

@description('Azure region. Must support GPT-4 and Phi models (e.g. westus3).')
param location string

@description('Resource tags.')
param tags object = {}

// ── AI Hub ──────────────────────────────────────────────────────────────────
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: hubName
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: 'ZavaStorefront AI Foundry Hub (dev)'
    friendlyName: 'Zava AI Hub'
    publicNetworkAccess: 'Enabled'
  }
}

// ── AI Project (child of Hub) ────────────────────────────────────────────────
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: projectName
  location: location
  tags: tags
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: 'ZavaStorefront AI Foundry Project (dev)'
    friendlyName: 'Zava AI Project'
    hubResourceId: aiHub.id
    publicNetworkAccess: 'Enabled'
  }
}

// ── GPT-4 model deployment ───────────────────────────────────────────────────
resource gpt4Deployment 'Microsoft.MachineLearningServices/workspaces/onlineEndpoints@2024-04-01' = {
  name: 'gpt-4'
  parent: aiProject
  location: location
  tags: tags
  kind: 'Managed'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    authMode: 'AMLToken'
    publicNetworkAccess: 'Enabled'
    description: 'GPT-4 endpoint for ZavaStorefront dev'
  }
}

// ── Phi-4 model deployment ───────────────────────────────────────────────────
resource phi4Deployment 'Microsoft.MachineLearningServices/workspaces/onlineEndpoints@2024-04-01' = {
  name: 'phi-4'
  parent: aiProject
  location: location
  tags: tags
  kind: 'Managed'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    authMode: 'AMLToken'
    publicNetworkAccess: 'Enabled'
    description: 'Phi-4 endpoint for ZavaStorefront dev'
  }
}

@description('Resource ID of the AI Hub.')
output hubId string = aiHub.id

@description('Resource ID of the AI Project.')
output projectId string = aiProject.id

@description('AI Project endpoint URI.')
output projectEndpoint string = 'https://${location}.api.azureml.ms'

@description('Name of the GPT-4 endpoint.')
output gpt4EndpointName string = gpt4Deployment.name

@description('Name of the Phi-4 endpoint.')
output phi4EndpointName string = phi4Deployment.name
