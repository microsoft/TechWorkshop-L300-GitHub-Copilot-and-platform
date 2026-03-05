// ACR Pull Role Assignment
// Grants the App Service managed identity permission to pull images from ACR
// Uses built-in AcrPull role (7f951dda-4ed3-4680-a7ca-43fe172d538d)

@description('Name of the existing Container Registry')
param containerRegistryName string

@description('Principal ID of the App Service managed identity')
param principalId string

// Built-in AcrPull role definition ID
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// Reference existing ACR
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

// Role Assignment — AcrPull for App Service identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, principalId, acrPullRoleDefinitionId)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
