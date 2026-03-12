@description('Name of the target Azure Container Registry.')
param acrName string

@description('Managed identity principal ID to grant AcrPull.')
param principalId string

@description('Role definition GUID for AcrPull.')
param acrPullRoleDefinitionGuid string = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, principalId, acrPullRoleDefinitionGuid)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleDefinitionGuid)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

output id string = acrPullAssignment.id
