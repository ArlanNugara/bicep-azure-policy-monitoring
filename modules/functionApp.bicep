param functionAppData object
param customer string
param commonTags object

var tags = union(commonTags, functionAppData.tags)

var functionAppName = 'FN-${toUpper(customer)}-${functionAppData.name}'
var storageAccountName = 'sa${toLower(customer)}${toLower(functionAppData.storageAccountNameRef)}'
//var storageAccountRef = reference(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageAccountName), '2021-06-01')
var applicationInsightsName = 'AI-${toUpper(customer)}-${functionAppData.appInsightsName}'
var applicationServicePlanName = 'ASP-${toUpper(customer)}-${functionAppData.appServicePlanName}'

var functionName = 'PolicyMonitor'
var logAnalyticsAPIVersion = '2021-06-01'

var workSpaceName = 'LAW-${toUpper(customer)}-${functionAppData.logAnalytics.logWorkSpaceNameRef}'
var logStorageAccountName = 'sa${toLower(customer)}${toLower(functionAppData.logAnalytics.logStorageAccountNameRef)}'
/*
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: functionAppData.storageAccountName
  location: resourceGroup().location
  tags: functionAppData.tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
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
*/

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: resourceGroup().location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: resourceId(resourceGroup().name, 'Microsoft.OperationalInsights/workspaces', workSpaceName)
  }
}

resource plan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: applicationServicePlanName
  location: resourceGroup().location
  kind: 'linux'
  tags: tags
  sku: {
    name: 'B1'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2021-02-01' = {
  name: functionAppName
  location: resourceGroup().location
  tags: tags
  kind: 'functionapp,linux'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${functionAppName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${functionAppName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: plan.id
    reserved: true
    isXenon: false
    hyperV: false
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageAccountName), '2021-06-01').keys[0].value}'
        }
        {
          name: 'WORKSPACE_ID'
          value: '${reference(resourceId(resourceGroup().name, 'Microsoft.OperationalInsights/workspaces', workSpaceName), logAnalyticsAPIVersion).customerId}'
        }
        {
          name: 'WORKSPACE_KEY'
          value: '${listKeys(resourceId(resourceGroup().name, 'Microsoft.OperationalInsights/workspaces', workSpaceName), logAnalyticsAPIVersion).primarySharedKey}'
        }
      ]
      numberOfWorkers: 1
      linuxFxVersion: 'PYTHON|3.9'
    }
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource funcAppDiagonosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${functionAppName}-Diagonostics'
  scope: functionApp
  properties: {
    storageAccountId: resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', logStorageAccountName)
    workspaceId: resourceId(resourceGroup().name, 'Microsoft.OperationalInsights/workspaces', workSpaceName)
    logs: [
      {
        category: 'FunctionAppLogs'
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

resource appServicePlanDiagonosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${applicationServicePlanName}-Diagonostics'
  scope: plan
  properties: {
    storageAccountId: resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', logStorageAccountName)
    workspaceId: resourceId(resourceGroup().name, 'Microsoft.OperationalInsights/workspaces', workSpaceName)
    logs: []
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output functionAppHostName string = functionApp.properties.defaultHostName
output functionName string = functionName
