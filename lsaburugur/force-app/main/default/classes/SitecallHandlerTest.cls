/*****************************
@Author: Nita Disale - Slalom
@Description : Test Class for SitecallHandler 
******************************/
@isTest
public with sharing class SitecallHandlerTest {
	private static String getDate {
        get {
            return 'Tue, 07 Jun 2019 20:51:35 GMT';
        }
    } 
    	private static String getdigest {
        get {
            return 'SHA-256=X48E9qOokqqrvdts8nOJRJN3OWDUoyWxBf7kbu9DBPE=';
        }
    } 

     private static List<String> getrequired(){
     	List<String> required = new List<String>();
        required.add('date');
        required.add('digest');
        required.add('(request-target)');
        return required;
     }


	@isTest
	public static void testcreatesitesignature(){

		HttpSignature signature = new HttpSignature('key-alias', 'hmac-sha256', '', getrequired());
        Signer signer = new Signer(signature,'hmac-sha256','dont tell');

        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        Test.startTest();
        String createsiteval = SitecallHandler.createsitesignature(signature,signer,opps[0],SitecallHandlerTest.getDate,SitecallHandlerTest.getdigest);
        system.debug('createsiteval>>>>'+ createsiteval);
        system.assert(createsiteval != null);


        opps[0].Atlas_Site_ID__c = '1234';
        update opps[0];
        String updatesiteval = SitecallHandler.updatesitesignature(signature,signer,opps[0],SitecallHandlerTest.getDate,SitecallHandlerTest.getdigest);
        system.debug('updatesiteval>>>>'+ updatesiteval);
        system.assert(updatesiteval != null);

        String changesiteval = SitecallHandler.changesitestatussignature(signature,signer,opps[0],SitecallHandlerTest.getDate,SitecallHandlerTest.getdigest);
        system.debug('changesiteval>>>>'+ changesiteval);
        system.assert(changesiteval != null);

        Test.stopTest();
	}

	@isTest
	public static void testcreatedigest(){
		Test.startTest();
		List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        opps[0].Store__c = stores[0].id;
        update opps[0];
		String payload = AtlasPayload.generateXMLPayload(opps[0].id);
		String digest = SitecallHandler.createdigest(payload);
		system.assert(digest !=null);

		Test.stopTest();
	}
	
}