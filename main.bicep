targetScope = 'subscription'

param policyMonitorData object

module PolicyMonitorFunctionAppDep 'deploymentZone.bicep' = [for (rg, i) in policyMonitorData.resourceGroupArray: {
  name: '${policyMonitorData.client}-PolicyMonitorFunctionAppDeployment-${i}'
  params: {
    commonTags: policyMonitorData.commonTagsForResources
    customer: policyMonitorData.client
    resourceGroup: rg
  }
}]
