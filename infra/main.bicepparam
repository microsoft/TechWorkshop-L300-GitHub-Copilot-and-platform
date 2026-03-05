using 'main.bicep'

// Environment configuration
param environmentName = 'dev'
param location = 'swedencentral'
param appName = 'zavastore'

// SKU configurations (dev-appropriate, minimal cost)
param appServiceSkuName = 'B1'
param acrSku = 'Basic'

// Container image
param dockerImageName = 'zavastore:latest'

// Additional tags
param tags = {
  project: 'ZavaStorefront'
  owner: 'DevTeam'
}
