/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description AtlasRetry Handler class
*/

public with sharing class AtlasRetry {

    /*
    @method : callRetryAtlasUpdateSite
    @description : Retry future call for Update Site
    */

	@future(callout = true)
    public static void callRetryAtlasUpdateSite(Id opportunityId,Id integrationStatusId) {
        
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
                AtlasIntegrationStatus.updateintegrationstatus(String.valueOf(integrationStatusId),opportunityId,errorcode,errorMessage,message,method,syncStatus,systemName);
        	
            }else {
                errorMessage = rm.errorMessage;
                errorcode = Opportunity_TriggerHandler.geterrorcode(rm.data);
                message = 'Atlas call failed, review Log message for details';
                syncStatus = 'Error';
                AtlasIntegrationStatus.updateintegrationstatus(String.valueOf(integrationStatusId),opportunityId,errorcode,errorMessage,message,method,syncStatus,systemName);
        	}
            
        } catch(Exception e) {
            rm.isSuccess = false;
            rm.errorMessage = 'Error Please notify an Administrator: ' + e.getMessage();
        }
       
    }

    
    /*
    @method : callRetryAtlaschangesite
    @description : Retry future call for promote Site
    */

    @future(callout = true)
    public static void callRetryAtlaschangesite(Id opportunityId,Id integrationStatusId) {
        
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
                statusval = Opportunity_TriggerHandler.getstatus(rm.data);
                system.debug('statusval>>>>>>>'+ statusval);
                Opportunity opp = Opportunity_TriggerHandler.getOpportunity(opportunityId);
                opp.Atlas_Lifecycle_Status__c = statusval;
                Database.update(opp,false);
                if(opp.StageName.equals('In Development')){
                     Task tsk = Opportunity_TriggerHandler.createActivity(opp);
                     if(tsk == null) 
                AtlasIntegrationStatus.updateintegrationstatus(String.valueOf(integrationStatusId),opportunityId,errorcode,errorMessage,message,method,syncStatus,systemName);
                }
               
                AtlasIntegrationStatus.updateintegrationstatus(String.valueOf(integrationStatusId),opportunityId,errorcode,errorMessage,message,method,syncStatus,systemName);
            
            }else {
                errorMessage = rm.errorMessage;
                errorcode = Opportunity_TriggerHandler.geterrorcode(rm.data);
                message = 'Atlas call failed, review Log message for details';
                syncStatus = 'Error';
                // sdk_LoggerHelper.error('Opportunity_TriggerHandler', 'AtlasUpdateSite', rm.errorMessage);
                AtlasIntegrationStatus.updateintegrationstatus(String.valueOf(integrationStatusId),opportunityId,errorcode,errorMessage,message,method,syncStatus,systemName);
            }
            
        } catch(Exception e) {
            rm.isSuccess = false;
            rm.errorMessage = 'Error Please notify an Administrator: ' + e.getMessage();
        }
       
    }


}