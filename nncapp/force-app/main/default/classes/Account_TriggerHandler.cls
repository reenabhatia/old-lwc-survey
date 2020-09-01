/**
* @author Slalom Consulting
* @date 2019
*
* @description StarbucksTeam_TriggerHandler class
*/
public with sharing class Account_TriggerHandler extends TriggerFactoryHandlerBase {
	
    public override void OnAfterUpdate(List<SObject> oldList, List<SObject> newList, Map<Id,SObject> oldMap, Map<Id,SObject> newMap) {

        // Call Atlas UpdateSite on Applicable SBuxTeam Updates
        conditionallyCallAtlasUpdateSite((List<Account>)newList, (Map<Id,Account>)oldMap);
    }

    private static void conditionallyCallAtlasUpdateSite(List<Account> newList, Map<Id,Account> oldMap) {
        // INSERT oldMap = null
        // UPDATE both applicable
        // DELETE newList = null

        Boolean isDelete = newList == null;
        List<Account> accountList = isDelete ? oldMap.values() : newList;
        Set<Id> accountIdSet = new Set<Id>();

        for (Account accnt : accountList) {
            Account newAccount = isDelete ? null : accnt;
            Account oldAccount = isDelete ? accnt 
                                          : oldMap == null
                                            ? null
                                            : oldMap.get(accnt.Id);

            Boolean reqUpd = requiresAtlasSiteUpdate(newAccount, oldAccount);

            if (requiresAtlasSiteUpdate(newAccount, oldAccount)) {
                accountIdSet.add(accnt.Id);
            }
        }

        if (!accountIdSet.isEmpty()) {
            Batch_Atlas_UpdateSite batchUpdate = new Batch_Atlas_UpdateSite();
            batchUpdate.query = 'SELECT Id FROM Opportunity WHERE AccountId IN :keySet AND Atlas_Site_ID__c != NULL';
            batchUpdate.keySet = accountIdSet;
            Database.executeBatch(batchUpdate, 10);
        }
    }

    private static Boolean requiresAtlasSiteUpdate(Account newAccount, Account oldAccount) {
        return
            // UPDATE (either Name(Licensee Name) or License Code is changing)
            newAccount != null && oldAccount != null
            && (newAccount.Name != oldAccount.Name
                || newAccount.Licensee_Code__c != oldAccount.Licensee_Code__c);
    }
}