param storageAccountData object
param customer string
param commonTags object

var tags = union(commonTags, storageAccountData.tags)
var storageAccountName = 'sa${toLower(customer)}${toLower(storageAccountData.name)}'

var workSpaceName = 'LAW-${toUpper(customer)}-${storageAccountData.logAnalytics.logWorkSpaceNameRef}'
var logStorageAccountName = 'sa${toLower(customer)}${toLower(storageAccountData.logAnalytics.logStorageAccountNameRef)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: resourceGroup().location
  tags: tags
  sku: {
    name: storageAccountData.skuName
  }
  kind: 'StorageV2'
  properties: {
    networkAcls:{
      defaultAction:'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource diagonosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccountName}-Diagonostics'
  scope: storageAccount
  properties: {
    storageAccountId: resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', logStorageAccountName)
    workspaceId: resourceId(resourceGroup().name, 'Microsoft.OperationalInsights/workspaces', workSpaceName)
    logs: []
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}
