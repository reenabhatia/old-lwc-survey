@IsTest
private with sharing class SBUX_B2B_cc_hk_CatalogTest
{
    private static Map<String, Object> testData;

    private static void setupTestData() 
    {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
    }



    @IsTest
    private static void testModifyAutoCompleteWithIncludeEntitlement()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);

        Test.startTest();

        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        String storefrontName = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        SBUX_B2B_cc_hk_Catalog catalogExtension = new SBUX_B2B_cc_hk_Catalog ();//ccrz.cc_hk_Catalog.getInstance(new Map<String,Object>{ccrz.cc_hk_Catalog.PARAM_STOREFRONT => storefrontName});

        System.runAs(testUser) 
        {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = storefrontName;
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            
            ccrz.cc_CallContext.init(ctx);
            ccrz.cc_CallContext.currAccountId = testAccount.Id;
            ccrz.cc_CallContext.storefront =  ctx.storefront;

            List <String> prodList = new List <String>();

            for (ccrz__E_Product__c prod: testProductList)
            {
                prodList.add(prod.Name);
            }
            Map<String,Object> autocompleteData =  new Map<String,Object>{ccrz.cc_hk_Catalog.PARAM_SEARCH_RESULTS => prodList,
                                                                                    ccrz.cc_hk_Catalog.PARAM_RESULTS_LIMIT => 10};

            Map<String,Object> retData = catalogExtension.modifyAutoComplete(autocompleteData);

           List<String> resultData = (List<String> )retData.get(ccrz.cc_hk_Catalog.PARAM_SEARCH_RESULTS );
           System.assertNotEquals(0,resultData.size());                                                                    
        }
        Test.stopTest();
    }



    @IsTest
    private static void testModifyAutoCompleteWithoutEntitlement()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);

        List<SBUX_B2B_CatalogEntitlementRule__c> catalogRules = (List<SBUX_B2B_CatalogEntitlementRule__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_RULES);
        delete catalogRules;

        Test.startTest();

        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        String storefrontName = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        SBUX_B2B_cc_hk_Catalog catalogExtension = new SBUX_B2B_cc_hk_Catalog (); //ccrz.cc_hk_Catalog.getInstance(new Map<String,Object>{ccrz.cc_hk_Catalog.PARAM_STOREFRONT => storefrontName});

        System.runAs(testUser) 
        {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = storefrontName;
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            
            ccrz.cc_CallContext.init(ctx);
            ccrz.cc_CallContext.currAccountId = testAccount.Id;
            ccrz.cc_CallContext.storefront =  ctx.storefront;

            List <String> prodList = new List <String>();

            for (ccrz__E_Product__c prod: testProductList)
            {
                prodList.add(prod.Name);
            }
            Map<String,Object> autocompleteData =  new Map<String,Object>{ccrz.cc_hk_Catalog.PARAM_SEARCH_RESULTS => prodList,
                                                                                    ccrz.cc_hk_Catalog.PARAM_RESULTS_LIMIT => 10};

            Map<String,Object> retData = catalogExtension.modifyAutoComplete(autocompleteData);

           List<String> resultData = (List<String> )retData.get(ccrz.cc_hk_Catalog.PARAM_SEARCH_RESULTS );
           System.assertEquals(0,resultData.size());                                                                    
        }
        Test.stopTest();
    }
}