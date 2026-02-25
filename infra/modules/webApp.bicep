// Linux Web App for hosting containerized application
@description('The name of the Web App')
param webAppName string

@description('The location for the Web App')
param location string = resourceGroup().location

@description('The resource ID of the App Service Plan')
param appServicePlanId string

@description('The login server of the Azure Container Registry')
param acrLoginServer string

@description('The Application Insights connection string')
param applicationInsightsConnectionString string

@description('The Azure OpenAI endpoint')
param openAiEndpoint string = ''

@description('The name of the GPT-4 deployment')
param gpt4DeploymentName string = 'gpt-4o'

@description('The name of the Phi deployment')
param phiDeploymentName string = 'Phi-4'

@description('The container image name and tag')
param containerImageName string = 'zava-storefront:latest'

@description('Tags to apply to the resource')
param tags object = {}

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${containerImageName}'
      alwaysOn: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'Recommended'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'AzureOpenAI__Endpoint'
          value: openAiEndpoint
        }
        {
          name: 'AzureOpenAI__Gpt4DeploymentName'
          value: gpt4DeploymentName
        }
        {
          name: 'AzureOpenAI__PhiDeploymentName'
          value: phiDeploymentName
        }
      ]
      healthCheckPath: '/health'
    }
  }
}

@description('The resource ID of the Web App')
output webAppId string = webApp.id

@description('The default hostname of the Web App')
output webAppHostName string = webApp.properties.defaultHostName

@description('The URL of the Web App')
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'

@description('The principal ID of the Web App managed identity')
output webAppPrincipalId string = webApp.identity.principalId

@description('The name of the Web App')
output webAppName string = webApp.name
