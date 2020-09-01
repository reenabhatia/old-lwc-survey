/**
 * Created by dgajwani on 4/22/20.
 */

global with sharing class SBUX_B2B_ccServiceCartItem extends ccrz.ccServiceCartItem {

    /**
     * @description Fetches custom fields from the CC Cart Item object.
     */
    global override Map<String, Object> getFieldsMap(Map<String, Object> inputData){
        // Get OOTB Fields Map.
        Map<String, Object> outputData = super.getFieldsMap(inputData);

        // Add custom fields
        String fields = (String)outputData.get(ccrz.ccService.OBJECTFIELDS);
        fields += ',SBUX_B2B_Is_Emergency__c';
        fields += ',Product__r.ccrz__UnitOfMeasure__c';
        fields += ',Product__r.SBUX_B2B_UOMConv__c';
        fields += ',Product__r.SBUX_B2B_CogsSupply__c';
        fields += ',Product__r.SBUX_B2B_ItemSource__c';
        fields += ',Product__r.SBUX_B2B_UPC__c';
        fields += ',Product__r.SBUX_B2B_PrimaryUOM__c';
        fields += ',Product__r.SBUX_B2B_Max_Orderable_Qty__c';

        outputData.put(ccrz.ccService.OBJECTFIELDS,fields);
        return outputData;
    }
}