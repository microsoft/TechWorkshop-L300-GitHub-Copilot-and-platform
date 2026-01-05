// Role Assignment Module
@description('Principal ID to assign the role to')
param principalId string

@description('Role Definition ID (e.g., AcrPull)')
param roleDefinitionId string

@description('ACR Name')
param acrName string

// Reference the existing ACR
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, principalId, roleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

@description('The role assignment ID')
output roleAssignmentId string = roleAssignment.id
