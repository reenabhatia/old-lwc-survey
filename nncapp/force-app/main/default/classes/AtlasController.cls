public without sharing class AtlasController {
    //Adding as Without Sharing so that the process can run and create Store records in System mode 
    @AuraEnabled
    public static ReturnMessage callSitePreRequisites(Id oppId) {
        ReturnMessage rm = new ReturnMessage();
        //first create the Store record, this also in turn create a starbucks team record
        try {
            Store__c store = StoreHelper.createStoreFromOpportunity(oppId);
            if(store.Id==null) {
                rm.isSuccess = false;
                rm.errorMessage = 'Unable to create store record, please notify and administrator';
            }
            //Link the Store to the Opp
            Opportunity o = AtlasProxy.getOpportunity(oppId);
            if(o.Store__c==null) {
                update new Opportunity(Id = oppId, Store__c = store.Id);
            }
        } catch(Exception e) {
            rm.isSuccess = false;
            rm.errorMessage = 'Error Please notify an Administrator: ' + e.getMessage();
        }
         return rm;
    }
    
    @AuraEnabled
    public static ReturnMessage callAtlasCreateSite(Id oppId) {
        ReturnMessage rm = new ReturnMessage();
        try {
            rm = AtlasProxy.createSite(oppId);
            if(rm.isSuccess) {
                //if successful, advance the stage of the Opp and write the Atlas Site ID to Opp and Store
                sObject opp = rm.returnedObjects[0];
                String atlasSiteId = String.valueOf(opp.get('Atlas_Site_ID__c'));
                if(!String.isBlank(atlasSiteId)) {                                   
                    update new Opportunity(Id = oppId, StageName = 'Prospect', Atlas_Site_ID__c = atlasSiteId);
                    Opportunity o = AtlasProxy.getOpportunity(oppId);
                    if(o.Store__c!=null) {
                        update new Store__c(Id = o.Store__c, Atlas_Site_ID__c = atlasSiteId);
                    }
                }
            }
        } catch(Exception e) {
            rm.isSuccess = false;
            rm.errorMessage = 'Error Please notify an Administrator: ' + e.getMessage();
        }
        return rm;
    }
    
    @AuraEnabled
    public static ReturnMessage callAtlasDeactivateSite(Id oppId) {
        ReturnMessage rm = new ReturnMessage();
        String errorcode = '';
        try {
            rm = AtlasProxy.deactivateSite(oppId);
            if(rm.isSuccess){
                update new Opportunity(Id = oppId, NextStep='Deactivating', Atlas_Lifecycle_Status__c = 'Prospect', StageName = 'Closed Lost');
                //Clear out the bypass NextStep='Deactivating'
                update new Opportunity(Id = oppId, NextStep='');
                
                Opportunity o = AtlasProxy.getOpportunity(oppId);
                if(o.Store__c != null){
                    update new Store__c(Id = o.Store__c, Status__c = 'Dead');
                }
            }else{
                if(rm.data != null)
                errorcode = Opportunity_TriggerHandler.geterrorcode(rm.data);
                if(errorcode.equals('4001013'))
                Task tsk = UtilityMethod.createActivityOnDeactivate(oppId);
            }  
        } catch(Exception e) {
            rm.isSuccess = false;
            rm.errorMessage = 'Error Please notify an Administrator: ' + e.getMessage();
        }
        return rm;
    }
}