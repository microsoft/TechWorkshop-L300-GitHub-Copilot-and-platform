targetScope = 'resourceGroup'

@description('AZD environment name.')
param environmentName string

@description('Azure location for all resources.')
param location string

@description('Stable unique token for resource naming.')
param resourceToken string

@description('App Service plan sku.')
param appServiceSku string = 'B1'

@description('Container image repository name in ACR.')
param imageRepository string = 'zavastorefront'

@description('Container image tag to deploy.')
param imageTag string = environmentName

@description('OpenAI deployment name for GPT-4.')
param gpt4DeploymentName string = 'gpt4'

@description('OpenAI deployment name for Phi.')
param phiDeploymentName string = 'phi'

@description('Model name used for GPT-4 deployment.')
param gpt4ModelName string = 'gpt-4'

@description('Model version used for GPT-4 deployment.')
param gpt4ModelVersion string = '0613'

@description('Model name used for Phi deployment.')
param phiModelName string = 'phi-4'

@description('Model version used for Phi deployment.')
param phiModelVersion string = '1'

@description('Set to true to create OpenAI model deployments in the account.')
param deployModelDeployments bool = false

@description('Optional role definition id for assigning Web App managed identity data-plane access to Azure AI account.')
param openAiRoleDefinitionId string = ''

@description('Set to true to deploy the Application Insights site extension.')
param deployAppInsightsSiteExtension bool = false

var acrName = 'azacr${resourceToken}'
var appServicePlanName = 'azasp${resourceToken}'
var webAppName = 'azapp${resourceToken}'
var userManagedIdentityName = 'azumi${resourceToken}'
var logAnalyticsWorkspaceName = 'azlaw${resourceToken}'
var applicationInsightsName = 'azapi${resourceToken}'
var azureAiAccountName = 'azcog${resourceToken}'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

resource userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: userManagedIdentityName
  location: location
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: appServiceSku
    tier: 'Basic'
    size: appServiceSku
    family: 'B'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userManagedIdentity.id}': {}
    }
  }
  tags: {
    'azd-service-name': 'web'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistry.properties.loginServer}/${imageRepository}:${imageTag}'
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: userManagedIdentity.properties.clientId
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: userManagedIdentity.properties.clientId
        }
        {
          name: 'AZURE_AI_ENDPOINT'
          value: azureAiAccount.properties.endpoint
        }
        {
          name: 'AZURE_AI_GPT4_DEPLOYMENT'
          value: gpt4DeploymentName
        }
        {
          name: 'AZURE_AI_PHI_DEPLOYMENT'
          value: phiDeploymentName
        }
      ]
    }
  }
}

resource appInsightsSiteExtension 'Microsoft.Web/sites/siteextensions@2024-04-01' = if (deployAppInsightsSiteExtension) {
  parent: webApp
  name: 'Microsoft.ApplicationInsights.AzureWebSites'
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, userManagedIdentity.id, 'acrpull')
  scope: containerRegistry
  properties: {
    principalId: userManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

resource azureAiAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: azureAiAccountName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: azureAiAccountName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = if (deployModelDeployments) {
  parent: azureAiAccount
  name: gpt4DeploymentName
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gpt4ModelName
      version: gpt4ModelVersion
    }
    versionUpgradeOption: 'NoAutoUpgrade'
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = if (deployModelDeployments) {
  parent: azureAiAccount
  name: phiDeploymentName
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: phiModelName
      version: phiModelVersion
    }
    versionUpgradeOption: 'NoAutoUpgrade'
  }
}

resource openAiRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(openAiRoleDefinitionId)) {
  name: guid(azureAiAccount.id, userManagedIdentity.id, openAiRoleDefinitionId)
  scope: azureAiAccount
  properties: {
    principalId: userManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', openAiRoleDefinitionId)
  }
}

output acrName string = containerRegistry.name
output acrLoginServer string = containerRegistry.properties.loginServer
output webAppName string = webApp.name
output userManagedIdentityClientId string = userManagedIdentity.properties.clientId
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString
output azureAiEndpoint string = azureAiAccount.properties.endpoint
output gpt4DeploymentName string = gpt4DeploymentName
output phiDeploymentName string = phiDeploymentName
