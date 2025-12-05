@description('The name of the App Service')
param name string

@description('The location of the App Service')
param location string = resourceGroup().location

@description('The resource ID of the App Service Plan')
param appServicePlanId string

@description('The Docker image to use (e.g., myregistry.azurecr.io/myapp:latest)')
param dockerImage string = 'mcr.microsoft.com/appsvc/staticsite:latest'

@description('Enable system-assigned managed identity')
param enableManagedIdentity bool = true

@description('Enforce HTTPS only')
param httpsOnly bool = true

@description('Application Insights connection string')
@secure()
param appInsightsConnectionString string = ''

@description('Application Insights instrumentation key')
@secure()
param appInsightsInstrumentationKey string = ''

@description('Additional app settings')
param additionalAppSettings array = []

@description('Tags to apply to the App Service')
param tags object = {}

resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: enableManagedIdentity ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: httpsOnly
    siteConfig: {
      linuxFxVersion: 'DOCKER|${dockerImage}'
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: union([
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
      ], !empty(appInsightsConnectionString) ? [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
      ] : [], !empty(appInsightsInstrumentationKey) ? [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
      ] : [], additionalAppSettings)
    }
  }
}

@description('The resource ID of the App Service')
output resourceId string = appService.id

@description('The name of the App Service')
output name string = appService.name

@description('The default hostname of the App Service')
output defaultHostname string = appService.properties.defaultHostName

@description('The principal ID of the system-assigned managed identity')
output principalId string = enableManagedIdentity ? appService.identity.principalId : ''

@description('The location of the App Service')
output location string = appService.location
