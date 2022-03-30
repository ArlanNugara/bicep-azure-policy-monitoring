param keyVaultData object
param customer string
param commonTags object

var tags = union(commonTags, keyVaultData.tags)
var keyVaultName = 'KV-${toUpper(customer)}-${keyVaultData.name}'

var workSpaceName = 'LAW-${toUpper(customer)}-${keyVaultData.logAnalytics.logWorkSpaceNameRef}'
var logStorageAccountName = 'sa${toLower(customer)}${toLower(keyVaultData.logAnalytics.logStorageAccountNameRef)}'

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: resourceGroup().location
  tags: tags
  properties: {
    enablePurgeProtection:true
    enableSoftDelete:true
    tenantId: subscription().tenantId
    sku: {
      family: keyVaultData.skuFamily
      name: keyVaultData.skuName
    }
    accessPolicies: []
  }
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = [for (kvSecret, i) in keyVaultData.secrects: {
  name: '${keyVault.name}/${kvSecret.name}'
  tags: tags
  properties: {
    value: listKeys('${resourceId(resourceGroup().name, 'Microsoft.Web/sites', 'FN-${toUpper(customer)}-${kvSecret.functionAppNameRef}')}/host/default', '2021-02-01').functionKeys.default
  }
}]

resource diagonosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${keyVaultName}-Diagonostics'
  scope: keyVault
  properties: {
    storageAccountId: resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', logStorageAccountName)
    workspaceId: resourceId(resourceGroup().name, 'Microsoft.OperationalInsights/workspaces', workSpaceName)
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
      {
        category: 'AzurePolicyEvaluationDetails'
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
