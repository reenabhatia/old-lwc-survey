public with sharing class SBUX_B2B_ccProductTriggerHandler {

    private static final String UOM_CONVERSION_TO_CODE = 'toCode';
    private static final String UOM_CONVERSION_FROM_CODE = 'fromCode';
    private static final String UOM_CONVERSION_CONVERSION_FACTOR = 'convRt';
    private static final Set<String> profileToExclude = new Set<String>{
            'System Administrator'
            , 'LS Integration'
    };


    public static void bypassUpdateForIntegration(List<ccrz__E_Product__c> newProducts,
            Map<Id, ccrz__E_Product__c> oldMap,
            Map<Id, ccrz__E_Product__c> newMap) {
        String contextPath = System.URL.getCurrentRequestUrl().getPath();
        // Do not let the integration layer overwrite the following fields for subsequent update pushes
        //TODO - use a regular expression to match the fully qualified context path
        if (contextPath != null && !String.isEmpty(contextPath) && contextPath.contains('/services/data/')) {
            for (ccrz__E_Product__c product : newProducts) {
                ccrz__E_Product__c oldProduct = oldMap.get(product.Id);
                ccrz__E_Product__c newProduct = newMap.get(product.Id);

                newProduct.Name = oldProduct.Name;
                newProduct.ccrz__UnitOfMeasure__c = oldProduct.ccrz__UnitOfMeasure__c ;
                newProduct.ccrz__ProductStatus__c = oldProduct.ccrz__ProductStatus__c;
            }
        }
    }

    public static void updateUOMConversionFactor(List<ccrz__E_Product__c> newProducts, Map<Id, ccrz__E_Product__c> oldMap) {
        Map<Id, ccrz__E_Product__c> productsInScope;
        Boolean generateErrorMessage = true;
        if (Trigger.isBefore && Trigger.isUpdate) {
            productsInScope = new Map<Id, ccrz__E_Product__c> ([
                    SELECT Id, SBUX_B2B_UOMConv__c, SBUX_B2B_PrimaryUOM__c,ccrz__UnitOfMeasure__c
                    FROM ccrz__E_Product__c
                    WHERE Id IN :newProducts
            ]);
            Map<Id, Profile> profilesToExclude = new Map<Id, Profile>([
                    SELECT Id
                    FROM Profile
                    WHERE Name IN :profileToExclude
            ]);
            if (profilesToExclude.containsKey(UserInfo.getProfileId())) {
                generateErrorMessage = false;
            }
        }

        for (ccrz__E_Product__c product : newProducts) {
            product.SBUX_B2B_Orderable_UOM_Conversion_Factor__c = 1;
            if (Trigger.isBefore && Trigger.isInsert) {
                if (product.ccrz__UnitOfMeasure__c != null && product.SBUX_B2B_PrimaryUOM__c != null && product.SBUX_B2B_UOMConv__c != null) {
                    populateConversionFactor(product, oldMap, product.SBUX_B2B_UOMConv__c, product.SBUX_B2B_PrimaryUOM__c, product.ccrz__UnitOfMeasure__c, generateErrorMessage);
                }
            } else if (Trigger.isBefore && Trigger.isUpdate) {

                ccrz__E_Product__c currProduct = productsInScope.containsKey(product.Id) ? productsInScope.get(product.Id) : new ccrz__E_Product__c();

                String JSONConversionString, primaryUOM, orderableUOM;

                if (product.SBUX_B2B_UOMConv__c != null || currProduct.SBUX_B2B_UOMConv__c != null) {
                    JSONConversionString = (product.SBUX_B2B_UOMConv__c != null) ? product.SBUX_B2B_UOMConv__c : currProduct.SBUX_B2B_UOMConv__c;
                }

                if (product.SBUX_B2B_PrimaryUOM__c != null || currProduct.SBUX_B2B_PrimaryUOM__c != null) {
                    primaryUOM = (product.SBUX_B2B_PrimaryUOM__c != null) ? product.SBUX_B2B_PrimaryUOM__c : currProduct.SBUX_B2B_PrimaryUOM__c;
                }

                if (product.ccrz__UnitOfMeasure__c != null || currProduct.ccrz__UnitOfMeasure__c != null) {
                    orderableUOM = (product.ccrz__UnitOfMeasure__c != null) ? product.ccrz__UnitOfMeasure__c : currProduct.ccrz__UnitOfMeasure__c;
                }

                if (product != null && JSONConversionString != null && primaryUOM != null && orderableUOM != null) {
                    populateConversionFactor(product, oldMap, JSONConversionString, primaryUOM, orderableUOM, generateErrorMessage);
                } else {
                    populateErrorMessage(product, oldMap, Label.UOM_Conversion_Missing_Error, null, null, generateErrorMessage);
                }
            }
        }
    }

    private static void populateConversionFactor(ccrz__E_Product__c product
            , Map<Id, ccrz__E_Product__c> oldMap
            , String JSONConversionMap
            , String primaryUOM
            , String orderableUOM
            , Boolean generateErrorMessage) {
        try {
            Boolean conversionFactorSuccess = false;
            List<Object> UOMConversionMapList = (List<Object>) JSON.deserializeUntyped(JSONConversionMap);
            for (Object convMap : UOMConversionMapList) {
                Map<String, Object> currConversionMap = (Map<String, Object>) convMap;
                if (currConversionMap.containsKey(UOM_CONVERSION_TO_CODE)
                        && currConversionMap.containsKey(UOM_CONVERSION_FROM_CODE)
                        && currConversionMap.containsKey(UOM_CONVERSION_CONVERSION_FACTOR)
                        && ((String) currConversionMap.get(UOM_CONVERSION_TO_CODE)).equalsIgnoreCase(orderableUOM)
                        && ((String) currConversionMap.get(UOM_CONVERSION_FROM_CODE)).equalsIgnoreCase(primaryUOM)) {
                    Decimal conversionFactor = (Decimal) currConversionMap.get(UOM_CONVERSION_CONVERSION_FACTOR);
                    if (conversionFactor != null) {
                        product.SBUX_B2B_Orderable_UOM_Conversion_Factor__c = conversionFactor;
                        conversionFactorSuccess = true;
                    }
                }
            }
            if (!conversionFactorSuccess
                    && Trigger.isBefore
                    && Trigger.isUpdate
                    && oldMap.containsKey(product.Id)) {
                populateErrorMessage(product, oldMap, Label.Invalid_UOM_Conversion_Error, primaryUOM, orderableUOM, generateErrorMessage);
            }
        } catch (Exception e) {
            // If there is an exception, we set the factor to 1.
            product.SBUX_B2B_Orderable_UOM_Conversion_Factor__c = 1;
        }
    }

    public static void populateErrorMessage(ccrz__E_Product__c product
            , Map<Id, ccrz__E_Product__c> oldMap
            , String message, String primaryUOM
            , String orderableUOM
            , Boolean generateErrorMessage) {
        ccrz__E_Product__c oldProduct = oldMap.get(product.Id);
        if (oldProduct.ccrz__UnitOfMeasure__c != product.ccrz__UnitOfMeasure__c && generateErrorMessage) {
            if (primaryUOM != null && orderableUOM != null) {
                product.addError(String.format(message, new List<Object>{
                        primaryUOM, orderableUOM, oldProduct.ccrz__UnitOfMeasure__c
                }));
            } else {
                product.addError(message);
            }
        }
    }
}