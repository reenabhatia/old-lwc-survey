/**
 * Created by dgajwani on 5/18/20.
 */

global with sharing class SBUX_B2B_ccLogicCartValidate extends ccrz.ccLogicCartValidate {

    private static final String CART_ITEM_MESSAGING_SECTION = 'messagingSection-';
    private static final String MAX_ORDERABLE_QTY_MESSAGE_PL = 'CartInc_ItemLevelCapError';
    private static final String CART_MESSAGING_HEADER_PL = 'CartInc_ItemLevelCapsHeaderError';
    private static final String CART_MESSAGING_NO_SHIPPING_ADDRESS_PL = 'CartInc_NoShippingAddressError';
    private static final String CART_MESSAGING_CSS_CLASS = 'cartMessaging';

    global override Map <String, Object> processValidate(Map <String, Object> inputData) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartValidate:processValidate');

        inputData = super.processValidate(inputData);

        // Check inventory if OOTB validation passed.
        if ((Boolean) inputData.get(ccrz.ccApiCart.ALLOW_CHECKOUT)){
            Store__c currStore = SBUX_B2B_StorefrontUtil.fetchCurrentStore();
            String siteID = SBUX_B2B_StorefrontUtil.getSiteIDForCustomer(currStore.Id);
            if (siteID == null){
                // If we dont have a site ID, we dont have a valid shipTO.
                inputData.put(ccrz.ccApiCart.ALLOW_CHECKOUT, false);
                List <ccrz.cc_bean_Message> existingMessages = (List<ccrz.cc_bean_Message>) inputData.get(ccrz.ccApi.MESSAGES);
                ccrz.cc_bean_Message newMessage = new ccrz.cc_bean_Message();
                newMessage.type = ccrz.cc_bean_Message.MessageType.CUSTOM;
                newMessage.severity = ccrz.cc_bean_Message.MessageSeverity.ERROR;
                newMessage.classToAppend = CART_MESSAGING_CSS_CLASS;
                newMessage.labelId = CART_MESSAGING_NO_SHIPPING_ADDRESS_PL;
                existingMessages.add(newMessage);
            }
        }

        Contact currContact = [
                SELECT Id,SBUX_B2B_SkipQtyEnforcement__c
                FROM Contact
                WHERE Id IN (
                        SELECT ContactId
                        FROM User
                        WHERE Id = :UserInfo.getUserId()
                )
        ];
        // Validate Max Orderable Qty
        if ((Boolean) inputData.get(ccrz.ccApiCart.ALLOW_CHECKOUT) && !currContact.SBUX_B2B_SkipQtyEnforcement__c) {
            validateMaxOrderableQty(inputData);
        }

        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartValidate:processValidate');
        return inputData;
    }

    /**
     * @description Fetches the current cart using ccApiCart.fetch()
     */
    private static Map<String, Object> fetchCart() {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartValidate:fetchCart');
        Map<String, Object> cartFetchRequest = new Map<String, Object>{
                ccrz.ccAPI.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccAPICart.CART_ENCID => ccrz.cc_CallContext.currCartId,
                ccrz.ccApi.SIZING => new Map<String, Object>{
                        ccrz.ccAPICart.ENTITYNAME => new Map<String, Object>{
                                ccrz.ccAPI.SZ_DATA => ccrz.ccAPI.SZ_XL,
                                ccrz.ccAPI.SZ_SKIPTRZ => true
                        }
                }
        };
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartValidate:fetchCart');
        return ccrz.ccApiCart.fetch(cartFetchRequest);
    }

    private static void validateMaxOrderableQty(Map<String, Object> inputData) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartValidate:validateMaxOrderableQty');
        List <ccrz.cc_bean_Message> existingMessages = (List<ccrz.cc_bean_Message>) inputData.get(ccrz.ccApi.MESSAGES);
        Boolean allowCheckout = (Boolean) inputData.get(ccrz.ccApiCart.ALLOW_CHECKOUT);
        Map<String, Object> cartFetchResponse = fetchCart();

        //check the fetch response to see if cart data was returned
        if (!((Boolean) cartFetchResponse.get(ccrz.ccAPI.SUCCESS))
                || !cartFetchResponse.containsKey(ccrz.ccAPICart.CART_OBJLIST)
                || ((List<ccrz__E_Cart__c>) cartFetchResponse.get(ccrz.ccAPICart.CART_OBJLIST) == null)
                || ((List<ccrz__E_Cart__c>) cartFetchResponse.get(ccrz.ccAPICart.CART_OBJLIST)).isEmpty()) {
            return;
        }

        Map<String, List<ccrz__E_CartItem__c>> cartItemsByCartId = (Map<String, List<ccrz__E_CartItem__c>>) cartFetchResponse.get(ccrz.ccAPICart.CARTITEMSBYID);
        List<ccrz__E_Cart__c>cartList = (List<ccrz__E_Cart__c>) cartFetchResponse.get(ccrz.ccAPICart.CART_OBJLIST);

        //grab the first cart and its cart Items
        ccrz__E_Cart__c currCart = cartList[0];
        List<ccrz__E_CartItem__c> cartItems = cartItemsByCartId.get(currCart.Id);

        if (cartItems != null && !cartItems.isEmpty()) {
            ccrz__E_PageLabel__c itemLevelCapErrorMsg = [
                    SELECT ccrz__ValueRT__c
                    FROM ccrz__E_PageLabel__c
                    WHERE Name = :MAX_ORDERABLE_QTY_MESSAGE_PL
            ];
            for (ccrz__E_CartItem__c currCartItem : cartItems) {
                if (currCartItem.ccrz__Quantity__c > currCartItem.ccrz__Product__r.SBUX_B2B_Max_Orderable_Qty__c) {
                    allowCheckout = false;
                    existingMessages.add(generateErrorMessage(currCartItem, itemLevelCapErrorMsg.ccrz__ValueRT__c));
                }
            }
        }

        if (!allowCheckout) {
            ccrz.cc_bean_Message newMessage = new ccrz.cc_bean_Message();
            newMessage.type = ccrz.cc_bean_Message.MessageType.CUSTOM;
            newMessage.severity = ccrz.cc_bean_Message.MessageSeverity.ERROR;
            newMessage.classToAppend = CART_MESSAGING_CSS_CLASS;
            newMessage.labelId = CART_MESSAGING_HEADER_PL;
            existingMessages.add(newMessage);
        }

        inputData.put(ccrz.ccApiCart.ALLOW_CHECKOUT, allowCheckout);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartValidate:validateMaxOrderableQty');
    }

    private static ccrz.cc_bean_Message generateErrorMessage(ccrz__E_CartItem__c currCartItem, String messageTemplateString) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartValidate:generateErrorMessage');

        ccrz.cc_bean_Message newMessage = new ccrz.cc_bean_Message();
        newMessage.type = ccrz.cc_bean_Message.MessageType.CUSTOM;
        newMessage.severity = ccrz.cc_bean_Message.MessageSeverity.ERROR;
        newMessage.classToAppend = CART_ITEM_MESSAGING_SECTION + currCartItem.Id;
        newMessage.message = String.format(messageTemplateString, new List<Object>{
                currCartItem.ccrz__Product__r.ccrz__SKU__c
                , currCartItem.ccrz__Product__r.SBUX_B2B_Max_Orderable_Qty__c
                , currCartItem.ccrz__UnitOfMeasure__c
        });

        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartValidate:generateErrorMessage');
        return newMessage;
    }

}