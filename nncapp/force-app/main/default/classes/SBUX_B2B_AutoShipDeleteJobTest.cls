@isTest
private class SBUX_B2B_AutoShipDeleteJobTest {
    
    public static Map<String, Object> testData;
    public static SBUX_B2B_AutoShipHeader__c testAutoShipHeader;

    public static void setupTestData() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        testAutoShipHeader = SBUX_B2B_TestDataFactory.createInsertTestAutoShipHeader();
    }

    static testmethod void testDeleteJob() {
        setupTestData();
        
        //set Order values
        Map<String, Object> orderInsertResult = SBUX_B2B_TestDataFactory.createInsertTestOrder(testData);
        String orderId = (String)orderInsertResult.get('orderId');
        ccrz__E_Order__c testOrder = new ccrz__E_Order__c(
            id=orderId,
            ccrz__OrderStatus__c=SBUX_B2B_AutoShipDeleteOrdersJob.ORDER_STATUS_DRAFT,
            SBUX_B2B_AutoShipHeader__c=testAutoShipHeader.Id);
        update testOrder;

        //set Forecast values
        SBUX_B2B_AutoshipForecast__c currForecast = new SBUX_B2B_AutoshipForecast__c(
            SBUX_B2B_Autoship_Header__c = testAutoShipHeader.Id
        );
        insert currForecast;

        //test
        Test.startTest();
        SBUX_B2B_AutoShipDeleteForecastJob deleteJob = new SBUX_B2B_AutoShipDeleteForecastJob(testAutoShipHeader.Id,true,true,false,false);
        Id batchId = Database.executeBatch(deleteJob);
        Test.stopTest();
        
        //validate
        System.assertEquals(0, [SELECT count() FROM ccrz__E_Order__c WHERE SBUX_B2B_AutoShipHeader__c =: testAutoShipHeader.Id]);
        System.assertEquals(0, [SELECT count() FROM SBUX_B2B_AutoshipForecast__c WHERE SBUX_B2B_Autoship_Header__c = :testAutoShipHeader.Id]);
    }
}