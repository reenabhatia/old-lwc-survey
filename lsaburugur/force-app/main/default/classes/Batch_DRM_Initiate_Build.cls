/*******
 * @description  Batch class runs daily to populate the Store_Hierarchy__c table with Stores and their corresponding User Hierarchy.
 * @author andyj@slalom.com
 * @version 1.0
 * @date 5/8/2019
 * @group LSCRM
 ******/
global class Batch_DRM_Initiate_Build  implements Database.Batchable<sObject> {
	global Database.QueryLocator start(Database.BatchableContext bc) {
        //return all records out of the table to delete
    	return Database.getQueryLocator([SELECT Id From Store_Hierarchy__c]);
    }
    
    global void execute(Database.BatchableContext bc, List<Store_Hierarchy__c> scope) {
    	delete scope;
    }
    
    global void finish(Database.BatchableContext bc) {
        //once delete is finished, then invoke the Batch to Populate the Store_Hierarchy__c table
        Batch_DRM_StoreHierarchy myBatchObject = new Batch_DRM_StoreHierarchy(); 
        Id batchId = Database.executeBatch(myBatchObject);
    }
}