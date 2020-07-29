/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description OpportunityTrigger Handler class
*/

/*@Method: OnAfterUpdate
* @description: 1. Check if any of Jira mentioned field changes on Opportunity ,then call update on Store record for related fields.
                2. IF Opportunity Stage is changed and is in 'In Approval' or 'In Development' , call Change Site API
*/

public class Opportunity_TriggerHandler extends TriggerFactoryHandlerBase{

    public override void OnAfterUpdate(List<SObject> oldList, List<SObject> newList, Map<Id,SObject> oldMap, Map<Id,SObject> newMap)
    {
    	system.debug('inside Opportunity_TriggerHandler>>>>');
        Set<Id> oppIds = new Set<Id>();
        Set<Id> changesiteIds = new Set<Id>();
         

    	for(Opportunity opp: (List<Opportunity>)newList){

    		if((opp.Site_Name__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).Site_Name__c ||
    			opp.Address_1__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).Address_1__c ||
    			opp.Address_2__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).Address_2__c ||
    			opp.City__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).City__c ||
    			opp.State_Province__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).State_Province__c ||
    			opp.Postal_Code__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).Postal_Code__c ||
    			opp.Country__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).Country__c ||
    			opp.External_Presence__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).External_Presence__c ||
    			opp.CloseDate != ((Map<Id,Opportunity>)oldMap).get(opp.id).CloseDate ||
    			opp.Store_Type__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).Store_Type__c ||
    			opp.Atlas_Segment__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).Atlas_Segment__c ||
    			opp.Atlas_Subsegment__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).Atlas_Subsegment__c ||
    			opp.Store_Profile_Type__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).Store_Profile_Type__c ||
    			opp.Engine_Type__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).Engine_Type__c ||
    			opp.Planned_Store_Size_ft__c != ((Map<Id,Opportunity>)oldMap).get(opp.id).Planned_Store_Size_ft__c ||
    			opp.AccountId != ((Map<Id,Opportunity>)oldMap).get(opp.id).AccountId) && opp.Atlas_Site_ID__c != null
    			){
    			oppIds.add(opp.Id);
    		}

    	}
        for(Opportunity opp: (List<Opportunity>)newList){

            if((opp.StageName != ((Map<Id,Opportunity>)oldMap).get(opp.id).StageName) &&
                (opp.StageName =='In Approval' || opp.StageName =='In Development') && opp.Atlas_Site_ID__c != null){
                changesiteIds.add(opp.Id);

            }
        }

    	if(oppIds.size() > 0){
            system.debug('updateSite>>>>>');
    		Map<Id,Opportunity> newupdatemap = new Map<Id,Opportunity>();
    		for(Id o : oppIds){
                Store__c store = StoreHelper.updateStoreFromOpportunity(o);   //Call to update the Store record
                //if(store.Id != null)
                //callAtlasUpdateSite(o);	
    		}
    		
    	}
        if(changesiteIds.size() >0){
            system.debug('changesiteIds>>>>>>');
            
		
            //callAtlasChangeSites(changesiteIds);
            for(Id o : changesiteIds){
                callAtlasChangeSite(o);
            }
        }

    }


