targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param name string
param location string
param tags object

@description('ACR login server (e.g. myacr.azurecr.io). Used to configure the Web App for Containers image source.')
param acrLoginServer string

@description('Application Insights connection string for monitoring.')
param appInsightsConnectionString string

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-${name}'
  location: location
  tags: tags
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: true // required for Linux
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: 'app-${name}'
  location: location
  tags: union(tags, { 'azd-service-name': 'web' })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      // Web App for Containers — image pulled from ACR via managed identity
      linuxFxVersion: 'DOCKER|${acrLoginServer}/web:latest'
      // Use managed identity to authenticate with ACR (no passwords)
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      minTlsVersion: '1.2'
      http20Enabled: true
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
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        {
          name: 'WEBSITES_PORT'
          value: '80'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
      ]
    }
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output name string = webApp.name
output principalId string = webApp.identity.principalId
output defaultHostname string = webApp.properties.defaultHostName
output id string = webApp.id
