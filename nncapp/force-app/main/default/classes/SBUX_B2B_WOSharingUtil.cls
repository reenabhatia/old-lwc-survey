/**
 * Created by dgajwani on 7/9/20.
 */

public without sharing class SBUX_B2B_WOSharingUtil {

    public static List<SBUX_B2B_ProductExceptionRule__c> queryProductExceptions() {
        List<SBUX_B2B_ProductExceptionRule__c> productExceptionsForThisCartAndStore = [
                SELECT SBUX_B2B_Product__c, SBUX_B2B_CogsSupplyException__c
                FROM SBUX_B2B_ProductExceptionRule__c
                WHERE SBUX_B2B_Account__c = :ccrz.cc_CallContext.currAccount.ParentId
                AND SBUX_B2B_Product__c IN (
                        SELECT ccrz__Product__c
                        FROM ccrz__E_CartItem__c
                        WHERE ccrz__Cart__r.ccrz__EncryptedId__c = :ccrz.cc_CallContext.currCartId
                )
        ];
        return productExceptionsForThisCartAndStore;
    }

    public static Boolean checkEOAllowed() {
        Account parentAccount = [
                SELECT Parent.SBUX_B2B_Allow_EO_Orders__c
                FROM Account
                WHERE Id = :ccrz.cc_CallContext.currAccount.Id
        ];
        return parentAccount.Parent.SBUX_B2B_Allow_EO_Orders__c;
    }
}