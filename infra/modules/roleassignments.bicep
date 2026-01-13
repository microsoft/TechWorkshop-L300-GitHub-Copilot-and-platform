// Role Assignments module - Assigns AcrPull role to App Service managed identity
@description('The name of the Azure Container Registry')
param acrName string

@description('The principal ID of the App Service managed identity')
param appServicePrincipalId string

// Reference existing ACR
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
}

// AcrPull role definition ID (built-in Azure role)
// See: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// Assign AcrPull role to App Service managed identity on ACR scope
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, appServicePrincipalId, acrPullRoleDefinitionId)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output roleAssignmentId string = roleAssignment.id
output roleDefinitionId string = acrPullRoleDefinitionId
