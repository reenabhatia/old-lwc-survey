/**
* @author Slalom Consulting
* @date 2019
*
* @description StarbucksTeam_TriggerHandler class
*/
trigger StarbucksTeamTrigger on Starbucks_Team__c (after insert, after update, after delete) {
    TriggerFactory.createHandler();
}