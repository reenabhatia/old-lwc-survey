@isTest
public with sharing class AtlasPayloadTest {
    @isTest
    public static void generateXMLPayloadTest(){

        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);

        opps[0].Store__c = stores[0].id;
        update opps[0];

        Test.startTest();
        String payload = AtlasPayload.generateXMLPayload(opps[0].id);
        system.assert(payload != null);
        Test.stopTest();
    }

    @isTest
    public static void generateXMLChangeSiteTest(){
    	String status = 'Deactivate';
    	 List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        Test.startTest();
        String payload = changeSitePayload.generateXMLChangeSite(opps[0].id,status);
        system.assert(payload != null);
        Test.stopTest();


    }
}