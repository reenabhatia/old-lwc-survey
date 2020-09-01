/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description AtlasRetry Test class
*/
@isTest
public with sharing class AtlasRetryTest {

	@isTest
	public static void testcallRetryAtlasUpdateSite(){

		List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        List<Integration_Status__c> listchelck = TestDataFactory.createIntegrationStatus(1,True,'',opps[0].id);
        List<Scorecard_Approval__c> scorelist = TestDataFactory.createScorecardApproval(1,opps[0].id);
        opps[0].Store__c = stores[0].id;
        update opps[0];


		    List<HttpResponse> responses = new List<HttpResponse>();
        
        HttpResponse res = createResponse(201, '<>');	
        responses.add(res); 
        
        res = createResponse(200, '<>');	
        responses.add(res); 

        res = createResponse(400, '<Error><code>4001003</code><message>Errormessage</message></Error>');	
        responses.add(res);
        res = createResponse(400, '<Error><code>4001004</code><message>Errormessage</message></Error>');	
        responses.add(res);
        res = createResponse(400, '<Error><code>4001005</code><message>Errormessage</message></Error>');	
        responses.add(res);
        res = createResponse(400, '<Error><code>4001006</code><message>Errormessage</message></Error>');	
        responses.add(res);
        res = createResponse(400, '<Error><code>4001007</code><message>Errormessage</message></Error>');	
        responses.add(res);
        res = createResponse(400, '<Error><code>4001008</code><message>Errormessage</message></Error>');	
        responses.add(res);
        res = createResponse(400, '<Error><code>4001009</code><message>Errormessage</message></Error>');	
        responses.add(res);
        res = createResponse(400, '<Error><code>4001010</code><message>Errormessage</message></Error>');	
        responses.add(res);
        res = createResponse(400, '<Error><code>4001011</code><message>Errormessage</message></Error>');	
        responses.add(res);
        res = createResponse(400, '<Error><code>4001012</code><message>Errormessage</message></Error>');	
        responses.add(res);
        res = createResponse(400, '<Error><code>4001013</code><message>Errormessage</message></Error>');	
        responses.add(res);

        res = createResponse(404, '<Error><code>404</code><message>message</message></Error>');	
        responses.add(res);
        
     
    		Test.startTest();
    		Test.setMock(HttpCalloutMock.class, new mockPartnerAPIResponses(0, responses, null));
    		AtlasRetry.callRetryAtlasUpdateSite(opps[0].id,listchelck[0].id);
          scorelist[0].Status__c = 'Approved';
        update scorelist[0];
        opps[0].IMDS_Approval__c = 'Go';
        opps[0].MLA__c = True;
        opps[0].Radius_Restriction__c = 'No Restriction';
        opps[0].State_Waiver_Restriction__c = 'No Restriction';
        opps[0].Scorecard_Approval__c = scorelist[0].id;
    		opps[0].StageName = 'In Development';
    		update opps[0];

    		List<HttpResponse> errorresponses = new List<HttpResponse>();
    		HttpResponse res1 = createResponse(400, '<Error><code>4001008</code><message>Errormessage</message></Error>');	
        errorresponses.add(res1);
        res1 = createResponse(400, '<Error><code>4001013</code><message>Errormessage</message></Error>');	
        errorresponses.add(res1);
        res1 = createResponse(404, '<Error><code>404</code><message>message</message></Error>');	
        errorresponses.add(res1);

    		Test.setMock(HttpCalloutMock.class, new mockPartnerAPIResponses(0, errorresponses, null));
    		AtlasRetry.callRetryAtlaschangesite(opps[0].id,listchelck[0].id);
    		Test.stopTest();
		
	}

	@isTest
	public static void testSuccessResponseCallRetryAtlasUpdateSite(){

		    List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        List<Integration_Status__c> listchelck = TestDataFactory.createIntegrationStatus(1,True,'',opps[0].id);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        Test.startTest();
        List<HttpResponse> successresponses = new List<HttpResponse>();
	    	HttpResponse res = createResponse(200, '<>');	
        successresponses.add(res); 

		    Test.setMock(HttpCalloutMock.class, new mockPartnerAPIResponses(0, successresponses, null));
		    AtlasRetry.callRetryAtlasUpdateSite(opps[0].id,listchelck[0].id);
		    Test.stopTest();

	}

	@isTest
	public static void testSuccessResponsecallRetryAtlaschangesite(){

		    List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        List<Integration_Status__c> listchelck = TestDataFactory.createIntegrationStatus(1,True,'',opps[0].id);
        opps[0].Store__c = stores[0].id;
        opps[0].StageName = 'In Approval';
        update opps[0];

        Test.startTest();
        List<HttpResponse> successresponses = new List<HttpResponse>();
        String xmlstring ='<?xml version="1.0" encoding="UTF-8"?><retailSite><status>potential</status></retailSite>';

		    HttpResponse res = createResponse(200, xmlstring);	
        successresponses.add(res); 

		    Test.setMock(HttpCalloutMock.class, new mockPartnerAPIResponses(0, successresponses, null));
		    AtlasRetry.callRetryAtlaschangesite(opps[0].id,listchelck[0].id);
		    Test.stopTest();

	}

  @isTest
  public static void testSuccessResponseCallRetryAtlaschangesiteInDevelop(){

        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(1,'',True,stores[0].id);
        List<Integration_Status__c> listchelck = TestDataFactory.createIntegrationStatus(1,True,'',opps[0].id);
        List<Scorecard_Approval__c> scorelist = TestDataFactory.createScorecardApproval(1,opps[0].id);
        scorelist[0].Status__c = 'Approved';
        update scorelist[0];
      
        opps[0].Store__c = stores[0].id;
        opps[0].IMDS_Approval__c = 'Go';
        opps[0].MLA__c = True;
        opps[0].Radius_Restriction__c = 'No Restriction';
        opps[0].State_Waiver_Restriction__c = 'No Restriction';
        opps[0].Scorecard_Approval__c = scorelist[0].id;
        opps[0].StageName = 'In Development';

        update opps[0];

        Test.startTest();
        List<HttpResponse> successresponses = new List<HttpResponse>();
        String xmlstring ='<?xml version="1.0" encoding="UTF-8"?><retailSite><status>potential</status></retailSite>';

        HttpResponse res = createResponse(200, xmlstring);  
        successresponses.add(res); 

        Test.setMock(HttpCalloutMock.class, new mockPartnerAPIResponses(0, successresponses, null));
        AtlasRetry.callRetryAtlaschangesite(opps[0].id,listchelck[0].id);
        Test.stopTest();

  }


	public static HttpRequest createRequest(String reqMethod, String endpoint, Map<String,String> headers, String reqBody){
        
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod(reqMethod);
        httpRequest.setEndpoint(endpoint);
        httpRequest.setHeader('Date', headers.get('formatteddate'));
        httpRequest.setHeader('Digest', headers.get('digest'));
        httpRequest.setHeader('Content-type', 'application/xml');
        httpRequest.setHeader('Accept', 'application/xml');
        httpRequest.setHeader('Authorization', headers.get('httpsignature'));
        httpRequest.setHeader('x-correlation-id', headers.get('correlation'));
        httpRequest.setBody(reqBody);
        return httpRequest;
    }
    
    public static HttpResponse createResponse(Integer statusCode, String body)
    {
    	HttpResponse res = new HttpResponse();
    	res.setBody(body);
    	res.setStatusCode(statusCode);
    	return res;
    }
    
    public static List<HttpResponse> createAllErrorResponses(List<HttpResponse> responses)
    {
        HttpResponse res = createResponse(400, 'Bad Request!');	
        responses.add(res);
        res = createResponse(404, 'Resource not found');	
        responses.add(res);
        res = createResponse(401, 'Unathorized');	
        responses.add(res);
        res = createResponse(403, 'Forbidden');	
        responses.add(res);
        return responses;
    }
    public static List<HttpRequest> createManyRequests(Integer count, List<HttpRequest> expectedRequests, String reqMethod, String endpoint, Map<String,String> headers, String reqBody)
    {
        for (Integer i = 0; i < count; i++)
        {
            HttpRequest req = createRequest(reqMethod,endpoint,headers,reqBody);
            expectedRequests.add(req); 
            
        }
        return expectedRequests;
    }
    
    
    /******************************************************************
	*	   				   Helper Class 							  *
	******************************************************************/
    
    public class mockPartnerAPIResponses implements HttpCalloutMock
	{
	   Integer index;
	   List<HttpResponse> responses;
	   List<HttpRequest> expectedRequests;
	   
       public mockPartnerAPIResponses(Integer index, List<HttpResponse> responses, List<HttpRequest> expectedRequests)
       {
			this.index = index;
			this.responses = responses;
			this.expectedRequests = expectedRequests;  
       }
       public HttpResponse respond(HttpRequest req)
       {

       	 if (req.getBody().contains('retailSiteID'))
           {

           	   String xmlstring ='<?xml version="1.0" encoding="UTF-8"?><retailSite><status>potential</status><retailSiteID>1111</retailSiteID><createdDate>2019-09-09</createdDate></retailSite>';
               HttpResponse res = new HttpResponse();
               res.setStatusCode(201);
               res.setBody(xmlstring);
               return res;
           }
           if (req.getBody().contains('status'))
           {

               String xmlstring ='<?xml version="1.0" encoding="UTF-8"?><retailSite><status>potential</status></retailSite>'; 
               HttpResponse res = new HttpResponse();
               res.setStatusCode(200);
               res.setBody(xmlstring);
               return res;
           }
           if (req.getBody().contains('4001013'))
           {

               String xmlstring ='<Error><code>4001013</code><message>Errormessage</message></Error>'; 
               HttpResponse res = new HttpResponse();
               res.setStatusCode(400);
               res.setBody(xmlstring);
               return res;
           }
               return responses[index++];
       }
	}

}