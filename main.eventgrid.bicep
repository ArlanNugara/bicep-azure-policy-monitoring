targetScope = 'subscription'

param EventGridArray array

module eventGridM 'modules/eventGrid.bicep' = [for (evtGrid, i) in EventGridArray: {
  name: 'EG-${evtGrid.client}-EventGridDeployment-${i}'
  scope: resourceGroup('RG-${evtGrid.client}-${evtGrid.rgNameRef}')
  params: {
    EventGridData: evtGrid
    customer: evtGrid.client
  }
}]
