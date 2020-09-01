@IsTest
public with sharing class SBUX_B2B_ccLogicProductPricingTest {
    private static final String PRODUCT_PRICE = 'productPrice';

    public static Map<String, Object> testData;

    public static void setupTestData() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
    }

    @IsTest
    public static void testProductEntitlementRuleInclude() {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList = (List<ccrz__E_Product__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);

        Test.startTest();

        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);

        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;

            ccrz.cc_CallContext.init(ctx);
            ccrz.cc_CallContext.currAccountId = testAccount.Id;

            List <String> prodList = new List <String>();

            for (ccrz__E_Product__c prod : testProductList) {
                prodList.add(prod.id);
            }

            Map<String, Object> inputData = new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccAPI.CURRENT_VERSION,
                    ccrz.ccAPIProduct.PRODUCTIDLIST => prodList,
                    ccrz.ccAPIProduct.PARAM_INCLUDE_PRICING => true,
                    ccrz.ccAPI.SIZING => new Map<String, Object>{
                            ccrz.ccApiProduct.ENTITYNAME => new Map<String, Object>{
                                    ccrz.ccAPI.SZ_DATA => ccrz.ccAPI.SZ_XL,
                                    ccrz.ccAPI.SZ_ASSC => false
                            }
                    }
            };

            Map<String, Object> outputData = ccrz.ccApiProduct.fetch(inputData);

            List<Map<String, Object>> outputProductList = (List<Map<String, Object>>) outputData.get(ccrz.ccAPIProduct.PRODUCTLIST);

            Map<String, Object> productObject = (Map<String, Object>) outputProductList.get(0);

            System.assertEquals(productObject.isEmpty(), false);
        }
        Test.stopTest();

    }

    @IsTest
    public static void testProductEntitlementRuleExclude() {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList = (List<ccrz__E_Product__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);

        Store__c testStore = (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        List <Store__c> storeList = new List<Store__c>();
        storeList.add(testStore);

        List<SBUX_B2B_CatalogEntitlementRule__c> catalogRules = (List<SBUX_B2B_CatalogEntitlementRule__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_RULES);
        delete catalogRules;

        SBUX_B2B_TestDataFactory.createCatalogEntitlementRule(testProductList, storeList, 'Exclude');

        Test.startTest();

        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);

        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;

            ccrz.cc_CallContext.init(ctx);
            ccrz.cc_CallContext.currAccountId = testAccount.Id;

            List <String> prodSKUList = new List <String>();

            for (ccrz__E_Product__c prod : testProductList) {
                prodSKUList.add(prod.ccrz__SKU__c);
            }

            Map<String, Object> inputData = new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccAPI.CURRENT_VERSION,
                    ccrz.ccAPIProduct.PRODUCTSKULIST => prodSKUList,
                    ccrz.ccAPIProduct.PARAM_INCLUDE_PRICING => true,
                    ccrz.ccAPI.SIZING => new Map<String, Object>{
                            ccrz.ccApiProduct.ENTITYNAME => new Map<String, Object>{
                                    ccrz.ccAPI.SZ_DATA => ccrz.ccAPI.SZ_XL,
                                    ccrz.ccAPI.SZ_ASSC => false
                            }
                    }
            };

            Map<String, Object> outputData = ccrz.ccApiProduct.fetch(inputData);

            List<Map<String, Object>> outputProductList = (List<Map<String, Object>>) outputData.get(ccrz.ccAPIProduct.PRODUCTLIST);

            System.assertEquals(outputProductList, null);
        }
        Test.stopTest();


    }

    @IsTest
    public static void testPriceConversion() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        Map<String, Object> productFetchResponse;
        Test.startTest();
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            ctx.userLocale = 'en_US';
            ctx.userIsoCode = 'USD';
            ccrz.cc_CallContext.init(ctx);

            productFetchResponse = ccrz.ccAPIProduct.fetch(new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccApiProduct.PRODUCTSKULIST => new Set<String>{
                            SBUX_B2B_TestDataFactory.TEST_SKU + 0
                    },
                    ccrz.ccApiProduct.PARAM_INCLUDE_PRICING => true
            });
        }

        Test.stopTest();
        System.assertNotEquals(null, productFetchResponse);
        System.assertEquals(true, (Boolean) productFetchResponse.get(ccrz.ccApi.SUCCESS));
        Map<String, Object> productPricingData = (Map<String, Object>) productFetchResponse.get(ccrz.ccApiProduct.PRODUCTPRICINGDATA);
        System.assertNotEquals(0, productPricingData.size());

        for (String productSFID : productPricingData.keySet()){
            Map<String, Object> currProductPricingMap = (Map<String, Object>) productPricingData.get(productSFID);
            Map<String, Object> pricingMap = (Map<String, Object>) currProductPricingMap.get(PRODUCT_PRICE);
            System.assertEquals(true, pricingMap.containsKey(SBUX_B2B_ccLogicProductPricing.PRICE_KEY));
            System.assertEquals(SBUX_B2B_TestDataFactory.TEST_PRODUCT_PRICE * 6, (Decimal) pricingMap.get(SBUX_B2B_ccLogicProductPricing.PRICE_KEY));
        }

    }
}