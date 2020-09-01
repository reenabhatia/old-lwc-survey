/**
 * Created by dgajwani on 7/9/20.
 */

global with sharing class SBUX_B2B_ccServiceAccount extends ccrz.ccServiceAccount {

    public static final String BILLING_STREET = 'billingStreet';
    private static final String BILLING_CITY = 'billingCity';
    private static final String BILLING_STATE = 'billingState';
    private static final String BILLING_COUNTRY = 'billingCountry';
    private static final String BILLING_POSTAL_CODE = 'billingPostalCode';

    private static final String SHIPPING_STREET = 'shippingStreet';
    private static final String SHIPPING_CITY = 'shippingCity';
    private static final String SHIPPING_STATE = 'shippingState';
    private static final String SHIPPING_COUNTRY = 'shippingCountry';
    private static final String SHIPPING_POSTAL_CODE = 'shippingPostalCode';

    /**
     * @description OOTB method to retrieve account info
     */
    global override Map<String, Object> fetch(Map<String, Object> inputData) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccServiceAccount:fetch');
        Map<String, Object> outputData = super.fetch(inputData);
        addBillToShipToAddress(outputData);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccServiceAccount:fetch');
        return outputData;
    }

    /**
     * @description Adds the billTo and ShipTo address for the account from Address__c.
     */
    public static void addBillToShipToAddress(Map<String, Object> accountFetchOutput) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccServiceAccount:addBillToShipToAddress');
        // Sanity check to ensure we have some account data.
        if (accountFetchOutput.containsKey(ccrz.ccApiAccount.ACCOUNTS)) {
            // Determine if data is transformed
            if (accountFetchOutput.containsKey(ccrz.ccAPI.SIZING)) {
                Map<String, Object> sizingMap = (Map<String, Object>) accountFetchOutput.get(ccrz.ccAPI.SIZING);
                if (sizingMap.containsKey(ccrz.ccAPIAccount.ENTITYNAME)) {
                    Map<String, Object> accountMap = (Map<String, Object>) sizingMap.get(ccrz.ccAPIAccount.ENTITYNAME);

                    if (accountMap.containsKey(ccrz.ccAPI.SZ_SKIPTRZ) && (Boolean) accountMap.get(ccrz.ccAPI.SZ_SKIPTRZ)) {
                        handleSKIPTransformedAccountData(accountFetchOutput);
                    } else {
                        handleTransformedAccountData(accountFetchOutput);
                    }
                }
            } else {
                handleTransformedAccountData(accountFetchOutput);
            }

        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccServiceAccount:addBillToShipToAddress');
    }

    public static void handleTransformedAccountData(Map<String, Object> accountFetchOutput) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccServiceAccount:handleTransformedAccountData');
        List<Map<String, Object>> allAccounts = (List<Map<String, Object>>) accountFetchOutput.get(ccrz.ccApiAccount.ACCOUNTS);
        if (!allAccounts.isEmpty()) {
            Map<String, Object> currAccount = allAccounts[0];
            Store__c currStore = SBUX_B2B_StorefrontUtil.fetchCurrentStore();
            ccrz__E_ContactAddr__c billTo = SBUX_B2B_ccLogicCartInitItemGroups.getBillToAddressForStore(currStore.Id);
            ccrz__E_ContactAddr__c shipTo = SBUX_B2B_ccLogicCartInitItemGroups.getShipToAddressForStore(currStore.Id);

            if (billTo != null){
                currAccount.put(BILLING_STREET, billTo.ccrz__AddressFirstline__c);
                currAccount.put(BILLING_CITY, billTo.ccrz__City__c);
                currAccount.put(BILLING_STATE, billTo.ccrz__State__c);
                currAccount.put(BILLING_COUNTRY, billTo.ccrz__Country__c);
                currAccount.put(BILLING_POSTAL_CODE, billTo.ccrz__PostalCode__c);
            }
            if (shipTo != null){
                currAccount.put(SHIPPING_STREET, shipTo.ccrz__AddressFirstline__c);
                currAccount.put(SHIPPING_CITY, shipTo.ccrz__City__c);
                currAccount.put(SHIPPING_STATE, shipTo.ccrz__State__c);
                currAccount.put(SHIPPING_COUNTRY, shipTo.ccrz__Country__c);
                currAccount.put(SHIPPING_POSTAL_CODE, shipTo.ccrz__PostalCode__c);
            }
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccServiceAccount:handleTransformedAccountData');
    }

    public static void handleSKIPTransformedAccountData(Map<String, Object> accountFetchOutput) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccServiceAccount:handleSKIPTransformedAccountData');
        List<Account> allAccounts = (List<Account>) accountFetchOutput.get(ccrz.ccApiAccount.ACCOUNTS);
        if (!allAccounts.isEmpty()) {
            Account currAccount = allAccounts[0];
            Store__c currStore = SBUX_B2B_StorefrontUtil.fetchCurrentStore();
            ccrz__E_ContactAddr__c billTo = SBUX_B2B_ccLogicCartInitItemGroups.getBillToAddressForStore(currStore.Id);
            ccrz__E_ContactAddr__c shipTo = SBUX_B2B_ccLogicCartInitItemGroups.getShipToAddressForStore(currStore.Id);

            if (billTo != null){
                currAccount.BillingStreet = billTo.ccrz__AddressFirstline__c;
                currAccount.BillingCity = billTo.ccrz__City__c;
                currAccount.BillingState = billTo.ccrz__State__c;
                currAccount.BillingCountry = billTo.ccrz__Country__c;
                currAccount.BillingPostalCode = billTo.ccrz__PostalCode__c;
            }
            if (shipTo != null){
                currAccount.ShippingStreet = shipTo.ccrz__AddressFirstline__c;
                currAccount.ShippingCity = shipTo.ccrz__City__c;
                currAccount.ShippingState = shipTo.ccrz__State__c;
                currAccount.ShippingCountry = shipTo.ccrz__Country__c;
                currAccount.ShippingPostalCode = shipTo.ccrz__PostalCode__c;
            }
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccServiceAccount:handleSKIPTransformedAccountData');
    }
}