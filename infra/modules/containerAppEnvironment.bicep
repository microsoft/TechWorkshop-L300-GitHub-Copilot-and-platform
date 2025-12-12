param location string
param environmentName string

var containerAppEnvName = 'aze-${substring(uniqueString(subscription().id, location, environmentName), 0, 12)}'

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnvName
  location: location
  properties: {
  }
  tags: {
    'azd-env-name': environmentName
  }
}

output id string = containerAppEnvironment.id
output name string = containerAppEnvironment.name
