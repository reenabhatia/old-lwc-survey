@isTest
public with sharing class AtlasIntegrationStatusTest {

	@isTest
	public static void testlogIntegrationStatus(){

	List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);


        opps[0].Store__c = stores[0].id;
        update opps[0];


        List<Integration_Status__c> listchelck = TestDataFactory.createIntegrationStatus(1,True,'',opps[0].id);
        Set<Id> inteids = new Set<Id>();
        if(!listchelck.isEmpty()) {
        	for(Integration_Status__c i: listchelck){
        		inteids.add(i.id);
        	}
        }

	Test.startTest();
	AtlasIntegrationStatus.logIntegrationStatus(listchelck[0].name,opps[0].id,listchelck[0].Error_Code__c,listchelck[0].Error_Message__c,
	listchelck[0].Message__c,listchelck[0].Method__c,listchelck[0].Sync_Status__c,listchelck[0].System__c);
	List<Integration_Status__c> newinte = AtlasIntegrationStatus.getIntegrationStatus(inteids);

	listchelck[0].Sync_Status__c = 'Submitted';
	AtlasIntegrationStatus.updateintegrationstatus(listchelck[0].id,opps[0].id,listchelck[0].Error_Code__c,listchelck[0].Error_Message__c,
	listchelck[0].Message__c,listchelck[0].Method__c,listchelck[0].Sync_Status__c,listchelck[0].System__c);
        

        listchelck[0].Sync_Status__c = 'Error';
        listchelck[0].Method__c = 'Site Transition';
        update listchelck[0];

        listchelck[0].Sync_Status__c = 'Submitted';
        update listchelck[0];


	Test.stopTest();
	
        }
}