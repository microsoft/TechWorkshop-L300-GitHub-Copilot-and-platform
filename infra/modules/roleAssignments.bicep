@description('The resource ID of the Azure Container Registry')
param containerRegistryId string

@description('The principal ID to assign the role to')
param principalId string

@description('The type of principal (ServicePrincipal, User, Group)')
param principalType string = 'ServicePrincipal'

// AcrPull role definition ID (built-in Azure role)
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: last(split(containerRegistryId, '/'))
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(containerRegistry.id, principalId, acrPullRoleDefinitionId)
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}

@description('The resource ID of the role assignment')
output roleAssignmentId string = acrPullRoleAssignment.id
