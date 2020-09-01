global with sharing class SBUX_B2B_ccLogicProductPricing extends ccrz.ccLogicProductPricing 
{
    private final static String RULE_INCLUDE = 'Include';
    private static final String PRICE_LIST_ITEMS = 'priceListItems';
    private static final String ENTITLED_PLIS = 'entitledPLIs';
    private static final String CONVERSION_FACTOR = 'SBUXB2BOrderableUOMConversionFactor';
    public static final String PRICE_KEY = 'price';
    private static final String PRODUCT_RELATION = 'productR';

    global virtual override Map<String, Object> preProcess(Map<String, Object> inputData) 
    {
        Map<String, Object> outputData = super.preProcess(inputData);

        if (outputData != null && (outputData.get(ccrz.ccAPIProduct.PRODUCTIDLIST) != null 
                                && ccrz.ccUtil.isKeyValued(outputData, ccrz.ccAPIProduct.PRODUCTIDLIST))
                || (outputData.get(ccrz.ccAPIProduct.PRODUCTSKULIST) != null
                 && ccrz.ccUtil.isKeyValued(outputData, ccrz.ccAPIProduct.PRODUCTSKULIST))) 
        {
            List<String> storeRulesList = SBUX_B2B_StorefrontUtil.eligibleRulesForCurrentStore();

            if (outputData.get(ccrz.ccAPIProduct.PRODUCTSKULIST) != null
                    && ccrz.ccUtil.isKeyValued(outputData, ccrz.ccAPIProduct.PRODUCTSKULIST)) 
            {
                processProdEligibilityFromRules(outputData, ccrz.ccAPIProduct.PRODUCTSKULIST, storeRulesList);
            } 
            else if (outputData.get(ccrz.ccAPIProduct.PRODUCTIDLIST) != null
                     && ccrz.ccUtil.isKeyValued(outputData, ccrz.ccAPIProduct.PRODUCTIDLIST)) 
            {
                processProdEligibilityFromRules(outputData, ccrz.ccAPIProduct.PRODUCTIDLIST, storeRulesList);
            }
        }
        return outputData;
    }

    global virtual override Map<String, Object> processPriceListItems(Map<String, Object> inputData) 
    {
        Map<String, Object> outputData = super.processPriceListItems(inputData);

        Map<String, Object> priceListItems = (Map<String, Object>) outputData.get(PRICE_LIST_ITEMS);

        for (String productSFID : priceListItems.keySet()) 
        {
            Map<String, Object> currProductPricingData = (Map<String, Object>) priceListItems.get(productSFID);
            List<Object> entitledPLIs = (List<Object>) currProductPricingData.get(ENTITLED_PLIS);

            for (Object currPLI : entitledPLIs) 
            {
                Map<String, Object> currPLIMap = (Map<String, Object>) currPLI;
                Map<String, Object> currProductMap = (Map<String, Object>) currPLIMap.get(PRODUCT_RELATION);
                Decimal conversionFactor = (Decimal) currProductMap.get(CONVERSION_FACTOR);
                Decimal price = (Decimal) currPLIMap.get(PRICE_KEY);

                if (conversionFactor != null && price != null) 
                {
                    currPLIMap.put(PRICE_KEY, price * conversionFactor);
                }
            }
        }

        return outputData;
    }

    private static void processProdEligibilityFromRules(Map<String, Object> outputData, String prodMapKey, List<String> storeRulesList) 
    {
        Set <String> eligibleProdList = new Set<String>();

        Boolean isInstanceOfSet = false;

        Set <String> prodIDs = new Set<String>();

        if (outputData.get(prodMapKey) instanceof List<String>) 
        {
            prodIDs = new Set <String>((List<String>) outputData.get(prodMapKey));
        } 
        else 
        {
            isInstanceOfSet = true;

            prodIDs = (Set<String>) outputData.get(prodMapKey);
        }
        if (!storeRulesList.isEmpty())
         {
            eligibleProdList = SBUX_B2B_StorefrontUtil.generateEligibleSKUList(storeRulesList, prodIDs, eligibleProdList, prodMapKey, null);
         }
         updateProductMapData(isInstanceOfSet, outputData, prodMapKey, eligibleProdList);
    }



    private static void updateProductMapData(Boolean isInstanceOfSet, Map<String, Object> outputData,
                                            String prodMapKey, Set<String> prodList) 
    {
        if (isInstanceOfSet) 
        {
            outputData.put(prodMapKey, prodList);
        } 
        else 
        {
            outputData.put(prodMapKey, new List<String>(prodList));
        }
    }

}