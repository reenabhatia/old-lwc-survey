/*****************************
@Author: Nita Disale - Slalom
@Description : Test Class for AtlasRestAPI 
******************************/
@isTest
public with sharing class AtlasRestAPITest {

    Static Store__c init(){
        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);

        //stores[0].CRM_ID__c = '123';
        //update stores[0];

        opps[0].Store__c = stores[0].id;
        update opps[0];

        Opportunity opp = getSOQLs.getOpportunitywithStores(stores[0].CRM_ID__c);
        Store__c st = getSOQLs.getStore(stores[0].CRM_ID__c);
        return st; 

    }

    @isTest
    public static void  testGetStore(){
        Store__c st = init();   
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/Store__c/'+ st.CRM_ID__c;
        req.httpMethod = 'GET';  
        RestContext.request = req;
        RestContext.response = res;
        Store__c apist = AtlasRestAPI.geSiteById();
        system.assert( apist.id != null);
        Test.stopTest();

    }

    @isTest
    public static void testupdateStore(){
        Store__c st = init();
        Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/Store__c/' + st.CRM_ID__c;  
        req.httpMethod = 'PUT';  
        req.requestBody = Blob.valueOf(AtlasRestAPITest.getJSonBody(st));
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        String storeid = AtlasRestAPI.updateStore();
        system.debug('storeid>>>>'+storeid);
        Test.stopTest();

    }

    public static String getJSonBody(Store__c st){
        StoreWrapper wrapper = new StoreWrapper();
        wrapper.ESTIMATED_OPEN_DATE = '2020-09-08';
        wrapper.COUNTRY = 'US';
        wrapper.ADDRESS1 ='1223 str';
        wrapper.CITY ='Seattle';
        wrapper.STATE_PROVINCE = 'WA';
        wrapper.POSTAL_CODE = '13210';
        wrapper.CRM_ID = st.CRM_ID__c;
        String json = JSON.serialize(wrapper);
        return json;
    }
    
}