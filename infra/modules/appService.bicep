// App Service Plan and Web App module
// Configures Linux App Service Plan and Web App for Docker container deployment

@description('App Service Plan name')
param appServicePlanName string

@description('App Service (Web App) name')
param appServiceName string

@description('Azure region for the resources')
param location string

@description('App Service Plan SKU (e.g., B1, B2, B3, S1, P1V2)')
param skuName string = 'B2'

@description('Number of instances')
param instanceCount int = 1

@description('Container image name from ACR')
param containerImageName string

@description('Container image tag')
param containerImageTag string = 'latest'

@description('Azure Container Registry name')
param acrName string

@description('Managed Identity resource ID')
param managedIdentityId string

@description('Managed Identity client ID')
param managedIdentityClientId string = ''

@description('Application Insights instrumentation key')
param appInsightsInstrumentationKey string = ''

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Environment name')
param environment string

// Variables
var acrLoginServer = '${acrName}.azurecr.io'
var containerImageUri = '${acrLoginServer}/${containerImageName}:${containerImageTag}'
var alwaysOn = skuName != 'F1' ? true : false

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: {
    environment: environment
    project: 'ZavaStorefront'
    managedBy: 'AZD'
    
  }
  kind: 'Linux'
  sku: {
    name: skuName
    capacity: instanceCount
  }
  properties: {
    reserved: true
  }
}

// Web App (App Service)
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  tags: {
    environment: environment
    project: 'ZavaStorefront'
    managedBy: 'AZD'
    'azd-service-name': 'web'
  }
  kind: 'app,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      alwaysOn: alwaysOn
      linuxFxVersion: 'DOTNETCORE|8.0'
      appSettings: [
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
          value: 'default'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environment
        }
        {
          name: 'ASPNETCORE_URLS'
          value: 'http://+:80'
        }
      ]
      connectionStrings: [
        {
          name: 'DefaultConnection'
          connectionString: ''
          type: 'SQLServer'
        }
      ]
      healthCheckPath: '/'
      numberOfWorkers: 1
      defaultDocuments: [
        'Default.htm'
        'Default.html'
        'index.htm'
        'index.html'
      ]
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'Disabled'
    }
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
  }
}

// Web App Configuration - Authentication
resource webAppAuth 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: webApp
  name: 'authsettingsV2'
  properties: {
    globalValidation: {
      requireAuthentication: false
      unauthenticatedClientAction: 'AllowAnonymous'
    }
  }
}

// Note: Diagnostic settings configuration removed as Application Insights is already connected via app settings

// Outputs
@description('App Service Plan ID')
output appServicePlanId string = appServicePlan.id

@description('App Service Plan Name')
output appServicePlanName string = appServicePlan.name

@description('Web App ID')
output webAppId string = webApp.id

@description('Web App Name')
output webAppName string = webApp.name

@description('Web App URL')
output appServiceUrl string = 'https://${webApp.properties.defaultHostName}'

@description('Web App Hostname')
output appServiceHostname string = webApp.properties.defaultHostName

@description('Container Image URI')
output containerImageUri string = containerImageUri
