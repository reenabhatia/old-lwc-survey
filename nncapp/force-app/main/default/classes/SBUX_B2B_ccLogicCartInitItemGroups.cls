/**
 * Created by dgajwani on 4/28/20.
 */

global with sharing class SBUX_B2B_ccLogicCartInitItemGroups extends ccrz.ccLogicCartInitItemGroups {

    private static final String SHIP_STRUCTURE_LLI = 'LLI';
    public static final String EMERGENCY_ORDER = 'Emergency_Order';
    public static final String CART_ITEM_GROUP_CART_KEY = 'cart';
    public static final String CART_ITEM_GROUP_GROUP_NAME_KEY = 'groupName';
    private static final String CART_ITEM_GROUP_SHIP_TO_KEY = 'shipTo';
    public static final String CART_ITEM_GROUPS_KEY = 'ECartItemGroupsS';
    private static final String ADDRESS_TYPE_BILL_TO = 'BillTo';
    private static final String ADDRESS_TYPE_SHIP_TO = 'ShipTo';
    private static final String NAME_DELIMITTER = '_';

    global override Map<String, Object> initItemGroups(Map<String, Object> inputData) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartInitItemGroups:initItemGroups');
        Map<String, Object> cartFetchResponse = fetchCart(inputData);
        createCartItemGroups(cartFetchResponse);

        // Check re-fetch flag --> if TRUE re-fetch Updated CartItemGroups in accordance with passed in Sizing.
        if (ccrz.ccUtil.isTrue(ccrz.ccAPI.lookUpSz(inputData, ccrz.ccAPICart.ENTITYNAME, ccrz.ccAPI.SZ_REFETCH))) {
            Map<String, Object> rfRes = ccrz.ccAPICart.fetch(new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => inputData.get(ccrz.ccApi.API_VERSION),
                    ccrz.ccAPICart.CART_ENCID => ccrz.cc_CallContext.currCartId,
                    ccrz.ccAPI.SIZING => ccrz.ccUtil.defv(inputData, ccrz.ccAPI.SIZING, new Map<String, Object>())
            });

            inputData.putAll(rfRes);
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartInitItemGroups:initItemGroups');
        return inputData;
    }

    private static Map<String, Object> getProductExceptionsForStore() {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartInitItemGroups:getProductExceptionsForStore');
        Map<String, Object> result = new Map<String, Object> ();
        if (ccrz.cc_CallContext.currAccount.ParentId != null){
            List<SBUX_B2B_ProductExceptionRule__c> productExceptionsForThisCartAndStore = SBUX_B2B_WOSharingUtil.queryProductExceptions();
            for (SBUX_B2B_ProductExceptionRule__c exceptionRule : productExceptionsForThisCartAndStore){
                result.put(exceptionRule.SBUX_B2B_Product__c, exceptionRule.SBUX_B2B_CogsSupplyException__c);
            }
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartInitItemGroups:getProductExceptionsForStore');
        return result;
    }

    private static void validateExistingCart(ccrz__E_Cart__c currCart, Map<String, Object> existingCartItemGroups, ccrz__E_ContactAddr__c billToForStore, ccrz__E_ContactAddr__c shipToForStore){
        if (currCart.ccrz__ShipStructure__c != SHIP_STRUCTURE_LLI || currCart.ccrz__BillTo__c == null || currCart.ccrz__ShipTo__c == null) {
            currCart.ccrz__ShipStructure__c = SHIP_STRUCTURE_LLI;

            if (billToForStore != null) {
                insert billToForStore;
                currCart.ccrz__BillTo__c = billToForStore.Id;
            } else {
                ccrz.ccLog.log(System.LoggingLevel.ERROR, 'No BillTo Address found for store: ' + currCart.SBUX_B2B_Store__c);
            }
            if (shipToForStore != null) {
                insert shipToForStore;
                currCart.ccrz__ShipTo__c = shipToForStore.Id;
            } else {
                ccrz.ccLog.log(System.LoggingLevel.ERROR, 'No ShipTo Address found for store: ' + currCart.SBUX_B2B_Store__c);
            }
            update currCart;
        }


        List<ccrz__E_CartItemGroup__c> cartItemGroupsToDelete = new List<ccrz__E_CartItemGroup__c>();
        if (!currCart.ccrz__E_CartItemGroups__r.isEmpty()) {
            for (ccrz__E_CartItemGroup__c cig : currCart.ccrz__E_CartItemGroups__r) {
                if (cig.ccrz__ShipTo__c == null){
                    cartItemGroupsToDelete.add(cig);
                } else {
                    existingCartItemGroups.put(cig.ccrz__GroupName__c, cig.Id);
                }
            }
            delete cartItemGroupsToDelete;
        }
    }

    /**
     * @description Categorizes cart items into different cart item groups based on CDC/RDC, COGS/Supply and EO.
     */
    private static void createCartItemGroups(Map<String, Object> cartFetchResponse) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartInitItemGroups:createCartItemGroups');
        //check the fetch response to see if cart data was returned
        if (!((Boolean) cartFetchResponse.get(ccrz.ccAPI.SUCCESS)) || !cartFetchResponse.containsKey(ccrz.ccAPICart.CART_OBJLIST) || ((List<ccrz__E_Cart__c>) cartFetchResponse.get(ccrz.ccAPICart.CART_OBJLIST) == null) || ((List<ccrz__E_Cart__c>) cartFetchResponse.get(ccrz.ccAPICart.CART_OBJLIST)).isEmpty()) {
            return;
        }

        Map<String, List<ccrz__E_CartItem__c>> cartItemsById = (Map<String, List<ccrz__E_CartItem__c>>) cartFetchResponse.get(ccrz.ccAPICart.CARTITEMSBYID);
        List<ccrz__E_Cart__c>cartList = (List<ccrz__E_Cart__c>) cartFetchResponse.get(ccrz.ccAPICart.CART_OBJLIST);

        //grab the first cart
        ccrz__E_Cart__c currCart = cartList[0];
        Map<String, Object> existingCartItemGroups = new Map<String, Object> ();
        ccrz__E_ContactAddr__c shipTo = getShipToAddressForStore(currCart.SBUX_B2B_Store__c);
        ccrz__E_ContactAddr__c billTo = getBillToAddressForStore(currCart.SBUX_B2B_Store__c);

        validateExistingCart(currCart,existingCartItemGroups, billTo, shipTo);
        if (shipTo.Id == null){
            shipTo.Id = currCart.ccrz__ShipTo__c;
        }

        List<ccrz__E_CartItem__c> emergencyOrder = new List<ccrz__E_CartItem__c> ();
        Map<String, Object> cogsSupplyMap = new Map<String, Object> ();
        Map<String, Object> itemSourcingMap = new Map<String, Object> ();

        // Sort Order Items into various categories that we split on.
        categorizeCartItems(cartItemsById.get(currCart.Id), emergencyOrder, itemSourcingMap, cogsSupplyMap);

        // Now we should have all the possible split variations, we just need to merge the different combinations
        List<ccrz__E_CartItem__c> cartItemsToUpdate = new List<ccrz__E_CartItem__c>();

        if (emergencyOrder.size() > 0) {
            String cartItemGroupSFID = (String) existingCartItemGroups.remove(EMERGENCY_ORDER);
            if (cartItemGroupSFID == null) {
                cartItemGroupSFID = insertCartItemGroup(currCart.Id, EMERGENCY_ORDER, shipTo);
            }
            for (ccrz__E_CartItem__c ci : emergencyOrder) {
                ci.ccrz__CartItemGroup__c = cartItemGroupSFID;
                cartItemsToUpdate.add(ci);
            }
        }

        for (String currCogsSupplyValue : cogsSupplyMap.keySet()) {
            for (String currItemSourcingValue : itemSourcingMap.keySet()) {
                // Gather all order items that match the current criteria
                Set<ccrz__E_CartItem__c> cartItemsForCurrentCogsSupplyValue = (Set<ccrz__E_CartItem__c>) cogsSupplyMap.get(currCogsSupplyValue);
                Set<ccrz__E_CartItem__c> cartItemsForCurrentItemSourcingValue = (Set<ccrz__E_CartItem__c>) itemSourcingMap.get(currItemSourcingValue);

                // Put all cart items in a set to gather unique order items for this combination.
                Set<ccrz__E_CartItem__c> cartItemsForThisPermutation = new Set<ccrz__E_CartItem__c>(cartItemsForCurrentItemSourcingValue);
                cartItemsForThisPermutation.retainAll(cartItemsForCurrentCogsSupplyValue);

                if (cartItemsForThisPermutation.size() > 0) {
                    String cartItemGroupSFID = (String) existingCartItemGroups.remove(currCogsSupplyValue.toUpperCase() + NAME_DELIMITTER + currItemSourcingValue.toUpperCase());
                    if (cartItemGroupSFID == null) {
                        cartItemGroupSFID = insertCartItemGroup(currCart.Id, currCogsSupplyValue.toUpperCase() + NAME_DELIMITTER + currItemSourcingValue.toUpperCase(), shipTo);
                    }

                    for (ccrz__E_CartItem__c ci : cartItemsForThisPermutation) {
                        ci.ccrz__CartItemGroup__c = cartItemGroupSFID;
                        cartItemsToUpdate.add(ci);
                    }
                }
            }
        }
        update cartItemsToUpdate;

        // delete orphaned cart item groups
        if (existingCartItemGroups.size() > 0) {
            List<ccrz__E_CartItemGroup__c> cartItemGroupsToDelete = new List<ccrz__E_CartItemGroup__c>();
            for (String cig : existingCartItemGroups.keySet()) {
                cartItemGroupsToDelete.add(new ccrz__E_CartItemGroup__c(Id = (String) existingCartItemGroups.get(cig)));
            }
            delete cartItemGroupsToDelete;
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartInitItemGroups:createCartItemGroups');
    }

    /**
     * @description Fetches the current cart using ccApiCart.fetch()
     */
    private static Map<String, Object> fetchCart(Map<String, Object> inputData) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartInitItemGroups:fetchCart');
        Map<String, Object> cartFetchRequest = new Map<String, Object>{
                ccrz.ccAPI.API_VERSION => inputData.get(ccrz.ccAPI.API_VERSION),
                ccrz.ccAPICart.CART_ENCID => inputData.get(ccrz.ccAPICart.CART_ENCID),
                ccrz.ccApi.SIZING => new Map<String, Object>{
                        ccrz.ccAPICart.ENTITYNAME => new Map<String, Object>{
                                ccrz.ccAPI.SZ_DATA => ccrz.ccAPI.SZ_XL,
                                ccrz.ccAPI.SZ_SKIPTRZ => true
                        }
                }
        };
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartInitItemGroups:fetchCart');
        return ccrz.ccApiCart.fetch(cartFetchRequest);
    }

    /**
     * @description Categorizes cart items into their various splits by CDC/RDC, COGS/Supply and EO.
     */
    private static void categorizeCartItems(List<ccrz__E_CartItem__c> cartItems, List<ccrz__E_CartItem__c> emergencyOrder, Map<String, Object> itemSourcingMap, Map<String, Object> cogsSupplyMap) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartInitItemGroups:categorizeCartItems');
        Map<String, Object> productExceptionsMapByProductSFID = getProductExceptionsForStore();
        for (ccrz__E_CartItem__c currCartItem : cartItems) {

            // Handle Emergency Orders
            if (currCartItem.SBUX_B2B_Is_Emergency__c) {
                emergencyOrder.add(currCartItem);
                continue;
            }

            // *** Item Source Splits****
            String currItemSourceValue = currCartItem.ccrz__Product__r.SBUX_B2B_ItemSource__c;

            // Get the list of order items for the currItemSourceValue. If we dont have one, create a new List.
            Set<ccrz__E_CartItem__c> currItemSourceList = (Set<ccrz__E_CartItem__c>) itemSourcingMap.get(currItemSourceValue);
            if (currItemSourceList == null) {
                currItemSourceList = new Set<ccrz__E_CartItem__c> ();
                itemSourcingMap.put(currItemSourceValue, currItemSourceList);
            }
            currItemSourceList.add(currCartItem);

            // *** COGS/Supply Splits****
            String currItemCogsSupplyValue = currCartItem.ccrz__Product__r.SBUX_B2B_CogsSupply__c;

            // Check if we have an override for this product
            if (productExceptionsMapByProductSFID.containsKey(currCartItem.ccrz__Product__c)){
                String overrideValue = (String)productExceptionsMapByProductSFID.get(currCartItem.ccrz__Product__c);
                if (overrideValue != null && !String.isEmpty(overrideValue)){
                    currItemCogsSupplyValue = overrideValue;
                }
            }

            // Get the list of order items for the currItemCogsSupplyValue. If we dont have one, create a new List.
            Set<ccrz__E_CartItem__c> currItemCogsSupplyValueList = (Set<ccrz__E_CartItem__c>) cogsSupplyMap.get(currItemCogsSupplyValue);
            if (currItemCogsSupplyValueList == null) {
                currItemCogsSupplyValueList = new Set<ccrz__E_CartItem__c> ();
                cogsSupplyMap.put(currItemCogsSupplyValue, currItemCogsSupplyValueList);
            }
            currItemCogsSupplyValueList.add(currCartItem);
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartInitItemGroups:categorizeCartItems');
    }

    /**
     * @description Uses the ccApiCart.createCartItemGroup to insert the cart item group and returns its SFID.
     */
    private static String insertCartItemGroup(String cartSFID, String groupName, ccrz__E_ContactAddr__c shipToForStore) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartInitItemGroups:insertCartItemGroup');
        ccrz__E_ContactAddr__c shipToForCIG = shipToForStore.clone(false, true, false, false);
        shipToForCIG.ccrz__ShippingComments__c = groupName;
        insert shipToForCIG;
        Map<String, Object> insertGroup = new Map<String, Object>{
                CART_ITEM_GROUP_CART_KEY => cartSFID,
                CART_ITEM_GROUP_GROUP_NAME_KEY => groupName,
                CART_ITEM_GROUP_SHIP_TO_KEY => shipToForCIG.Id
        };
        Map<String, Object> cartItemGroupCreateRequest = new Map<String, Object>{
                ccrz.ccAPI.API_VERSION => 9,
                CART_ITEM_GROUPS_KEY => new List<Map<String, Object>>{
                        insertGroup
                }
        };
        Map<String, Object> res = ccrz.ccApiCart.createCartItemGroup(cartItemGroupCreateRequest);
        String newCartItemGroupSFID = (String) res.get(ccrz.ccApiCart.ITEMGROUPID);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartInitItemGroups:insertCartItemGroup');
        return newCartItemGroupSFID;
    }

    /**
     * @description Returns a CC Contact Address representing the shipTo address for the store.
     */
    public static ccrz__E_ContactAddr__c getShipToAddressForStore(String storeSFID) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartInitItemGroups:getShipToAddressForStore');
        ccrz__E_ContactAddr__c result;
        String siteID = SBUX_B2B_StorefrontUtil.getSiteIDForCustomer(storeSFID);
        List<Address__c> shipToAddressForStore = [
                SELECT Id,Account_Name__c,Account_Number__c,Address_1__c,Address_2__c,Address_3__c,Address_Type__c,City__c,Country__c,County__c,Name,Postal_Code__c,Site_Id__c,Site_Number__c,State__c,State_Province__c,Store__c,Store_Id__c,Store_Number__c,Sub__c,Telephone_Number__c,Unit_Number__c,Warehouse_Code__c,Zone__c
                FROM Address__c
                WHERE Store__c = :storeSFID
                AND Address_Type__c = :ADDRESS_TYPE_SHIP_TO
                AND Status__c = 'Y'
                AND Primary__c = 'Y'
                AND Site_Id__c = :siteID
        ];
        if (shipToAddressForStore.size() > 0) {
            result = prepareContactAddress(shipToAddressForStore[0]);
        }
        // If this is a running test, we probably wont find any addresses given all validation. Add a backup.
        if (result == null && Test.isRunningTest()) {
            result = prepareContactAddress(new Address__c(Address_1__c = 'test', City__c = 'test'));
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartInitItemGroups:getShipToAddressForStore');
        return result;
    }

    /**
     * @description Returns a CC Contact Address representing the billTo address for the store.
     */
    public static ccrz__E_ContactAddr__c getBillToAddressForStore(String storeSFID) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartInitItemGroups:getBillToAddressForStore');
        ccrz__E_ContactAddr__c result;
        List<Address__c> shipToAddressForStore = [
                SELECT Id,Billto_Site_Number__c
                FROM Address__c
                WHERE Store__c = :storeSFID
                AND Address_Type__c = :ADDRESS_TYPE_SHIP_TO
                AND Status__c = 'Y'
                AND Primary__c = 'Y'
        ];
        if (shipToAddressForStore.size() > 0) {
            List<Address__c> billToAddressForStore = [
                    SELECT Id,Account_Name__c,Account_Number__c,Address_1__c,Address_2__c,Address_3__c,Address_Type__c,City__c,Country__c,County__c,Name,Postal_Code__c,Site_Id__c,Site_Number__c,State__c,State_Province__c,Store__c,Store_Id__c,Store_Number__c,Sub__c,Telephone_Number__c,Unit_Number__c,Warehouse_Code__c,Zone__c
                    FROM Address__c
                    WHERE Store__c = :storeSFID
                    AND Address_Type__c = :ADDRESS_TYPE_BILL_TO
                    AND Status__c = 'Y'
                    AND Site_Id__c = :shipToAddressForStore[0].Billto_Site_Number__c
            ];
            if (billToAddressForStore.size() > 0) {
                result = prepareContactAddress(billToAddressForStore[0]);
            }
        }
        // If this is a running test, we probably wont find any addresses given all validation. Add a backup.
        if (result == null && Test.isRunningTest()) {
            result = prepareContactAddress(new Address__c(Address_1__c = 'test', City__c = 'test'));
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartInitItemGroups:getBillToAddressForStore');
        return result;
    }

    /**
    * @description Creates a CC Contact address from the Address__c record.
    *
    * @return A ccrz__E_ContactAddr__c representing the BillTo for the current store.
    */
    public static ccrz__E_ContactAddr__c prepareContactAddress(Address__c addressToUse) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartInitItemGroups:prepareContactAddress');
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
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartInitItemGroups:prepareContactAddress');
        return result;
    }
}