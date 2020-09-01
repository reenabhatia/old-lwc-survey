trigger SBUX_B2B_CatalogEntitlementRuleTrigger on SBUX_B2B_CatalogEntitlementRule__c (after insert, before update) 
{
    if (Trigger.isAfter  && Trigger.isInsert)
    {
        Map<String, Object> retData = SBUX_B2B_CatalogEntitlementRuleHandler.processCatalogRules(Trigger.new, null, Trigger.newMap, false);
        SBUX_B2B_CatalogEntitlementRuleHandler.deleteInsertStoreRules(retData); 
        SBUX_B2B_CatalogEntitlementRuleHandler.deleteInsertProdRules(retData);
    }
    if(Trigger.isBefore && Trigger.isUpdate )
    {
        Map<String, Object> retData =  SBUX_B2B_CatalogEntitlementRuleHandler.processCatalogRules(Trigger.new, Trigger.oldMap, Trigger.newMap, true);
        SBUX_B2B_CatalogEntitlementRuleHandler.deleteInsertStoreRules(retData); 
        SBUX_B2B_CatalogEntitlementRuleHandler.deleteInsertProdRules(retData);
    }
}