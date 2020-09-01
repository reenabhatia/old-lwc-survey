/**
 * Created by dgajwani on 4/6/20.
 */
@IsTest
public with sharing class SBUX_B2B_AutoShipProcessorJobTest {

    public static Map<String, Object> testData;
    public static SBUX_B2B_AutoShipHeader__c testAutoShipHeader;

    public static void setupTestData() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        testAutoShipHeader = SBUX_B2B_TestDataFactory.createInsertTestAutoShipHeader();
        Account licenseeAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_LICENSEE_ACCOUNT);
        List<ccrz__E_Product__c> testProducts = (List<ccrz__E_Product__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        SBUX_B2B_TestDataFactory.createInsertTestAutoShipLines(testAutoShipHeader, testProducts);
        SBUX_B2B_TestDataFactory.createInsertTestProductExceptionRules(licenseeAccount, testProducts[1]);

    }

    @IsTest
    public static void testAutoShipHeaderProcessNoSplit() {
        setupTestData();

        Store__c testStore = (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        SBUX_B2B_TestDataFactory.createInsertTestStoreAttribute('Target EDI', testStore);

        Test.startTest();
        SBUX_B2B_AutoShipProcessorJob job = new SBUX_B2B_AutoShipProcessorJob(testAutoShipHeader.Id, false, false);
        Database.executeBatch(job, 10);
        Test.stopTest();

        ccrz__E_Order__c currOrder = [
                SELECT Id, SBUX_B2B_PONumber__c
                FROM ccrz__E_Order__c
                LIMIT 1
        ];
        List<ccrz__E_OrderItem__c> orderItems = [
                SELECT Id
                FROM ccrz__E_OrderItem__c
        ];

        // This confirms there were no splits.
        System.assertEquals(null, currOrder.SBUX_B2B_PONumber__c);
        System.assertEquals(4, orderItems.size());
    }

    @IsTest
    public static void testAutoShipHeaderProcessWithSplit() {
        setupTestData();

        Store__c testStore = (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        SBUX_B2B_TestDataFactory.createInsertTestStoreAttribute(SBUX_B2B_AutoShipProcessorJob.PROGRAM_TYPE_STARBUCKS_SHIPS, testStore);

        Test.startTest();
        SBUX_B2B_AutoShipProcessorJob job = new SBUX_B2B_AutoShipProcessorJob(testAutoShipHeader.Id, true,false);
        Database.executeBatch(job, 10);
        Test.stopTest();

        ccrz__E_Order__c currOrder = [
                SELECT Id, SBUX_B2B_PONumber__c, ccrz__OrderStatus__c
                FROM ccrz__E_Order__c
                LIMIT 1
        ];
        List<ccrz__E_OrderItem__c> orderItems = [
                SELECT Id
                FROM ccrz__E_OrderItem__c
        ];

        // This confirms that splits were attempted.
        System.assertNotEquals(null, currOrder.SBUX_B2B_PONumber__c);
        System.assertNotEquals(SBUX_B2B_AutoShipUtil.ORDER_STATUS_ORDER_SUBMITTED, currOrder.ccrz__OrderStatus__c);
        System.assertEquals(4, orderItems.size());
    }

    @IsTest
    public static void testAutoShipHeaderFinalizeOrders() {
        setupTestData();

        Store__c testStore = (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        SBUX_B2B_TestDataFactory.createInsertTestStoreAttribute(SBUX_B2B_AutoShipProcessorJob.PROGRAM_TYPE_STARBUCKS_SHIPS, testStore);

        List<ccrz__E_Product__c> testProducts = (List<ccrz__E_Product__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        SBUX_B2B_TestDataFactory.createInsertItemDCSourcing(testProducts[0]);
        SBUX_B2B_TestDataFactory.createInsertDeliverySchedules(testStore);
        SBUX_B2B_TestDataFactory.createInsertStoreDCSourcing(testStore);

        Test.startTest();
        SBUX_B2B_AutoShipProcessorJob job = new SBUX_B2B_AutoShipProcessorJob(testAutoShipHeader.Id, true,true);
        Database.executeBatch(job, 10);
        Test.stopTest();

        ccrz__E_Order__c currOrder = [
                SELECT Id, SBUX_B2B_PONumber__c, SBUX_B2B_Order_Source__c, SBUX_B2B_OrderPublishFlag__c, ccrz__OrderStatus__c
                FROM ccrz__E_Order__c
                LIMIT 1
        ];
        List<ccrz__E_OrderItem__c> orderItems = [
                SELECT Id, ccrz__Price__c
                FROM ccrz__E_OrderItem__c
        ];

        // This confirms that splits were attempted.
        System.assertNotEquals(null, currOrder.SBUX_B2B_PONumber__c);
        System.assertEquals(SBUX_B2B_AutoShipUtil.ORDER_STATUS_ORDER_SUBMITTED, currOrder.ccrz__OrderStatus__c);
        System.assertEquals(SBUX_B2B_AutoShipUtil.ORDER_SOURCE_AUTOSHIP, currOrder.SBUX_B2B_Order_Source__c);
        System.assertEquals(true, currOrder.SBUX_B2B_OrderPublishFlag__c);
        System.assertNotEquals(0, orderItems[0].ccrz__Price__c);
        System.assertEquals(4, orderItems.size());
    }
}