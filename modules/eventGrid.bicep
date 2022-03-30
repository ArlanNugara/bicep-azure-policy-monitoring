param EventGridData object
param customer string

var rgName = 'RG-${customer}-${EventGridData.rgNameRef}'
var functionAppName = 'FN-${toUpper(customer)}-${EventGridData.subscriptions.functionAppNameRef}'
var functionAppResourceId = '${resourceId(rgName, 'Microsoft.Web/sites', functionAppName)}/functions/${EventGridData.subscriptions.functionName}'

var workSpaceName = 'LAW-${toUpper(customer)}-${EventGridData.topic.logAnalytics.logWorkSpaceNameRef}'
var logStorageAccountName = 'sa${toLower(customer)}${toLower(EventGridData.topic.logAnalytics.logStorageAccountNameRef)}'

//Create Event Grid Topic 
resource eventGridTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' = {
  name: 'EG-${toUpper(customer)}-${EventGridData.topic.name}'
  location: 'global'
  tags: EventGridData.tags
  properties: {
    source: subscription().id
    topicType: 'Microsoft.PolicyInsights.PolicyStates'
  }
}

//Create Event Grid Subscription
resource evtGridSub 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2021-06-01-preview' = {
  name: '${eventGridTopic.name}/EG-${toUpper(customer)}-${EventGridData.subscriptions.name}'
  properties: {
    eventDeliverySchema: 'EventGridSchema'
    destination: {
      endpointType: 'AzureFunction'
      properties: {
        resourceId: functionAppResourceId
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
    }
    filter: {
      subjectBeginsWith: ''
      subjectEndsWith: ''
      includedEventTypes: [
        'Microsoft.PolicyInsights.PolicyStateChanged'
        'Microsoft.PolicyInsights.PolicyStateCreated'
        'Microsoft.PolicyInsights.PolicyStateDeleted'
      ]
      enableAdvancedFilteringOnArrays: true
    }
  }
}

resource diagonosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'EG-${toUpper(customer)}-${EventGridData.topic.name}-Diagonostics'
  scope: eventGridTopic
  properties: {
    storageAccountId: resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', logStorageAccountName)
    workspaceId: resourceId(resourceGroup().name, 'Microsoft.OperationalInsights/workspaces', workSpaceName)
    logs: [
      {
        category: 'DeliveryFailures'
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

output evtGridSubId string = evtGridSub.id
