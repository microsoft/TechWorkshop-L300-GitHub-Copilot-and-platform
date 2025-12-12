param location string
param environmentName string
param containerAppEnvironmentId string
param containerAppName string
param containerRegistryUrl string
param containerRegistryIdentityId string
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerRegistryIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: false
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      registries: [
        {
          server: containerRegistryUrl
          identity: containerRegistryIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          image: containerImage
          name: 'zavastorefront'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
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
      ]
      scale: {
        minReplicas: 1
        maxReplicas: environmentName == 'prod' ? 5 : 3
      }
    }
  }
  tags: {
    'azd-env-name': environmentName
    'azd-service-name': 'src'
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
output id string = containerApp.id
