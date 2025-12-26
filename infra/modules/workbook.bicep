@description('Location for the workbook resource (use the Log Analytics workspace region).')
param location string

@description('Resource ID of the Log Analytics workspace to scope queries.')
param workspaceResourceId string

@description('Name of the workbook resource.')
param name string = 'ai-services-observability'

@description('Display name shown in the Azure portal.')
param displayName string = 'AI Services Observability'

@description('Optional workbook description.')
param description string = 'Observability workbook for AI services: request volume, latency percentiles, and operation breakdown.'

@description('Serialized workbook definition JSON.')
param workbookDefinition string = loadTextContent('../workbooks/ai-services-observability.json')

@description('Workbook category used by the portal blade.')
param category string = 'workbook'

resource workbook 'Microsoft.Insights/workbooks@2022-09-01' = {
  name: name
  location: location
  kind: 'shared'
  properties: {
    displayName: displayName
    category: category
    description: description
    serializedData: workbookDefinition
    sourceId: workspaceResourceId
  }
}

output workbookId string = workbook.id
output workbookName string = workbook.name
