global with sharing class SBUX_B2B_cc_hk_Catalog extends ccrz.cc_hk_Catalog
{
    global virtual override Map<String,Object> modifyAutoComplete(Map<String,Object> inputResults)
    {
        Set <String> elligibleProdList = new Set<String>();

        if (inputResults != null  && !inputResults.isEmpty() 
            && ccrz.ccUtil.isKeyValued(inputResults, ccrz.cc_hk_Catalog.PARAM_SEARCH_RESULTS))
        {
           List<String> prodNames = (List<String>)inputResults.get(ccrz.cc_hk_Catalog.PARAM_SEARCH_RESULTS);

           List<String> storeRulesList = SBUX_B2B_StorefrontUtil.eligibleRulesForCurrentStore();

           if ( storeRulesList != null && !storeRulesList.isEmpty())
           {
              elligibleProdList = SBUX_B2B_StorefrontUtil.generateEligibleSKUList(storeRulesList,null,elligibleProdList,null,prodNames);
           }
        }
        inputResults.put(ccrz.cc_hk_Catalog.PARAM_SEARCH_RESULTS, new List<String>(elligibleProdList));

        Map<String,Object> retData = super.modifyAutoComplete(inputResults);
       
        return retData;
    }
}