/**
 * Created by dgajwani on 6/4/20.
 */

global with sharing class SBUX_B2B_ccServicePLI extends ccrz.ccServicePLI {

    global override Map<String, Object> getFieldsMap(Map<String, Object> inputData) {
        // Get OOTB Fields Map.
        Map<String, Object> outputData = super.getFieldsMap(inputData);

        // Add additional fields
        String fields = (String) outputData.get(ccrz.ccService.OBJECTFIELDS);
        fields += ', Product__r.SBUX_B2B_Orderable_UOM_Conversion_Factor__c';
        outputData.put(ccrz.ccService.OBJECTFIELDS, fields);

        return outputData;
    }
}