@description('Azure Container Registry name')
param acrName string

@description('Principal object ID that receives the role')
param principalId string

@description('Principal type')
param principalType string

@description('Role definition resource ID')
param roleDefinitionId string

resource scopeResource 'Microsoft.ContainerRegistry/registries@2025-03-01-preview' existing = {
  name: acrName
}

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(scopeResource.id, principalId, roleDefinitionId)
  scope: scopeResource
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: roleDefinitionId
  }
}

output id string = acrPullAssignment.id
