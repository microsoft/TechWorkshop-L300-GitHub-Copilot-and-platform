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

// GPT-4o Model Deployment (replaces deprecated GPT-4 0613)
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: cognitiveServices
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20'
    }
    raiPolicyName: 'Microsoft.Default'
  }
}

// GPT-4o-mini Model Deployment (cost-effective alternative)
resource gpt4oMiniDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: cognitiveServices
  name: 'gpt-4o-mini'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
    raiPolicyName: 'Microsoft.Default'
  }
  dependsOn: [
    gpt4oDeployment
  ]
}

output id string = cognitiveServices.id
output name string = cognitiveServices.name
output endpoint string = cognitiveServices.properties.endpoint
