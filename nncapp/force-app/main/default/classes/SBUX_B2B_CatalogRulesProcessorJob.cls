public with sharing class SBUX_B2B_CatalogRulesProcessorJob implements Database.Batchable<SObject>, Database.Stateful, Schedulable
{
    private List<SBUX_B2B_StoreEntitlementRule__c> storeRulesToDelete =  new List <SBUX_B2B_StoreEntitlementRule__c> ();
    private List<SBUX_B2B_StoreEntitlementRule__c> storeRulesToInsert = new List <SBUX_B2B_StoreEntitlementRule__c> ();
    private static final Integer BATCH_SIZE = 2000;

    public Database.QueryLocator start(Database.BatchableContext batchableCtx)
    {
        String CATALOG_RULES_QUERY = 'SELECT ID' +
                                    ',SBUX_B2B_City__c' +
                                    ',SBUX_B2B_Country__c' +
                                    ',SBUX_B2B_EngineType__c' +
                                    ',SBUX_B2B_EndDate__c'+
                                    ',SBUX_B2B_LicenseeAccount__c'+
                                    ',SBUX_B2B_LocalProduct__c'+
                                    ',SBUX_B2B_ProductCategory__c'+
                                    ',SBUX_B2B_ProgramType__c'+
                                    ',SBUX_B2B_RuleType__c'+
                                    ',SBUX_B2B_SkuList__c'+
                                    ',SBUX_B2B_State__c'+
                                    ',SBUX_B2B_StoreNumber__c' +
                                    ',SBUX_B2B_StartDate__c'+
                                    ' FROM SBUX_B2B_CatalogEntitlementRule__c' +
                                    ' WHERE ((SBUX_B2B_StartDate__c <= TODAY  OR  SBUX_B2B_StartDate__c = NULL) ' + 
                                    ' AND (SBUX_B2B_EndDate__c >= TODAY  OR  SBUX_B2B_EndDate__c = NULL) )';

        return Database.getQueryLocator(CATALOG_RULES_QUERY);
    }


     public void execute(Database.BatchableContext batchableCtx, List<SObject> scope) 
     {  
         List<SBUX_B2B_CatalogEntitlementRule__c> catalogRules = (List<SBUX_B2B_CatalogEntitlementRule__c>) scope;

         Map<String, Object> retData = SBUX_B2B_CatalogEntitlementRuleHandler.processCatalogRules(catalogRules, null, null, false);
         SBUX_B2B_CatalogEntitlementRuleHandler.deleteInsertProdRules(retData);

         if (retData != null && !retData.isEmpty())
           {
              if (ccrz.ccUtil.isKeyValued(retData, 'storeRulesToDelete'))
              {
                this.storeRulesToDelete.addAll((List <SBUX_B2B_StoreEntitlementRule__c>)retData.get('storeRulesToDelete'));
              }
              if (ccrz.ccUtil.isKeyValued(retData, 'storeRulesToInsert'))
              {
                 this.storeRulesToInsert.addAll((List <SBUX_B2B_StoreEntitlementRule__c>)retData.get('storeRulesToInsert'));
              }
           }
     }



     public void finish(Database.BatchableContext batchableCtx) 
     {       
        SBUX_B2B_StoreRulesCleanupJob storeCleanupJob =  new SBUX_B2B_StoreRulesCleanupJob(this.storeRulesToDelete,this.storeRulesToInsert);
        Database.executeBatch(storeCleanupJob,BATCH_SIZE);
     }

     public void execute(SchedulableContext sc)
     {
        Database.executebatch(new SBUX_B2B_CatalogRulesProcessorJob(),1);
     }

}