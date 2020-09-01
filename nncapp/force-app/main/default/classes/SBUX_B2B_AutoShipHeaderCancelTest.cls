@isTest
private class SBUX_B2B_AutoShipHeaderCancelTest {
    
    static testmethod void testMethodCancel() {        
        
        //setup
//TODO: replace with DataFactory
        SBUX_B2B_AutoShipHeader__c testHeader = new SBUX_B2B_AutoShipHeader__c(
            SBUX_B2B_AutoshipStatus__c='Draft',
            SBUX_B2B_Description__c='TEST CANCEL JOB', 
            SBUX_B2B_AutoshipType__c='Promo', 
            SBUX_B2B_FirstShipDate__c=date.parse('4/7/2020'), 
            SBUX_B2B_FreightTerms__c='Collect', 
            SBUX_B2B_ShipPriority__c='Cutover'
        );
        insert testHeader;
        
        ccrz__E_Order__c testOrder = new ccrz__E_Order__c(
            SBUX_B2B_AutoShipHeader__c=testHeader.id,
            ccrz__OrderStatus__c='Draft'
        );
        insert testOrder;
        
        
        Test.startTest();
        testHeader.SBUX_B2B_AutoshipStatus__c='Cancelled';
        update testHeader;
        Test.stopTest();
        
        //validate
        System.assertEquals(0, [select count() from ccrz__E_Order__c where SBUX_B2B_AutoShipHeader__c =: testHeader.id]);
        
    }
    
}