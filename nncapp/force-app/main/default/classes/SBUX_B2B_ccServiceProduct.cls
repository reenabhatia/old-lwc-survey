/**
 * Created by dgajwani on 4/22/20.
 */

global with sharing class SBUX_B2B_ccServiceProduct extends ccrz.ccServiceProduct 
{
    /**
     * @description Fetches custom fields from the CC Product object.
     */
    global override Map<String, Object> getFieldsMap(Map<String, Object> inputData)
    {
        // Get OOTB Fields Map.
        Map<String, Object> outputData = super.getFieldsMap(inputData);

        // Add custom fields
        String fields = (String)outputData.get(ccrz.ccService.OBJECTFIELDS);
        fields += ',SBUX_B2B_EO_Eligible__c';
        fields += ',SBUX_B2B_UOMConv__c';
        fields += ',SBUX_B2B_CogsSupply__c';
        fields += ',SBUX_B2B_ItemSource__c';
        fields += ',SBUX_B2B_UPC__c';
        fields += ',SBUX_B2B_PrimaryUOM__c';
        fields += ',SBUX_B2B_Max_Orderable_Qty__c';

        outputData.put(ccrz.ccService.OBJECTFIELDS,fields);
        return outputData;
    }


    global override Map<String, Object> getSubQueryMap(Map<String, Object> inputData)
    {
        Map<String, Object> outputData = super.getSubQueryMap(inputData);

        Map<String,Object> sourcingDCMap  =  SBUX_B2B_StorefrontUtil.getSourcingDCMap();

        if (sourcingDCMap !=  null  && !sourcingDCMap.isEmpty()
             && ccrz.ccUtil.isKeyValued(sourcingDCMap, 'sourcingDC'))
        {
            List <String> sourcingDC =  (List <String>)sourcingDCMap.get('sourcingDC');

            outputData.put('ItemSourcing__r', '(SELECT SBUX_B2B_ItemNumber__c,SBUX_B2B_UpperThreshold__c,SBUX_B2B_LowerThreshold__c,SBUX_B2B_InventoryQuantity__c,SBUX_B2B_CutoffTime__c,SBUX_B2B_CuttoffTimeZone__c,SBUX_B2B_DistributionCenter__c,SBUX_B2B_DPNumber__c,SBUX_B2B_EndOrderDate__c,SBUX_B2B_StartOrderDate__c FROM SBUX_B2B_ItemDCSourcing__r WHERE SBUX_B2B_DistributionCenter__c  IN (\'' + String.join(sourcingDC, '\',\'') + '\'))'); 
        }
        return outputData;
    }

}