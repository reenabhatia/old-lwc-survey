@isTest
public with sharing class StoreHelperTest {

	@isTest
	public static void testcreateStoreFromOpportunity(){

		List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        
        Test.startTest();
        Store__c newstore = new Store__c();
        newstore = StoreHelper.createStoreFromOpportunity(opps[0].id);
        opps[0].Store__c = newstore.id;
        update opps[0];
        newstore = StoreHelper.createStoreFromOpportunity(opps[0].id);
        Test.stopTest();
	}
	
}