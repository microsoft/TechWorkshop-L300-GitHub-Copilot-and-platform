@description('Principal ID to assign the role to')
param principalId string

@description('Principal type')
@allowed(['ServicePrincipal', 'User', 'Group'])
param principalType string = 'ServicePrincipal'

@description('The resource ID of the ACR')
param acrId string

// AcrPull role definition ID
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: last(split(acrId, '/'))
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, principalId, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: acrPullRoleDefinitionId
  }
}

@description('The resource ID of the role assignment')
output roleAssignmentId string = acrPullRoleAssignment.id
