param customer string
param commonTags object
param metricsData object

var tags = union(commonTags, metricsData.tags)
//var applicationInsightsAlertName = 'ALT-${toUpper(customer)}-${metricsData.name}'
var workSpaceName = 'LAW-${toUpper(customer)}-${metricsData.logWorkSpaceNameRef}'

/*
resource metricsAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name:applicationInsightsAlertName
  location:'global'
  tags:tags
  properties:{
    description:'Compliance Status for Microsoft Azure - CSP Adastra Sandbox subscription'
    displ
  }
}
*/

resource emailActionGroup 'Microsoft.Insights/actionGroups@2021-09-01' = {
  name: metricsData.emailAction.name
  location: 'global'
  tags: tags
  properties: {
    groupShortName: metricsData.emailAction.name
    enabled: true
    emailReceivers: [
      {
        name: metricsData.emailAction.name
        emailAddress: metricsData.emailAction.emailId
        useCommonAlertSchema: true
      }
    ]
  }
}

resource alerts 'Microsoft.Insights/scheduledQueryRules@2021-08-01' = {
  name: metricsData.name
  location: resourceGroup().location
  tags: tags
  dependsOn: [
    emailActionGroup
  ]
  properties: {
    displayName: metricsData.name
    description:metricsData.description
    severity: metricsData.severity
    enabled: true
    evaluationFrequency: metricsData.evaluationFrequency
    scopes: [
      resourceId(resourceGroup().name, 'Microsoft.OperationalInsights/workspaces', workSpaceName)
    ]
    windowSize: 'PT1H'
    criteria: {
      allOf: [
        {
          query: metricsData.query
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    actions: {
      actionGroups: [
        emailActionGroup.id
      ]
    }
  }
}
