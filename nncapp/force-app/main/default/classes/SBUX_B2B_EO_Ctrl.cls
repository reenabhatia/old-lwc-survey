/**
 * Created by dgajwani on 4/23/20.
 */

global with sharing class SBUX_B2B_EO_Ctrl {

    /**
     * @description Updates the SBUX_B2B_Is_Emergency__c of the cart items to the EOStatus value.
     */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult updateCartItemsEOStatus(ccrz.cc_RemoteActionContext ctx, String cartItemsJSON){
        ccrz.cc_RemoteActionResult result = ccrz.cc_CallContext.init(ctx);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_EO_Ctrl:updateCartItemEOStatus');
        if (SBUX_B2B_WOSharingUtil.checkEOAllowed()){
            // Deserialize JSON into cartItemSFID=>EOStatus map.
            Map<String, Object> cartItemsMap = (Map<String, Object>) JSON.deserializeUntyped(cartItemsJSON);

            List<ccrz__E_CartItem__c> cartItemsToUpdate = new List<ccrz__E_CartItem__c>();

            for (String cartItemSFID : cartItemsMap.keySet()){
                ccrz__E_CartItem__c currCartItem = new ccrz__E_CartItem__c(Id=cartItemSFID);
                currCartItem.SBUX_B2B_Is_Emergency__c = (Boolean) cartItemsMap.get(cartItemSFID);

                cartItemsToUpdate.add(currCartItem);
            }
            update cartItemsToUpdate;
            result.success = true;
        }else {
            ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'EO is not allowed for this store.');
        }

        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_EO_Ctrl:updateCartItemEOStatus');
        ccrz.ccLog.close(result);
        return result;
    }

}