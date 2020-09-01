/**
* @author Slalom Consulting
* @date 2019
*
* @description StarbucksTeam_TriggerHandler class
*/
trigger AccountTrigger on Account (after update) {
    TriggerFactory.createHandler();
}