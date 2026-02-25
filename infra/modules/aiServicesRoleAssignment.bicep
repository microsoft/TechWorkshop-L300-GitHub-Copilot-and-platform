// AI Services RBAC Role Assignment Module
// Grants a managed identity the Cognitive Services User role on AI Services

param principalId string
param aiServicesId string
param roleDefinitionId string = 'a97b65f3-24c7-4388-baec-2e87135dc908' // Cognitive Services User

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: split(aiServicesId, '/')[8]
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: aiServices
  name: guid(aiServices.id, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = roleAssignment.id
