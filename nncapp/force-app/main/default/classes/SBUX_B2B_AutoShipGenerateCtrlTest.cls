@isTest
private class SBUX_B2B_AutoShipGenerateCtrlTest{
    
    @isTest
    static void testForecast(){
        
//TODO - replace with TestDataFactory

        //setup
        SBUX_B2B_AutoShipHeader__c testHeader = new SBUX_B2B_AutoShipHeader__c(
            SBUX_B2B_AutoshipStatus__c='Draft',
            SBUX_B2B_Description__c='TEST FORECAST JOB', 
            SBUX_B2B_AutoshipType__c='Promo', 
            SBUX_B2B_FirstShipDate__c=date.parse('4/7/2020'), 
            SBUX_B2B_FreightTerms__c='Collect', 
            SBUX_B2B_ShipPriority__c='Cutover'
        );
        insert testHeader;
        
        //create List for stdSetController
        List<SBUX_B2B_AutoShipHeader__c> testHeaderList = new List<SBUX_B2B_AutoShipHeader__c>();
        testHeaderList.add(testHeader);
        
        //test
        Test.StartTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testHeader);
        SBUX_B2B_AutoShipGenerateCtrl cc = new SBUX_B2B_AutoShipGenerateCtrl(sc);
        
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(testHeaderList);
        ssc.setSelected(testHeaderList);
        SBUX_B2B_AutoShipGenerateCtrl csc = new SBUX_B2B_AutoShipGenerateCtrl(ssc);
        
        PageReference pageRef = Page.SBUX_B2B_AutoShipGenerateForecastAll;
        Test.setCurrentPage(pageRef);
        
        //no selection (all)
        cc.autoShipForecastAll();
        
        //selected Set
        csc.autoShipForecastAll();
        
        Test.StopTest();

    }
    
    
    @isTest
    static void testPreview(){
        
//TODO - replace with TestDataFactory

        //setup
        SBUX_B2B_AutoShipHeader__c testHeader = new SBUX_B2B_AutoShipHeader__c(
            SBUX_B2B_AutoshipStatus__c='Forecasted',
            SBUX_B2B_Description__c='TEST PREVIEW JOB', 
            SBUX_B2B_AutoshipType__c='Promo', 
            SBUX_B2B_FirstShipDate__c=date.parse('4/7/2020'), 
            SBUX_B2B_FreightTerms__c='Collect', 
            SBUX_B2B_ShipPriority__c='Cutover'
        );
        insert testHeader;
        
        //create List for stdSetController
        List<SBUX_B2B_AutoShipHeader__c> testHeaderList = new List<SBUX_B2B_AutoShipHeader__c>();
        testHeaderList.add(testHeader);
        
        //test
        Test.StartTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testHeader);
        SBUX_B2B_AutoShipGenerateCtrl cc = new SBUX_B2B_AutoShipGenerateCtrl(sc);
        
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(testHeaderList);
        ssc.setSelected(testHeaderList);
        SBUX_B2B_AutoShipGenerateCtrl csc = new SBUX_B2B_AutoShipGenerateCtrl(ssc);
        
        PageReference pageRef = Page.SBUX_B2B_AutoShipGenerateForecastAll;
        Test.setCurrentPage(pageRef);
        
        //no selection (all)
        cc.autoShipPreviewAll();
        
        //selected Set
        csc.autoShipPreviewAll();
        
        Test.StopTest();

    }
    
    
    @isTest
    static void testSubmit(){
        
//TODO - replace with TestDataFactory

        //setup
        SBUX_B2B_AutoShipHeader__c testHeader = new SBUX_B2B_AutoShipHeader__c(
            SBUX_B2B_AutoshipStatus__c='In Preview',
            SBUX_B2B_Description__c='TEST SUBMIT JOB', 
            SBUX_B2B_AutoshipType__c='Promo', 
            SBUX_B2B_FirstShipDate__c=date.parse('4/7/2020'), 
            SBUX_B2B_FreightTerms__c='Collect', 
            SBUX_B2B_ShipPriority__c='Cutover'
        );
        insert testHeader;        
        
        //create Lists for stdSetController
        List<SBUX_B2B_AutoShipHeader__c> testHeaderList = new List<SBUX_B2B_AutoShipHeader__c>();
        testHeaderList.add(testHeader);
        
        //test
        Test.StartTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testHeader);
        SBUX_B2B_AutoShipGenerateCtrl cc = new SBUX_B2B_AutoShipGenerateCtrl(sc);
        
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(testHeaderList);
        ssc.setSelected(testHeaderList);
        SBUX_B2B_AutoShipGenerateCtrl csc = new SBUX_B2B_AutoShipGenerateCtrl(ssc);
        
        PageReference pageRef = Page.SBUX_B2B_AutoShipSubmitOrdersAll;
        Test.setCurrentPage(pageRef);
        
        //no selection (all)
        cc.autoShipSubmitAll();
        
        //selected set
        csc.autoShipSubmitAll();
        
        Test.StopTest();

    }
    
}