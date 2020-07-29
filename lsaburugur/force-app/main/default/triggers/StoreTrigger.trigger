/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description OpportunityTrigger 
*/
trigger StoreTrigger on Store__c (after update) {
	TriggerFactory.createHandler();

}