/**
 * Created by dgajwani on 3/31/20.
 */

public with sharing class SBUX_B2B_AutoShipUtil {

    //BATCH SIZE VARS - used for AutoshipJobs
    public static final Integer DELETE_FORECAST_BATCH_SIZE = 2000;
    public static final Integer DELETE_ORDERS_BATCH_SIZE = 200;
    public static final Integer PURGE_ORDERS_BATCH_SIZE = 200;
    public static final Integer PROCESSOR_BATCH_SIZE = 10;

    public static final String BEVERAGE_AUTOSHIP = 'Beverage';
    private static final String COFFEE_FOR_BREWING_5_LB_BULLET = 'Coffee for Brewing 5lb';
    private static final String RETAIL_WHOLE_BEAN_COFFEE = 'Retail Whole Bean';
    private static final String GIFT_CARD_PARTICIPATION = 'Gift Card';
    private static final String MERCHANDISE = 'Merchandise';
    private static final String AUTOSHIP_STOREFRONT = 'DefaultStore';
    private static final String ORDER_STATUS_DRAFT = 'Draft';
    private static final String ORDER_CURRENCY_USD = 'USD';
    private static final String ORDER_CURRENCY_CAD = 'CAD';
    private static final String ORDER_LINE_TYPE_MAJOR = 'Major';
    private static final String SUPPLIES_SMALLWARES = 'Supplies/Smallwares';
    private static final String LOCAL_PRODUCT = 'Local Product';
    private static final String NO_AUTOSHIP = 'No Autoship';
    private static final String ORDER_TYPE_US = ' - US';
    private static final String ORDER_TYPE_CA = ' - CAN';
    private static final String STORE_COUNTRY_US = 'US';
    private static final String STORE_COUNTRY_CA = 'CA';
    private static final String AUTOSHIP_LINE_RECORD_TYPE_STORE_ATTRIBUTE = 'SBUX_B2B_Store_Attribute';
    private static final String ASSORTMENT_SIZE_US_ALL = 'US All';
    private static final String ASSORTMENT_SIZE_CANADA_ALL = 'CN All';
    public static final String ORDER_STATUS_ORDER_SUBMITTED = 'Order Submitted';
    public static final String ORDER_SOURCE_AUTOSHIP = 'Autoship';
    public static final String SIMPLE_PRODUCT = 'Product';
    private static final String AUTOSHIP_US_PRICELIST = 'Autoship US';
    private static final String AUTOSHIP_CANADA_PRICELIST = 'Autoship Canada';
    private static final String UOM_CONVERSION_TO_CODE = 'toCode';
    private static final String UOM_CONVERSION_FROM_CODE = 'fromCode';
    private static final String UOM_CONVERSION_CONVERSION_FACTOR = 'convRt';
    private static final String SHIP_STRUCTURE_LLI = 'LLI';
    private static final String NAME_DELIMITER = '_';
    public static final String ORDER_STATUS_ERROR = 'Error';
    private static final String MISSING_SHIP_TO_ERROR = 'A valid shipTo for this store was not found.';
    private static final String SPACE_DELIMITER = ' ';
    private static final String HYPHEN_DELIMITER = '-';

    /**
     * @description Gets the pricing data from the US/CA pricelist for the products referenced in autoship lines.
     */
    public static void getPricingData(
            String autoShipHeaderId
            , Map<String, Object> USAutoShipPricing
            , Map<String, Object> CAAutoShipPricing) {
        List<ccrz__E_PriceListItem__c> USPriceListItems = [
                SELECT ccrz__Product__r.ccrz__SKU__c, ccrz__Price__c
                FROM ccrz__E_PriceListItem__c
                WHERE ccrz__Pricelist__r.Name = :AUTOSHIP_US_PRICELIST
                AND ccrz__Product__c IN (
                        SELECT SBUX_B2B_ItemSKU__c
                        FROM SBUX_B2B_AutoShipLine__c
                        WHERE SBUX_B2B_AutoshipHeader__c = :autoShipHeaderId
                )
        ];
        for (ccrz__E_PriceListItem__c pli : USPriceListItems) {
            USAutoShipPricing.put(pli.ccrz__Product__r.ccrz__SKU__c, pli.ccrz__Price__c);
        }
        List<ccrz__E_PriceListItem__c> CAPriceListItems = [
                SELECT ccrz__Product__r.ccrz__SKU__c, ccrz__Price__c
                FROM ccrz__E_PriceListItem__c
                WHERE ccrz__Pricelist__r.Name = :AUTOSHIP_CANADA_PRICELIST
                AND ccrz__Product__c IN (
                        SELECT SBUX_B2B_ItemSKU__c
                        FROM SBUX_B2B_AutoShipLine__c
                        WHERE SBUX_B2B_AutoshipHeader__c = :autoShipHeaderId
                )
        ];
        for (ccrz__E_PriceListItem__c pli : CAPriceListItems) {
            CAAutoShipPricing.put(pli.ccrz__Product__r.ccrz__SKU__c, pli.ccrz__Price__c);
        }
    }

    /**
     * @description Gets the orderable UOM => Primary UOM Qty conversion factor.
     */
    public static void getOrderableUOMToPrimaryUOM(Map<String, Object> orderableUOMToPrimaryUOM, List<SBUX_B2B_AutoShipLine__c> autoShipLines) {
        for (SBUX_B2B_AutoShipLine__c currAutoShipLine : autoShipLines) {
            try {
                if (currAutoShipLine.SBUX_B2B_ItemSKU__r.SBUX_B2B_UOMConv__c == null || currAutoShipLine.SBUX_B2B_ItemSKU__r.SBUX_B2B_PrimaryUOM__c == null) {
                    continue;
                }
                List<Object> UOMConversionMapList = (List<Object>) JSON.deserializeUntyped(currAutoShipLine.SBUX_B2B_ItemSKU__r.SBUX_B2B_UOMConv__c);
                for (Object convMap : UOMConversionMapList) {
                    Map<String, Object> currConversionMap = (Map<String, Object>) convMap;
                    if (currConversionMap.containsKey(UOM_CONVERSION_TO_CODE)
                            && currConversionMap.containsKey(UOM_CONVERSION_FROM_CODE)
                            && currConversionMap.containsKey(UOM_CONVERSION_CONVERSION_FACTOR)
                            && ((String) currConversionMap.get(UOM_CONVERSION_FROM_CODE)).equalsIgnoreCase(currAutoShipLine.SBUX_B2B_ItemSKU__r.SBUX_B2B_PrimaryUOM__c)
                            && ((String) currConversionMap.get(UOM_CONVERSION_TO_CODE)).equalsIgnoreCase(currAutoShipLine.SBUX_B2B_ItemSKU__r.ccrz__UnitOfMeasure__c)) {
                        Integer conversionFactor = (Integer) currConversionMap.get(UOM_CONVERSION_CONVERSION_FACTOR);
                        if (conversionFactor != null) {
                            orderableUOMToPrimaryUOM.put(currAutoShipLine.SBUX_B2B_ItemSKU__c, conversionFactor);
                        }
                    }
                }
            } catch (Exception e) {
                // Skip this product if there was a problem. Conversion factor is defaulted to 1.
            }
        }
    }

    /**
    * @description Returns additional filtering on LS Category, Assortment Size that can be applied on Store attributes to limit the number of stores to be processed.
    *
    * @param autoShipHeaderSFID
    *
    * @return
    */
    public static List<String> prepareCategoryAndAssortmentSizeFilter(String autoShipHeaderSFID) {
        List<String> filters = new List<String>();
        List<AggregateResult> uniqueLSCategoriesAssortmentSizes = [
                SELECT SBUX_B2B_LSCategory__c,SBUX_B2B_AssortmentSize__c
                FROM SBUX_B2B_AutoShipLine__c
                WHERE SBUX_B2B_AssortmentSize__c != NULL
                AND SBUX_B2B_AutoshipHeader__c = :autoShipHeaderSFID
                GROUP BY SBUX_B2B_LSCategory__c, SBUX_B2B_AssortmentSize__c
        ];

        Boolean hasAll = false;
        Set<String> uniqueLSCategories = new Set<String>();
        Map<String, Object> assortmentFilterMap = new Map<String, Object>();

        for (AggregateResult ar : uniqueLSCategoriesAssortmentSizes) {
            String currLSCategory = (String) ar.get('SBUX_B2B_LSCategory__c');
            String currAssortmentSize = (String) ar.get('SBUX_B2B_AssortmentSize__c');

            // We cannot have an assortment filter if we have a 'US All' or 'CA All'
            if (currAssortmentSize.equals(ASSORTMENT_SIZE_US_ALL) || currAssortmentSize.equals(ASSORTMENT_SIZE_CANADA_ALL)) {
                hasAll = true;
            }
            uniqueLSCategories.add(currLSCategory);
            List<String> assortmentSizesForCurrentLSCategory = (List<String>) assortmentFilterMap.get(currLSCategory);
            if (assortmentSizesForCurrentLSCategory == null) {
                assortmentSizesForCurrentLSCategory = new List<String>();
                assortmentFilterMap.put(currLSCategory, assortmentSizesForCurrentLSCategory);
            }
            assortmentSizesForCurrentLSCategory.add(currAssortmentSize);
        }

        if (uniqueLSCategories.size() > 0) {
            for (String lsCategory : uniqueLSCategories) {
                List<String> assortmentSizesForCategory = (List<String>) assortmentFilterMap.get(lsCategory);
                if (lsCategory.equals(BEVERAGE_AUTOSHIP)) {
                    if (hasAll) {
                        filters.add(' (Beverage_Autoship_Qty__c > 0 AND Beverage_Autoship__c != \'No Autoship PO Required\') ');
                    } else {
                        filters.add(' (Beverage_Autoship_Qty__c > 0 AND Beverage_Autoship__c IN (\'' + String.join(assortmentSizesForCategory, '\',\'') + '\'))');
                    }
                }
                if (lsCategory.equals(COFFEE_FOR_BREWING_5_LB_BULLET)) {
                    if (hasAll) {
                        filters.add(' (Coffee_For_Brewing_Qty__c > 0 AND Coffee_For_Brewing__c != \'No Autoship PO Required\') ');
                    } else {
                        filters.add(' (Coffee_For_Brewing_Qty__c > 0 AND Coffee_For_Brewing__c IN (\'' + String.join(assortmentSizesForCategory, '\',\'') + '\'))');
                    }
                }
                if (lsCategory.equals(RETAIL_WHOLE_BEAN_COFFEE)) {
                    if (hasAll) {
                        filters.add(' (Retail_Whole_Bean_Coffee_Qty__c > 0 AND Retail_Whole_Bean_Coffee__c != \'No Autoship PO Required\') ');
                    } else {
                        filters.add(' (Retail_Whole_Bean_Coffee_Qty__c > 0 AND Retail_Whole_Bean_Coffee__c IN (\'' + String.join(assortmentSizesForCategory, '\',\'') + '\'))');
                    }
                }
                if (lsCategory.equals(GIFT_CARD_PARTICIPATION)) {
                    if (hasAll) {
                        filters.add(' (Gift_Card_Participation_Qty__c > 0 AND Gift_Card_Participation__c != \'No Autoship PO Required\') ');
                    } else {
                        filters.add(' (Gift_Card_Participation_Qty__c > 0 AND Gift_Card_Participation__c IN (\'' + String.join(assortmentSizesForCategory, '\',\'') + '\'))');
                    }
                }
                if (lsCategory.equals(MERCHANDISE)) {
                    if (hasAll) {
                        filters.add(' (Merchandise_Qty__c > 0 AND Merchandise__c != \'No Autoship PO Required\') ');
                    } else {
                        filters.add(' (Merchandise_Qty__c > 0 AND Merchandise__c IN (\'' + String.join(assortmentSizesForCategory, '\',\'') + '\'))');
                    }
                }
                if (lsCategory.equals(LOCAL_PRODUCT)) {
                    if (hasAll) {
                        filters.add(' (Local_Product_Qty__c > 0 AND Local_Product_Size__c != \'No Autoship PO Required\') ');
                    } else {
                        filters.add(' (Local_Product_Qty__c > 0 AND Local_Product_Size__c IN (\'' + String.join(assortmentSizesForCategory, '\',\'') + '\'))');
                    }
                }
                if (lsCategory.equals(SUPPLIES_SMALLWARES)) {
                    filters.add(' (Smallware_Supply_Qty__c > 0) ');
                }
            }
        }
        return filters;
    }

    /**
    * @description Returns a Set of unique stores (From Store attribute type) for a given autoship header
    *
    * @param autoShipHeaderSFID
    * @return
    */
    public static Set<String> getStoreListForStoreAttributeLines(String autoShipHeaderSFID) {
        Set<String> storeNumbersToBeIncluded = new Set<String>();
        List<AggregateResult> storeNumbersThatNeedToBeIncluded = [
                SELECT SBUX_B2B_StoreAttributeValue__c
                FROM SBUX_B2B_AutoShipLine__c
                WHERE SBUX_B2B_StoreAttributeValue__c != NULL
                AND SBUX_B2B_AutoshipHeader__c = :autoShipHeaderSFID
                GROUP BY SBUX_B2B_StoreAttributeValue__c
        ];

        // We have store specific lines, so these stores need to be included at all costs.
        if (storeNumbersThatNeedToBeIncluded.size() > 0) {
            for (AggregateResult ar : storeNumbersThatNeedToBeIncluded) {
                String currStoreNumber = (String) ar.get('SBUX_B2B_StoreAttributeValue__c');
                storeNumbersToBeIncluded.add('\'' + currStoreNumber + '\'');
            }
        }
        return storeNumbersToBeIncluded;
    }

    /**
    * @description Returns additional filtering on LS Category, Assortment Size and Store numbers that can be applied on Store attributes to limit the number of stores to be processed.
    *
    * @param autoShipHeaderSFID
    * @param storeNumbersToBeIncluded
    * @return
    */
    public static String prepareCategoryAssortmentSizeAndStoreNumberFilter(String autoShipHeaderSFID, Set<String> storeNumbersToBeIncluded) {
        String result = '';

        List<String> categoryAndAssortmentSizeFilters = prepareCategoryAndAssortmentSizeFilter(autoShipHeaderSFID);

        if (categoryAndAssortmentSizeFilters.size() > 0 && storeNumbersToBeIncluded.size() > 0) {
            // We have to join both category and stores
            result = ' AND ((' + String.join(categoryAndAssortmentSizeFilters, ' OR ') + ') OR (Store__r.Store_Number__c IN (' + String.join(new List<String>(storeNumbersToBeIncluded), ',') + ')))';
        } else if (categoryAndAssortmentSizeFilters.size() > 0) {
            result = ' AND (' + String.join(categoryAndAssortmentSizeFilters, ' OR ') + ')';
        } else if (storeNumbersToBeIncluded.size() > 0) {
            result = ' AND Store__r.Store_Number__c IN (' + String.join(new List<String>(storeNumbersToBeIncluded), ',') + ')';
        }
        return result;
    }

    /**
    * @description Creates a map representing dcNumber => dcName for easy population on forecast line items.
    *
    * @return Map<String,Object> representing dcNumber => dcName
    */
    public static Map<String, Object> getDCMappings() {
        Map<String, Object> result = new Map<String, Object> ();

        List<SBUX_B2B_StoreDCMapping__mdt> dcMetadata = [
                SELECT
                        DeveloperName,
                        Id,
                        Label,
                        MasterLabel,
                        SBUX_B2B_dcName__c,
                        SBUX_B2B_dcNumber__c,
                        SBUX_B2B_dcType__c
                FROM SBUX_B2B_StoreDCMapping__mdt
        ];

        for (SBUX_B2B_StoreDCMapping__mdt DCOption : dcMetadata) {
            result.put(DCOption.SBUX_B2B_dcNumber__c, DCOption.SBUX_B2B_dcName__c);
        }
        return result;
    }

    /**
    * @description Gets the BillTo and ShipTo Addresses for the current stores in batch.
    *
    * @param licenseeAccounts
    * @param autoShipLines
    * @param productExceptionsByLicenseeAccount
    *
    */
    public static void getProductExceptionsForStoresInBatch(
            Set<String> licenseeAccounts
            , List<SBUX_B2B_AutoShipLine__c> autoShipLines
            , Map<String, Object> productExceptionsByLicenseeAccount) {
        List<SBUX_B2B_ProductExceptionRule__c> productExceptionsForStoresInBatch = [
                SELECT SBUX_B2B_Product__c, SBUX_B2B_CogsSupplyException__c, SBUX_B2B_Account__c
                FROM SBUX_B2B_ProductExceptionRule__c
                WHERE SBUX_B2B_Account__c IN :licenseeAccounts
                AND SBUX_B2B_Product__c IN (
                        SELECT SBUX_B2B_ItemSKU__c
                        FROM SBUX_B2B_AutoShipLine__c
                        WHERE Id IN :autoShipLines
                )
        ];
        for (SBUX_B2B_ProductExceptionRule__c exceptionRule : productExceptionsForStoresInBatch) {
            Map<String, Object> productExceptionsForCurrLicensee = (Map<String, Object>) productExceptionsByLicenseeAccount.get(exceptionRule.SBUX_B2B_Account__c);
            if (productExceptionsForCurrLicensee == null) {
                productExceptionsForCurrLicensee = new Map<String, Object> ();
                productExceptionsByLicenseeAccount.put(exceptionRule.SBUX_B2B_Account__c, productExceptionsForCurrLicensee);
            }
            productExceptionsForCurrLicensee.put(exceptionRule.SBUX_B2B_Product__c, exceptionRule.SBUX_B2B_CogsSupplyException__c);
        }
    }

    /**
    * @description Gets the BillTo and ShipTo Addresses for the current stores in batch.
    *
    * @param storeSFIDList
    * @param billToAddressMap
    * @param shipToAddressMap
    *
    */
    public static void getBillToShipToAddressesForStoresInBatch(
            List<String> storeSFIDList
            , Map<String, Object> billToAddressMap
            , Map<String, Object> shipToAddressMap) {
        List<Address__c> shipToAddressesForStoresInBatch = [
                SELECT Id,Billto_Site_Number__c,Account_Name__c,Account_Number__c,Address_1__c,Address_2__c,Address_3__c,Address_Type__c,City__c,Country__c,County__c,Name,Postal_Code__c,Site_Id__c,Site_Number__c,State__c,State_Province__c,Store__c,Store_Id__c,Store_Number__c,Sub__c,Telephone_Number__c,Unit_Number__c,Warehouse_Code__c,Zone__c
                FROM Address__c
                WHERE Store__c IN :storeSFIDList
                AND Address_Type__c = 'ShipTo'
                AND Status__c = 'Y'
                AND Primary__c = 'Y'

        ];
        List<String> siteIDForStoresInBatchList = new List<String>();
        for (Address__c addr : shipToAddressesForStoresInBatch) {
            // Check if we have already seen an address for this store. If we have, this store needs to be ignored since we have multiple active ShipTo records.
            if (!shipToAddressMap.containsKey((String) addr.Store__c)){
                shipToAddressMap.put((String) addr.Store__c, addr);
                if (addr.Billto_Site_Number__c != null) {
                    siteIDForStoresInBatchList.add(addr.Billto_Site_Number__c);
                }
            } else {
                shipToAddressMap.remove((String) addr.Store__c);
            }
        }

        if (siteIDForStoresInBatchList.size() > 0) {
            List<Address__c> bilToAddressesForStoresInBatch = [
                    SELECT Id,Account_Name__c,Account_Number__c,Address_1__c,Address_2__c,Address_3__c,Address_Type__c,City__c,Country__c,County__c,Name,Postal_Code__c,Site_Id__c,Site_Number__c,State__c,State_Province__c,Store__c,Store_Id__c,Store_Number__c,Sub__c,Telephone_Number__c,Unit_Number__c,Warehouse_Code__c,Zone__c
                    FROM Address__c
                    WHERE Store__c IN :storeSFIDList
                    AND Address_Type__c = 'BillTo'
                    AND Status__c = 'Y'
                    AND Site_Id__c IN :siteIDForStoresInBatchList
            ];
            for (Address__c addr : bilToAddressesForStoresInBatch) {
                billToAddressMap.put((String) addr.Store__c, addr);
            }
        }
    }

    /**
    * @description Build a billTo record for the current store.
    *
    * @return A ccrz__E_ContactAddr__c representing the BillTo for the current store.
    */
    public static ccrz__E_ContactAddr__c prepareContactAddress(Address__c addressToUse) {
        ccrz__E_ContactAddr__c result;
        if (addressToUse != null) {
            result = new ccrz__E_ContactAddr__c();
            result.ccrz__AddressFirstline__c = addressToUse.Address_1__c;
            result.ccrz__AddressSecondline__c = addressToUse.Address_2__c;
            result.ccrz__AddressThirdline__c = addressToUse.Address_3__c;
            result.ccrz__City__c = addressToUse.City__c;
            result.ccrz__State__c = addressToUse.State_Province__c;
            result.ccrz__StateISOCode__c = addressToUse.State_Province__c;
            result.ccrz__Country__c = addressToUse.Country__c;
            result.ccrz__PostalCode__c = addressToUse.Postal_Code__c;
            result.SBUX_B2B_AccountNumber__c = addressToUse.Account_Number__c;
            result.SBUX_B2B_SiteId__c = addressToUse.Site_Id__c;
        }
        return result;
    }

    /**
    * @description gets the DistributionCode by Store# + CDC/RDC (Ex: '12355-RDC' : 'F24')
    *       *Only processes against the Stores in the current Batch*
    *
    * @param storeNumbers
    * @param distributionCodeMap
    */
    public static void getDistributionCodeMap(
            Set<String> storeNumbers,
            Map<String, Object> distributionCodeMap){
        List<SBUX_B2B_StoreSourcing__c> storeSourcingList = [
                SELECT Id,SBUX_B2B_StoreNumber__c,SBUX_B2B_DistributionCenter__c,SBUX_B2B_DPNumber__c
                FROM SBUX_B2B_StoreSourcing__c
                WHERE SBUX_B2B_StoreNumber__c IN :storeNumbers
        ];

        for(SBUX_B2B_StoreSourcing__c storeSource : storeSourcingList){
            if(storeSource.SBUX_B2B_DPNumber__c <> null && storeSource.SBUX_B2B_StoreNumber__c <> null)
            {
                String DCKey = storeSource.SBUX_B2B_DPNumber__c.left(3);
                String storeKey = storeSource.SBUX_B2B_StoreNumber__c+'-'+DCKey;
                if(!distributionCodeMap.containsKey(storeKey)){
                    distributionCodeMap.put(storeKey,storeSource.SBUX_B2B_DistributionCenter__c);
                }
            }
        }
    }

    /**
    * @description adds DC mapping to order as part of finalization
    *
    * @param orderHeaderForCurrentCombination
    * @param storeNumber
    * @param currItemSourcingValue
    * @param distributionCodeMap
    */
    public static void addDistributionCodeOnOrder(
            ccrz__E_Order__c orderHeaderForCurrentCombination,
            String storeNumber,
            String currItemSourcingValue,
            Map<String, Object> distributionCodeMap){

        if(currItemSourcingValue != null && storeNumber != null && distributionCodeMap != null){
            String storeKey = storeNumber + '-' + currItemSourcingValue;
            if(distributionCodeMap.containsKey(storeKey)){
                orderHeaderForCurrentCombination.SBUX_B2B_Distribution_Center_Code__c = (String)distributionCodeMap.get(storeKey);
            }
        }

    }

    /**
    * @description Method to do all the Quantity calculations for all Autoship lines for this store.
    *
    * @param currStoreAttribute
    * @param autoShipLines
    *
    * @return Returns a Map of AutoShipLineSFID => MultiplicatonFactor to generate order Items
    */
    public static Map<String, Object> calculateLineMultiplicationFactorForStore(Store_Attribute__c currStoreAttribute, List<SBUX_B2B_AutoShipLine__c> autoShipLines) {
        Map<String, Object> result = new Map<String, Object> ();

        for (SBUX_B2B_AutoShipLine__c currLine : autoShipLines) {
            if (currLine.RecordType.DeveloperName.equals(AUTOSHIP_LINE_RECORD_TYPE_STORE_ATTRIBUTE) && currLine.SBUX_B2B_StoreAttributeValue__c != null) {
                // This is a store specific, so multiplication factor will be 1
                if (currStoreAttribute.Store__r.Store_Number__c.equals(currLine.SBUX_B2B_StoreAttributeValue__c)) {
                    result.put(currLine.Id, 1);
                }
            } else if (currLine.SBUX_B2B_LSCategory__c.equals(SUPPLIES_SMALLWARES) && currStoreAttribute.Smallware_Supply_Qty__c != null && currStoreAttribute.Smallware_Supply_Qty__c > 0) {
                result.put(currLine.Id, currStoreAttribute.Smallware_Supply_Qty__c);
            } else if ((currLine.SBUX_B2B_AssortmentSize__c.equals(ASSORTMENT_SIZE_US_ALL) && currStoreAttribute.Store__r.Country__c.equals(STORE_COUNTRY_US)) || (currLine.SBUX_B2B_AssortmentSize__c.equals(ASSORTMENT_SIZE_CANADA_ALL) && currStoreAttribute.Store__r.Country__c.equals(STORE_COUNTRY_CA))) {
                if (currLine.SBUX_B2B_LSCategory__c.equals(BEVERAGE_AUTOSHIP) && currStoreAttribute.Beverage_Autoship__c != null && !currStoreAttribute.Beverage_Autoship__c.contains(NO_AUTOSHIP) && currStoreAttribute.Beverage_Autoship_Qty__c != null && currStoreAttribute.Beverage_Autoship_Qty__c > 0) {
                    result.put(currLine.Id, currStoreAttribute.Beverage_Autoship_Qty__c);
                }
                if (currLine.SBUX_B2B_LSCategory__c.equals(COFFEE_FOR_BREWING_5_LB_BULLET) && currStoreAttribute.Coffee_For_Brewing__c != null && !currStoreAttribute.Coffee_For_Brewing__c.contains(NO_AUTOSHIP) && currStoreAttribute.Coffee_For_Brewing_Qty__c != null && currStoreAttribute.Coffee_For_Brewing_Qty__c > 0) {
                    result.put(currLine.Id, currStoreAttribute.Coffee_For_Brewing_Qty__c);
                }
                if (currLine.SBUX_B2B_LSCategory__c.equals(RETAIL_WHOLE_BEAN_COFFEE) && currStoreAttribute.Retail_Whole_Bean_Coffee__c != null && !currStoreAttribute.Retail_Whole_Bean_Coffee__c.contains(NO_AUTOSHIP) && currStoreAttribute.Retail_Whole_Bean_Coffee_Qty__c != null && currStoreAttribute.Retail_Whole_Bean_Coffee_Qty__c > 0) {
                    result.put(currLine.Id, currStoreAttribute.Retail_Whole_Bean_Coffee_Qty__c);
                }
                if (currLine.SBUX_B2B_LSCategory__c.equals(GIFT_CARD_PARTICIPATION) && currStoreAttribute.Gift_Card_Participation__c != null && !currStoreAttribute.Gift_Card_Participation__c.contains(NO_AUTOSHIP) && currStoreAttribute.Gift_Card_Participation_Qty__c != null && currStoreAttribute.Gift_Card_Participation_Qty__c > 0) {
                    result.put(currLine.Id, currStoreAttribute.Gift_Card_Participation_Qty__c);
                }
                if (currLine.SBUX_B2B_LSCategory__c.equals(MERCHANDISE) && currStoreAttribute.Merchandise__c != null && !currStoreAttribute.Merchandise__c.contains(NO_AUTOSHIP) && currStoreAttribute.Merchandise_Qty__c != null && currStoreAttribute.Merchandise_Qty__c > 0) {
                    result.put(currLine.Id, currStoreAttribute.Merchandise_Qty__c);
                }
                if (currLine.SBUX_B2B_LSCategory__c.equals(LOCAL_PRODUCT) && currStoreAttribute.Local_Product_Size__c != null && !currStoreAttribute.Local_Product_Size__c.contains(NO_AUTOSHIP) && currStoreAttribute.Local_Product_Qty__c != null && currStoreAttribute.Local_Product_Qty__c > 0) {
                    result.put(currLine.Id, currStoreAttribute.Local_Product_Qty__c);
                }

            } else {
                // This is a regular assortment size
                if (currLine.SBUX_B2B_LSCategory__c.equals(BEVERAGE_AUTOSHIP) && currStoreAttribute.Beverage_Autoship__c != null && currStoreAttribute.Beverage_Autoship__c.equals(currLine.SBUX_B2B_AssortmentSize__c) && currStoreAttribute.Beverage_Autoship_Qty__c != null) {
                    result.put(currLine.Id, currStoreAttribute.Beverage_Autoship_Qty__c);
                }
                if (currLine.SBUX_B2B_LSCategory__c.equals(COFFEE_FOR_BREWING_5_LB_BULLET) && currStoreAttribute.Coffee_For_Brewing__c != null && currStoreAttribute.Coffee_For_Brewing__c.equals(currLine.SBUX_B2B_AssortmentSize__c) && currStoreAttribute.Coffee_For_Brewing_Qty__c != null) {
                    result.put(currLine.Id, currStoreAttribute.Coffee_For_Brewing_Qty__c);
                }
                if (currLine.SBUX_B2B_LSCategory__c.equals(RETAIL_WHOLE_BEAN_COFFEE) && currStoreAttribute.Retail_Whole_Bean_Coffee__c != null && currStoreAttribute.Retail_Whole_Bean_Coffee__c.equals(currLine.SBUX_B2B_AssortmentSize__c) && currStoreAttribute.Retail_Whole_Bean_Coffee_Qty__c != null) {
                    result.put(currLine.Id, currStoreAttribute.Retail_Whole_Bean_Coffee_Qty__c);
                }
                if (currLine.SBUX_B2B_LSCategory__c.equals(GIFT_CARD_PARTICIPATION) && currStoreAttribute.Gift_Card_Participation__c != null && currStoreAttribute.Gift_Card_Participation__c.equals(currLine.SBUX_B2B_AssortmentSize__c) && currStoreAttribute.Gift_Card_Participation_Qty__c != null) {
                    result.put(currLine.Id, currStoreAttribute.Gift_Card_Participation_Qty__c);
                }
                if (currLine.SBUX_B2B_LSCategory__c.equals(MERCHANDISE) && currStoreAttribute.Merchandise__c != null && currStoreAttribute.Merchandise__c.equals(currLine.SBUX_B2B_AssortmentSize__c) && currStoreAttribute.Merchandise_Qty__c != null) {
                    result.put(currLine.Id, currStoreAttribute.Merchandise_Qty__c);
                }
                if (currLine.SBUX_B2B_LSCategory__c.equals(LOCAL_PRODUCT) && currStoreAttribute.Local_Product_Size__c != null && currStoreAttribute.Local_Product_Size__c.equals(currLine.SBUX_B2B_AssortmentSize__c) && currStoreAttribute.Local_Product_Qty__c != null) {
                    result.put(currLine.Id, currStoreAttribute.Local_Product_Qty__c);
                }
            }
        }
        return result;
    }

    /**
    * @description Adds the BillTo and ShipTo Address on the current order.
    *
    * @param currOrder
    * @param billToAddressMap
    * @param shipToAddressMap
    *
    */
    public static void addBillToShipToAddressesOnOrder(ccrz__E_Order__c currOrder, Map<String, Object> billToAddressMap, Map<String, Object> shipToAddressMap) {
        List<ccrz__E_ContactAddr__c> contactAddrsToInsert = new List<ccrz__E_ContactAddr__c>();
        ccrz__E_ContactAddr__c billToForCurrentStore = SBUX_B2B_AutoShipUtil.prepareContactAddress((Address__c) billToAddressMap.get(currOrder.SBUX_B2B_Store__c));
        if (billToForCurrentStore != null) {
            contactAddrsToInsert.add(billToForCurrentStore);
        }

        ccrz__E_ContactAddr__c shipToForCurrentStore = SBUX_B2B_AutoShipUtil.prepareContactAddress((Address__c) shipToAddressMap.get(currOrder.SBUX_B2B_Store__c));
        if (shipToForCurrentStore != null) {
            contactAddrsToInsert.add(shipToForCurrentStore);
        }

        insert contactAddrsToInsert;

        if (billToForCurrentStore != null) {
            currOrder.ccrz__BillTo__c = billToForCurrentStore.Id;
        }
        if (shipToForCurrentStore != null) {
            currOrder.ccrz__ShipTo__c = shipToForCurrentStore.Id;
        } else {
            // If the shipTo does not exist, this order should not proceed.
            if (!Test.isRunningTest()){
                currOrder.ccrz__OrderStatus__c = ORDER_STATUS_ERROR;
                currOrder.SBUX_B2B_OrderPublishFlag__c = false;
                currOrder.SBUX_B2B_Order_Source__c = null;
                currOrder.SBUX_B2B_Autoship_Error__c = MISSING_SHIP_TO_ERROR;
            }
        }
    }

    /**
    * @description Method to build a ccrz__E_Order__c object corresponding to this store for the given autoship header.
    *
    * @param currAutoShipHeader
    * @param currStoreAttribute
    * @param billToSFID
    * @param shipToSFID
    * @param finalizeOrder
    *
    * @return Returns an ccrz__E_Order__c object in Draft/Preview Status.
    */
    public static ccrz__E_Order__c buildOrderHeaderForStore(SBUX_B2B_AutoShipHeader__c currAutoShipHeader, Store_Attribute__c currStoreAttribute) {
        ccrz__E_Order__c currOrder = new ccrz__E_Order__c();

        // Regular CCRZ fields
        currOrder.ccrz__Storefront__c = AUTOSHIP_STOREFRONT;
        currOrder.ccrz__OrderStatus__c = ORDER_STATUS_DRAFT;
        currOrder.ccrz__Account__c = currStoreAttribute.Store__r.Store_Account__c;
        currOrder.ccrz__ShipStructure__c = SHIP_STRUCTURE_LLI;

        // SBUX fields
        currOrder.SBUX_B2B_StoreProgramType__c = currStoreAttribute.Autoship_Program_Type__c;
        currOrder.SBUX_B2B_Store__c = currStoreAttribute.Store__c;
        currOrder.SBUX_B2B_AutoShipHeader__c = currAutoShipHeader.Id;
        currOrder.SBUX_B2B_FreightTerms__c = currAutoShipHeader.SBUX_B2B_FreightTerms__c;
        currOrder.SBUX_B2B_ShipPriority__c = currAutoShipHeader.SBUX_B2B_ShipPriority__c;
        currOrder.SBUX_B2B_ShipDate__c = currAutoShipHeader.SBUX_B2B_FirstShipDate__c;

        // Order Types
        if (currStoreAttribute.Store__r.Country__c == STORE_COUNTRY_US) {
            currOrder.SBUX_B2B_OrderType__c = currAutoShipHeader.SBUX_B2B_OrderType__c + ORDER_TYPE_US;
            currOrder.ccrz__CurrencyISOCode__c = ORDER_CURRENCY_USD;
        } else if (currStoreAttribute.Store__r.Country__c == STORE_COUNTRY_CA) {
            currOrder.SBUX_B2B_OrderType__c = currAutoShipHeader.SBUX_B2B_OrderType__c + ORDER_TYPE_CA;
            currOrder.ccrz__CurrencyISOCode__c = ORDER_CURRENCY_CAD;
        }
        return currOrder;
    }

    /**
    * @description Method to build a ccrz__E_OrderItem__c records for the current order.
    *
    * @param currStoreAttribute
    * @param currOrder
    * @param autoShipLines
    * @param lineDetailsForStore
    * @param USAutoShipPricing
    * @param CAAutoShipPricing
    * @return Returns a list of ccrz__E_OrderItem__c records for the corresponding order and
    */
    public static List<ccrz__E_OrderItem__c> buildOrderLinesForStore(
            Store_Attribute__c currStoreAttribute
            , ccrz__E_Order__c currOrder
            , Map<Id, SBUX_B2B_AutoShipLine__c> autoShipLines
            , Map<String, Object> orderableUOMToPrimaryUOMQty
            , Map<String, Object> lineDetailsForStore
            , Map<String, Object> USAutoShipPricing
            , Map<String, Object> CAAutoShipPricing) {
        List<ccrz__E_OrderItem__c> orderItems = new List<ccrz__E_OrderItem__c>();

        for (String currAutoShiplineSFID : lineDetailsForStore.keySet()) {
            SBUX_B2B_AutoShipLine__c currAutoShipLine = autoShipLines.get(currAutoShiplineSFID);
            // If the assortment size is US All or CN All, check store country.
            if (currAutoShipLine.SBUX_B2B_AssortmentSize__c != null && ((currAutoShipLine.SBUX_B2B_AssortmentSize__c.equals(ASSORTMENT_SIZE_US_ALL) && currStoreAttribute.Store__r.Country__c != STORE_COUNTRY_US) || (currAutoShipLine.SBUX_B2B_AssortmentSize__c.equals(ASSORTMENT_SIZE_CANADA_ALL) && currStoreAttribute.Store__r.Country__c != STORE_COUNTRY_CA))) {
                continue;
            }
            Decimal multiplicationFactor = (Decimal) lineDetailsForStore.get(currAutoShipLine.Id);
            ccrz__E_OrderItem__c currOrderItem = new ccrz__E_OrderItem__c();

            // CCRZ fields
            currOrderItem.ccrz__OriginalQuantity__c = currAutoShipLine.SBUX_B2B_LineQty__c * multiplicationFactor;
            currOrderItem.ccrz__Quantity__c = currAutoShipLine.SBUX_B2B_LineQty__c * multiplicationFactor;
            currOrderItem.ccrz__Order__c = currOrder.Id;
            currOrderItem.ccrz__Price__c = 0;
            currOrderItem.ccrz__Product__c = currAutoShipLine.SBUX_B2B_ItemSKU__c;
            currOrderItem.ccrz__OrderLineType__c = ORDER_LINE_TYPE_MAJOR;
            currOrderItem.ccrz__UnitOfMeasure__c = currAutoShipLine.SBUX_B2B_ItemSKU__r.ccrz__UnitOfMeasure__c;
            currOrderItem.ccrz__ProductType__c = SIMPLE_PRODUCT;

            // SBUX Fields
            currOrderItem.SBUX_B2B_AutoShipLine__c = currAutoShipLine.Id;
            currOrderItem.SBUX_B2B_MultiplicationFactor__c = multiplicationFactor;

            // If we have pricing, apply that.
            if (USAutoShipPricing != null && CAAutoShipPricing != null) {
                if (currStoreAttribute.Store__r.Country__c.equals(STORE_COUNTRY_US)) {
                    currOrderItem.ccrz__Price__c = USAutoShipPricing.containsKey(currAutoShipLine.SBUX_B2B_ItemSKU__r.ccrz__SKU__c) ? (Decimal) USAutoShipPricing.get(currAutoShipLine.SBUX_B2B_ItemSKU__r.ccrz__SKU__c) : 0.0;
                }
                if (currStoreAttribute.Store__r.Country__c.equals(STORE_COUNTRY_CA)) {
                    currOrderItem.ccrz__Price__c = CAAutoShipPricing.containsKey(currAutoShipLine.SBUX_B2B_ItemSKU__r.ccrz__SKU__c) ? (Decimal) CAAutoShipPricing.get(currAutoShipLine.SBUX_B2B_ItemSKU__r.ccrz__SKU__c) : 0.0;
                }
            }
            currOrderItem.ccrz__OriginalItemPrice__c = currOrderItem.ccrz__Price__c;
            currOrderItem.ccrz__SubAmount__c = currOrderItem.ccrz__OriginalQuantity__c * currOrderItem.ccrz__Price__c;

            if (orderableUOMToPrimaryUOMQty != null && orderableUOMToPrimaryUOMQty.containsKey(currAutoShipLine.SBUX_B2B_ItemSKU__c)) {
                Integer conversionFactor = (Integer) orderableUOMToPrimaryUOMQty.get(currAutoShipLine.SBUX_B2B_ItemSKU__c);
                currOrderItem.SBUX_B2B_Primary_UOM_Quantity__c = conversionFactor * currOrderItem.ccrz__Quantity__c;
                currOrderItem.SBUX_Primary_UOM__c = currAutoShipLine.SBUX_B2B_ItemSKU__r.SBUX_B2B_PrimaryUOM__c;
            } else {
                currOrderItem.SBUX_B2B_Primary_UOM_Quantity__c = currOrderItem.ccrz__Quantity__c;
                currOrderItem.SBUX_Primary_UOM__c = currAutoShipLine.SBUX_B2B_ItemSKU__r.ccrz__UnitOfMeasure__c;
            }
            orderItems.add(currOrderItem);
        }
        return orderItems;
    }

    /**
    * @description Method to build a SBUX_B2B_AutoshipForecast__c records for the given order items.
    *
    * @param currStoreAttribute
    * @param dcMap
    * @param currHeader
    * @param autoShipLines
    * @param orderItems
    *
    *
    * @return Returns a list of SBUX_B2B_AutoshipForecast__c records for the corresponding orderItems
    */
    public static List<SBUX_B2B_AutoshipForecast__c> generateForecastLines(
            Store_Attribute__c currStoreAttribute
            , Map<String, Object> dcMap
            , List<ccrz__E_OrderItem__c> orderItems
            , Map<Id, SBUX_B2B_AutoShipLine__c> autoShipLines) {
        List<SBUX_B2B_AutoshipForecast__c> forecastLines = new List<SBUX_B2B_AutoshipForecast__c>();

        for (ccrz__E_OrderItem__c orderItem : orderItems) {
            SBUX_B2B_AutoShipLine__c currLine = autoShipLines.get(orderItem.SBUX_B2B_AutoShipLine__c);
            SBUX_B2B_AutoshipForecast__c forecastLine = new SBUX_B2B_AutoshipForecast__c(
                    SBUX_B2B_Autoship_Header__c = currLine.SBUX_B2B_AutoshipHeader__c,
                    SBUX_B2B_Autoship_Line__c = currLine.Id,
                    SBUX_B2B_CCOrderItem__c = orderItem.Id,
                    SBUX_B2B_ItemQty__c = orderItem.ccrz__Quantity__c,
                    SBUX_B2B_Sku__c = currLine.SBUX_B2B_ItemSKU__r.ccrz__SKU__c,
                    SBUX_B2B_SourceName__c = (String) dcMap.get(currStoreAttribute.Store__r.RDC__c),
                    SBUX_B2B_Store__c = currStoreAttribute.Store__r.Store_Number__c
            );

            forecastLines.add(forecastLine);
        }
        return forecastLines;
    }

    /**
    * @description Splits the order and order items into multiple orders based on COGS/Supply, CDC/RDC.
    *
    * @param currAutoShipHeader
    * @param currOrder
    * @param originalOrderItemsList
    * @param currStoreAttribute
    * @param autoShipLines
    *
    * @return The orderItems as a result of split. Deletes currOrder if the split was successful.
    */
    public static List<ccrz__E_OrderItem__c> splitOrder(
            Boolean finalizeOrders
            , SBUX_B2B_AutoShipHeader__c currAutoShipHeader
            , ccrz__E_Order__c currOrder
            , List<ccrz__E_OrderItem__c> originalOrderItemsList
            , Store_Attribute__c currStoreAttribute
            , Map<Id, SBUX_B2B_AutoShipLine__c> autoShipLines
            , Map<String, Object> billToAddressMap
            , Map<String, Object> shipToAddressMap
            , Map<String, Object> distributionCodeMap
            , Map<String, Object> productExceptions) {
        Map<String, Object> cogsSupplyMap = new Map<String, Object> ();
        Map<String, Object> itemSourcingMap = new Map<String, Object> ();


        // Sort Order Items into various categories that we split on.
        for (ccrz__E_OrderItem__c oi : originalOrderItemsList) {
            // Get the current autoship line to access the corresponding product. (Fetching product via autoship line should will bring back less records.)
            SBUX_B2B_AutoShipLine__c currLine = autoShipLines.get(oi.SBUX_B2B_AutoShipLine__c);

            // *** Item Source Splits****
            String currItemSourceValue = currLine.SBUX_B2B_ItemSKU__r.SBUX_B2B_ItemSource__c;

            // Get the list of order items for the currItemSourceValue. If we dont have one, create a new List.
            Set<ccrz__E_OrderItem__c> currItemSourceList = (Set<ccrz__E_OrderItem__c>) itemSourcingMap.get(currItemSourceValue);
            if (currItemSourceList == null) {
                currItemSourceList = new Set<ccrz__E_OrderItem__c> ();
                itemSourcingMap.put(currItemSourceValue, currItemSourceList);
            }
            currItemSourceList.add(oi);

            // *** COGS/Supply Splits****
            String currItemCogsSupplyValue = currLine.SBUX_B2B_ItemSKU__r.SBUX_B2B_CogsSupply__c;

            // Check if we have an override for this product
            if (productExceptions.containsKey(currLine.SBUX_B2B_ItemSKU__c)) {
                String overrideValue = (String) productExceptions.get(currLine.SBUX_B2B_ItemSKU__c);
                if (overrideValue != null && !String.isEmpty(overrideValue)) {
                    currItemCogsSupplyValue = overrideValue;
                }
            }

            // Get the list of order items for the currItemCogsSupplyValue. If we dont have one, create a new List.
            Set<ccrz__E_OrderItem__c> currItemCogsSupplyValueList = (Set<ccrz__E_OrderItem__c>) cogsSupplyMap.get(currItemCogsSupplyValue);
            if (currItemCogsSupplyValueList == null) {
                currItemCogsSupplyValueList = new Set<ccrz__E_OrderItem__c> ();
                cogsSupplyMap.put(currItemCogsSupplyValue, currItemCogsSupplyValueList);
            }
            currItemCogsSupplyValueList.add(oi);
        }

        // Now we should have all the possible split variations, we just need to merge the different combinations
        List<ccrz__E_OrderItem__c> splitOrdersItemToInsert = new List<ccrz__E_OrderItem__c>();

        for (String currCogsSupplyValue : cogsSupplyMap.keySet()) {
            for (String currItemSourcingValue : itemSourcingMap.keySet()) {
                // Gather all order items that match the current criteria
                Set<ccrz__E_OrderItem__c> orderItemsForCurrentCogsSupplyValue = (Set<ccrz__E_OrderItem__c>) cogsSupplyMap.get(currCogsSupplyValue);
                Set<ccrz__E_OrderItem__c> orderItemsForCurrentItemSourcingValue = (Set<ccrz__E_OrderItem__c>) itemSourcingMap.get(currItemSourcingValue);

                // Put all order items in a set to gather unique order items for this combination.
                Set<ccrz__E_OrderItem__c> orderItemsForThisPermutation = new Set<ccrz__E_OrderItem__c>(orderItemsForCurrentItemSourcingValue);
                orderItemsForThisPermutation.retainAll(orderItemsForCurrentCogsSupplyValue);

                // Create a order header if have atleast 1 item for this combination.
                ccrz__E_Order__c orderHeaderForCurrentCombination;
                ccrz__E_OrderItemGroup__c currOrderItemGroup;
                if (orderItemsForThisPermutation.size() > 0) {
                    orderHeaderForCurrentCombination = buildOrderHeaderForStore(currAutoShipHeader, currStoreAttribute);
                    if (finalizeOrders) {
                        orderHeaderForCurrentCombination.ccrz__OrderStatus__c = ORDER_STATUS_ORDER_SUBMITTED;
                        orderHeaderForCurrentCombination.SBUX_B2B_OrderPublishFlag__c = true;
                        orderHeaderForCurrentCombination.SBUX_B2B_Order_Source__c = ORDER_SOURCE_AUTOSHIP;
                        orderHeaderForCurrentCombination.ccrz__OrderDate__c = System.today();
                        SBUX_B2B_AutoShipUtil.addBillToShipToAddressesOnOrder(orderHeaderForCurrentCombination, billToAddressMap, shipToAddressMap);
                        SBUX_B2B_AutoShipUtil.addDistributionCodeOnOrder(orderHeaderForCurrentCombination, currStoreAttribute.Store__r.Store_Number__c, currItemSourcingValue, distributionCodeMap);

                        currOrderItemGroup = new ccrz__E_OrderItemGroup__c();
                        currOrderItemGroup.ccrz__GroupName__c = currCogsSupplyValue.toUpperCase() + NAME_DELIMITER + currItemSourcingValue.toUpperCase();
                    }
                    orderHeaderForCurrentCombination.SBUX_B2B_PONumber__c = currAutoShipHeader.SBUX_B2B_Description__c + HYPHEN_DELIMITER + currStoreAttribute.Store__r.Country__c + SPACE_DELIMITER + currCogsSupplyValue.replace('Supply', 'SUPP') + SPACE_DELIMITER + currItemSourcingValue;
                    insert orderHeaderForCurrentCombination;

                    if (currOrderItemGroup != null){
                        currOrderItemGroup.ccrz__Order__c = orderHeaderForCurrentCombination.Id;
                        insert currOrderItemGroup;
                    }
                }

                // Depending on whether the originalOrderItemsList are already inserted, we can either create new or reparent. This implementation assumed NOT Inserted.
                for (ccrz__E_OrderItem__c oi : orderItemsForThisPermutation) {
                    oi.ccrz__Order__c = orderHeaderForCurrentCombination.Id;

                    if (currOrderItemGroup != null){
                        oi.ccrz__OrderItemGroup__c = currOrderItemGroup.Id;
                    }
                    splitOrdersItemToInsert.add(oi);
                }
            }
        }

        // If everything went correctly, we should have the same number of order items in both lists.
        if (originalOrderItemsList.size() == splitOrdersItemToInsert.size()) {
            delete currOrder;
            return splitOrdersItemToInsert;
        } else {
            // Split failed, return original order items like this never happened.
            return originalOrderItemsList;
        }
    }
}