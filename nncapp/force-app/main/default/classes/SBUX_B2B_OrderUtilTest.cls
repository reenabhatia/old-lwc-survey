/**
 * Created by dgajwani on 5/6/20.
 */
@IsTest
public with sharing class SBUX_B2B_OrderUtilTest {
    public static Map<String, Object> testData;

    public static void setupTestData() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        Store__c testStore = (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        List<ccrz__E_Product__c> testProducts = (List<ccrz__E_Product__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        SBUX_B2B_TestDataFactory.createInsertItemDCSourcing(testProducts[0]);
        SBUX_B2B_TestDataFactory.createInsertDeliverySchedules(testStore);
        SBUX_B2B_TestDataFactory.createInsertStoreDCSourcing(testStore);
    }

    private static String createCartAndCartItemGroups() {
        Map<String, Object> addToCartResult = ccrz.ccApiCart.addTo(new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccApiCart.LINE_DATA => new List<Map<String, Object>>{
                        new Map<String, Object>{
                                ccrz.ccApiCart.LINE_DATA_SKU => SBUX_B2B_TestDataFactory.TEST_SKU + 1,
                                ccrz.ccApiCart.LINE_DATA_QUANTITY => 3
                        }
                }
        });

        String currCartENCID = (String) addToCartResult.get(ccrz.ccApiCart.CART_ENCID);

        ccrz.ccApiCart.initItemGroups(new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccAPICart.CART_ENCID => currCartENCID
        });

        List<ccrz__E_CartItemGroup__c> cartItemGroups = [
                SELECT Id
                FROM ccrz__E_CartItemGroup__c
                WHERE ccrz__Cart__r.ccrz__EncryptedId__c = :currCartENCID
        ];

        // Add requested delivery date to cart item group
        for (ccrz__E_CartItemGroup__c cig : cartItemGroups) {
            cig.ccrz__RequestDate__c = Date.today().addDays(12);
        }
        update cartItemGroups;

        return currCartENCID;
    }

    @isTest
    public static void testRDCCartItemGroup() {
        setupTestData();

        Test.startTest();
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            ctx.userLocale = 'en_US';
            ctx.currentPageName = SBUX_B2B_ccServiceCart.CHECKOUT_PAGE;
            ctx.userIsoCode = 'USD';

            ccrz.cc_CallContext.init(ctx);
            createCartAndCartItemGroups();

            SBUX_B2B_CheckoutCtrl.placeOrder(ctx);
        }

        Test.stopTest();
        List<ccrz__E_Order__c> allOrders = [
                SELECT Id, ccrz__OriginatedCart__r.ccrz__EncryptedId__c,ccrz__OrderDate__c,SBUX_B2B_ShipDate__c,ccrz__RequestDate__c, (SELECT Id FROM ccrz__E_OrderItems__r)
                FROM ccrz__E_Order__c
        ];
        System.assertEquals(1, allOrders.size());
        System.assertEquals(1, allOrders[0].ccrz__E_OrderItems__r.size());
        System.assertEquals(Date.today().addDays(4), allOrders[0].ccrz__OrderDate__c);
        System.assertEquals(Date.today().addDays(8), allOrders[0].SBUX_B2B_ShipDate__c);
        System.assertEquals(Date.today().addDays(12), allOrders[0].ccrz__RequestDate__c);
    }

    @isTest
    public static void testCDCCartItemGroup() {
        setupTestData();

        ccrz__E_Product__c productToUpdate = [SELECT Id FROM ccrz__E_Product__c WHERE ccrz__SKU__c = :SBUX_B2B_TestDataFactory.TEST_SKU + 1];
        productToUpdate.SBUX_B2B_ItemSource__c = 'CDC';
        update productToUpdate;

        Test.startTest();
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            ctx.userLocale = 'en_US';
            ctx.userIsoCode = 'USD';

            ccrz.cc_CallContext.init(ctx);
            createCartAndCartItemGroups();

            SBUX_B2B_CheckoutCtrl.placeOrder(ctx);
        }

        Test.stopTest();
        List<ccrz__E_Order__c> allOrders = [
                SELECT Id, ccrz__OriginatedCart__r.ccrz__EncryptedId__c,ccrz__OrderDate__c,SBUX_B2B_ShipDate__c,ccrz__RequestDate__c, (SELECT Id FROM ccrz__E_OrderItems__r)
                FROM ccrz__E_Order__c
        ];
        System.assertEquals(1, allOrders.size());
        System.assertEquals(1, allOrders[0].ccrz__E_OrderItems__r.size());
        System.assertEquals(Date.today().addDays(4), allOrders[0].ccrz__OrderDate__c);
        System.assertEquals(Date.today().addDays(8), allOrders[0].SBUX_B2B_ShipDate__c);
        System.assertEquals(Date.today().addDays(12), allOrders[0].ccrz__RequestDate__c);
    }

    @isTest
    public static void testExpiredDeliveryDate() {
        setupTestData();

        ccrz__E_Product__c productToUpdate = [SELECT Id FROM ccrz__E_Product__c WHERE ccrz__SKU__c = :SBUX_B2B_TestDataFactory.TEST_SKU + 1];
        productToUpdate.SBUX_B2B_ItemSource__c = 'CDC';
        update productToUpdate;

        Test.startTest();
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            ctx.userLocale = 'en_US';
            ctx.userIsoCode = 'USD';

            ccrz.cc_CallContext.init(ctx);
            createCartAndCartItemGroups();

            List<ccrz__E_CartItemGroup__c> cartItemGroups = [
                    SELECT Id
                    FROM ccrz__E_CartItemGroup__c
            ];

            // Add requested delivery date to cart item group
            for (ccrz__E_CartItemGroup__c cig : cartItemGroups) {
                cig.ccrz__RequestDate__c = Date.today().addDays(-12);
            }
            update cartItemGroups;

            SBUX_B2B_CheckoutCtrl.placeOrder(ctx);
        }

        Test.stopTest();
        List<ccrz__E_Order__c> allOrders = [
                SELECT Id, ccrz__OriginatedCart__r.ccrz__EncryptedId__c,ccrz__OrderDate__c,SBUX_B2B_ShipDate__c,ccrz__RequestDate__c, (SELECT Id FROM ccrz__E_OrderItems__r)
                FROM ccrz__E_Order__c
        ];
        System.assertEquals(0, allOrders.size());
    }

    @isTest
    public static void testMultipleCartItemGroups() {
        setupTestData();

        Test.startTest();
        String currCartENCID;
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            ctx.userLocale = 'en_US';
            ctx.userIsoCode = 'USD';

            ccrz.cc_CallContext.init(ctx);

            Map<String, Object> addToCartResult = ccrz.ccApiCart.addTo(new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccApiCart.LINE_DATA => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                    ccrz.ccApiCart.LINE_DATA_SKU => SBUX_B2B_TestDataFactory.TEST_SKU + 0,
                                    ccrz.ccApiCart.LINE_DATA_QUANTITY => 3
                            },
                            new Map<String, Object>{
                                    ccrz.ccApiCart.LINE_DATA_SKU => SBUX_B2B_TestDataFactory.TEST_SKU + 1,
                                    ccrz.ccApiCart.LINE_DATA_QUANTITY => 1
                            }
                    }
            });

            currCartENCID = (String) addToCartResult.get(ccrz.ccApiCart.CART_ENCID);
            
            // Mark a cart item EO.
            List<ccrz__E_CartItem__c> currCartItems = [
                    SELECT Id
                    FROM ccrz__E_CartItem__c
                    WHERE ccrz__Product__r.ccrz__SKU__c = :SBUX_B2B_TestDataFactory.TEST_SKU + 1
            ];
            currCartItems[0].SBUX_B2B_Is_Emergency__c = true;
            update currCartItems[0];

            ccrz.ccApiCart.initItemGroups(new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccAPICart.CART_ENCID => currCartENCID
            });
            List<ccrz__E_CartItemGroup__c> cartItemGroups = [
                    SELECT Id
                    FROM ccrz__E_CartItemGroup__c
                    WHERE ccrz__Cart__r.ccrz__EncryptedId__c = :currCartENCID
            ];
            for (ccrz__E_CartItemGroup__c cig : cartItemGroups){
                cig.ccrz__RequestDate__c = Date.today().addDays(12);
            }
            update cartItemGroups;
            SBUX_B2B_CheckoutCtrl.placeOrder(ctx);
        }

        Test.stopTest();

        List<ccrz__E_Order__c> allOrders = [
                SELECT Id, ccrz__OriginatedCart__r.ccrz__EncryptedId__c, (SELECT Id FROM ccrz__E_OrderItems__r)
                FROM ccrz__E_Order__c
        ];
        System.assertEquals(2, allOrders.size());
        for (ccrz__E_Order__c order : allOrders) {
            System.assertEquals(currCartENCID, order.ccrz__OriginatedCart__r.ccrz__EncryptedId__c);
            System.assertEquals(1, order.ccrz__E_OrderItems__r.size());
        }
    }
}