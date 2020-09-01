/**
 * Created by dgajwani on 7/2/20.
 */
@isTest
public with sharing class SBUX_B2B_cc_hk_UserInterfaceTest {

    @isTest
    public static void testMetaContentRGShop() {

        String metaResult;

        Test.startTest();
        SBUX_B2B_cc_hk_UserInterface uiHook = new SBUX_B2B_cc_hk_UserInterface();
        metaResult = uiHook.metaContent();
        Test.stopTest();

        System.assertNotEquals(null, metaResult);
    }
}