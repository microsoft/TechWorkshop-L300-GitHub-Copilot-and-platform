@description('The name of the AI Project (Machine Learning Workspace)')
param name string

@description('The location for the AI Project')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('The resource ID of the AI Hub')
param aiHubId string

resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'Project'
  properties: {
    friendlyName: name
    hubResourceId: aiHubId
    publicNetworkAccess: 'Enabled'
  }
}

output id string = aiProject.id
output name string = aiProject.name
output principalId string = aiProject.identity.principalId
