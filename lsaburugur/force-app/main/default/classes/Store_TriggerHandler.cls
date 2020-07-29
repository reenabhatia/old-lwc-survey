/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description Store_TriggerHandler  class
*/

/*@Method: OnAfterUpdate
* @description: 1. Check if any of Jira mentioned field is changed on Store call the update Site API 
*/
public with sharing class Store_TriggerHandler extends TriggerFactoryHandlerBase{
    
     public override void OnAfterUpdate(List<SObject> oldList, List<SObject> newList, Map<Id,SObject> oldMap, Map<Id,SObject> newMap)
    {
        system.debug('inside store trigger>>>>');

        Set<Id> storeIds = new Set<Id>();
        Map<Id,Opportunity> opprecord = new Map<Id,Opportunity>();
        Set<Id> oppIds = new Set<Id>();
  
        for(Store__c store: (List<Store__c>)newList){

            if((store.Site_Name__c != ((Map<Id,Store__c>)oldMap).get(store.id).Site_Name__c ||
                store.Address_1__c != ((Map<Id,Store__c>)oldMap).get(store.id).Address_1__c ||
                store.Address_2__c != ((Map<Id,Store__c>)oldMap).get(store.id).Address_2__c ||
                store.City__c != ((Map<Id,Store__c>)oldMap).get(store.id).City__c ||
                store.State__c != ((Map<Id,Store__c>)oldMap).get(store.id).State__c ||
                store.Postal_Code__c != ((Map<Id,Store__c>)oldMap).get(store.id).Postal_Code__c ||
                store.Country__c != ((Map<Id,Store__c>)oldMap).get(store.id).Country__c ||
                store.External_Presence__c != ((Map<Id,Store__c>)oldMap).get(store.id).External_Presence__c ||
                store.Estimated_Open_Date__c != ((Map<Id,Store__c>)oldMap).get(store.id).Estimated_Open_Date__c ||
                store.Store_Type__c != ((Map<Id,Store__c>)oldMap).get(store.id).Store_Type__c ||
                store.Atlas_Segment__c != ((Map<Id,Store__c>)oldMap).get(store.id).Atlas_Segment__c ||
                store.Atlas_Subsegment__c != ((Map<Id,Store__c>)oldMap).get(store.id).Atlas_Subsegment__c ||
                store.Store_Profile_Type__c != ((Map<Id,Store__c>)oldMap).get(store.id).Store_Profile_Type__c ||
                store.Engine_Type__c != ((Map<Id,Store__c>)oldMap).get(store.id).Engine_Type__c ||
                store.Planned_Store_Size__c != ((Map<Id,Store__c>)oldMap).get(store.id).Planned_Store_Size__c || 
                store.Licensee__c != ((Map<Id,Store__c>)oldMap).get(store.id).Licensee__c ||
                store.Licensee_Store_Number__c != ((Map<Id,Store__c>)oldMap).get(store.id).Licensee_Store_Number__c) && store.Atlas_Site_ID__c != null
                ){
                 storeIds.add(store.Id);
            }
               
        }

        if(storeIds.size() > 0){
            system.debug('Store_TriggerHandler update >>>>');
            opprecord = getSOQLs.getOpportunityfromStore(storeIds); 
            oppIds = opprecord.keySet();
        }
        
        if(oppIds.size() > 0){

         for(Id o:oppIds){

            if(opprecord.containsKey(o)){
                if(opprecord.get(o).Atlas_Site_ID__c != null)
                Opportunity_TriggerHandler.callAtlasUpdateSite(o);
            }
            
         }
         
        }

    }

}