public class StoreHelper {
    public static String RECORD_TYPE_STORE = 'Store';
    private static RecordType getRecordTypeByDeveloperName(String rtDeveloperName) {
        RecordType[] rts = [SELECT Id, Name, DeveloperName FROM RecordType 
                                WHERE SObjectType = 'Store__c' 
                                        AND IsActive = TRUE
                                        AND DeveloperName = :rtDeveloperName];
        if(!rts.isEmpty()) {
            return rts[0];
        }
        return new RecordType();
    }
    
/*@Method: getOpportunity
* @description: SOQL to get opportunity record
*/
    private static Opportunity getOpportunity(Id oppId) {
        if(oppId==null) return new Opportunity();
        Opportunity[] opp = [SELECT Id, 
                                    Atlas_Site_ID__c,
                                    Address_1__c,
                                    Address_2__c,
                                    Estimated_Annualized_Sales__c,
                                    Atlas_Segment__c,
                                    Atlas_Subsegment__c,
                                    Estimated_Average_Weekly_Sales__c,
                                    City__c,
                                    Country__c,
                                    Currency__c,
                                    Owner.Sbux_Division__c,
                                    Engine_Type__c,
                                    CloseDate,
                                    External_Presence__c,
                                    AccountId,
                                    Name,
                                    OwnerId,
                                    Planned_Store_Size_ft__c,
                                    Postal_Code__c,
                                    Owner.Region__c,
                                    Segment__c,
                                    Site_Name__c,
                                    State_Province__c,
                                    Store_Profile_Type__c,
                                    Store_Type__c,
                                    Subsegment__c,
                                    Store__c
                             FROM Opportunity 
                             WHERE Id = :oppId LIMIT 1];
        if(!opp.isEmpty()) {
            return opp[0];
        }
        return new Opportunity(Id = oppId);  
    }
    

/*@Method: createStoreFromOpportunity
* @description: Create store related to opportunity is not present else update the store if already present
*/
    public static Store__c createStoreFromOpportunity(Id oppId) {
        if(oppId==null) return new Store__c();
        Opportunity opp = getOpportunity(oppId);
        if(opp.Store__c!=null) {
            return updateStoreFromOpportunity(oppId);    
        }
        //Set the correct Record Type
        RecordType rt = UtilityMethod.getRecordTypesByDeveloperName(Store__c.SObjectType.getDescribe()).get(RECORD_TYPE_STORE);
        /**
         * Nihar -- Added this as part of Store Account Refactoring Story.
         **/
        Account StoreAcc = new Account(Store_Unique_Id__c = opp.Id);
        StoreAcc.Is_a_Store__c = 'Licensed Store';
        StoreAcc.Name = opp.Name;
        StoreAcc.ParentId = opp.AccountId;
        StoreAcc.OwnerId = opp.OwnerId;
		upsert StoreAcc Store_Unique_Id__c;
        
        Store__c store = new Store__c();
        store.Address_1__c = opp.Address_1__c;
        store.Address_2__c = opp.Address_2__c;
        store.Annualized_Sales__c = String.valueOf(opp.Estimated_Annualized_Sales__c);
        store.Atlas_Segment__c = opp.Atlas_Segment__c;
        store.Atlas_Subsegment__c = opp.Atlas_Subsegment__c;
        store.Average_Weekly_Sales__c = opp.Estimated_Average_Weekly_Sales__c;
        store.City__c = opp.City__c;
        store.Country__c = opp.Country__c;
        store.Currency__c = opp.Currency__c;
        store.put('Division__c', opp.Owner.Sbux_Division__c);
        store.Engine_Type__c = opp.Engine_Type__c;
        store.Estimated_Open_Date__c = opp.CloseDate;
        store.External_Presence__c = opp.External_Presence__c;
        store.Licensee__c = opp.AccountId;
        store.Name = opp.Name;
        //store.OwnerId = opp.OwnerId;Nihar --commented this out as part of Store Account Refactoring Story.
        //store.StoreOwnerId__c = opp.OwnerId;
        store.Store_Account__c = StoreAcc.Id;//Nihar -- Added this as part of Store Account Refactoring Story.
        store.Planned_Store_Size__c = String.valueOf(opp.Planned_Store_Size_ft__c);
        store.Postal_Code__c = opp.Postal_Code__c;
        store.put('Region__c', opp.Owner.Region__c);
        store.Segment__c = opp.Segment__c;
        store.Site_Name__c = opp.Site_Name__c;
        store.State__c = opp.State_Province__c;
        store.Store_Profile_Type__c = opp.Store_Profile_Type__c;
        store.Store_Type__c = opp.Store_Type__c;
        store.Subsegment__c = opp.Subsegment__c;
        store.RecordTypeId = rt.Id;
        insert store;
        return store;
    }


/*@Method: updateStoreFromOpportunity
* @description: update the store record fields based on Opportunity record 
*/
    public static Store__c updateStoreFromOpportunity(Id oppId) {

        Opportunity opp = getSOQLs.getSingleOpportunityStore(oppId);
        if(opp == null && opp.Id ==null) return new Store__c();
        Store__c store = new Store__c();

        store.Id = opp.Store__r.Id;
        store.Address_1__c = opp.Address_1__c;
        store.Address_2__c = opp.Address_2__c;
        store.Atlas_Segment__c = opp.Atlas_Segment__c;
        store.Atlas_Subsegment__c = opp.Atlas_Subsegment__c;
        store.City__c = opp.City__c;
        store.Country__c = opp.Country__c;
        store.Engine_Type__c = opp.Engine_Type__c;
        store.Estimated_Open_Date__c = opp.CloseDate;
        store.External_Presence__c = opp.External_Presence__c;
        store.Licensee__c = opp.AccountId;
        store.Planned_Store_Size__c = String.valueOf(opp.Planned_Store_Size_ft__c);
        store.Postal_Code__c = opp.Postal_Code__c;
        store.Site_Name__c = opp.Site_Name__c;
        store.State__c = opp.State_Province__c;
        store.Store_Profile_Type__c = opp.Store_Profile_Type__c;
        store.Store_Type__c = opp.Store_Type__c;
        store.Atlas_Site_ID__c = opp.Atlas_Site_ID__c;
        
        update store;
        return store;
    }
    
    
}