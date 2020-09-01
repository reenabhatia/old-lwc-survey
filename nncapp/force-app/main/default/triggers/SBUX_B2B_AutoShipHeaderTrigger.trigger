trigger SBUX_B2B_AutoShipHeaderTrigger on SBUX_B2B_AutoShipHeader__c (after update) {
    
    //if autoshipHeader is moved to "Cancelled" status, delete any associated Forecast+Preview data
    if(trigger.isUpdate)
    {
        for(SBUX_B2B_AutoShipHeader__c header : trigger.new)
        {
            if (header.SBUX_B2B_AutoshipStatus__c <> null && header.SBUX_B2B_AutoshipStatus__c == 'Cancelled' && trigger.oldMap.get(header.id).SBUX_B2B_AutoshipStatus__c <> 'Cancelled')
            {
                //call 'DeleteForecast' and 'DeleteOrders' jobs (in succession)
                Id batchDeleteId = Database.executeBatch(new SBUX_B2B_AutoShipDeleteForecastJob(header.id,true,false,false,false), 200);
            }
        }
    }
}