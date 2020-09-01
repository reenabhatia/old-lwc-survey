@IsTest
private with sharing class SBUX_B2B_cc_hk_SSOTest 
{ 
    
    private static Map<String, Object> testData;

    private static void setupTestData() 
    {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
    }

    
    @IsTest
    private static void testGetLinkOverrideMap()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        Test.startTest();

        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        String storefrontName = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ccrz.cc_hk_SSO ssoHk = new SBUX_B2B_cc_hk_SSO();

        System.runAs(testUser) 
        {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = storefrontName;
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            
            ccrz.cc_CallContext.init(ctx);
            ccrz.cc_CallContext.currAccountId = testAccount.Id;
            ccrz.cc_CallContext.storefront =  ctx.storefront;

           
            Map<String,Object> inputData =  new Map<String,Object>();

            Map<String,Object> retData = ssoHk.getLinkOverrideMap(inputData);

            System.assertNotEquals(null,retData.get(ccrz.cc_hk_SSO.HEADER_LOGIN));  
            System.assertNotEquals(null,retData.get(ccrz.cc_hk_SSO.MYACCOUNT_CHANGEPASSWORD));                                                                    
        }
        Test.stopTest();
    }

}