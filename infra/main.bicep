// main.bicep — subscription-scoped entry point for ZavaStorefront
targetScope = 'subscription'

param environmentName string
param location string

var tags = { 'azd-env-name': environmentName }

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module app './app.bicep' = {
  name: 'app-resources'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
  }
}

output RESOURCE_GROUP_ID string = rg.id
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = app.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output CONTAINER_APP_NAME string = app.outputs.CONTAINER_APP_NAME
output CONTAINER_APP_URI string = app.outputs.CONTAINER_APP_URI
