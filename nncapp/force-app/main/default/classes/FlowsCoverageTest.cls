@isTest
public with sharing class FlowsCoverageTest {
    @isTest
    public static void testFlows(){

        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        opps[0].Store__c = stores[0].id;
        update opps[0];
        List<Shipping_Billing_Request__c> sbr = TestDataFactory.createSBR(1,stores[0].id);
        RecordType rt = UtilityMethod.getRecordTypesByDeveloperName(Task.SObjectType.getDescribe()).get('Ls_Activities');

        Activity_Plan__c at = new Activity_Plan__c();
        at.Store__c = stores[0].id;
        at.Type__c = 'LS Store Shipping Billing Request';
        at.Task_Record_Type_Id__c = rt.id;
        at.LS_Store_SB_1__c = false;
        insert at;
        at.LS_Store_Setup_1__c  = True;
        update at;
    }

    @isTest
    public static void testCreateActivityPlanEvent(){

        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        // Create a test event instance
        Activity_Plan_Event__e actEvent = new Activity_Plan_Event__e(Action__c='Create', 
                                             Store_Id__c = stores[0].id,
                                             Type__c = 'LS Store Shipping Billing Request');
        Activity_Plan_Event__e actEvent2 = new Activity_Plan_Event__e(Action__c='Set LS_Store_Setup_1__c To True', 
                                             Store_Id__c = stores[0].id,
                                             Type__c = 'LS Store Setup');
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(actEvent);
        Database.SaveResult sr2 = EventBus.publish(actEvent2);
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess());
        System.assertEquals(true, sr2.isSuccess());

      }
      
      @isTest
      public static void testStoreinsertupdate(){
      	Test.startTest();
        RecordType rt = UtilityMethod.getRecordTypesByDeveloperName(Store__c.SObjectType.getDescribe()).get('Store');
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
        store.RecordTypeId = rt.id;
        store.Open_Date__c = System.today();
        insert store;
        System.assert(store.RecordType.Name != 'Commissary');

        store.Open_Date__c = null;
        update store;
        System.assert(store.Open_Date__c == null);
        Test.stopTest();

      }
      @isTest
      public static void testStoreupdateProcessFlow(){
      	Test.startTest();

      	List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        opps[0].Store__c = stores[0].id;
        update opps[0];

        stores[0].Open_Date__c = System.today();
        update stores[0];
        System.assert(stores[0].Open_Date__c != null);
        Test.stopTest();

      }
     @isTest
      public static void testCreateActivityPlanflow(){
      	Test.startTest();
      	List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
      	List<Scorecard_Approval__c> scorelist = TestDataFactory.createScorecardApproval(1,opps[0].id);

        scorelist[0].Status__c = 'Approved';
        update scorelist[0];
        
        opps[0].IMDS_Approval__c = 'Go';
        opps[0].MLA__c = True;
        opps[0].Radius_Restriction__c = 'No Restriction';
        opps[0].State_Waiver_Restriction__c = 'No Restriction';
        opps[0].Scorecard_Approval__c = scorelist[0].id;
        opps[0].StageName = 'In Development';
        opps[0].Sub_Stage__c = 'Schematic Authorization';
        update opps[0];
        System.assert(opps[0].StageName == 'In Development');
        opps[0].Sub_Stage__c = 'NTP';
        update opps[0];
      	Test.stopTest();
      }

      @isTest 
      public static void testCreateAttributeFlows(){
      	Test.startTest();

      	List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        opps[0].Store__c = stores[0].id;
        update opps[0];
        List<Store_Attribute__c> autoshiplist = TestDataFactory.createautoshipAttribute(1,stores[0].id);
        List<Store_Attribute__c> marketinglist = TestDataFactory.createMarketingAttribute(1,stores[0].id);
        stores[0].Marketing_Attributes__c = marketinglist[0].id;
        stores[0].Autoship_Attributes__c = autoshiplist[0].id;

        update stores[0];
        System.assert(stores[0].Marketing_Attributes__c != null && stores[0].Autoship_Attributes__c != null);
        Test.stopTest();

      }

    @testVisible private static List<Activity_Plan_Event__e> eventList = new List<Activity_Plan_Event__e>();
    @isTest
    public static void publishEvent() {
    	Test.startTest();
    	List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        //Store__c str = [select id from Store__c where id =: stores[0].id];
        Activity_Plan_Event__e eve = new Activity_Plan_Event__e(Action__c = 'Create', 
                                             Store_Id__c = stores[0].id,
                                             Type__c = 'LS Store Shipping Billing Request');

        eventList.add(eve);
        EventBus.publish(eve);
        Test.stopTest();
    }

    @isTest
    public static void testflowv2(){
    	Test.startTest();
    	List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
    	// Call the Flow
		Map<String, Object> params = new Map<String, Object>();
		params.put('stores', stores);
		Flow.Interview.Validate_Store_Number_Exists recordFlow = new Flow.Interview.Validate_Store_Number_Exists(params);
		recordFlow.start();
    	Test.stopTest();
    }
    @isTest
    public static void testflowCustomPermission(){
    	Test.startTest();
    	List<CustomPermission> customPermissionlist = [select Id from CustomPermission where DeveloperName = 'Can_Create_Site'];
    	Map<String, Object> params = new Map<String, Object>();
		params.put('customPermissionlist', customPermissionlist);
		Flow.Interview.Custom_Permission_Check recordFlow = new Flow.Interview.Custom_Permission_Check(params);
		recordFlow.start();
    	Test.stopTest();
    }


}