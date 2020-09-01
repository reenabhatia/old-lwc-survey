global with sharing class SBUX_B2B_ccLogicPIFetchEntitled extends ccrz.ccLogicPIFetchEntitled 
{

    public virtual override Map<String, Object> processProductIndices(Map<String, Object> inputData)
    {
        Map<String, Object> outputData =  super.processProductIndices(inputData);

        if (outputData != null && !outputData.isEmpty() 
             && ccrz.ccUtil.isTrue(outputData, ccrz.ccAPIProductIndex.INCLUDE_COUNT)
             && ccrz.ccUtil.isKeyValued(outputData, ccrz.ccAPIProductIndex.COUNT)
             && ccrz.ccUtil.isKeyValued(outputData, ccrz.ccAPIProductIndex.PRODUCT_IDS))
        {
            Set <String> eligibleProdList = new Set<String>();

            Set<String> prodIds =  new Set <String>((List<String>)outputData.get(ccrz.ccAPIProductIndex.PRODUCT_IDS));

            List<String> storeRulesList = SBUX_B2B_StorefrontUtil.eligibleRulesForCurrentStore();

            if (!storeRulesList.isEmpty())
            {
               eligibleProdList = SBUX_B2B_StorefrontUtil.generateEligibleSKUList(storeRulesList, prodIds, eligibleProdList, ccrz.ccAPIProduct.PRODUCTIDLIST, null);
            }
            outputData.put(ccrz.ccAPIProductIndex.COUNT,eligibleProdList.size());
        }

        return outputData;
    }
}