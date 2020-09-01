trigger SBUX_B2B_ccProductOnUpsert on ccrz__E_Product__c (before insert,  before update) 
{
    if(Trigger.isBefore && Trigger.isUpdate)
    {
        SBUX_B2B_ccProductTriggerHandler.bypassUpdateForIntegration(Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
    SBUX_B2B_ccProductTriggerHandler.updateUOMConversionFactor(Trigger.new, Trigger.oldMap);
}