/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description AtlasIntegrationStatus class
*/
public with sharing class AtlasIntegrationStatus {

	private static String LOG_CUSTOM_OBJECT_NAME ='Integration_Status__c';

/* @description: Insert/update Integration Status record based on provided information
*/
 public static void logIntegrationStatus(String name ,String opp,String errorcode, String errorMessage, String message, String method, String syncStatus,String systemName) {

        Schema.SObjectType exceptionLogObjDesc = Schema.getGlobalDescribe().get(LOG_CUSTOM_OBJECT_NAME);
        SObject exceptionLogObj = exceptionLogObjDesc.newSObject();
         
        system.debug('Integration_Status__c>>>>>');
        exceptionLogObj.put('Name', name);
        exceptionLogObj.put('Error_Code__c', errorcode);
        exceptionLogObj.put('Error_Message__c', errorMessage);
        exceptionLogObj.put('Message__c', message);
        exceptionLogObj.put('Method__c', method);
        exceptionLogObj.put('Sync_Status__c', syncStatus);
        exceptionLogObj.put('System__c', systemName);
        exceptionLogObj.put('Opportunity__c', opp);
    
        Database.upsert(exceptionLogObj, True);
    }

    /* @description: get Integration Status SOQL based on given integration status set of ids
*/

    public static List<Integration_Status__c> getIntegrationStatus(Set<Id> inteids) {

        if(inteids==null) return new List<Integration_Status__c>();
        List<Integration_Status__c> intelist = [SELECT Id, 
                                    Sync_Status__c,
                                    Error_Code__c,
                                    Error_Message__c,
                                    Message__c,
                                    Method__c,
                                    Opportunity__c,
                                    System__c
                             FROM Integration_Status__c 
                             WHERE Id IN :inteids];
        if(intelist.size() > 0)
        return intelist;
        else 
        return new List<Integration_Status__c>();
    }


    /*
    @method: getIntegrationStatusId 
    @description: get Integration Status SOQL based on given integration status String id
    */

    public static Integration_Status__c getIntegrationStatusId(String inteid) {

        if(inteid==null) return new Integration_Status__c();
        Integration_Status__c intelist = [SELECT Id, 
                                    Sync_Status__c,
                                    Error_Code__c,
                                    Error_Message__c,
                                    Message__c,
                                    Method__c,
                                    Opportunity__c,
                                    System__c
                             FROM Integration_Status__c 
                             WHERE Id =: inteid];
        if(intelist != null)
        return intelist;
        else 
        return new Integration_Status__c();
    }


/*
    @method: updateintegrationstatus 
    @description: update Integration Status record 
    */
 public static void updateintegrationstatus(String inteid ,String opp,String errorcode, String errorMessage, String message, String method, String syncStatus,String systemName) {
        Integration_Status__c inteobj = new Integration_Status__c();
        List<Integration_Status__c> updatelist = new List<Integration_Status__c>();
        inteobj = getIntegrationStatusId(inteid);
        if(inteobj != null){
            inteobj.Error_Code__c = errorcode;
            inteobj.Error_Message__c = errorMessage;
            inteobj.Message__c = message;
            inteobj.Sync_Status__c = syncStatus;
            inteobj.System__c = systemName;
            updatelist.add(inteobj);
        }

        if(updatelist.size() > 0)
        update updatelist;

    }
}