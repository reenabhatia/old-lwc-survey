public with sharing class SBUX_B2B_StorefrontUtil {
    private final static String RULE_INCLUDE = 'Include';
    private static final String ADDRESS_TYPE_SHIP_TO = 'ShipTo';

    public static Store__c fetchCurrentStore() {
        Store__c currentStore = null;

        if (ccrz.cc_CallContext.isGuest == false
                && ccrz.cc_CallContext.currUser != null
                && ccrz.cc_CallContext.currUser.AccountId != null) {
            String currAccountId = ccrz.cc_CallContext.currUser.AccountId;

            currentStore = [
                    SELECT
                            Id,
                            Store_Number__c
                    FROM Store__c
                    WHERE Store_Account__c = :currAccountId
                    LIMIT 1
            ];
        }
        return currentStore;
    }

    public static String getSiteIDForCustomer(String storeSFID){
        String siteId;
        if (ccrz.cc_CallContext.isGuest == false
                && ccrz.cc_CallContext.currUser != null
                && ccrz.cc_CallContext.currUser.AccountId != null
                && ccrz.cc_CallContext.currContact != null) {

            List<Address__c> shipToAddressForStore = [
                    SELECT Id,Site_Id__c
                    FROM Address__c
                    WHERE Store__c = :storeSFID
                    AND Address_Type__c = :ADDRESS_TYPE_SHIP_TO
                    AND Status__c = 'Y'
                    AND Primary__c = 'Y'
            ];

            if (shipToAddressForStore.isEmpty()){
                // If store does not have active shipTo, we cannot proceed. This is probably a data error/store not ready.
            } else if (shipToAddressForStore.size() == 1){
                siteId = shipToAddressForStore[0].Site_Id__c;
            } else {
                // We have multiple active shipTo records. This store is probably in a transfer to a new licensee.
                // Check if the contact has an address record indicating which one to use
                Contact currContact = [
                        SELECT Id, SBUX_B2B_Store_ShipTo_Address__c, SBUX_B2B_Store_ShipTo_Address__r.Site_Id__c
                        FROM Contact
                        WHERE Id = :ccrz.cc_CallContext.currContact.Id
                ];
                if (currContact != null && currContact.SBUX_B2B_Store_ShipTo_Address__c != null && currContact.SBUX_B2B_Store_ShipTo_Address__r.Site_Id__c != null){
                    siteId = currContact.SBUX_B2B_Store_ShipTo_Address__r.Site_Id__c;
                }
            }
        }
        if (Test.isRunningTest()){
            // TODO: Temporary workaround since addresses arent working in tests.
            siteId = '12345';
        }
        return siteId;
    }

    public static List<SBUX_B2B_StoreSourcing__c> fetchCurrentStoreSourcing() {
        List<SBUX_B2B_StoreSourcing__c> storeSourcing = null;

        Store__c store = fetchCurrentStore();
        //TODO - do we need to use the shipto site numbers and customer shipto to filter down this list ?

        if (store != null) {
            storeSourcing = [
                    SELECT
                            Id,
                            SBUX_B2B_StoreNumber__c,SBUX_B2B_CustomerShipToNumber__c,SBUX_B2B_ShipToSiteNumber__c,
                            SBUX_B2B_DistributionCenter__c,SBUX_B2B_DPNumber__c,SBUX_B2B_SourcingGroup__c
                    FROM SBUX_B2B_StoreSourcing__c
                    WHERE SBUX_B2B_StoreNumber__c = :store.Store_Number__c
            ];
        }
        return storeSourcing;
    }

    public static Map<String, Object> getSourcingDCMap() {
        Map<String, Object> sourcingMap = new Map<String, Object>();

        List<String> storeSourcingDC = new List<String>();

        List<SBUX_B2B_StoreSourcing__c> storeSourcingDCList = fetchCurrentStoreSourcing();

        if (storeSourcingDCList != null && !storeSourcingDCList.isEmpty()) {
            for (SBUX_B2B_StoreSourcing__c storeSourcing : storeSourcingDCList) {
                storeSourcingDC.add(storeSourcing.SBUX_B2B_DistributionCenter__c);
            }
        }
        if (!storeSourcingDC.isEmpty()) {
            sourcingMap.put('sourcingDC', storeSourcingDC);
            sourcingMap.put('storeNumber', storeSourcingDCList[0].SBUX_B2B_StoreNumber__c);
        }
        return sourcingMap;
    }

    public static List<SBUX_B2B_DeliverySchedule__c> fetchStoreDeliverySchedule() {
        List<SBUX_B2B_DeliverySchedule__c> deliveryScheduleList = new List<SBUX_B2B_DeliverySchedule__c>();

        Map<String, Object> sourcingDCMap = getSourcingDCMap();
        Store__c currStore = SBUX_B2B_StorefrontUtil.fetchCurrentStore();
        String siteId = getSiteIDForCustomer(currStore.Id);

        if (sourcingDCMap != null && !sourcingDCMap.isEmpty() && siteId != null) {
            List <String> storeSourcingDC = (List <String>) sourcingDCMap.get('sourcingDC');

            String storeNumber = (String) sourcingDCMap.get('storeNumber');

            deliveryScheduleList = [
                    SELECT
                            Id,
                            SBUX_B2B_CustomerNumber__c,SBUX_B2B_CustomerSiteNumber__c,SBUX_B2B_DeliveryDate__c,
                            SBUX_B2B_DistributionCenter__c,SBUX_B2B_DPNumber__c,SBUX_B2B_ItemGroup__c,
                            SBUX_B2B_OrderDate__c,SBUX_B2B_ShipDate__c,SBUX_B2B_StoreNumber__c,SBUX_B2B_ScheduleType__c
                    FROM SBUX_B2B_DeliverySchedule__c
                    WHERE
                    SBUX_B2B_DistributionCenter__c IN :storeSourcingDC
                    AND SBUX_B2B_StoreNumber__c = :storeNumber
                    AND SBUX_B2B_CustomerSiteNumber__c = :siteId
            ];
        }
        return deliveryScheduleList;
    }


    public static Map <String, ccrz__E_Product__c> createProductSKUMap(List<String> productSKUs) {
        Map <String, ccrz__E_Product__c> productSKUMap = new Map <String, ccrz__E_Product__c>();

        List<ccrz__E_Product__c> productList = [
                SELECT
                        ID,
                        ccrz__SKU__C,
                        SBUX_B2B_AutoShipLSCategory__c
                FROM
                        ccrz__E_Product__c
                WHERE
                        ccrz__SKU__C IN :(productSKUs)
        ];


        if (productList != null && !productList.isEmpty()) {
            for (ccrz__E_Product__c product : productList) {
                productSKUMap.put(product.ccrz__SKU__C, product);
            }
        }

        return productSKUMap;
    }


    public static List<SBUX_B2B_StoreEntitlementRule__c> fetchStoreRuleList(String storeId) {
        return [
                SELECT
                        ID,
                        SBUX_B2B_CatalogRule__c,
                        SBUX_B2B_CatalogRule__r.SBUX_B2B_RuleType__c,
                        SBUX_B2B_Store__c
                FROM SBUX_B2B_StoreEntitlementRule__c
                WHERE SBUX_B2B_Store__c = :storeId
                AND ((SBUX_B2B_CatalogRule__r.SBUX_B2B_StartDate__c <= TODAY OR SBUX_B2B_CatalogRule__r.SBUX_B2B_StartDate__c = NULL)
                AND (SBUX_B2B_CatalogRule__r.SBUX_B2B_EndDate__c >= TODAY OR SBUX_B2B_CatalogRule__r.SBUX_B2B_EndDate__c = NULL) )
                LIMIT 500
        ];
    }


    public static String createEligibleProdRulesQuery(List<String> storeRulesList, Set<String> prodIds,
            String currentKey, List<String> prodNames) {
        String PROD_RULE_QUERY = 'SELECT Id' +
                ',SBUX_B2B_CatalogRule__c' +
                ',SBUX_B2B_CatalogRule__r.SBUX_B2B_RuleType__c' +
                ',SBUX_B2B_ProductItem__r.ccrz__SKU__c' +
                ',SBUX_B2B_ProductItem__r.Name' +
                ',SBUX_B2B_ProductItem__c' +
                ',SBUX_B2B_EndDate__c' +
                ',SBUX_B2B_StartDate__c' +
                ' FROM SBUX_B2B_ProductEntitlementRule__c ' +
                ' WHERE ' +
                '((SBUX_B2B_StartDate__c <= TODAY  OR  SBUX_B2B_StartDate__c = NULL) AND (SBUX_B2B_EndDate__c >= TODAY  OR  SBUX_B2B_EndDate__c = NULL) )' +
                ' AND SBUX_B2B_CatalogRule__c IN :storeRulesList ' ;

        if (ccrz.ccAPIProduct.PRODUCTSKULIST.equals(currentKey)) {
            PROD_RULE_QUERY += ' AND SBUX_B2B_ProductItem__r.ccrz__SKU__c IN  :prodIds' ;
        } else if (ccrz.ccAPIProduct.PRODUCTIDLIST.equals(currentKey)) {
            PROD_RULE_QUERY += ' AND SBUX_B2B_ProductItem__c IN  :prodIds' ;
        } else if (prodNames != null && !prodNames.isEmpty()) {
            PROD_RULE_QUERY += ' AND SBUX_B2B_ProductItem__r.Name IN  :prodNames' ;
        }
        return PROD_RULE_QUERY;
    }


    public static Set<String> generateEligibleSKUList(List<String> storeRulesList, Set<String> prodIds,
            Set <String> elligibleProdList, String prodMapKey,
            List<String> prodNames) {
        String prodRulesQuery = createEligibleProdRulesQuery(storeRulesList, prodIDs, prodMapKey, prodNames);

        Set <String> includeProdList = new Set<String>();
        Set <String> excludeProdList = new Set<String>();

        for (SBUX_B2B_ProductEntitlementRule__c prodRule : Database.query(prodRulesQuery)) {
            if (prodRule.SBUX_B2B_CatalogRule__r.SBUX_B2B_RuleType__c == RULE_INCLUDE) {
                updateProdList(prodRule, includeProdList, prodMapKey);
            } else {
                updateProdList(prodRule, excludeProdList, prodMapKey);
            }
        }
        if (!includeProdList.isEmpty() && excludeProdList.isEmpty()) {
            elligibleProdList.addAll(includeProdList);
        }
        if (!includeProdList.isEmpty() && !excludeProdList.isEmpty()) {
            elligibleProdList.addAll(includeProdList);
            elligibleProdList.removeAll(excludeProdList);
        }

        return elligibleProdList;
    }


    private static void updateProdList(SBUX_B2B_ProductEntitlementRule__c prodRule, Set <String> prodList, String prodMapKey) {

        if (ccrz.ccAPIProduct.PRODUCTSKULIST.equals(prodMapKey)) {
            prodList.add(prodRule.SBUX_B2B_ProductItem__r.ccrz__SKU__c);
        } else if (ccrz.ccAPIProduct.PRODUCTIDLIST.equals(prodMapKey)) {
            prodList.add(prodRule.SBUX_B2B_ProductItem__c);
        } else {
            prodList.add(prodRule.SBUX_B2B_ProductItem__r.Name);
        }
    }


    public static List<String> eligibleRulesForCurrentStore() {
        List <String> elligibleRulesId = new List<String>();

        Store__c currStore = fetchCurrentStore();

        if (currStore != null) {
            for (SBUX_B2B_StoreEntitlementRule__c storeRule : fetchStoreRuleList(currStore.Id)) {
                elligibleRulesId.add(storeRule.SBUX_B2B_CatalogRule__c);
            }
        }
        return elligibleRulesId;
    }


}