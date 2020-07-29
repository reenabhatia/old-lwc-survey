/**
* @author Slalom Consulting
* @date 2019
*
* @description StarbucksTeam_TriggerHandler class
*/
public with sharing class StarbucksTeam_TriggerHandler extends TriggerFactoryHandlerBase {

	public static final String[] SBUX_TITLES_REQUIREATLASUPDATESITE = new String[] { 'BDM', 'Sr BDM', 'NAE', 'Sr NAE' };

    public override void OnAfterInsert(List<SObject> newList) {

        // Call Atlas UpdateSite on Applicable SBuxTeam Insertions
        conditionallyCallAtlasUpdateSite((List<Starbucks_Team__c>)newList, null);
    }

    public override void OnAfterUpdate(List<SObject> oldList, List<SObject> newList, Map<Id,SObject> oldMap, Map<Id,SObject> newMap) {
        
        // Call Atlas UpdateSite on Applicable SBuxTeam Updates
        conditionallyCallAtlasUpdateSite((List<Starbucks_Team__c>)newList, (Map<Id,Starbucks_Team__c>)oldMap);
    }

    public override void OnAfterDelete(List<SObject> oldList, Map<Id,SObject> oldMap) {
        
        // Call Atlas UpdateSite on Applicable SBuxTeam Deletions
        conditionallyCallAtlasUpdateSite(null, (Map<Id,Starbucks_Team__c>)oldMap);
    }

    private static void conditionallyCallAtlasUpdateSite(List<Starbucks_Team__c> newList, Map<Id,Starbucks_Team__c> oldMap) {
        // INSERT oldMap = null
        // UPDATE both applicable
        // DELETE newList = null

        Boolean isDelete = newList == null;
        List<Starbucks_Team__c> starbucksTeamList = isDelete ? oldMap.values() : newList;
        Set<Id> storeIdSet = new Set<Id>();

        for (Starbucks_Team__c sBuxTeam : starbucksTeamList) {
            Starbucks_Team__c newSBuxTeam = isDelete ? null     : sBuxTeam;
            Starbucks_Team__c oldSBuxTeam = isDelete ? sBuxTeam 
                                                     : oldMap == null
                                                       ? null
                                                       : oldMap.get(sBuxTeam.Id);

            if (requiresAtlasSiteUpdate(newSBuxTeam, oldSBuxTeam)) {
                storeIdSet.add(sBuxTeam.Store__c);
            }
        }

        if (!storeIdSet.isEmpty()) {
            Batch_Atlas_UpdateSite batchUpdate = new Batch_Atlas_UpdateSite();
            batchUpdate.query = 'SELECT Id, Atlas_Site_ID__c FROM Opportunity WHERE Store__c IN :keySet AND Atlas_Site_ID__c != NULL';
            batchUpdate.keySet = storeIdSet;
            Database.executeBatch(batchUpdate, 10);
        }
    }

    private static Boolean requiresAtlasSiteUpdate(Starbucks_Team__c newSBuxTeam, Starbucks_Team__c oldSBuxTeam) {
        if(oldSBuxTeam == NULL)
        return 
            // INSERT (Inserted records User's SBux Title must be one Atlas cares about)
            (oldSBuxTeam == null && SBUX_TITLES_REQUIREATLASUPDATESITE.contains(newSBuxTeam.Sbux_Title__c));

            // UPDATE (Updated records user is changing, and the prior or current user's SBux Title must be one Atlas cares about)
            else if(newSBuxTeam != null && oldSBuxTeam != null)
            return
            (oldSBuxTeam.User__c != newSBuxTeam.User__c
                && (SBUX_TITLES_REQUIREATLASUPDATESITE.contains(oldSBuxTeam.Sbux_Title__c)
                    || SBUX_TITLES_REQUIREATLASUPDATESITE.contains(newSBuxTeam.Sbux_Title__c))
            );
            else
            return
            // DELETE (Deleted record's User's SBux Title must be one Atlas cares about)
             (newSBuxTeam == null && SBUX_TITLES_REQUIREATLASUPDATESITE.contains(oldSBuxTeam.Sbux_Title__c));
    }
}