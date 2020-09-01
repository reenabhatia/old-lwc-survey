/**
 * Created by dgajwani on 4/29/20.
 */

global with sharing class SBUX_B2B_ccLogicCartGetShippingOptions extends ccrz.ccLogicCartGetShippingOptions {

    private static final String OOTB_DELIMITER = ' - ';
    private static final String PREFERRED_DELIMITER = '-';

    global virtual override Map<String, Object> getShippingOptions(Map<String, Object> inputData) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartGetShippingOptions:getShippingOptions');
        List<Object> shipAddrs = (List<Object>) inputData.get(ccrz.ccApiCart.SHIPPING_ADDRLIST);
        List<ccrz__E_ShippingRate__c> availableShippingOptions = [
                SELECT ccrz__Shipper__c,Name
                FROM ccrz__E_ShippingRate__c e
                WHERE ccrz__CurrencyISOCode__c = :ccrz.cc_CallContext.userCurrency
                AND ccrz__Storefront__c INCLUDES (:ccrz.cc_CallContext.storefront)
                ORDER BY ccrz__Sequence__c ASC
        ];
        List<ccrz.cc_ctrl_hlpr_ShippingOption> shippingOptions = new List<ccrz.cc_ctrl_hlpr_ShippingOption>();

        for (ccrz__E_ShippingRate__c currShipOption : availableShippingOptions) {
            ccrz.cc_ctrl_hlpr_ShippingOption currShippingOption = new ccrz.cc_ctrl_hlpr_ShippingOption(currShipOption.ccrz__Shipper__c, '', currShipOption.Name, ccrz.cc_CallContext.userCurrency, 0, 0);
            currShippingOption.uid = currShippingOption.uid.replaceFirst(OOTB_DELIMITER, PREFERRED_DELIMITER);
            currShippingOption.uniqueId = currShippingOption.uniqueId.replaceFirst(OOTB_DELIMITER, PREFERRED_DELIMITER);
            shippingOptions.add(currShippingOption);
        }

        if (ccrz.ccUtil.isEmpty(shipAddrs)) {
            inputData.put(ccrz.ccApiCart.SHIPPING_OPTIONS, JSON.serialize(shippingOptions));
        } else {
            Map<String, Object> retLst = new Map<String, Object>();
            for (Object shipAddr : shipAddrs) {
                Map<String, Object> item = (Map<String, Object>) shipAddr;
                String addrId = (String) item.get('sfid');
                retLst.put(addrId, JSON.deserializeUntyped(JSON.serialize(shippingOptions)));
            }
            inputData.put(ccrz.ccApiCart.SHIPPING_OPTIONS, retLst);
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartGetShippingOptions:getShippingOptions');
        return inputData;
    }
}