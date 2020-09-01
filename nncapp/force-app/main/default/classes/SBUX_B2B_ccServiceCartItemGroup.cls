/**
 * Created by dgajwani on 4/30/20.
 */

global with sharing class SBUX_B2B_ccServiceCartItemGroup extends ccrz.ccServiceCartItemGroup{

    global override Map<String, Object> revise(Map<String, Object> inputData){
        Map<String, Object> tIndex = (Map<String, Object>) inputData.get(ccrz.ccService.TRANSFORMINDEX);
        tIndex.put('SBUXB2BExpeditedReasonCode','SBUX_B2B_ExpeditedReasonCode__c');
        tIndex.put('SBUXB2BExpeditedComment','SBUX_B2B_ExpeditedComment__c');
        tIndex.put('SBUXB2BPONumber','SBUX_B2B_PONumber__c');
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_ccServiceCartItemGroup:revise:JSON.serialize(tIndex)', JSON.serialize(tIndex));
        return super.revise(inputData);
    }
}