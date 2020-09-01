/**
 * Created by dgajwani on 4/28/20.
 */

global with sharing class SBUX_B2B_ccServiceCart extends ccrz.ccServiceCart {

    public static final String CHECKOUT_PAGE = 'ccrz__Checkout';
    private static final String CART_ITEM_GROUP_SUBQUERY = '(SELECT Cart__c,GroupName__c,Note__c,RequestDate__c,ShipAmount__c,ShipMethod__c,ShipTo__c,SBUX_B2B_ExpeditedComment__c,SBUX_B2B_ExpeditedReasonCode__c,SBUX_B2B_PONumber__c FROM E_CartItemGroups__r)';
    private static final String EO_REASON_LABEL = 'label';
    private static final String EO_REASON_VALUE = 'value';
    private static final String EO_REASON_CODES = 'availableReasonCodes';
    private static final String CART_PAGE = 'ccrz__Cart';
    private static final String ALLOW_EO = 'allowEO';

    /**
     * @description Fetches custom fields from the CC Cart Item object.
     */
    global override Map<String, Object> getFieldsMap(Map<String, Object> inputData) {
        // Get OOTB Fields Map.
        Map<String, Object> outputData = super.getFieldsMap(inputData);

        // Add custom fields
        String fields = (String) outputData.get(ccrz.ccService.OBJECTFIELDS);
        fields += ',SBUX_B2B_Store__c';
        outputData.put(ccrz.ccService.OBJECTFIELDS, fields);
        return outputData;
    }

    global override Map<String, Object> getSubQueryMap(Map<String, Object> inputData) {
        Map<String, Object> subQueryMap = super.getSubQueryMap(inputData);
        String cartItemGroupSubQuery = CART_ITEM_GROUP_SUBQUERY;
        subQueryMap.put('E_CartItemGroups__r', cartItemGroupSubQuery);
        return subQueryMap;
    }

    global override Map<String, Object> fetch(Map<String, Object> inputData) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccServiceCart:fetch');
        Map<String, Object> outputData = super.fetch(inputData);
        if (ccrz.cc_CallContext.currPageName != null && ccrz.cc_CallContext.currPageName.equalsIgnoreCase(CHECKOUT_PAGE)) {
            List<Map<String, Object>> availableEOReasonCodes = new List<Map<String, Object>>();
            Schema.DescribeFieldResult reasonCodeDescribe = ccrz__E_Order__c.SBUX_B2B_ReasonCode__c.getDescribe();
            List<Schema.PicklistEntry> reasonCodePicklistValues = reasonCodeDescribe.getPicklistValues();
            for (Schema.PicklistEntry plValue : reasonCodePicklistValues) {
                availableEOReasonCodes.add(new Map<String, Object>{
                        EO_REASON_LABEL => plValue.getLabel(),
                        EO_REASON_VALUE => plValue.getValue()
                });
            }
            outputData.put(EO_REASON_CODES, availableEOReasonCodes);
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccServiceCart:fetch');
        return outputData;
    }

    /**
     * @description Add a flag to check if EO is allowed
     */
    global override Map<String, Object> prepReturn(Map<String, Object> inputData) {
        try {
            if (ccrz.cc_CallContext.currPageName != null && ccrz.cc_CallContext.currPageName.equalsIgnoreCase(CART_PAGE)) {
                List<Object> cartList = (List<Object>) inputData.get(ccrz.ccApiCart.CART_OBJLIST);
                if (cartList.size() > 0) {
                    Object cartObj = cartList.get(0);
                    if (!(cartObj instanceof ccrz__E_Cart__c)) {
                        Map<String, Object> cartMso = (Map<String, Object>) cartObj;
                        cartMso.put(ALLOW_EO, SBUX_B2B_WOSharingUtil.checkEOAllowed());
                    }
                }
            }
        } catch (Exception e) {
            ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_ccServiceCart:prepReturn:e', e);
        }
        Map<String, Object> output = super.prepReturn(inputData);
        return output;
    }
}