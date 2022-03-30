param workspaceData object
param customer string
param commonTags object

var tags = union(commonTags, workspaceData.tags)
var workSpaceName = 'LAW-${toUpper(customer)}-${workspaceData.name}'
var storageAccountName = 'sa${toLower(customer)}${toLower(workspaceData.logAnalytics.logStorageAccountNameRef)}'

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: workSpaceName
  location: resourceGroup().location
  tags: tags
  properties: {
    sku: {
      name: workspaceData.sku
    }
    retentionInDays: workspaceData.retentionInDays
    workspaceCapping: {
      dailyQuotaGb: 1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource diagonosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${workSpaceName}-Diagonostics'
  scope: workspace
  properties: {
    storageAccountId: resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageAccountName)
    workspaceId: workspace.id
    logs: [
      {
        category: 'Audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
