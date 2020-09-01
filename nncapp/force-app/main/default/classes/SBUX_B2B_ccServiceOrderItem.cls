global with sharing class SBUX_B2B_ccServiceOrderItem extends ccrz.ccServiceOrderItem 
{
    /**
     * @description includes additional  fields from the CC Order Item object.
     */
    global override Map<String, Object> getFieldsMap(Map<String, Object> inputData)
    {
        // Get OOTB Fields Map.
        Map<String, Object> outputData = super.getFieldsMap(inputData);

        // Add additional fields
        String fields = (String)outputData.get(ccrz.ccService.OBJECTFIELDS);
        fields += ', ccrz__Product_Name__c';
        fields += ', Product__r.ccrz__UnitOfMeasure__c';
        fields += ', Product__r.SBUX_B2B_UOMConv__c';
        fields += ', SBUX_B2B_Return_Reason_Code__c';
        fields += ', ccrz__Product__r.SBUX_B2B_UPC__c';
        fields += ',Product__r.SBUX_B2B_PrimaryUOM__c';
        fields += ',SBUX_B2B_Primary_UOM_Quantity__c';
        fields += ',SBUX_Primary_UOM__c';

        outputData.put(ccrz.ccService.OBJECTFIELDS,fields);

        return outputData;
    }
}