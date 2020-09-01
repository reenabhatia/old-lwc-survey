trigger SBUX_B2B_ItemDCSourcingTrigger on SBUX_B2B_ItemDCSourcing__c (before insert, before update) 
{
  if ( Trigger.isInsert)
    {
       SBUX_B2B_ItemDCSourcingHandler.processItemSourcing(Trigger.new, true);
    }
    if(Trigger.isUpdate )
    {
       SBUX_B2B_ItemDCSourcingHandler.processItemSourcing(Trigger.new, false);
    }
}