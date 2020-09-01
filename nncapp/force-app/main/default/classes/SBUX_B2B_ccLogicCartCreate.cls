/**
 * Created by dgajwani on 5/5/20.
 */

global with sharing class SBUX_B2B_ccLogicCartCreate extends ccrz.ccLogicCartCreate {

    /**
         * @description Add the contact's email on the cart.
         */
    global override Map<String, Object> createCarts(Map<String, Object> inputData) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartCreate:createCarts');
        Map<String, Object> outputData = super.createCarts(inputData);

        // Get current cart and add addresses and email
        List<ccrz__E_Cart__c> newCarts = (List<ccrz__E_Cart__c>) outputData.get(ccrz.ccAPICart.CART_OBJLIST);
        ccrz__E_Cart__c currCart = newCarts[0];

        if (currCart.ccrz__Account__c != null) {
            Store__c currStore = [
                    SELECT Id
                    FROM Store__c
                    WHERE Store_Account__c = :currCart.ccrz__Account__c
            ];
            currCart.SBUX_B2B_Store__c = currStore.Id;
        }

        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartCreate:createCarts');
        return outputData;
    }


}