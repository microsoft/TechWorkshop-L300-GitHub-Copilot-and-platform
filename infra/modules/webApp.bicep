@description('Web App name')
param name string

@description('Resource location')
param location string

@description('App Service Plan resource ID')
param appServicePlanId string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Application Insights instrumentation key')
param appInsightsInstrumentationKey string

@description('ACR login server (e.g. myacr.azurecr.io)')
param acrLoginServer string

@description('If true, reference an existing Web App')
param useExisting bool = false

// ─── Existing reference ───────────────────────────────────────
resource existing 'Microsoft.Web/sites@2023-12-01' existing = if (useExisting) {
  name: name
}

// ─── New resource ─────────────────────────────────────────────
resource webApp 'Microsoft.Web/sites@2023-12-01' = if (!useExisting) {
  name: name
  location: location
  kind: 'app,linux,container'
  tags: {
    'azd-service-name': 'web'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/zavastore:latest'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
    }
  }
}

output id string = useExisting ? existing.id : webApp.id
output name string = useExisting ? existing.name : webApp.name
output defaultHostName string = useExisting ? existing.properties.defaultHostName : webApp.properties.defaultHostName
output principalId string = useExisting ? existing.identity.principalId : webApp.identity.principalId
