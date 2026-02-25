@description('Web app name.')
param name string

@description('Resource location.')
param location string

@description('App Service plan resource ID.')
param appServicePlanId string

@description('User-assigned managed identity resource ID.')
param userAssignedIdentityResourceId string

@description('User-assigned managed identity client ID.')
param userAssignedIdentityClientId string

@description('Application Insights connection string.')
param appInsightsConnectionString string

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceId string

@description('azd service name for resource tagging.')
param serviceName string

@description('ACR login server, e.g. myacr.azurecr.io.')
param acrLoginServer string

@description('Container image name in ACR.')
param containerImageName string

@description('Container image tag in ACR.')
param containerImageTag string

@description('Allowed CORS origins.')
param allowedCorsOrigins array

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, name)

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  kind: 'app,linux,container'
  tags: {
    'azd-service-name': serviceName
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${containerImageName}:${containerImageTag}'
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: userAssignedIdentityClientId
      alwaysOn: false
      minTlsVersion: '1.2'
      cors: {
        allowedOrigins: allowedCorsOrigins
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
      ]
    }
  }
}

resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'azds${resourceToken}'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output id string = webApp.id
