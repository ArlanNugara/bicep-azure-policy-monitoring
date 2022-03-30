targetScope = 'subscription'

param customer string
param commonTags object
param resourceGroup object

//Create Resource Group 
resource rgs 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'RG-${customer}-${resourceGroup.rgName}'
  location: resourceGroup.rgLocation
  tags: union(commonTags, resourceGroup.tags)
}

//Create Storage Account
module storageAccountModule 'modules/storageaccount.bicep' = [for (storage, i) in resourceGroup.storageAccountArray: {
  name: 'SA-${customer}-${storage.name}-Deployment-${i}'
  scope: rgs
  params: {
    commonTags: commonTags
    customer: customer
    storageAccountData: storage
  }
}]

//Create Log Analytics Workspace
module logAWSModule 'modules/workspace.bicep' = [for (law, i) in resourceGroup.logAnalyticsWorkspaceArray: {
  name: 'LAW-${customer}-${law.name}-Deployment-${i}'
  scope: rgs
  dependsOn: [
    storageAccountModule
  ]
  params: {
    commonTags: commonTags
    customer: customer
    workspaceData: law
  }
}]

//Create Function App for Policy Monitor
module funcAppModule 'modules/functionApp.bicep' = [for (funcapp, i) in resourceGroup.functionAppArray: {
  name: 'FN-${customer}-${funcapp.name}-Deployment-${i}'
  scope: rgs
  params: {
    commonTags: commonTags
    customer: customer
    functionAppData: funcapp
  }
  dependsOn: [
    storageAccountModule
    logAWSModule
  ]
}]

//Create Key Vault Secret
module keyValueSecretModule 'modules/keyVault.bicep' = [for (kv, i) in resourceGroup.keyVaultArray: {
  name: 'KV-${customer}-${kv.name}-Deployment-${i}'
  scope: rgs
  params: {
    commonTags: commonTags
    customer: customer
    keyVaultData: kv
  }
  dependsOn: [
    storageAccountModule
    logAWSModule
    funcAppModule
  ]
}]

//Create Metrics
module metricsAlerts 'modules/metrics.bicep' = [for (metricAlt, i) in resourceGroup.metricsArray: {
  name: 'METRICS-${customer}-Deployment-${i}'
  scope: rgs
  params: {
    commonTags: commonTags
    customer: customer
    metricsData: metricAlt
  }
  dependsOn: [
    funcAppModule
  ]
}]