/*@Method: callAtlasUpdateSite
* @description: Future method to call Atlas Update Site API
*/
    @future(callout = true)
    public static void callAtlasUpdateSite(Id opportunityId) {
        callAtlasUpdateSiteSynchronous(opportunityId);
    }

    public static ReturnMessage callAtlasUpdateSiteSynchronous(Id opportunityId) {
        
          ReturnMessage rm = new ReturnMessage();
          String errorcode;
          String errorMessage;
          String message;
          String method ='Update Site';
          String syncStatus;
          String systemName = 'Atlas';
        try {
            rm = AtlasProxy.updateSite(opportunityId);
            
            if(rm.isSuccess){
                errorcode ='';
                errorMessage ='';
                message = rm.successMessage;
                syncStatus = 'Success';
                if(!System.isBatch()) {
                AtlasIntegrationStatus.logIntegrationStatus('LS-'+String.valueOf(opportunityId),opportunityId,errorcode,errorMessage,message,method,syncStatus,systemName);
               }
            
            }else {
                errorMessage = rm.errorMessage;
                message = 'Atlas call failed, review Log message for details';
                syncStatus = 'Error';
                if(!System.isBatch()) {
                AtlasIntegrationStatus.logIntegrationStatus('LS-'+String.valueOf(opportunityId),opportunityId,errorcode,errorMessage,message,method,syncStatus,systemName);
            }
        }
            
        } catch(Exception e) {
            rm.isSuccess = false;
            rm.errorMessage = 'Error Please notify an Administrator: ' + e.getMessage();
        }
        return rm;
    }


    public static String geterrorcode(String xmlstring){
        Dom.Document doc = new Dom.Document();
        doc.load(xmlstring);
        Dom.XMLNode details = doc.getRootElement();
        String code = details.getChildElement('code', null).getText();
        return code;
    }

    /*@Method: callAtlaschangesite
    * @description: Future method to call Atlas Promote Site API
    */
    @future(callout = true)
    public static void callAtlaschangesite(Id opportunityId) {
        Long startTime = DateTime.now().getTime();
        Long finishTime = DateTime.now().getTime();
        Key_Value_Setting__mdt[] settings = [SELECT DeveloperName, Value__c,Description__c,Filter_Criteria__c
                                              FROM Key_Value_Setting__mdt 
                                              where DeveloperName = 'Atlas_Call_Lag' LIMIT 1]; 
        Integer lagMilliseconds = 2000; //default to 2 seconds
        if(!settings.isEmpty() && settings[0].Value__c!='') {
            lagMilliseconds = integer.valueof(String.valueOf(settings[0].Value__c));
        }
        while ((finishTime - startTime) < lagMilliseconds) {
            //sleep for n milliseconds
            finishTime = DateTime.now().getTime();
        }
        ReturnMessage rm = new ReturnMessage();
        String errorcode;
        String errorMessage;
        String message;
        String method ='Site Transition';
        String syncStatus;
        String systemName = 'Atlas';
        String statusval;
        try {
            rm = AtlasProxy.promoteSite(opportunityId);
            
            if(rm.isSuccess){
                errorcode ='';
                errorMessage ='';
                message = rm.successMessage;
                syncStatus = 'Success';
                if(rm.data != null)
                statusval = getstatus(rm.data);
                system.debug('statusval>>>>>>>'+ statusval);
                Opportunity opp = getOpportunity(opportunityId);
                opp.Atlas_Lifecycle_Status__c = statusval;
                Database.update(opp,false);
                if(opp.StageName.equals('In Development')){
                     Task tsk = createActivity(opp);
                     if(tsk == null) 
                    AtlasIntegrationStatus.logIntegrationStatus('LS-'+String.valueOf(opportunityId),opportunityId,errorcode,'Create Project activity failed.',message,method,syncStatus,systemName);
                }
               
                AtlasIntegrationStatus.logIntegrationStatus('LS-'+String.valueOf(opportunityId),opportunityId,errorcode,errorMessage,message,method,syncStatus,systemName);
            
            }else {
                errorMessage = rm.errorMessage;
                message = 'Atlas call failed, review Log message for details';
                syncStatus = 'Error';
                // sdk_LoggerHelper.error('Opportunity_TriggerHandler', 'AtlasUpdateSite', rm.errorMessage);
                AtlasIntegrationStatus.logIntegrationStatus('LS-'+String.valueOf(opportunityId),opportunityId,errorcode,errorMessage,message,method,syncStatus,systemName);
            }
            
        } catch(Exception e) {
            rm.isSuccess = false;
            rm.errorMessage = 'Error Please notify an Administrator: ' + e.getMessage();
        }  
    }

    public static String getstatus(String xmlstring){
        Dom.Document doc = new Dom.Document();
        doc.load(xmlstring);
        Dom.XMLNode details = doc.getRootElement();
        String status = details.getChildElement('status', null).getText();
        return status;
    }


    public static Opportunity getOpportunity(Id oppId) {
        if(oppId==null) return new Opportunity();
        Opportunity[] opp = [SELECT Id, 
                                    Atlas_Lifecycle_Status__c,OwnerId,
                                    StageName
                             FROM Opportunity 
                             WHERE Id = :oppId LIMIT 1];
        if(!opp.isEmpty()) {
            return opp[0];
        }
        return new Opportunity(Id = oppId);  
    }



/*@Method: createActivity
* @description: Create Activity once opportunity stage is in 'In Development'
*/
    public static Task createActivity(Opportunity opp){
        if(opp.id == null) return new Task();
        RecordType rt = UtilityMethod.getRecordTypesByDeveloperName(Task.SObjectType.getDescribe()).get('Ls_Activities');
        
        User user =  UtilityMethod.getuser('SYSTEM');
        
        if(opp.StageName.equals('In Development')){

                Task tsk = new Task(
                whatID = opp.id,
                Ownerid = user.Id,
                Queue_Name__c ='LS CR Queue',
                Type ='Create Projects',
                Task_Type__c = 'Create Projects', 
                Status ='Not Started',
                Subject = 'Create Projects',
                RecordTypeId = rt.Id
                );
                insert tsk;
                return tsk;
        }
        else return new Task();  
    }

}