// main.bicep - Azure infrastructure for .NET Storefront Web App
// Uses Azure Verified Modules and best practices

// =====================
// Parameters
// =====================
param location string = 'eastus' // Azure region
param resourcePrefix string = 'zava' // Prefix for resource names

param sqlPassword string // SQL admin password (use Key Vault in production)
param sqlAdmin string = 'sqladminuser' // SQL admin username

// =====================
// Container Registry
// =====================
module acr 'modules/acr.bicep' = {
  name: '${resourcePrefix}-acr'
  params: {
    name: '${resourcePrefix}acrdev20251202'
    location: location
    sku: 'Basic'
  }
}

// =====================
// Log Analytics Workspace
// =====================
module logAnalytics 'modules/logAnalytics.bicep' = {
  name: '${resourcePrefix}-law'
  params: {
    name: '${resourcePrefix}-law'
    location: location
    retentionInDays: 30
  }
}

// =====================
// Application Insights
// =====================
module appInsights 'modules/appInsights.bicep' = {
  name: '${resourcePrefix}-ai'
  params: {
    name: '${resourcePrefix}-ai'
    location: location
  }
}

// =====================
// Virtual Network
// =====================
module vnet 'modules/vnet.bicep' = {
  name: '${resourcePrefix}-vnet'
  params: {
    name: '${resourcePrefix}-vnet'
    location: location
    addressPrefixes: ['10.0.0.0/16']
    subnets: [
      {
        name: 'web'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'data'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

// =====================
// Storage Account
// =====================
module storage 'modules/storage.bicep' = {
  name: '${resourcePrefix}-storage'
  params: {
    name: '${resourcePrefix}store'
    location: location
    skuName: 'Standard_LRS'
    enableHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

// =====================
// Key Vault
// =====================
module keyVault 'modules/keyVault.bicep' = {
  name: '${resourcePrefix}-kv'
  params: {
    name: '${resourcePrefix}-kv'
    location: location
    tenantId: subscription().tenantId
    skuName: 'standard'
  }
}

// =====================
// SQL Server & Database
// =====================
module sql 'modules/sql.bicep' = {
  name: '${resourcePrefix}-sql'
  params: {
    serverName: '${resourcePrefix}-sqlsrv'
    dbName: '${resourcePrefix}-db'
    location: location
    adminLogin: sqlAdmin
    adminPassword: sqlPassword
    skuName: 'S0'
  }
}

// =====================
// App Service Plan
// =====================
module appServicePlan 'modules/appServicePlan.bicep' = {
  name: '${resourcePrefix}-asp'
  params: {
    name: '${resourcePrefix}-asp'
    location: location
    skuName: 'P1v2'
    isLinux: false
  }
}

// =====================
// Web App
// =====================
module webApp 'modules/webApp.bicep' = {
  name: '${resourcePrefix}-webapp'
  params: {
    name: '${resourcePrefix}-web'
    location: location
    serverFarmId: appServicePlan.outputs.aspId
    appSettings: [
      {
        name: 'KeyVault__Uri'
        value: keyVault.outputs.keyVaultUri
      }
      {
        name: 'APPINSIGHTS_CONNECTION_STRING'
        value: appInsights.outputs.appInsightsConnectionString
      }
      {
        name: 'ACR_LOGIN_SERVER'
        value: acr.outputs.acrLoginServer
      }
    ]
    identityType: 'SystemAssigned'
  }
}

// =====================
// Outputs
// =====================
output webAppUrl string = webApp.outputs.webAppUrl
output keyVaultUri string = keyVault.outputs.keyVaultUri
output acrLoginServer string = acr.outputs.acrLoginServer
output appInsightsConnectionString string = appInsights.outputs.appInsightsConnectionString
