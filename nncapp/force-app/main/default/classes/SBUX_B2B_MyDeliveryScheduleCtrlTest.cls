@IsTest
private with sharing class SBUX_B2B_MyDeliveryScheduleCtrlTest
{
    public static Map<String, Object> testData;
    public static Store__c testStore;
    public static List<ccrz__E_Product__c> testProducts;
    public static String AcctId;

    public static void setupTestData() {
        //init
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        testStore = (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        testProducts = (List<ccrz__E_Product__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        //link testStore to testAccount
        Account testAcct = (Account)testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);
        testAcct.Store__c = testStore.Id;
        update testAcct;
        AcctId = (String)testAcct.Id;
    }
    
    @isTest
    public static void testDeliverySchedule() {
        setupTestData();
        SBUX_B2B_TestDataFactory.createInsertItemDCSourcing(testProducts[0]);
        SBUX_B2B_TestDataFactory.createInsertDeliverySchedules(testStore);
        SBUX_B2B_TestDataFactory.createInsertStoreDCSourcing(testStore);
		ccrz.cc_RemoteActionResult result;
        Test.startTest();
		
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            ctx.userLocale = 'en_US';
            ctx.userIsoCode = 'USD';
            ccrz.cc_CallContext.init(ctx);
            ccrz.cc_CallContext.currAccountId = AcctId;

            SBUX_B2B_MyDeliveryScheduleCtrl ctrl = new SBUX_B2B_MyDeliveryScheduleCtrl();
            result = SBUX_B2B_MyDeliveryScheduleCtrl.getDeliveryData(ctx, AcctId);
        }
        Test.stopTest();
        
        //assert at least 1 schedule has been returned w/ values
        System.assertEquals(true,result.success);
		System.assert(result.data <> null);

    }
}