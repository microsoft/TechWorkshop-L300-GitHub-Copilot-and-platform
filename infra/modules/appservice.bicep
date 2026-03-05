param location string
param tags object = {}
param uamiId string
// uamiClientId retained for interface compatibility but not needed by Container Apps
#disable-next-line no-unused-params
param uamiClientId string
param registryLoginServer string
param appInsightsConnectionString string
param logAnalyticsCustomerId string
@secure()
param logAnalyticsKey string
param imageTag string = 'latest'

resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'cae-zava-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsKey
      }
    }
  }
  tags: tags
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-zava-${uniqueString(resourceGroup().id)}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
      registries: [
        {
          server: registryLoginServer
          identity: uamiId
        }
      ]
    }
    template: {
      // Use a public placeholder image until ACR build completes in postprovision hook
      containers: [
        {
          name: 'zava-storefront'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsightsConnectionString
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:80'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
  tags: tags
}

output containerAppName string = containerApp.name
output containerAppHostName string = containerApp.properties.configuration.ingress.fqdn
