@description('Name of the Web App.')
param name string

@description('Azure region.')
param location string

@description('Resource ID of the App Service Plan.')
param appServicePlanId string

@description('Login server of the Azure Container Registry (e.g. myregistry.azurecr.io).')
param acrLoginServer string

@description('Full container image reference including tag (e.g. myregistry.azurecr.io/zava-storefront:latest).')
param containerImage string

@description('Application Insights connection string.')
param appInsightsConnectionString string

@description('Resource tags.')
param tags object = {}

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'  // Used for AcrPull role assignment — no registry passwords
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerImage}'
      alwaysOn: false  // Save cost on dev
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        // NOTE: No DOCKER_REGISTRY_SERVER_USERNAME or DOCKER_REGISTRY_SERVER_PASSWORD.
        // The Web App uses its system-assigned managed identity + AcrPull role instead.
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
        }
        {
          name: 'ASPNETCORE_URLS'
          value: 'http://+:8080'
        }
      ]
    }
  }
}

@description('Default hostname of the Web App.')
output defaultHostname string = webApp.properties.defaultHostName

@description('Resource ID of the Web App.')
output id string = webApp.id

@description('Principal ID of the Web App system-assigned managed identity.')
output principalId string = webApp.identity.principalId

@description('Name of the Web App.')
output name string = webApp.name
