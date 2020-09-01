@isTest
private class AtlasControllerTest {
	
	@isTest

	static void testcallSitePreRequisites(){

	    List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        User user = new User();
        user.id = UserInfo.getUserId();
        user.Sbux_Title__c = 'BDM';
        update user;
        opps[0].Store__c = stores[0].id;
        opps[0].OwnerId = user.id;
        update opps[0];

        System.runAs(user) {

        ReturnMessage rm = AtlasController.callSitePreRequisites(opps[0].id);
        Id oppid = null;
        ReturnMessage rmerror = AtlasController.callSitePreRequisites(oppid);

       }
   }

       @isTest

       static void testcallAtlasCreateSite() {

        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        List<HttpResponse> responses = new List<HttpResponse>();
        String xmlstring ='<?xml version="1.0" encoding="UTF-8"?><retailSite><status>potential</status><retailSiteID>1111</retailSiteID><createdDate>2019-09-09</createdDate></retailSite>';
        HttpResponse res = AtlasRetryTest.createResponse(201, xmlstring);   
        responses.add(res); 

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AtlasRetryTest.mockPartnerAPIResponses(0, responses, null));
        ReturnMessage rm = AtlasController.callAtlasCreateSite(opps[0].id);
        Test.stopTest();
        
       }


       @isTest

       static void testcallAtlasCreateSiteError() {

        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        List<HttpResponse> responses = new List<HttpResponse>();
        String xmlstring ='<Error><code>4001013</code><message>Errormessage</message></Error>';
        HttpResponse res = AtlasRetryTest.createResponse(400, xmlstring);   
        responses.add(res); 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AtlasRetryTest.mockPartnerAPIResponses(0, responses, null));
        ReturnMessage rm = AtlasController.callAtlasCreateSite(opps[0].id);
        Test.stopTest();
        
       }

       @isTest

       static void testcallAtlasCreateSiteError4001007() {

        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        List<HttpResponse> responses = new List<HttpResponse>();
        String xmlstring ='<Error><code>4001007</code><message>Errormessage</message></Error>';
        HttpResponse res = AtlasRetryTest.createResponse(400, xmlstring);   
        responses.add(res); 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AtlasRetryTest.mockPartnerAPIResponses(0, responses, null));
        ReturnMessage rm = AtlasController.callAtlasCreateSite(opps[0].id);
        Test.stopTest();
        
       }

         @isTest

       static void testcallAtlasCreateSiteError4001003() {

        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        List<HttpResponse> responses = new List<HttpResponse>();
        String xmlstring ='<Error><code>4001003</code><message>Errormessage</message></Error>';
        HttpResponse res = AtlasRetryTest.createResponse(400, xmlstring);   
        responses.add(res); 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AtlasRetryTest.mockPartnerAPIResponses(0, responses, null));
        ReturnMessage rm = AtlasController.callAtlasCreateSite(opps[0].id);
        Test.stopTest();
        
       }



       @isTest

       static void testcallAtlasDeactivateSite() {

        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        List<HttpResponse> responses = new List<HttpResponse>();
        String xmlstring ='<?xml version="1.0" encoding="UTF-8"?><retailSite><status>Deactivated</status></retailSite>';
        HttpResponse res = AtlasRetryTest.createResponse(200, xmlstring);   
        responses.add(res); 

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AtlasRetryTest.mockPartnerAPIResponses(0, responses, null));
        ReturnMessage rm = AtlasController.callAtlasDeactivateSite(opps[0].id);
        Test.stopTest();
        
       }

       @isTest

       static void testcallAtlasDeactivateSiteError() {

        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        List<HttpResponse> errorresponses = new List<HttpResponse>();
        HttpResponse res = AtlasRetryTest.createResponse(400, '<Error><code>4001013</code><message>Errormessage</message></Error>');   
        errorresponses.add(res); 

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AtlasRetryTest.mockPartnerAPIResponses(0, errorresponses, null));
        ReturnMessage rm = AtlasController.callAtlasDeactivateSite(opps[0].id);
        Task tsk = UtilityMethod.createActivityOnDeactivate(opps[0].id);

        Test.stopTest();
        
       }
 
 

	
}