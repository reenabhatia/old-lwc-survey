@IsTest private with sharing class SBUX_B2B_AutoshipUploadCtrlTest 
{
   

    @IsTest
    private static void testUpsertAutoshipLines()
    {
       SBUX_B2B_AutoShipHeader__c autoshipHeader = SBUX_B2B_TestDataFactory.createInsertTestAutoShipHeader();

       ContentVersion contentVersion = SBUX_B2B_TestDataFactory.createInsertTestContent();
       
       Test.startTest();

       Map<String, Object> createdLinesData = SBUX_B2B_AutoshipUploadCtrl.upsertAutoshipLines(contentVersion.contentDocumentId, autoshipHeader.Id);
       System.assertNotEquals(createdLinesData, null);
       List <SBUX_B2B_AutoShipLine__c> autoshipLines = (List <SBUX_B2B_AutoShipLine__c>)createdLinesData.get('autoshipLineList');
       System.assertEquals(autoshipLines.size(), 2);
       Test.stopTest();
    }


    @IsTest
    private static void testUpsertAutoshipLinesWithBatchJob()
    {
       SBUX_B2B_AutoShipHeader__c autoshipHeader = SBUX_B2B_TestDataFactory.createInsertTestAutoShipHeader();

       ContentVersion contentVersion = SBUX_B2B_TestDataFactory.createInsertTestContent();
       Map<String, Object> createdLinesData = SBUX_B2B_AutoshipUploadCtrl.upsertAutoshipLines(contentVersion.contentDocumentId, autoshipHeader.Id);

       List <SBUX_B2B_AutoShipLine__c> autoshipLines = (List <SBUX_B2B_AutoShipLine__c>)createdLinesData.get('autoshipLineList');

       // This is not an ideal test
       // We are unable to create 10k products as this results in a heap exception in the product trigger 
       //logic so we have to do this instead in order to test the batch job
       Test.startTest();
       SBUX_B2B_SObjectJobProcessor sobjecBatchProcessor =  new SBUX_B2B_SObjectJobProcessor(autoshipLines);
       Database.executeBatch(sobjecBatchProcessor);

       System.assertEquals(autoshipLines.size(), 2);

       Test.stopTest();
    }
}