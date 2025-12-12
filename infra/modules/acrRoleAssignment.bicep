targetScope = 'resourceGroup'

@description('Name of the Container Registry (must exist in the same resource group)')
param containerRegistryName string

@description('Principal ID of the App Service managed identity for AcrPull role')
param principalId string

var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

// Reference existing ACR in the current resource group
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-06-01-preview' existing = {
  name: containerRegistryName
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, acrPullRoleId, principalId)
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

@description('Role assignment ID')
output id string = acrPullRoleAssignment.id
