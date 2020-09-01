@IsTest
private with sharing class SBUX_B2B_ItemDCSourcingTriggerTest 
{
    public static Map<String, Object> testData;

    public static void setupTestData() 
    {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
    }


    @IsTest
    private static void testProcessItemSourcing()
    {
        setupTestData();

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);

        List<SBUX_B2B_ItemDCSourcing__c> testItemSourcingList = SBUX_B2B_TestDataFactory.createItemSourcing(testProductList);

        List <String> itemSourcingIds = new List<String>();

        for (SBUX_B2B_ItemDCSourcing__c  itemSourcing :testItemSourcingList)
        {
            itemSourcingIds.add(itemSourcing.ID);
        }
        
        List <SBUX_B2B_ItemDCSourcing__c> fetchItemSourcing =  [SELECT
                                                                    ID,
                                                                    SBUX_B2B_Item__c,
                                                                    SBUX_B2B_InventoryQuantity__c
                                                                    FROM 
                                                                    SBUX_B2B_ItemDCSourcing__c 
                                                                    WHERE 
                                                                        ID IN :itemSourcingIds LIMIT 10];

        // Test coverage for update path  in trigger                                                         
        fetchItemSourcing[0].SBUX_B2B_InventoryQuantity__c = 50;
        update fetchItemSourcing[0];

        Test.startTest();

        System.assertNotEquals(fetchItemSourcing[0].SBUX_B2B_Item__c, null);

        Test.stopTest();                                                                          
    }

    @IsTest
    private static void testProcessItemSourcingException()
    {
        setupTestData();

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);

        delete testProductList;
       
        Test.startTest();
        
        try
        {
            SBUX_B2B_TestDataFactory.createItemSourcing(testProductList);
        }
        catch(Exception ex)
        {
            Boolean exceptionGenerated =  ex.getMessage().contains('The provided Item Number ') ? true : false;

            System.assertEquals(exceptionGenerated, true);
        }
       
        Test.stopTest();                                                                          
    }
}