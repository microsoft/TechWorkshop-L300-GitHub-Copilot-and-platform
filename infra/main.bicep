targetScope = 'resourceGroup'

@description('AZD environment name.')
param environmentName string

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('App Service plan SKU name.')
param appServiceSkuName string = 'B1'

@description('App Service plan SKU tier.')
param appServiceSkuTier string = 'Basic'

@description('Container image repository name in ACR.')
param containerImageName string = 'zavastorefront'

@description('Container image tag to deploy.')
param containerImageTag string = 'latest'

@description('Set true to attempt model deployment creation in Azure OpenAI.')
param deployModelDeployments bool = false

@description('GPT deployment name in Azure OpenAI.')
param gpt4DeploymentName string = 'gpt4'

@description('GPT model name to deploy when deployModelDeployments=true.')
param gpt4ModelName string = 'gpt-4o'

@description('GPT model version to deploy when deployModelDeployments=true.')
param gpt4ModelVersion string = '2024-08-06'

@description('Phi deployment name in Azure OpenAI.')
param phiDeploymentName string = 'phi'

@description('Phi model name to deploy when deployModelDeployments=true.')
param phiModelName string = 'phi-4'

@description('Phi model version to deploy when deployModelDeployments=true.')
param phiModelVersion string = '1'

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var planName = toLower('azasp${resourceToken}')
var webAppName = toLower('azapp${resourceToken}')
var acrName = toLower('azacr${resourceToken}')
var identityName = toLower('azid${resourceToken}')
var logAnalyticsName = toLower('azlog${resourceToken}')
var appInsightsName = toLower('azai${resourceToken}')
var openAiName = toLower('azoai${resourceToken}')

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  sku: {
    name: appServiceSkuName
    tier: appServiceSkuTier
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: logAnalytics.id
  }
}

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

resource openAiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAiName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openAiName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (deployModelDeployments) {
  parent: openAiAccount
  name: gpt4DeploymentName
  properties: {
    model: {
      format: 'OpenAI'
      name: gpt4ModelName
      version: gpt4ModelVersion
    }
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (deployModelDeployments) {
  parent: openAiAccount
  name: phiDeploymentName
  properties: {
    model: {
      format: 'OpenAI'
      name: phiModelName
      version: phiModelVersion
    }
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  tags: {
    'azd-service-name': 'ZavaStorefront'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistry.properties.loginServer}/${containerImageName}:${containerImageTag}'
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: managedIdentity.properties.clientId
      alwaysOn: false
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_PORT'
          value: '80'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
        }
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: 'https://${openAiAccount.name}.openai.azure.com/'
        }
        {
          name: 'AZURE_OPENAI_GPT4_DEPLOYMENT'
          value: gpt4DeploymentName
        }
        {
          name: 'AZURE_OPENAI_PHI_DEPLOYMENT'
          value: phiDeploymentName
        }
      ]
    }
  }
}

resource appServiceSiteExtension 'Microsoft.Web/sites/siteextensions@2023-12-01' = {
  name: 'ApplicationInsightsAgent'
  parent: webApp
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, managedIdentity.id, 'AcrPull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output RESOURCE_GROUP_ID string = resourceGroup().id
output ZavaStorefront_NAME string = webApp.name
output ZavaStorefront_URI string = 'https://${webApp.properties.defaultHostName}'
output ACR_NAME string = containerRegistry.name
output ACR_LOGIN_SERVER string = containerRegistry.properties.loginServer
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.properties.ConnectionString
output AZURE_OPENAI_NAME string = openAiAccount.name
output AZURE_OPENAI_ENDPOINT string = 'https://${openAiAccount.name}.openai.azure.com/'
