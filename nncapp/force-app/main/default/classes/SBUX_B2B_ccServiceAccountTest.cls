/**
 * Created by dgajwani on 7/9/20.
 */
@isTest
public with sharing class SBUX_B2B_ccServiceAccountTest {

    public static Map<String, Object> testData;

    public static void setupTestData() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
    }

    @IsTest
    public static void testAccountFetchWTransform() {
        setupTestData();

        Map<String, Object> accountFetchResult;

        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        ccrz.cc_CallContext.init(ctx);

        // Without Transform
        accountFetchResult = ccrz.ccApiAccount.fetch(new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccApiAccount.ID => ((Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT)).Id
        });

        Test.stopTest();

        System.assertNotEquals(null, accountFetchResult);
        System.assertEquals(true, accountFetchResult.containsKey(ccrz.ccApiAccount.ACCOUNTS));
        List<Map<String, Object>> allAccounts = (List<Map<String, Object>>) accountFetchResult.get(ccrz.ccApiAccount.ACCOUNTS);
        System.assertNotEquals(0, allAccounts.size());
        Map<String, Object> currAccount = allAccounts[0];
        // This is coming from ccLogicCartInitCartItemGroups
        System.assertEquals('test', currAccount.get(SBUX_B2B_ccServiceAccount.BILLING_STREET));
    }

    @IsTest
    public static void testAccountFetchWOTransform() {
        setupTestData();

        Map<String, Object> accountFetchResult;

        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        ccrz.cc_CallContext.init(ctx);

        // Without Transform
        accountFetchResult = ccrz.ccApiAccount.fetch(new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccApiAccount.ID => ((Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT)).Id,
                ccrz.ccAPI.SIZING => new Map<String, Object>{
                        ccrz.ccApiAccount.ENTITYNAME => new Map<String, Object>{
                                ccrz.ccAPI.SZ_SKIPTRZ => TRUE
                        }
                }
        });

        Test.stopTest();

        System.assertNotEquals(null, accountFetchResult);
        System.assertEquals(true, accountFetchResult.containsKey(ccrz.ccApiAccount.ACCOUNTS));
        List<Account> allAccounts = (List<Account>) accountFetchResult.get(ccrz.ccApiAccount.ACCOUNTS);
        System.assertNotEquals(0, allAccounts.size());
        Account currAccount = allAccounts[0];
        // This is coming from ccLogicCartInitCartItemGroups
        System.assertEquals(true, currAccount.BillingStreet.equalsIgnoreCase('test'));
    }
}