/**
 * Created by dgajwani on 4/23/20.
 */
@IsTest
public with sharing class SBUX_B2B_EO_CtrlTest {

    public static Map<String, Object> testData;
    public static List<ccrz__E_Product__c> testProducts;

    public static void setupTestData() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        testProducts = (List<ccrz__E_Product__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            ccrz.cc_CallContext.init(ctx);
            // Add products to cart
            List<Map<String, Object>> lineData = new List<Map<String, Object>> ();
            Map<String, Object> currLine = new Map<String, Object> ();
            currLine.put(ccrz.ccApiCart.LINE_DATA_SKU, testProducts[0].ccrz__SKU__c);
            currLine.put(ccrz.ccApiCart.LINE_DATA_QUANTITY, Integer.valueOf(3));
            lineData.add(currLine);

            Map<String, Object> inputData = new Map<String, Object>{
                    ccrz.ccAPI.API_VERSION => ccrz.ccAPI.CURRENT_VERSION,
                    ccrz.ccApiCart.LINE_DATA => lineData
            };

            Map<String, Object> addToCartResult = ccrz.ccApiCart.addTo(inputData);
        }
    }

    @IsTest
    public static void testEONotAllowed() {
        setupTestData();
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);

        Map<String, Object> cartItemsMap = new Map<String, Object> ();
        List<ccrz__E_CartItem__c> availableCartItems = [
                SELECT Id
                FROM ccrz__E_CartItem__c
        ];
        cartItemsMap.put(availableCartItems[0].Id, true);

        Test.startTest();
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;

            SBUX_B2B_EO_Ctrl.updateCartItemsEOStatus(ctx, JSON.serialize(cartItemsMap));
        }
        Test.stopTest();

        availableCartItems = [SELECT Id, SBUX_B2B_Is_Emergency__c FROM ccrz__E_CartItem__c];
        System.assertNotEquals(0, availableCartItems.size());
        System.assertEquals(false, availableCartItems[0].SBUX_B2B_Is_Emergency__c);
    }

    @IsTest
    public static void testEOAllowed() {
        setupTestData();
        Account licenseeAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_LICENSEE_ACCOUNT);
        licenseeAccount.SBUX_B2B_Allow_EO_Orders__c = true;
        update licenseeAccount;

        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);

        Map<String, Object> cartItemsMap = new Map<String, Object> ();
        List<ccrz__E_CartItem__c> availableCartItems = [
                SELECT Id
                FROM ccrz__E_CartItem__c
        ];
        cartItemsMap.put(availableCartItems[0].Id, true);

        Test.startTest();
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;

            SBUX_B2B_EO_Ctrl.updateCartItemsEOStatus(ctx, JSON.serialize(cartItemsMap));
        }
        Test.stopTest();

        availableCartItems = [SELECT Id, SBUX_B2B_Is_Emergency__c FROM ccrz__E_CartItem__c];
        System.assertNotEquals(0, availableCartItems.size());
        System.assertEquals(true, availableCartItems[0].SBUX_B2B_Is_Emergency__c);
    }
}