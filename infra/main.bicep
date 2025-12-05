// =========================================================================
// Main Bicep Template - ZavaStorefront Infrastructure
// Provisions all Azure resources for dev environment in westus3
// Uses Azure Verified Modules (AVM) from public registry
// =========================================================================

targetScope = 'resourceGroup'

// -------------------------------------------------------------------------
// Parameters
// -------------------------------------------------------------------------

@description('Environment name (e.g., dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environmentName string = 'dev'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Base name for all resources')
param baseName string = 'zavastore'

@description('Tags to apply to all resources')
param tags object = {
  environment: environmentName
  project: 'ZavaStorefront'
  deployedWith: 'azd'
}

// -------------------------------------------------------------------------
// Variables
// -------------------------------------------------------------------------

var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, environmentName))
var shortToken = take(resourceToken, 8) // Shortened token for length-restricted resources
var abbrs = loadJsonContent('abbreviations.json')

// Resource names following Azure naming conventions
var logAnalyticsName = '${abbrs.operationalInsightsWorkspaces}${baseName}-${environmentName}-${shortToken}'
var appInsightsName = '${abbrs.insightsComponents}${baseName}-${environmentName}-${shortToken}'
var acrName = toLower(replace('${abbrs.containerRegistryRegistries}${baseName}${environmentName}${shortToken}', '-', ''))
var appServicePlanName = '${abbrs.webServerFarms}${baseName}-${environmentName}-${shortToken}'
var webAppName = '${abbrs.webSitesAppService}${baseName}-${environmentName}-${shortToken}'
var keyVaultName = take('${abbrs.keyVaultVaults}${baseName}${shortToken}', 24) // Max 24 chars
var storageAccountName = toLower(take('st${baseName}${shortToken}', 24)) // Max 24 chars, alphanumeric only
var aiFoundryName = '${abbrs.machineLearningServicesWorkspaces}${baseName}-${shortToken}'

// -------------------------------------------------------------------------
// Modules - Log Analytics Workspace
// -------------------------------------------------------------------------

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.11.1' = {
  name: 'logAnalyticsDeployment'
  params: {
    name: logAnalyticsName
    location: location
    tags: tags
    skuName: 'PerGB2018'
    dataRetention: 30
  }
}

// -------------------------------------------------------------------------
// Modules - Application Insights
// -------------------------------------------------------------------------

module appInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'appInsightsDeployment'
  params: {
    name: appInsightsName
    location: location
    tags: tags
    workspaceResourceId: logAnalytics.outputs.resourceId
    applicationType: 'web'
    kind: 'web'
  }
}

// -------------------------------------------------------------------------
// Modules - Azure Container Registry
// -------------------------------------------------------------------------

module acr 'modules/acr.bicep' = {
  name: 'acrDeployment'
  params: {
    name: acrName
    location: location
    tags: tags
    sku: 'Basic'
  }
}

// -------------------------------------------------------------------------
// Modules - App Service Plan (Linux)
// -------------------------------------------------------------------------

module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'appServicePlanDeployment'
  params: {
    name: appServicePlanName
    location: location
    tags: tags
    kind: 'linux'
    reserved: true
    skuName: 'B1'
    skuCapacity: 1
  }
}

// -------------------------------------------------------------------------
// Modules - Web App for Containers (Linux)
// -------------------------------------------------------------------------

// Tags for AZD service discovery
var webAppTags = union(tags, {
  'azd-service-name': 'web'
})

module webApp 'br/public:avm/res/web/site:0.15.1' = {
  name: 'webAppDeployment'
  params: {
    name: webAppName
    location: location
    tags: webAppTags
    kind: 'app,linux,container'
    serverFarmResourceId: appServicePlan.outputs.resourceId
    managedIdentities: {
      systemAssigned: true
    }
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acr.outputs.loginServer}/zavastorefront:latest'
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      alwaysOn: true
      http20Enabled: true
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acr.outputs.loginServer}'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.outputs.connectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
      ]
    }
    httpsOnly: true
  }
}

// -------------------------------------------------------------------------
// Modules - ACR Pull Role Assignment for Web App Managed Identity
// -------------------------------------------------------------------------

module acrPullRoleAssignment 'modules/acr-role-assignment.bicep' = {
  name: 'acrPullRoleAssignmentDeployment'
  params: {
    acrName: acr.outputs.name
    principalId: webApp.outputs.systemAssignedMIPrincipalId!
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull role
  }
}

// -------------------------------------------------------------------------
// Modules - Key Vault (required for AI Foundry)
// -------------------------------------------------------------------------

module keyVault 'br/public:avm/res/key-vault/vault:0.11.0' = {
  name: 'keyVaultDeployment'
  params: {
    name: keyVaultName
    location: location
    tags: tags
    enablePurgeProtection: false // Set to true for production
    enableRbacAuthorization: true
    sku: 'standard'
  }
}

// -------------------------------------------------------------------------
// Modules - Storage Account (required for AI Foundry)
// -------------------------------------------------------------------------

module storageAccount 'br/public:avm/res/storage/storage-account:0.18.2' = {
  name: 'storageAccountDeployment'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

// -------------------------------------------------------------------------
// Modules - AI Foundry (Azure Machine Learning Hub)
// -------------------------------------------------------------------------

module aiFoundry 'br/public:avm/res/machine-learning-services/workspace:0.11.1' = {
  name: 'aiFoundryDeployment'
  params: {
    name: aiFoundryName
    location: location
    tags: tags
    kind: 'Hub'
    sku: 'Basic'
    associatedKeyVaultResourceId: keyVault.outputs.resourceId
    associatedStorageAccountResourceId: storageAccount.outputs.resourceId
    associatedApplicationInsightsResourceId: appInsights.outputs.resourceId
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// -------------------------------------------------------------------------
// Outputs
// -------------------------------------------------------------------------

@description('The name of the resource group')
output resourceGroupName string = resourceGroup().name

@description('The name of the Azure Container Registry')
output acrName string = acr.outputs.name

@description('The login server URL for ACR')
output acrLoginServer string = acr.outputs.loginServer

@description('The name of the App Service Plan')
output appServicePlanName string = appServicePlan.outputs.name

@description('The name of the Web App')
output webAppName string = webApp.outputs.name

@description('The default hostname of the Web App')
output webAppHostname string = webApp.outputs.defaultHostname

@description('The Application Insights connection string')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('The Application Insights instrumentation key')
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey

@description('The name of the AI Foundry workspace')
output aiFoundryName string = aiFoundry.outputs.name

@description('The principal ID of the Web App managed identity')
output webAppPrincipalId string = webApp.outputs.?systemAssignedMIPrincipalId ?? ''
