@isTest
public with sharing class  StarbucksTeam_TriggerHandlerTest {
	@isTest
	public static void onupdatecheck(){

		List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        List<Opportunity> opps2 = TestDataFactory.createopportunity('Licensee',1,'checkit',True);
        List<Store__c> stores2 = TestDataFactory.createstores(1,'store',True,opps2[0]);
        opps2[0].Store__c = stores2[0].id;
        update opps2[0];
        teamslist[0].Store__c = stores2[0].id;
        update teamslist[0];
        
	}

	@isTest
	public static void ondeletecheck(){

	List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        /**
         * Nihar -- Added this as part of Store Account Refactoring Story.
         **/
        Account StoreAcc = new Account(Store_Unique_Id__c = opps[0].Id);
        StoreAcc.Is_a_Store__c = 'Licensed Store';
        StoreAcc.Name = opps[0].Name;
        StoreAcc.ParentId = opps[0].AccountId;
        StoreAcc.OwnerId = opps[0].OwnerId;
		upsert StoreAcc Store_Unique_Id__c;
        
        Store__c store = new Store__c();
        store.Name = opps[0].Name;
        store.Segment__c = 'Travel';
        store.Subsegment__c= 'Airport';
        store.Licensee__c = opps[0].AccountId;
        //store.OwnerId = opps[0].OwnerId; //Nihar--commented this out as part of Store Account Refactoring Story.
        store.Store_Account__c = StoreAcc.Id;//Nihar -- Added this as part of Store Account Refactoring Story.
        insert store;

       // List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,store.id);
        opps[0].Store__c = store.id;
        update opps[0];
        Test.startTest();
        Starbucks_Team__c team = new Starbucks_Team__c();
        team = teamslist[0];
        delete team;
        Test.stopTest();

	}
}