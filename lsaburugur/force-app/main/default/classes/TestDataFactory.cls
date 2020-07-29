/*****************************
Author: Nita Disale - Slalom
@Description : This is a factory class used to create Account,Opportunity, Store, Starbucks Teams for testing purpose
******************************/
@isTest
public with sharing class TestDataFactory {


     public static List<Account> createAccounts(String recordTypeName, Integer count, String dupeRandomizer, Boolean insertRecords){
        List<Account> newAccounts = new List<Account>();
        RecordType r = UtilityMethod.getRecordTypesByDeveloperName(Account.SObjectType.getDescribe()).get('Licensee');

        for(Integer i=0; i<count; i++){
            Account a = new Account(
                Name = 'TestAccount' + dupeRandomizer + i,
                RecordTypeId = r.Id,
                Licensee_Code__c =   dupeRandomizer + i
            );
            newAccounts.add(a);
        }
        if(insertRecords) insert newAccounts;
        return newAccounts;
    }

    public static List<Opportunity> createopportunity(String recordTypeName,integer count,String dupeRandomizer,boolean insertRecords){
        List<Opportunity> newOpps = new List<Opportunity>();
        User u = new User();
        u = [SELECT Id,Sbux_Title__c 
             	FROM User WHERE IsActive = true 
             		AND Profile.Name = 'System Administrator' limit 1];
        u.Sbux_Title__c = 'NAE';
        TestDataFactory.forcedUpdate(u);
        User user = new User();
        user.id = UserInfo.getUserId();
        user.Sbux_Title__c = 'BDM';
        update user;
        Account[] acct = createAccounts(recordTypeName,1, dupeRandomizer, TRUE);

        for(Integer i=0; i<count; i++){
            Opportunity o = new Opportunity(
                Name = 'TestOpportunity'+i,
                AccountId = acct[0].Id,
                Atlas_Status_Indicator__c ='10',
                Atlas_Lifecycle_Status__c ='Prospect',
                Store_Type__c='Cafe',
                Radius_Date__c=Date.valueof('2020-09-08'),
                MLA__c = TRUE,
                CloseDate = Date.valueof('2020-09-08'),
                Atlas_Dead_Date__c = Date.valueof('2020-09-08'),
                Relo_Indicator__c ='Y',
                Site_Name__c ='Site' +dupeRandomizer,
                Store_Profile_Type__c ='Concept',
                Country__c ='US',
                Planned_Store_Size_ft__c =14.6,
                Address_1__c ='abc',
                Address_2__c ='xyz',
                City__c ='Seattle',
                State_Province__c ='WA',
                Postal_Code__c ='13210',
                Atlas_Segment__c ='GROCERY',
                Atlas_Subsegment__c ='Grocery',
                Site_ID__c = '12345',
                StageName ='Target',
                Estimated_Average_Weekly_Sales__c =44.4,
                Currency__c = 'USD',
                Segment__c ='Lodging',
                Subsegment__c = 'Gaming with Lodging',
                Reason_Code__c = 'High Rent',
                Atlas_Status_Comments__c = 'High Rent Indeed',
                Engine_Type__c = 'Doppio',
                External_Presence__c = 'Low',
                OwnerId = u.Id

            );
            newOpps.add(o);
        }
        if(insertRecords) insert newOpps;
        return newOpps;

    }

    public static List<Store__c> createstores(integer count, String dupeRandomizer,boolean insertRecords,Opportunity opp){
      //Account[] acct = createAccounts('Licensee',1, 'Licenseeaccount', TRUE); 

        List<Store__c> newstores = new List<Store__c>();
        for(Integer i = 0;i<count ;i++){

            Store__c store = new Store__c();
            store.Licensee__c = opp.AccountId;
            store.Segment__c = 'Grocery';
            store.Subsegment__c = 'Convenience Store';
            store.Site_Name__c = opp.Site_Name__c + i;
            store.Address_1__c = opp.Address_1__c;
            store.Address_2__c = opp.Address_2__c;
            store.City__c = opp.City__c;
            store.State__c = opp.State_Province__c;
            store.Postal_Code__c = opp.Postal_Code__c;
            store.Country__c = opp.Country__c;
            store.Store_Type__c = opp.Store_Type__c;
            store.Licensee_Store_Number__c = '123' + i;
            store.External_Presence__c = 'Low';
            store.Engine_Type__c = 'Drive Thru';
            store.Planned_Store_Size__c = String.valueOf(opp.Planned_Store_Size_ft__c);
            store.Store_Profile_Type__c = opp.Store_Profile_Type__c;
            store.OwnerId = opp.OwnerId;
            store.Commissary_Status__c = 'Is Commissary';

            /*
            insert store;
            store = [Select id, Name,CRM_ID__c from Store__c where id  =: store.id];
            */
            newstores.add(store);
		}
        if(newstores!=null && insertRecords) insert newstores;
        newstores = [SELECT Id, 
                     		Name,
                     		CRM_ID__c,
                     		Licensee__c,
                            Segment__c,
                            Subsegment__c,
                            Site_Name__c,
                            Address_1__c,
                            Address_2__c,
                            City__c,
                            State__c,
                            Postal_Code__c,
                            Country__c,
                            Store_Type__c,
                            Licensee_Store_Number__c,
                            External_Presence__c,
                            Engine_Type__c,
                            Planned_Store_Size__c,
                            Store_Profile_Type__c 
                    			FROM Store__c 
                     				WHERE id IN :newstores For Update];
        return newstores;
    }


    public static List<Starbucks_Team__c> createstarbucksTeam(integer count, String dupeRandomizer,boolean insertRecords,Id storeid){
      

        List<Starbucks_Team__c> newteams = new List<Starbucks_Team__c>();

        User u = new User();
        u = [SELECT Id,Sbux_Title__c FROM User WHERE Sbux_Title__c = 'NAE' And IsActive = true limit 1];
        Id userid = UserInfo.getUserId();
        for(Integer i=0;i<count ;i++){
            Starbucks_Team__c team = new Starbucks_Team__c(
                 User__c = u.Id,
                 Store__c = storeid
                );
            newteams.add(team);
        }
        if(newteams!=null && insertRecords) insert newteams;
        return newteams;


    }

    public static List<Integration_Status__c> createIntegrationStatus(integer count,boolean insertRecords,String dupeRandomizer,Id oppid){
        List<Integration_Status__c> intelist = new List<Integration_Status__c>();
        for(Integer i = 0 ; i < count ; i++){
            Integration_Status__c inte = new Integration_Status__c(
                Name = 'LS-'+ oppid,
                Error_Code__c = '4001005',
                Error_Message__c = 'Value out of range:',
                Message__c = dupeRandomizer,
                Sync_Status__c= 'Error',
                System__c ='Atlas',
                Method__c = 'Update Site'
                );
            intelist.add(inte);
        }

      if(insertRecords) insert intelist;
      return intelist;

    }

    public static List<Address__c> createAddress(integer count,boolean insertRecords,String dupeRandomizer,Id storeid){
        List<Address__c> addresslist = new List<Address__c>();
        for(Integer i = 0 ; i < count ; i++){
            Address__c addr = new Address__c(
                Name = 'addr'+ dupeRandomizer + i,
                Address_1__c = '101 Main',
                City__c = 'Syracuse',
                State_Province__c = 'NY',
                Store__c = storeid,
                Postal_Code__c = '13210',
                Country__c = 'US',
                Primary__c ='Y',
                Account_Number__c ='234',
                Status__c = 'Y'
                );
            addresslist.add(addr);
        }

      if(insertRecords) insert addresslist;
      return addresslist;

    }
    
     public static List<Scorecard_Approval__c> createScorecardApproval(integer count,Id oppid){
        List<Scorecard_Approval__c> scorelist = new List<Scorecard_Approval__c>();
        for(Integer i = 0 ; i < count ; i++){
            Scorecard_Approval__c score = new Scorecard_Approval__c(
                Name = 'Scorecard'+ i,
                Opportunity__c = oppid
                );
            scorelist.add(score);

        }
        if(scorelist.size() >0){
            insert scorelist;
        }

        return scorelist;


    }

    public static Database.SaveResult forcedUpdate(SObject o) {
        Database.SaveResult result;
        while (result == null) { 
            try { 
                result = Database.update(o);
            } catch (DmlException e) {
                if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                    throw e;
                }
            }
        }
        return result;
    }
    
    public static List<Shipping_Billing_Request__c> createSBR(integer count,Id storeid){
        List<Shipping_Billing_Request__c> sbrlist = new List<Shipping_Billing_Request__c>();
        for(Integer i = 0 ; i < count ; i++){
            Shipping_Billing_Request__c sbr = new Shipping_Billing_Request__c(
                Store__c = storeid
                );
            sbrlist.add(sbr);
        }
        if(sbrlist.size() >0){
            insert sbrlist;
        }
        return sbrlist;
    }


    public static List<Store_Attribute__c> createautoshipAttribute(integer count,Id storeid){
        RecordType r = UtilityMethod.getRecordTypesByDeveloperName(Store_Attribute__c.SObjectType.getDescribe()).get('Autoship');
        List<Store_Attribute__c> stratt = new List<Store_Attribute__c>();
        for(Integer i = 0 ; i < count ; i++){
            Store_Attribute__c satt = new Store_Attribute__c(
                Store__c = storeid,
                RecordTypeId = r.id
                );
            stratt.add(satt);
        }
        if(stratt.size() >0){
            insert stratt;
        }
        return stratt;
    }

    public static List<Store_Attribute__c> createMarketingAttribute(integer count,Id storeid){
        RecordType r = UtilityMethod.getRecordTypesByDeveloperName(Store_Attribute__c.SObjectType.getDescribe()).get('Marketing');
        List<Store_Attribute__c> stratt = new List<Store_Attribute__c>();
        for(Integer i = 0 ; i < count ; i++){
            Store_Attribute__c satt = new Store_Attribute__c(
                Store__c = storeid,
                RecordTypeId = r.id,
                Ships_Marketing_Kit_Elsewhere__c = 'No',
                Menu_Board_Program__c = 'Web2Print - Not Regionally Priced',
                Pricing_Region__c = '14 - CAN Resort/Remote Alberta',
                Indoor_Menu_Type_1__c = 'Short',
                Indoor_Menu_Type_2__c = 'Digital - Doppio',
                Promotional_Door_and_Window_Cling__c = 'No',
                Daily_Offerings_Board_Sign__c = 'No',
                Menu_Panel_5__c = 'No',
                Menu_Panel_6__c = 'Yes',
                Menu_Panel_7__c = 'No',
                Menu_Panel_8__c = 'Yes',
                Menu_1_Qty__c = 3,
                Menu_2_Qty__c = 3,
                Food_Program__c = 'Bakery and Warming',
                Pastry_Case__c = 'Harmony 51" Chilled',
                Additional_Pastry_Case__c = 'Wall of Chill & Food Cubby',
                Food_Pricing_Tier__c = 'Alaska',
                Coffee_Signage__c = 'Medium'
                );
            stratt.add(satt);
        }
        if(stratt.size() >0){
            insert stratt;
        }
        return stratt;
    }

}