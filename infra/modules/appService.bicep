// ============================================================================
// App Service (Web App for Containers) Module
// Provides Linux container hosting with managed identity
// ============================================================================

@description('Name of the Web App')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('Resource ID of the App Service Plan')
param serverFarmResourceId string

@description('Docker image to deploy (e.g., myregistry.azurecr.io/myapp:latest)')
param linuxFxVersion string = 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'

@description('Application Insights connection string')
param appInsightsConnectionString string = ''

@description('Container Registry login server')
param acrLoginServer string = ''

// Deploy Web App using Azure Verified Module
module webApp 'br/public:avm/res/web/site:0.15.0' = {
  name: 'webAppDeployment'
  params: {
    name: name
    location: location
    tags: tags
    kind: 'app,linux,container'
    serverFarmResourceId: serverFarmResourceId
    httpsOnly: true
    
    // Enable system-assigned managed identity for ACR pull
    managedIdentities: {
      systemAssigned: true
    }
    
    // Site configuration
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: false // B1 SKU limitation
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      acrUseManagedIdentityCreds: true // Use managed identity for ACR
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
      ]
    }
    
    // Disable basic auth publishing credentials
    basicPublishingCredentialsPolicies: [
      {
        name: 'ftp'
        allow: false
      }
      {
        name: 'scm'
        allow: false
      }
    ]
  }
}

// Outputs
@description('The resource ID of the Web App')
output resourceId string = webApp.outputs.resourceId

@description('The name of the Web App')
output name string = webApp.outputs.name

@description('The default hostname of the Web App')
output defaultHostname string = webApp.outputs.defaultHostname

@description('The principal ID of the system-assigned managed identity')
output systemAssignedMIPrincipalId string = webApp.outputs.?systemAssignedMIPrincipalId ?? ''
