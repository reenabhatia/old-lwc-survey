trigger SBUX_B2B_AutoShipLineTrigger on SBUX_B2B_AutoShipLine__c (before insert, before update) 
{
    if(Trigger.isBefore )
    {
         if (Trigger.isInsert)
         {
            SBUX_B2B_AutoShipLineTriggerHandler.generateExternalID(Trigger.new);
         }
         if (Trigger.isUpdate)
         {
            SBUX_B2B_AutoShipLineTriggerHandler.updateExternalID(Trigger.new,Trigger.oldMap, Trigger.newMap);
         }
    }
}