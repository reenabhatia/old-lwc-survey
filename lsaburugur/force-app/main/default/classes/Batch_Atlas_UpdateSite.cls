/**
* @author Slalom Consulting
* @date 2019
*
* @description StarbucksTeam_TriggerHandler class
*/
global class Batch_Atlas_UpdateSite implements Database.Batchable<sObject>,Database.AllowsCallouts, Database.Stateful {
	
	public String query;
	public Set<Id> keySet;
    global Map<Id, ReturnMessage> returnMessages;
	
	global Batch_Atlas_UpdateSite() {
		returnMessages = new Map<Id, ReturnMessage>();	
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		for (sObject obj : scope) {
			Opportunity oppty = (Opportunity)obj;
			ReturnMessage rm = Opportunity_TriggerHandler.callAtlasUpdateSiteSynchronous(oppty.Id);
			//system.debug('rm>>>>>'+ rm);
            returnMessages.put(oppty.Id, rm);
		}
	}
	
	global void finish(Database.BatchableContext BC) {
        if(!returnMessages.isEmpty()) {
            for(Id oppId:returnMessages.keySet()) {
                ReturnMessage rm = returnMessages.get(oppId);
                sdk_LoggerHelper.info('Integration Message','AtlasProxy:Request',rm.requestData, String.valueOf(oppId));

                if(rm.isSuccess){

                    sdk_LoggerHelper.info('Integration Message','AtlasProxy:Response:' + rm.responseCode, rm.data, String.valueOf(oppId));
                    AtlasIntegrationStatus.logIntegrationStatus('LS-'+String.valueOf(oppId),oppId,'','',rm.successMessage,'Update Site','Success','Atlas');

                }else{

                    sdk_LoggerHelper.error('Integration Message','AtlasProxy:Error:' + rm.responseCode, rm.data, String.valueOf(oppId));
                    AtlasIntegrationStatus.logIntegrationStatus('LS-'+String.valueOf(oppId),oppId,'',rm.errorMessage,'Atlas call failed, review Log message for details','Update Site','Error','Atlas');

                }
            }    
        }	
	}
}