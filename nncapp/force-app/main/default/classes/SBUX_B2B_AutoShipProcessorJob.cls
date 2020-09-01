/**
 * Created by dgajwani on 3/23/20.
 */

public with sharing class SBUX_B2B_AutoShipProcessorJob implements Database.Batchable<SObject> {

    public static final String FORECAST_JOB_COMPLETE_STATUS = 'Forecasted';
    public static final String PREVIEW_JOB_COMPLETE_STATUS = 'In Preview';
    public static final String PROGRAM_TYPE_STARBUCKS_SHIPS = 'Starbucks Ships';
    public static final String AUTOSHIP_HEADER_STATUS_ORDERS_CREATED = 'Orders Created';

    public final Boolean processSplits;
    public final Boolean finalizeOrders;
    public final String autoShipHeaderId;
    public final SBUX_B2B_AutoShipHeader__c currAutoShipHeader;
    public final Map<Id, SBUX_B2B_AutoShipLine__c> autoShipLines;
    public final Map<String, Object> dcMappings;
    public final Set<String> storeNumbersToBeIncluded;
    public Map<String, Object> USAutoShipPricing;
    public Map<String, Object> CAAutoShipPricing;
    public Map<String, Object> orderableUOMToPrimaryUOMQty;

    public SBUX_B2B_AutoShipProcessorJob(String autoShipHeaderId, Boolean processSplits, Boolean finalizeOrders) {
        this.autoShipHeaderId = autoShipHeaderId;
        this.processSplits = processSplits;
        this.finalizeOrders = finalizeOrders;
        this.currAutoShipHeader = [
                SELECT Id,
                        Name,
                        SBUX_B2B_AutoshipStatus__c,
                        SBUX_B2B_AutoshipType__c,
                        SBUX_B2B_Description__c,
                        SBUX_B2B_FirstShipDate__c,
                        SBUX_B2B_FreightTerms__c,
                        SBUX_B2B_LongLeadFirstShipDate__c,
                        SBUX_B2B_OrderType__c,
                        SBUX_B2B_PromoEnd__c,
                        SBUX_B2B_PromoLaunch__c,
                        SBUX_B2B_ShipPriority__c
                FROM SBUX_B2B_AutoShipHeader__c
                WHERE Id = :autoShipHeaderId
        ];
        this.autoShipLines = new Map<Id, SBUX_B2B_AutoShipLine__c>([
                SELECT Id,
                        Name,
                        RecordType.DeveloperName,
                        SBUX_B2B_AssortmentSize__c,
                        SBUX_B2B_AutoshipHeader__c,
                        SBUX_B2B_AutoshipHeader__r.SBUX_B2B_Description__c,
                        SBUX_B2B_ItemSKU__c,
                        SBUX_B2B_ItemSKU__r.ccrz__SKU__c,
                        SBUX_B2B_ItemSKU__r.ccrz__UnitOfMeasure__c,
                        SBUX_B2B_ItemSKU__r.SBUX_B2B_CogsSupply__c,
                        SBUX_B2B_ItemSKU__r.SBUX_B2B_ItemSource__c,
                        SBUX_B2B_ItemSKU__r.SBUX_B2B_PrimaryUOM__c,
                        SBUX_B2B_ItemSKU__r.SBUX_B2B_UOMConv__c,
                        SBUX_B2B_LineQty__c,
                        SBUX_B2B_LSCategory__c,
                        SBUX_B2B_StoreAttribute__c,
                        SBUX_B2B_StoreAttributeValue__c
                FROM SBUX_B2B_AutoShipLine__c
                WHERE SBUX_B2B_AutoshipHeader__c = :autoShipHeaderId
        ]);
        this.dcMappings = SBUX_B2B_AutoShipUtil.getDCMappings();
        this.storeNumbersToBeIncluded = SBUX_B2B_AutoShipUtil.getStoreListForStoreAttributeLines(autoShipHeaderId);
        orderableUOMToPrimaryUOMQty = new Map<String, Object> ();
        SBUX_B2B_AutoShipUtil.getOrderableUOMToPrimaryUOM(orderableUOMToPrimaryUOMQty, autoShipLines.values());

        if (finalizeOrders) {
            USAutoShipPricing = new Map<String, Object> ();
            CAAutoShipPricing = new Map<String, Object> ();
            SBUX_B2B_AutoShipUtil.getPricingData(autoShipHeaderId, USAutoShipPricing, CAAutoShipPricing);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String storeAttributeQuery = 'SELECT Id' +
                ',Beverage_Autoship__c' +
                ',Beverage_Autoship_Qty__c' +
                ',Coffee_For_Brewing__c' +
                ',Coffee_For_Brewing_Qty__c' +
                ',Gift_Card_Participation__c' +
                ',Gift_Card_Participation_Qty__c' +
                ',Merchandise__c' +
                ',Merchandise_Qty__c' +
                ',Retail_Whole_Bean_Coffee__c' +
                ',Retail_Whole_Bean_Coffee_Qty__c' +
                ',Smallware_Supply_Qty__c' +
                ',Local_Product__c' +
                ',Local_Product_Qty__c' +
                ',Local_Product_Size__c' +
                ',Ships_Promotion_Elsewhere__c' +
                ',Autoship_Program_Type__c' +
                ',Store__r.ID' +
                ',Store__r.CDC_1__c' +
                ',Store__r.CDC_2__c' +
                ',Store__r.RDC__c' +
                ',Store__r.Country__c' +
                ',Store__r.Region__c ' +
                ',Store__r.Licensee__c ' +
                ',Store__r.Store_Account__c' +
                ',Store__r.Store_Number__c' +
                ',Store__r.Store_Status__c';
        storeAttributeQuery += ' FROM Store_Attribute__c';
        storeAttributeQuery += ' WHERE RecordType.DeveloperName = \'Autoship\'';
        storeAttributeQuery += ' AND ((Store__r.Commissary_Status__c = \'Is Commissary\' AND Store__r.Status__c = \'Prospect\') OR (Store__r.Status__c = \'Open to the Public\'))';
        storeAttributeQuery += ' AND Ships_Promotion_Elsewhere__c = \'No\'';
        storeAttributeQuery += SBUX_B2B_AutoShipUtil.prepareCategoryAssortmentSizeAndStoreNumberFilter(autoShipHeaderId, storeNumbersToBeIncluded);
        if (finalizeOrders || processSplits) {
            if (storeNumbersToBeIncluded.size() > 0) {
                storeAttributeQuery += ' AND (Autoship_Program_Type__c = \'Starbucks Ships\' OR Store__r.Store_Number__c IN (' + String.join(new List<String>(storeNumbersToBeIncluded), ',') + '))';
            } else {
                storeAttributeQuery += ' AND Autoship_Program_Type__c = \'Starbucks Ships\'';
            }
        } else {
            storeAttributeQuery += ' AND (Autoship_Program_Type__c != \'NULL\' AND Autoship_Program_Type__c != \'None\')';
        }
        return Database.getQueryLocator(storeAttributeQuery);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        try {
            // Get the list of stores that need to be processed in this transaction.
            List<Store_Attribute__c> storesToBeProcessedInCurrentBatch = (List<Store_Attribute__c>) scope;

            List<String> storeSFIDList = new List<String>();
            Set<String> licenseeAccounts = new Set<String>();
            Set<String> storeNumbersInCurrentBatch = new Set<String>();
            for (Store_Attribute__c storeAttribute : storesToBeProcessedInCurrentBatch) {
                storeSFIDList.add(storeAttribute.Store__c);
                licenseeAccounts.add(storeAttribute.Store__r.Licensee__c);
                storeNumbersInCurrentBatch.add(storeAttribute.Store__r.Store_Number__c);
            }
            Map<String, Object> billToAddressMap = new Map<String, Object> ();
            Map<String, Object> shipToAddressMap = new Map<String, Object> ();
            Map<String, Object> productExceptionsByLicenseeAccount = new Map<String, Object> ();
            Map<String, Object> distributionCodeMap = new Map<String, Object> ();
            
            if (finalizeOrders) {
                SBUX_B2B_AutoShipUtil.getBillToShipToAddressesForStoresInBatch(storeSFIDList, billToAddressMap, shipToAddressMap);
                SBUX_B2B_AutoShipUtil.getDistributionCodeMap(storeNumbersInCurrentBatch, distributionCodeMap);
            }

            // Get the product exception rules for all licensee accounts related to stores in batch.
            if (processSplits){
                SBUX_B2B_AutoShipUtil.getProductExceptionsForStoresInBatch(licenseeAccounts, autoShipLines.values(),productExceptionsByLicenseeAccount);
            }

            // For each store, build orders
            for (Store_Attribute__c currStoreAttribute : storesToBeProcessedInCurrentBatch) {
                try {
                    // Figure out the order items for this order
                    Map<String, Object> multiplicationFactorsForAutoShipLineMap = SBUX_B2B_AutoShipUtil.calculateLineMultiplicationFactorForStore(currStoreAttribute, autoShipLines.values());

                    // Check if we will have any order items for this store, else skip.
                    if (multiplicationFactorsForAutoShipLineMap.size() == 0) {
                        continue;
                    }

                    // Build Order Header
                    ccrz__E_Order__c currOrder = SBUX_B2B_AutoShipUtil.buildOrderHeaderForStore(currAutoShipHeader, currStoreAttribute);
                    insert currOrder;

                    // Build Order Items
                    List<ccrz__E_OrderItem__c> currOrderItems = SBUX_B2B_AutoShipUtil.buildOrderLinesForStore(currStoreAttribute, currOrder, autoShipLines, orderableUOMToPrimaryUOMQty, multiplicationFactorsForAutoShipLineMap, USAutoShipPricing, CAAutoShipPricing);

                    // Check if order needs splitting
                    if (processSplits
                            && (
                            currStoreAttribute.Autoship_Program_Type__c.equals(PROGRAM_TYPE_STARBUCKS_SHIPS)
                                    || storeNumbersToBeIncluded.contains('\'' + currStoreAttribute.Store__r.Store_Number__c + '\'')
                    )) {
                        Map<String, Object> productExceptionsForCurrLicensee = (Map<String, Object>) productExceptionsByLicenseeAccount.get(currStoreAttribute.Store__r.Licensee__c);
                        if (productExceptionsForCurrLicensee == null){productExceptionsForCurrLicensee = new Map<String, Object> ();}
                        currOrderItems = SBUX_B2B_AutoShipUtil.splitOrder(finalizeOrders, currAutoShipHeader, currOrder, currOrderItems, currStoreAttribute, autoShipLines, billToAddressMap, shipToAddressMap, distributionCodeMap, productExceptionsForCurrLicensee);
                    }
                    insert currOrderItems;

                    // Generate Forecast Items, even for final processing.
                    List<SBUX_B2B_AutoshipForecast__c> forecastLines = SBUX_B2B_AutoShipUtil.generateForecastLines(currStoreAttribute, dcMappings, currOrderItems, autoShipLines);
                    insert forecastLines;

                } catch (Exception e) {
                    //TODO: Handle Store Failures.
                }
            }
        } catch (Exception e) {
            //TODO: Handle Run Time exceptions.
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (processSplits && finalizeOrders) {
            currAutoShipHeader.SBUX_B2B_AutoshipStatus__c = AUTOSHIP_HEADER_STATUS_ORDERS_CREATED;
        } else if (processSplits) {
            currAutoShipHeader.SBUX_B2B_AutoshipStatus__c = PREVIEW_JOB_COMPLETE_STATUS;
        } else {
            currAutoShipHeader.SBUX_B2B_AutoshipStatus__c = FORECAST_JOB_COMPLETE_STATUS;
        }
        update currAutoShipHeader;
    }
}