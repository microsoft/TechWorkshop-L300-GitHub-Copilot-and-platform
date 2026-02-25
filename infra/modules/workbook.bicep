// Azure Monitor Workbook for AI Services Observability
param workbookName string
param location string
param logAnalyticsWorkspaceId string
param workbookDisplayName string = 'AI Services Observability'
param tags object = {}

// Load workbook definition from JSON file
var workbookContent = loadTextContent('workbook.json')

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(workbookName)
  location: location
  kind: 'shared'
  tags: tags
  properties: {
    displayName: workbookDisplayName
    serializedData: workbookContent
    category: 'Azure Monitor'
    sourceId: logAnalyticsWorkspaceId
  }
}

output workbookId string = workbook.id
output workbookName string = workbook.name
