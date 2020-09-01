@IsTest
private with sharing class SBUX_B2B_ccLogicPIFetchEntitledTest 
{
    private static Map<String, Object> testData;

    private static void setupTestData() 
    {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
    }



    @IsTest
    public static void testProductCountWithEntitlementRuleInclude() 
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList = (List<ccrz__E_Product__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);

        ccrz__E_Category__c category  = (ccrz__E_Category__c) testData.get(SBUX_B2B_TestDataFactory.TEST_CATEGORY);

        SBUX_B2B_TestDataFactory.createProductIndices(testData);

        Test.startTest();

        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);

        System.runAs(testUser) 
        {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;

            ccrz.cc_CallContext.init(ctx);
            ccrz.cc_CallContext.currAccountId = testAccount.Id;

            Map<String, Object> inputData = new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccAPI.CURRENT_VERSION,
                     ccrz.ccAPIProductIndex.ACTIVE => TRUE,
                     ccrz.ccAPIProductIndex.INCLUDE_COUNT => TRUE,
                     ccrz.ccAPIProductIndex.STOREFRONT => SBUX_B2B_TestDataFactory.TEST_STOREFRONT,
                     ccrz.ccAPIProductIndex.PRODUCT_IDS_ONLY => TRUE,
                     ccrz.ccAPIProductIndex.STATUS_FILTER => TRUE,
                     ccrz.ccAPIProductIndex.DATE_FILTER => TRUE,
                     ccrz.ccAPIProductIndex.CURRENCIES => new Set<String>{'USD'},
                     ccrz.ccAPIProductIndex.LOCALE => 'en_US',
                    ccrz.ccAPIProductIndex.CATEGORY_IDS => new List<String>{category.Id},
                    ccrz.ccAPI.SIZING => new Map<String, Object>{
                            ccrz.ccApiProduct.ENTITYNAME => new Map<String, Object>{
                                    ccrz.ccAPI.SZ_DATA => ccrz.ccAPI.SZ_XL,
                                    ccrz.ccAPI.SZ_ASSC => false
                            }
                    }
            };

            Map<String, Object> fetchEntitledResponse = ccrz.ccAPIProductIndex.fetchEntitled(inputData);
           
             Decimal productCount = (Decimal)fetchEntitledResponse.get(ccrz.ccAPIProductIndex.COUNT);

             System.assertEquals(productCount, testProductList.size());
        }
        Test.stopTest();

    }



    @IsTest
    public static void testProductCountEntitlementRuleExclude() 
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList = (List<ccrz__E_Product__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);

        Store__c testStore = (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        List <Store__c> storeList = new List<Store__c>();
        storeList.add(testStore);

        List<SBUX_B2B_CatalogEntitlementRule__c> catalogRules = (List<SBUX_B2B_CatalogEntitlementRule__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_RULES);
        delete catalogRules;

        SBUX_B2B_TestDataFactory.createCatalogEntitlementRule(testProductList, storeList, 'Exclude');

        ccrz__E_Category__c category  = (ccrz__E_Category__c) testData.get(SBUX_B2B_TestDataFactory.TEST_CATEGORY);

        SBUX_B2B_TestDataFactory.createProductIndices(testData);

        Test.startTest();

        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);

        System.runAs(testUser) 
        {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;

            ccrz.cc_CallContext.init(ctx);
            ccrz.cc_CallContext.currAccountId = testAccount.Id;

            Map<String, Object> inputData = new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccAPI.CURRENT_VERSION,
                 ccrz.ccAPIProductIndex.ACTIVE => TRUE,
                 ccrz.ccAPIProductIndex.INCLUDE_COUNT => TRUE,
                 ccrz.ccAPIProductIndex.STOREFRONT => SBUX_B2B_TestDataFactory.TEST_STOREFRONT,
                 ccrz.ccAPIProductIndex.PRODUCT_IDS_ONLY => TRUE,
                 ccrz.ccAPIProductIndex.STATUS_FILTER => TRUE,
                 ccrz.ccAPIProductIndex.DATE_FILTER => TRUE,
                 ccrz.ccAPIProductIndex.CURRENCIES => new Set<String>{'USD'},
                 ccrz.ccAPIProductIndex.LOCALE => 'en_US',
                ccrz.ccAPIProductIndex.CATEGORY_IDS => new List<String>{category.Id},
                ccrz.ccAPI.SIZING => new Map<String, Object>{
                        ccrz.ccApiProduct.ENTITYNAME => new Map<String, Object>{
                                ccrz.ccAPI.SZ_DATA => ccrz.ccAPI.SZ_XL,
                                ccrz.ccAPI.SZ_ASSC => false
                        }
                 } };

            Map<String, Object> fetchEntitledResponse = ccrz.ccAPIProductIndex.fetchEntitled(inputData);
        
            Decimal productCount = (Decimal)fetchEntitledResponse.get(ccrz.ccAPIProductIndex.COUNT);

            System.assertEquals(productCount, 0);
       }

        Test.stopTest();
    }

   
}