/**
 * Created by dgajwani on 5/7/20.
 */
@IsTest
public with sharing class SBUX_B2B_ccServiceCartItemGroupTest {

    public static Map<String, Object> testData;

    public static void setupTestData() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
    }

    @IsTest
    public static void testCartItemGroupRevise(){
        setupTestData();

        Map<String, Object> cartItemGroupReviseResponse;

        Test.startTest();
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            ccrz.cc_CallContext.init(ctx);

            Map<String, Object> cartCreateResult = ccrz.ccApiCart.create(new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION
            });

            String currCartSFID = (String) cartCreateResult.get(ccrz.ccApiCart.CART_ID);


            Map<String, Object> insertGroup = new Map<String, Object>{
                    SBUX_B2B_ccLogicCartInitItemGroups.CART_ITEM_GROUP_CART_KEY => currCartSFID,
                    SBUX_B2B_ccLogicCartInitItemGroups.CART_ITEM_GROUP_GROUP_NAME_KEY => 'TestGroup'
            };
            Map<String, Object> cartItemGroupCreateRequest = new Map<String, Object>{
                    ccrz.ccAPI.API_VERSION => 9,
                    SBUX_B2B_ccLogicCartInitItemGroups.CART_ITEM_GROUPS_KEY => new List<Map<String, Object>>{
                            insertGroup
                    }
            };
            Map<String, Object> res = ccrz.ccApiCart.createCartItemGroup(cartItemGroupCreateRequest);
            String newCartItemGroupSFID = (String) res.get(ccrz.ccApiCart.ITEMGROUPID);

            Map<String, Object> cartItemGroupReviseRequest = new Map<String, Object>{
                    ccrz.ccAPI.API_VERSION => 9,
                    SBUX_B2B_ccLogicCartInitItemGroups.CART_ITEM_GROUPS_KEY => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                    'sfid' => newCartItemGroupSFID,
                                    'groupName' => 'New test'
                            }
                    }
            };
            cartItemGroupReviseResponse = ccrz.ccApiCart.reviseCartItemGroup(cartItemGroupReviseRequest);
        }
        Test.stopTest();

        System.assertNotEquals(null, cartItemGroupReviseResponse);
    }

}