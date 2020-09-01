/**
 * Created by dgajwani on 5/6/20.
 */
@IsTest
public with sharing class SBUX_B2B_ccLogicCartInitItemGroupsTest {
    public static Map<String, Object> testData;

    public static void setupTestData() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        Account licenseeAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_LICENSEE_ACCOUNT);
        List<ccrz__E_Product__c> testProducts = (List<ccrz__E_Product__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        SBUX_B2B_TestDataFactory.createInsertTestProductExceptionRules(licenseeAccount, testProducts[1]);
    }

    @isTest
    public static void testInitCartItemGroups() {
        setupTestData();

        Store__c testStore = (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        Map<String, Object> initItemGroupsResponse;
        String currCartENCID;

        Test.startTest();
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
                                    ccrz.ccApiCart.LINE_DATA_SKU => SBUX_B2B_TestDataFactory.TEST_SKU + 1,
                                    ccrz.ccApiCart.LINE_DATA_QUANTITY => 3
                            }
                    }
            });

            currCartENCID = (String) addToCartResult.get(ccrz.ccApiCart.CART_ENCID);
            ctx.currentCartId = currCartENCID;
            ccrz.cc_CallContext.init(ctx);
            ccrz__E_Cart__c currCart = [
                    SELECT Id
                    FROM ccrz__E_Cart__c
                    WHERE ccrz__EncryptedId__c = :currCartENCID
            ];
            currCart.SBUX_B2B_Store__c = testStore.Id;
            update currCart;

            initItemGroupsResponse = ccrz.ccApiCart.initItemGroups(new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccAPICart.CART_ENCID => currCartENCID
            });
        }

        Test.stopTest();

        List<ccrz__E_CartItemGroup__c> cartItemGroups = [
                SELECT Id, ccrz__GroupName__c
                FROM ccrz__E_CartItemGroup__c
                WHERE ccrz__Cart__c IN (
                        SELECT Id
                        FROM ccrz__E_Cart__c
                        WHERE ccrz__EncryptedId__c = :currCartENCID
                )
        ];
        System.assertEquals(1, cartItemGroups.size());
        ccrz__E_CartItemGroup__c currCartItemGroup = cartItemGroups[0];
        System.assertEquals('SUPPLY_RDC', currCartItemGroup.ccrz__GroupName__c);
    }

    @isTest
    public static void testInitCartItemGroupsWEmergencyOrder() {
        setupTestData();

        Store__c testStore = (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        Map<String, Object> initItemGroupsResponse;
        String currCartENCID;

        Test.startTest();
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
            ccrz__E_Cart__c currCart = [
                    SELECT Id
                    FROM ccrz__E_Cart__c
                    WHERE ccrz__EncryptedId__c = :currCartENCID
            ];
            currCart.SBUX_B2B_Store__c = testStore.Id;
            update currCart;

            // Mark a cart item EO.
            List<ccrz__E_CartItem__c> currCartItems = [
                    SELECT Id
                    FROM ccrz__E_CartItem__c
                    WHERE ccrz__Product__r.ccrz__SKU__c = :SBUX_B2B_TestDataFactory.TEST_SKU + 1
            ];
            currCartItems[0].SBUX_B2B_Is_Emergency__c = true;
            update currCartItems[0];

            initItemGroupsResponse = ccrz.ccApiCart.initItemGroups(new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccAPICart.CART_ENCID => currCartENCID
            });
        }

        Test.stopTest();

        List<ccrz__E_CartItem__c> currCartItems = [
                SELECT Id, ccrz__CartItemGroup__r.ccrz__GroupName__c, SBUX_B2B_Is_Emergency__c
                FROM ccrz__E_CartItem__c
                WHERE ccrz__Cart__r.ccrz__EncryptedId__c = :currCartENCID
        ];
        System.assertEquals(2, currCartItems.size());
        for (ccrz__E_CartItem__c ci : currCartItems){
            if (ci.SBUX_B2B_Is_Emergency__c){
                System.assertEquals(SBUX_B2B_ccLogicCartInitItemGroups.EMERGENCY_ORDER, ci.ccrz__CartItemGroup__r.ccrz__GroupName__c);
            }
        }
    }
}