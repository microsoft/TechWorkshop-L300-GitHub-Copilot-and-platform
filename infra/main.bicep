// main.bicep - Clean infrastructure for ZavaStorefront (dev)
// Follows Bicep best practices

param location string = 'westus3'
param environment string = 'dev'
param appName string = 'zavastorefront'

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: '${appName}${environment}acr'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${appName}-${environment}-law'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${appName}-${environment}-ai'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${appName}-${environment}-plan'
  location: location
  sku: {
    name: 'P1v2'
    tier: 'PremiumV2'
  }
  properties: {
    reserved: true // Linux
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: '${appName}-${environment}-web'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    'azd-service-name': 'web'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|nginx' // Replace with actual image
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: acr.properties.loginServer
        }
      ]
      alwaysOn: true
    }
    httpsOnly: true
  }
  dependsOn: [appServicePlan, appInsights, acr]
}

resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(webApp.id, acr.id, 'acrpull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Microsoft Foundry (GPT-4, Phi) - placeholder for future Bicep support
