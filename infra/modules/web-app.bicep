// ============================================================================
// Web App for Containers Module
// ============================================================================
// Purpose: Deploy Linux Web App configured to pull containers from ACR
// Security: System-assigned managed identity for passwordless ACR pulls
// ============================================================================

@description('The name of the Web App')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Resource ID of the App Service Plan')
param appServicePlanId string

@description('ACR login server (e.g., myregistry.azurecr.io)')
param acrLoginServer string

@description('Container image name with tag (e.g., myapp:latest)')
param containerImage string = 'mcr.microsoft.com/appsvc/staticsite:latest'

@description('Application Insights connection string')
param appInsightsConnectionString string = ''

@description('Tags for the resource')
param tags object = {}

// ============================================================================
// Resources
// ============================================================================

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${containerImage}'
      acrUseManagedIdentityCreds: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      alwaysOn: true
      appSettings: concat(
        [
          {
            name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
            value: 'false'
          }
          {
            name: 'DOCKER_REGISTRY_SERVER_URL'
            value: 'https://${acrLoginServer}'
          }
        ],
        !empty(appInsightsConnectionString)
          ? [
              {
                name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
                value: appInsightsConnectionString
              }
              {
                name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
                value: '~3'
              }
            ]
          : []
      )
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the Web App')
output resourceId string = webApp.id

@description('The name of the Web App')
output name string = webApp.name

@description('The default hostname of the Web App')
output defaultHostname string = webApp.properties.defaultHostName

@description('The principal ID of the system-assigned managed identity')
output principalId string = webApp.identity.principalId
