targetScope = 'resourceGroup'

@description('Deployment location for all resources.')
param location string = resourceGroup().location

@description('Environment name used in resource naming.')
param environmentName string = 'dev'

@description('Base workload name used in resource naming.')
param workloadName string = 'zava'

@description('Container image repository name in ACR.')
param containerImageName string = 'zavastorefront'

@description('Container image tag to deploy.')
param containerImageTag string = 'latest'

@description('App Service plan SKU for the dev environment.')
param appServicePlanSku string = 'B1'

@description('Foundry (AIServices) SKU.')
param foundrySku string = 'S0'

@description('Disable Foundry public network access when true.')
param foundryDisablePublicNetworkAccess bool = false

@description('Deploy model deployments (GPT and Phi) inside the Foundry account.')
param deployModelDeployments bool = true

@description('Deployment name for the GPT model deployment.')
param gptDeploymentName string = 'gpt-4o'

@description('OpenAI model name for the GPT deployment.')
param gptModelName string = 'gpt-4o'

@description('OpenAI model version for the GPT deployment.')
param gptModelVersion string = '2024-11-20'

@description('SKU name for GPT deployment. Standard is typically used for pay-as-you-go.')
param gptSkuName string = 'Standard'

@description('Capacity for GPT deployment. 10 aligns with the account default for this model/SKU.')
param gptCapacity int = 10

@description('Deployment name for the Phi model deployment.')
param phiDeploymentName string = 'phi-4'

@description('Microsoft model name for Phi deployment.')
param phiModelName string = 'Phi-4'

@description('Model version for Phi deployment.')
param phiModelVersion string = '7'

@description('SKU for Phi deployment in this region/account.')
param phiSkuName string = 'GlobalStandard'

@description('Capacity for Phi deployment. Current quota in this account supports 1.')
param phiCapacity int = 1

@description('Responsible AI policy applied to the model deployments.')
param modelRaiPolicyName string = 'Microsoft.DefaultV2'

var uniqueToken = toLower(uniqueString(resourceGroup().id, workloadName, environmentName))
var namingSeed = take(uniqueToken, 6)
var baseName = toLower('${workloadName}-${environmentName}-${namingSeed}')

var acrName = toLower(take(replace('${workloadName}${environmentName}${uniqueToken}', '-', ''), 50))
var logAnalyticsName = '${baseName}-law'
var appInsightsName = '${baseName}-appi'
var appServicePlanName = '${baseName}-plan'
var webAppName = '${baseName}-web'
var foundryName = toLower(take(replace('${workloadName}${environmentName}${uniqueToken}', '-', ''), 24))

module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalyticsDeployment'
  params: {
    workspaceName: logAnalyticsName
    location: location
  }
}

module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsightsDeployment'
  params: {
    appInsightsName: appInsightsName
    location: location
    workspaceResourceId: logAnalytics.outputs.id
  }
}

module acr 'modules/acr.bicep' = {
  name: 'acrDeployment'
  params: {
    acrName: acrName
    location: location
  }
}

module appService 'modules/appService.bicep' = {
  name: 'appServiceDeployment'
  params: {
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    location: location
    servicePlanSku: appServicePlanSku
    acrLoginServer: acr.outputs.loginServer
    containerImageName: containerImageName
    containerImageTag: containerImageTag
    appInsightsConnectionString: appInsights.outputs.connectionString
  }
}

// App Service uses managed identity to pull images from ACR.
module acrPullRole 'modules/roleAssignment.bicep' = {
  name: 'acrPullRoleDeployment'
  params: {
    acrName: acr.outputs.name
    principalId: appService.outputs.principalId
  }
}

module foundry 'modules/foundry.bicep' = {
  name: 'foundryDeployment'
  params: {
    foundryName: foundryName
    location: location
    skuName: foundrySku
    disablePublicNetworkAccess: foundryDisablePublicNetworkAccess
  }
}

module modelDeployments 'modules/modelDeployments.bicep' = if (deployModelDeployments) {
  name: 'modelDeploymentsDeployment'
  params: {
    accountName: foundryName
    gptDeploymentName: gptDeploymentName
    gptModelName: gptModelName
    gptModelVersion: gptModelVersion
    gptSkuName: gptSkuName
    gptCapacity: gptCapacity
    phiDeploymentName: phiDeploymentName
    phiModelName: phiModelName
    phiModelVersion: phiModelVersion
    phiSkuName: phiSkuName
    phiCapacity: phiCapacity
    raiPolicyName: modelRaiPolicyName
  }
  dependsOn: [
    foundry
  ]
}

output acrName string = acr.outputs.name
output acrLoginServer string = acr.outputs.loginServer
output webAppName string = appService.outputs.name
output webAppHostName string = appService.outputs.hostName
output appInsightsName string = appInsightsName
output foundryResourceName string = foundryName
output foundryEndpoint string = foundry.outputs.endpoint
output gptModelDeploymentName string = deployModelDeployments ? gptDeploymentName : ''
output phiModelDeploymentName string = deployModelDeployments ? phiDeploymentName : ''
