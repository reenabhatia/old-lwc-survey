/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description IntegrationStatusTrigger for Retry Error(Update Site and Promote Site)
*/

trigger IntegrationStatusTrigger on Integration_Status__c (after update) {
	TriggerFactory.createHandler();

}