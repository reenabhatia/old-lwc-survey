/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description Integration_Status_TriggerHandler class used to trigger the retry from Integration Status Object
*/
    public with sharing class IntegrationStatus_TriggerHandler extends TriggerFactoryHandlerBase{
    
     public override void OnAfterUpdate(List<SObject> oldList, List<SObject> newList, Map<Id,SObject> oldMap, Map<Id,SObject> newMap)
    {
        Set<Id> retryIds = new Set<Id>();
        List<Integration_Status__c> retrylist = new List<Integration_Status__c>();
        //List<Id> updateoppids = new List<id>();
        //List<Id> promotesiteids = new List<Id>();
        Map<String,Id> oppMap = new Map<String,Id>();
//Check if integration sync status goes from 'Error' to 'Submitted' 
         for(Integration_Status__c inte: (List<Integration_Status__c>)newList){

            if((inte.Sync_Status__c != ((Map<Id,Integration_Status__c>)oldMap).get(inte.id).Sync_Status__c)
                && inte.Sync_Status__c.equals('Submitted') 
                && ((Map<Id,Integration_Status__c>)oldMap).get(inte.id).Sync_Status__c.equals('Error')){

                    retryIds.add(inte.id);
            }
              
        }

        if(!retryIds.isEmpty()){
            retrylist = AtlasIntegrationStatus.getIntegrationStatus(retryIds);
        }

        if(retrylist.size() > 0) {
             for(Integration_Status__c inte : retrylist){

                inte.Error_Code__c = '';
                inte.Error_Message__c = '';
                inte.Message__c = 'Atlas Update Is Retriggered';
                if(inte.Method__c.equals('Site Transition')){
                    AtlasRetry.callRetryAtlaschangesite(inte.Opportunity__c,inte.id);   // Call Future method for Change site API call
                }
                //promotesiteids.add(inte.Opportunity__c);
                if(inte.Method__c.equals('Update Site')){
                  AtlasRetry.callRetryAtlasUpdateSite(inte.Opportunity__c,inte.id);  // Call Future method for Update Site API call
                }
               // updateoppids.add(inte.Opportunity__c);
           }
                 update retrylist;
        }
       
       
    }

  
}