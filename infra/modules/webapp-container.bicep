@description('Web App name')
param name string

@description('Resource location')
param location string

@description('App Service Plan resource ID')
param appServicePlanId string

@description('ACR login server')
param acrLoginServer string

@description('Container image name')
param imageName string

@description('Container image tag')
param imageTag string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Foundry endpoint URL')
param foundryEndpoint string

@description('AZD service name')
param serviceName string

@description('User-assigned managed identity resource ID')
param userManagedIdentityResourceId string

resource webApp 'Microsoft.Web/sites@2024-11-01' = {
  name: name
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userManagedIdentityResourceId}': {}
    }
  }
  tags: {
    'azd-service-name': serviceName
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${imageName}:${imageTag}'
      alwaysOn: false
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'FOUNDRY_ENDPOINT'
          value: foundryEndpoint
        }
      ]
    }
  }
}

output id string = webApp.id
output defaultHostName string = webApp.properties.defaultHostName
output systemPrincipalId string = webApp.identity.principalId
