/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description OpportunityTrigger 
*/

trigger OpportunityTrigger on Opportunity (after update) {
	TriggerFactory.createHandler();
}