/***************************************************************************************************************
* Class Purpose: Test class for Batch_DRM_Initiate_BuildTest
*
* Created By: Nita Disale - Slalom
* ***************************************************************************************************************/
@isTest
public with sharing class Batch_DRM_Initiate_BuildTest {

    @isTest
      private static void whenStart(){
        Batch_DRM_Initiate_Build job = new Batch_DRM_Initiate_Build();
        Test.startTest();
        job.start(null);
        Test.stopTest();
    }
    
    @isTest
    private static void finishtest(){
        Batch_DRM_Initiate_Build job = new Batch_DRM_Initiate_Build();
        Test.startTest();
        User user = [Select id from User where Id = :UserInfo.getUserId()];
        System.runAs(user){
        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        List<Address__c> addresslist = TestDataFactory.createAddress(1,True,'',stores[0].id);
        job.finish(null);
        Test.stopTest();
       }
    }

    @isTest
    public static void executetest(){
        Test.startTest();
        Store_Hierarchy__c sth = new Store_Hierarchy__c();
        sth.Name = 'Name it';
        insert  sth;
        List<Store_Hierarchy__c> scope = [SELECT Id From Store_Hierarchy__c];
        DataBase.executeBatch(new Batch_DRM_Initiate_Build());
        Test.stopTest();

    }

    @isTest
    public static void testuserNAE(){
        
        Batch_DRM_Initiate_Build job = new Batch_DRM_Initiate_Build();
        Test.startTest();
        User u3 = [SELECT Id,Sbux_Title__c 
             	FROM User WHERE IsActive = true 
             		AND Profile.Name = 'System Administrator' limit 1];
        u3.Sbux_Title__c = 'NAE';
        TestDataFactory.forcedUpdate(u3);
        System.runAs(u3){

        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        List<Address__c> addresslist = TestDataFactory.createAddress(1,True,'',stores[0].id);
        job.finish(null);
        Test.stopTest();
            
        }

    }
    
     @isTest
    public static void testuserBDM(){
        
        Batch_DRM_Initiate_Build job = new Batch_DRM_Initiate_Build();
        Test.startTest();
        User u2 = [SELECT Id,Sbux_Title__c 
             	FROM User WHERE IsActive = true 
             		AND Profile.Name = 'System Administrator' limit 1];
        u2.Sbux_Title__c = 'NAE';
        TestDataFactory.forcedUpdate(u2);
        System.runAs(u2){
        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        /**
         * Nihar -- Added this as part of Store Account Refactoring Story.
         **/
        Account StoreAcc = new Account(Store_Unique_Id__c = opps[0].Id);
        StoreAcc.Is_a_Store__c = 'Licensed Store';
        StoreAcc.Name = opps[0].Name;
        StoreAcc.ParentId = opps[0].AccountId;
        StoreAcc.OwnerId = u2.id;
		upsert StoreAcc Store_Unique_Id__c;
            
        Store__c store = new Store__c();
        store.Name = opps[0].Name;
        store.Segment__c = 'Travel';
        store.Subsegment__c= 'Airport';
        store.Licensee__c = opps[0].AccountId;
        store.Commissary_Status__c = 'Is Commissary';
        //store.OwnerId = u2.id;
        store.Store_Account__c = StoreAcc.Id;//Nihar -- Added this as part of Store Account Refactoring Story.
        insert store;
        
        opps[0].Store__c = store.id;
        update opps[0];

        List<Address__c> addresslist = TestDataFactory.createAddress(1,True,'',store.id);
        Batch_DRM_StoreHierarchy st = new Batch_DRM_StoreHierarchy();
        st.getJobRole('region','NAE');
        job.finish(null);
        Test.stopTest();
            
        }

    }
    
    
}