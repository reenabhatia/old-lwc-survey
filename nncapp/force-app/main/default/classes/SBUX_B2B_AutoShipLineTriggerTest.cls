@IsTest
public with sharing class SBUX_B2B_AutoShipLineTriggerTest 
{
    @IsTest
    private static void testExternalIDOnInsert()
    {
        List<ccrz__E_Product__c> productList  = SBUX_B2B_TestDataFactory.createInsertTestProducts(1);

        SBUX_B2B_AutoShipHeader__c autoshipHeader = SBUX_B2B_TestDataFactory.createInsertTestAutoShipHeader();

        SBUX_B2B_AutoShipLine__c firstAutoshipLine = SBUX_B2B_TestDataFactory.createBeverageAutoshipLine(autoshipHeader, productList[0]);

        Test.startTest();
 
        SBUX_B2B_AutoShipLine__c fetchAutoShipLine = [SELECT
                                                    Name,
                                                    SBUX_B2B_ExternalID__c
                                            FROM SBUX_B2B_AutoShipLine__c
                                            WHERE 
                                                    ID =: firstAutoshipLine.ID];

        System.assertNotEquals(null, fetchAutoShipLine.SBUX_B2B_ExternalID__c);

        Test.stopTest();
    }

    
    @IsTest
     private static void testExternalIDOnUpdate()
     {
        List<ccrz__E_Product__c> productList  = SBUX_B2B_TestDataFactory.createInsertTestProducts(1);
       
        SBUX_B2B_AutoShipHeader__c autoshipHeader = SBUX_B2B_TestDataFactory.createInsertTestAutoShipHeader();

        SBUX_B2B_AutoShipLine__c firstAutoshipLine = SBUX_B2B_TestDataFactory.createBeverageAutoshipLine(autoshipHeader, productList[0]);
 
        SBUX_B2B_AutoShipLine__c fetchAutoShipLine = [SELECT
                                                    Name,
                                                    SBUX_B2B_ExternalID__c
                                            FROM SBUX_B2B_AutoShipLine__c
                                            WHERE 
                                                    ID =: firstAutoshipLine.ID];

        String oldExternalID = fetchAutoShipLine.SBUX_B2B_ExternalID__c;

        firstAutoshipLine.SBUX_B2B_LSCategory__c = 'Merchandise';
        update firstAutoshipLine;

        Test.startTest();

        SBUX_B2B_AutoShipLine__c fetchAutoShipLineAfterUpdate = [SELECT
                                                                    Name,
                                                                    sbux_b2b_externalid__c
                                                            FROM SBUX_B2B_AutoShipLine__c
                                                            WHERE 
                                                                    ID =: firstAutoshipLine.ID];

          System.assertNotEquals(oldExternalID, fetchAutoShipLineAfterUpdate.SBUX_B2B_ExternalID__c);
       
          Test.stopTest();
    }
}