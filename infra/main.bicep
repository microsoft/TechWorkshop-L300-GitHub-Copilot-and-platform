targetScope = 'subscription'

@description('AZD environment name.')
param environmentName string

@description('Azure location for all resources.')
param location string

@description('Resource group name for the environment.')
param resourceGroupName string = 'rg-${environmentName}'

var resourceToken = uniqueString(subscription().id, location, environmentName)

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
}

module resources 'resources.bicep' = {
  name: 'deploy-${environmentName}'
  scope: resourceGroup
  params: {
    environmentName: environmentName
    location: location
    resourceToken: resourceToken
  }
}

output RESOURCE_GROUP_ID string = resourceGroup.id
output ACR_NAME string = resources.outputs.acrName
output ACR_LOGIN_SERVER string = resources.outputs.acrLoginServer
output AZURE_WEB_APP_NAME string = resources.outputs.webAppName
output AZURE_CLIENT_ID string = resources.outputs.userManagedIdentityClientId
output APPLICATIONINSIGHTS_CONNECTION_STRING string = resources.outputs.applicationInsightsConnectionString
output AZURE_AI_ENDPOINT string = resources.outputs.azureAiEndpoint
output AZURE_AI_GPT4_DEPLOYMENT string = resources.outputs.gpt4DeploymentName
output AZURE_AI_PHI_DEPLOYMENT string = resources.outputs.phiDeploymentName
