// Role Assignments Module
// Assigns AcrPull role to App Service managed identity for ACR access

@description('The principal ID of the App Service managed identity')
param principalId string

@description('The resource ID of the Azure Container Registry')
param acrId string

@description('The role definition ID for AcrPull')
param roleDefinitionId string = '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull built-in role

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, principalId, roleDefinitionId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

@description('The ID of the role assignment')
output roleAssignmentId string = acrPullRoleAssignment.id
