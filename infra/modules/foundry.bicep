// Diagnostic settings for Foundry
param logAnalyticsWorkspaceId string

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
	name: 'foundry-diagnostics'
	scope: foundry
	properties: {
		workspaceId: logAnalyticsWorkspaceId
		logs: [
			// Enable all log categories (update with actual categories if needed)
			{
				category: 'Audit'
				enabled: true
				retentionPolicy: {
					enabled: false
					days: 0
				}
			}
			{
				category: 'OperationalLogs'
				enabled: true
				retentionPolicy: {
					enabled: false
					days: 0
				}
			}
		]
		metrics: [
			{
				category: 'AllMetrics'
				enabled: true
				retentionPolicy: {
					enabled: false
					days: 0
				}
			}
		]
	}
}
// Microsoft Foundry module
param resourceGroupName string
param location string
param environment string
param foundrySku string = 'dev'

resource foundry 'Microsoft.Foundry/workspaces@2024-01-01-preview' = {
	name: 'zavastore-foundry-${environment}'
	location: location
	sku: {
		name: foundrySku
	}
	properties: {
		// Add required Foundry properties here if needed
	}
}

output foundryResourceId string = foundry.id
output foundryName string = foundry.name

