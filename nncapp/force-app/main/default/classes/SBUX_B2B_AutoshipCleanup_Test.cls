@isTest
private class SBUX_B2B_AutoshipCleanup_Test {

    public static Map<String, Object> testData;

    static testmethod void testOrdersPurgeJob() {
        //create and delete CCOrder
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        Map<String, Object> orderInsertResult = SBUX_B2B_TestDataFactory.createInsertTestOrder(testData);
        String orderId = (String)orderInsertResult.get('orderId');
        ccrz__E_Order__c testOrder = new ccrz__E_Order__c(id=orderId);
        delete testOrder;
        
        //schedule job
        String CRON_EXP = '0 0 0 15 3 ? 2024';
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest1', CRON_EXP, new SBUX_B2B_AutoshipCleanup_OrdersPurge());
        Test.stopTest();
    }

    static testmethod void testForecastAgeJob() {
        //create header with correct status + ShipDate Age
        SBUX_B2B_AutoShipHeader__c header = SBUX_B2B_TestDataFactory.createInsertTestAutoShipHeader();
        Integer ageDaysMinusOne = SBUX_B2B_AutoshipCleanup_ForecastAge.AUTOSHIP_AGE_DAYS_LOWER - 1;
        header.SBUX_B2B_FirstShipDate__c = System.today().addDays(ageDaysMinusOne);
        header.SBUX_B2B_AutoshipStatus__c = SBUX_B2B_AutoshipCleanup_ForecastAge.AUTOSHIP_STATUS_ORDERS_CREATED;
        update header;
        
        //schedule job
        String CRON_EXP = '0 0 0 15 3 ? 2024';
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest2', CRON_EXP, new SBUX_B2B_AutoshipCleanup_ForecastAge());
        Test.stopTest();
    }
}