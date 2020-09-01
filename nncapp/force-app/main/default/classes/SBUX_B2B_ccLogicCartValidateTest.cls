/**
 * Created by dgajwani on 5/19/20.
 */
@IsTest
public with sharing class SBUX_B2B_ccLogicCartValidateTest {
    public static Map<String, Object> testData;

    public static void setupTestData() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        ccrz__E_PageLabel__c itemLevelCapError = new ccrz__E_PageLabel__c(Name='CartInc_ItemLevelCapError', ccrz__ValueRT__c = 'The max orderable Quantity for SKU:{0} is {1}');
        insert itemLevelCapError;
    }

    @isTest
    public static void testItemLevelCapsError() {
        setupTestData();
        Map<String, Object> cartValidateResponse;
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

            Map<String, Object> checkMinQty = new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccApiCart.CART_ENCID => currCartENCID
            };
            cartValidateResponse = ccrz.ccApiCart.validate(checkMinQty);
        }
        Test.stopTest();

        System.assertEquals(false, cartValidateResponse.get(ccrz.ccApiCart.ALLOW_CHECKOUT));
    }

    @IsTest
    public static void testItemLevelCapsHappyPath() {
        setupTestData();
        Map<String, Object> cartValidateResponse;
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
                                    ccrz.ccApiCart.LINE_DATA_QUANTITY => 2
                            }
                    }
            });

            currCartENCID = (String) addToCartResult.get(ccrz.ccApiCart.CART_ENCID);

            Map<String, Object> checkMinQty = new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccApiCart.CART_ENCID => currCartENCID
            };
            cartValidateResponse = ccrz.ccApiCart.validate(checkMinQty);
        }
        Test.stopTest();

        System.assertEquals(true, cartValidateResponse.get(ccrz.ccApiCart.ALLOW_CHECKOUT));
    }
}