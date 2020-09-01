@isTest
public with sharing class Opportunity_TriggerHandlerTest {

	@isTest
	public static void testafterupdate(){

        	List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
                List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
                List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
                List<Scorecard_Approval__c> scorelist = TestDataFactory.createScorecardApproval(1,opps[0].id);

                opps[0].Store__c = stores[0].id;
                update opps[0];

                opps[0].Address_1__c = 'checkit';
                opps[0].Atlas_Site_ID__c = 'quuuu';
                opps[0].StageName = 'In Approval';
                update opps[0];
                Opportunity oppcheck = Opportunity_TriggerHandler.getOpportunity(opps[0].id);
                system.assert(oppcheck != null);
                
                scorelist[0].Status__c = 'Approved';
                update scorelist[0];
                
                opps[0].IMDS_Approval__c = 'Go';
                opps[0].MLA__c = True;
                opps[0].Radius_Restriction__c = 'No Restriction';
                opps[0].State_Waiver_Restriction__c = 'No Restriction';
                opps[0].Scorecard_Approval__c = scorelist[0].id;
                opps[0].StageName = 'In Development';
                update opps[0];
                Task t = Opportunity_TriggerHandler.createActivity(opps[0]);
                system.assert(t != null);
	}

	@isTest
	public static void testgeterrorcode(){

        	String xmlstring ='<Error><code>4001010</code><message>Datatype mismatch:squareFootageMeas must be of type double</message></Error>';
                String code = Opportunity_TriggerHandler.geterrorcode(xmlstring);
                system.assertEquals(code,'4001010');
	}

	@isTest
	public static void testgetstatus(){

        	String xmlstring ='<success><status>statusval</status></success>';
                String status = Opportunity_TriggerHandler.getstatus(xmlstring);
                system.assertEquals(status,'statusval');
	}

        @isTest
        static void testcallAtlasUpdateSiteSuccess(){

                List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
                List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
                List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
                List<Integration_Status__c> listchelck = TestDataFactory.createIntegrationStatus(1,True,'',opps[0].id);
                List<HttpResponse> responses = new List<HttpResponse>();

                HttpResponse res = AtlasRetryTest.createResponse(200, '<>');   
                responses.add(res);
                Test.startTest(); 
                Test.setMock(HttpCalloutMock.class, new AtlasRetryTest.mockPartnerAPIResponses(0, responses, null));
                Opportunity_TriggerHandler.callAtlasUpdateSite(opps[0].id);
                Test.stopTest();

        }

        @isTest
        static void testcallAtlaschangesiteSuccess(){

                List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
                List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
                List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
                List<Integration_Status__c> listchelck = TestDataFactory.createIntegrationStatus(1,True,'',opps[0].id);
                opps[0].Store__c = stores[0].id;
                update opps[0];
                
                List<HttpResponse> successresponses = new List<HttpResponse>();
                String xmlstring ='<?xml version="1.0" encoding="UTF-8"?><retailSite><status>potential</status></retailSite>';

                HttpResponse res = AtlasRetryTest.createResponse(200, xmlstring);  
                successresponses.add(res); 
                Test.startTest();

                Test.setMock(HttpCalloutMock.class, new AtlasRetryTest.mockPartnerAPIResponses(0, successresponses, null));
                Opportunity_TriggerHandler.callAtlaschangesite(opps[0].id);
                Test.stopTest();

        }

	
}