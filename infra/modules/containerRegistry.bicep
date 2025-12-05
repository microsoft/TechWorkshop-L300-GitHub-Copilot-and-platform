@description('The name of the Container Registry')
param name string

@description('The location of the Container Registry')
param location string = resourceGroup().location

@description('The SKU name for the Container Registry')
@allowed(['Basic', 'Standard', 'Premium'])
param acrSku string = 'Basic'

@description('Enable admin user for Container Registry')
param acrAdminUserEnabled bool = false

@description('Tags to apply to the Container Registry')
param tags object = {}

@description('Role assignments for the Container Registry')
param roleAssignments array = []

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: acrAdminUserEnabled
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      retentionPolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        status: 'disabled'
      }
    }
  }
}

resource containerRegistry_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (roleAssignment, index) in roleAssignments: {
  name: guid(containerRegistry.id, roleAssignment.principalId, roleAssignment.roleDefinitionIdOrName)
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionIdOrName)
    principalId: roleAssignment.principalId
    principalType: roleAssignment.?principalType ?? 'ServicePrincipal'
  }
}]

@description('The resource ID of the Container Registry')
output resourceId string = containerRegistry.id

@description('The name of the Container Registry')
output name string = containerRegistry.name

@description('The login server of the Container Registry')
output loginServer string = containerRegistry.properties.loginServer

@description('The location of the Container Registry')
output location string = containerRegistry.location
