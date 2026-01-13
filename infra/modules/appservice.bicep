// App Service Plan and Web App module
@description('The Azure region for the resources')
param location string

@description('The name of the App Service Plan')
param appServicePlanName string

@description('The name of the App Service')
param appServiceName string

@description('App Service Plan SKU')
param appServicePlanSku string = 'B1'

@description('The Docker image name with tag')
param dockerImageName string

@description('The ACR login server URL')
param acrLoginServer string

@description('Application Insights connection string')
@secure()
param appInsightsConnectionString string

@description('Tags to apply to the resources')
param tags object = {}

// Create App Service Plan (Linux)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: appServicePlanSku
  }
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux
  }
}

// Create App Service (Web App for Containers)
resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceName
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned' // Enable system-assigned managed identity
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${dockerImageName}'
      alwaysOn: false // Set to false for Basic/Free tiers
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
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
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
      ]
      acrUseManagedIdentityCreds: true // Use managed identity for ACR authentication
    }
  }
}

// Outputs
output appServiceId string = appService.id
output appServiceName string = appService.name
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output appServiceDefaultHostName string = appService.properties.defaultHostName
output appServiceManagedIdentityPrincipalId string = appService.identity.principalId
output appServicePlanId string = appServicePlan.id
