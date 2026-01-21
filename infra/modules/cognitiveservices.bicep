@description('Name of the Cognitive Services account')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Tags for the resource')
param tags object = {}

@description('User-Assigned Managed Identity principal ID')
param managedIdentityPrincipalId string

@description('App Service System-Assigned Identity principal ID')
param appServicePrincipalId string

// Cognitive Services User role definition ID
var cognitiveServicesUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')

resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

// Grant Cognitive Services User role to User-Assigned Managed Identity
resource cognitiveServicesUserRoleAssignmentUAMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cognitiveServices.id, managedIdentityPrincipalId, cognitiveServicesUserRoleDefinitionId)
  scope: cognitiveServices
  properties: {
    principalId: managedIdentityPrincipalId
    roleDefinitionId: cognitiveServicesUserRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

// Grant Cognitive Services User role to App Service System-Assigned Identity
resource cognitiveServicesUserRoleAssignmentAppService 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cognitiveServices.id, appServicePrincipalId, cognitiveServicesUserRoleDefinitionId)
  scope: cognitiveServices
  properties: {
    principalId: appServicePrincipalId
    roleDefinitionId: cognitiveServicesUserRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

// GPT-4 Model Deployment
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: cognitiveServices
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0613'
    }
    raiPolicyName: 'Microsoft.Default'
  }
}

// Phi Model Deployment
resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: cognitiveServices
  name: 'phi-3-mini'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'phi-3-mini-128k-instruct'
      version: '1'
    }
    raiPolicyName: 'Microsoft.Default'
  }
  dependsOn: [
    gpt4Deployment
  ]
}

output id string = cognitiveServices.id
output name string = cognitiveServices.name
output endpoint string = cognitiveServices.properties.endpoint
