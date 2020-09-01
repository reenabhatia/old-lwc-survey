/**
 * Created by dgajwani on 5/4/20.
 */

public with sharing class SBUX_B2B_OrderUtil {

    public virtual class DeliveryDateExpiredException extends Exception {
    }

    private static final String ORDER_SUBMITTED = 'Order Submitted';
    private static final String ORDER_TYPE_EMERGENCY = 'Emergency_Order';
    private static final String ORDER_SOURCE_STOREFRONT = 'eCommerce';
    private static final String CLOSED = 'Closed';
    private static final String STORE_COUNTRY_US = 'US';
    private static final String STORE_COUNTRY_CA = 'CA';
    private static final String ORDER_COUNTRY_CANADA = 'CAN';
    private static final String DATE_FORMAT = 'MM/dd/yyyy';
    private static final String ORDER_TYPE_STANDARD_ORDER = 'Standard Order - ';
    private static final String CDC = 'CDC';
    private static final String RDC = 'RDC';
    private static final String KIT = 'KIT';
    private static final String PACIFIC_TIME_ZONE_ID = 'America/Los_Angeles';
    private static final String SIMPLE_PRODUCT = 'Product';
    private static final Set<String> SUPPORTED_DC_TYPES = new Set<String>{
            CDC, RDC, KIT
    };
    private static final Map<String, String> SUPPORTED_TIME_ZONES = new Map<String, String>{
            '-04:00' => 'America/Indiana/Indianapolis',
            '-05:00' => 'America/Chicago',
            '-06:00' => 'America/Denver',
            '-07:00' => 'America/Los_Angeles',
            '–08:00' => 'America/Anchorage',
            '-10:00' => 'Pacific/Honolulu'
    };
    private static final String UOM_CONVERSION_TO_CODE = 'toCode';
    private static final String UOM_CONVERSION_FROM_CODE = 'fromCode';
    private static final String UOM_CONVERSION_CONVERSION_FACTOR = 'convRt';
    private static final String EST_TIME_ZONE = '-04:00';
    private static final String PREPAY_ADD = 'Prepay & Add';
    private static final String PREPAID = 'Prepaid';
    private static final String CUSTOMER_REQUEST = 'CR';

    /**
     * @description Fetches the current cart using ccApiCart.fetch()
     */
    private static Map<String, Object> fetchCart() {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_OrderUtil:fetchCart');
        Map<String, Object> cartFetchRequest = new Map<String, Object>{
                ccrz.ccAPI.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccAPICart.CART_ENCID => ccrz.cc_CallContext.currCartId,
                ccrz.ccApi.SIZING => new Map<String, Object>{
                        ccrz.ccAPICart.ENTITYNAME => new Map<String, Object>{
                                ccrz.ccAPI.SZ_DATA => ccrz.ccAPI.SZ_XL,
                                ccrz.ccAPI.SZ_SKIPTRZ => true
                        }
                }
        };
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_OrderUtil:fetchCart');
        return ccrz.ccApiCart.fetch(cartFetchRequest);
    }

    /**
     * @description Calculates the orderDate and shipDate for the order based on the DC.
     */
    private static void calculateOrderDateAndShipDate(ccrz__E_Order__c currOrder, ccrz__E_CartItemGroup__c cig, Map<String, Object> deliveryDatesByDC) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_OrderUtil:calculateOrderDateAndShipDate');
        String orderType = cig.ccrz__GroupName__c;
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_OrderUtil:calculateOrderDateAndShipDate:groupName', orderType);
        Date orderDate = (cig.ccrz__RequestDate__c == null) ? Date.today() : cig.ccrz__RequestDate__c;

        if (orderType.equalsIgnoreCase(ORDER_TYPE_EMERGENCY)){
            if (deliveryDatesByDC.containsKey(RDC)){
                Map<String, Object> RDCDeliveryData = (Map<String, Object>) deliveryDatesByDC.get(RDC);
                for (String dateString : RDCDeliveryData.keySet()){
                    SBUX_B2B_DeliverySchedule__c currDeliverySchedule = (SBUX_B2B_DeliverySchedule__c) RDCDeliveryData.get(dateString);
                    currOrder.SBUX_B2B_Distribution_Center_Code__c = currDeliverySchedule.SBUX_B2B_DistributionCenter__c;
                }
            }
            // If the DC is blank, we dont have the RDC ODS data to proceed. So we throw an exception.
            if (currOrder.SBUX_B2B_Distribution_Center_Code__c == null){
                throw new DeliveryDateExpiredException(cig.Id);
            }
        }

        if (orderType != null && orderType.contains('_') && !orderType.equalsIgnoreCase(ORDER_TYPE_EMERGENCY)) {
            String currDC = orderType.split('_')[1];
            ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_OrderUtil:calculateOrderDateAndShipDate:currDC', currDC);
            Map<String, Object> deliveryDatesForCurrDC = (Map<String, Object>) deliveryDatesByDC.get(currDC);
            Datetime deliveryDate = Datetime.newInstance(cig.ccrz__RequestDate__c.year(), cig.ccrz__RequestDate__c.month(), cig.ccrz__RequestDate__c.day());

            if (deliveryDatesForCurrDC != null && deliveryDatesForCurrDC.containsKey(deliveryDate.format(DATE_FORMAT))) {
                SBUX_B2B_DeliverySchedule__c currDeliverySchedule = (SBUX_B2B_DeliverySchedule__c) deliveryDatesForCurrDC.get(deliveryDate.format(DATE_FORMAT));
                currOrder.SBUX_B2B_Distribution_Center_Code__c = currDeliverySchedule.SBUX_B2B_DistributionCenter__c;
                ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_OrderUtil:currDeliverySchedule', JSON.serialize(currDeliverySchedule));
                List<SBUX_B2B_ItemDCSourcing__c> cutOffTimeList = [
                        SELECT SBUX_B2B_CutoffTime__c, SBUX_B2B_CuttoffTimeZone__c
                        FROM SBUX_B2B_ItemDCSourcing__c
                        WHERE SBUX_B2B_DistributionCenter__c = :currDeliverySchedule.SBUX_B2B_DistributionCenter__c
                        AND SBUX_B2B_DPNumber__c = :currDeliverySchedule.SBUX_B2B_DPNumber__c
                        AND SBUX_B2B_CutoffTime__c != NULL
                        LIMIT 1
                ];
                // this is a valid delivery date.
                if (!cutOffTimeList.isEmpty()) {
                    if (cutOffTimeList[0].SBUX_B2B_CuttoffTimeZone__c == null) {
                        cutOffTimeList[0].SBUX_B2B_CuttoffTimeZone__c = EST_TIME_ZONE;
                    }
                    ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_OrderUtil:calculateOrderDateAndShipDate:ItemDCSouringRecord)', JSON.serialize(cutOffTimeList[0]));
                    if (currDC.equalsIgnoreCase(CDC)) {
                        getCDCOrderDate(currOrder, cutOffTimeList[0].SBUX_B2B_CutoffTime__c, cutOffTimeList[0].SBUX_B2B_CuttoffTimeZone__c, currDeliverySchedule.SBUX_B2B_OrderDate__c, currDeliverySchedule.SBUX_B2B_ShipDate__c);
                    } else if (currDC.equalsIgnoreCase(RDC)) {
                        getRDCOrderDate(currOrder, Time.newInstance(23, 59, 0, 0), currDeliverySchedule.SBUX_B2B_OrderDate__c, currDeliverySchedule.SBUX_B2B_ShipDate__c);
                    } else if (currDC.equalsIgnoreCase(KIT)) {
                        getCDCOrderDate(currOrder, cutOffTimeList[0].SBUX_B2B_CutoffTime__c, cutOffTimeList[0].SBUX_B2B_CuttoffTimeZone__c, currDeliverySchedule.SBUX_B2B_OrderDate__c, currDeliverySchedule.SBUX_B2B_ShipDate__c);
                    }
                }
            }
            // If we dont have an order date at this point, the delivery date cutoff has passed.
            if (currOrder.ccrz__OrderDate__c == null){
                throw new DeliveryDateExpiredException(cig.Id);
            }
        } else {
            currOrder.ccrz__OrderDate__c = orderDate;
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_OrderUtil:orderDate', currOrder.ccrz__OrderDate__c);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_OrderUtil:shipDate', currOrder.SBUX_B2B_ShipDate__c);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_OrderUtil:calculateOrderDateAndShipDate');
    }

    /**
     * @description Calculates the orderDate and shipDate for a CDC Order.
     */
    private static void getCDCOrderDate(ccrz__E_Order__c currOrder, Time cutOffTime, String cutOffTimeZone, Date orderDateFromDS, Date shipDateFromDS) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_OrderUtil:getCDCOrderDate');
        TimeZone tz = TimeZone.getTimeZone(SUPPORTED_TIME_ZONES.get(cutOffTimeZone));

        // Local Time at DC
        DateTime currTimeAtDC = Datetime.newInstance(System.now().getTime() + tz.getOffset(System.now()));

        // CutOff time at DC
        Integer GMTToTimeZoneOffset = tz.getOffset(Datetime.newInstanceGmt(Date.today(), Time.newInstance(0, 0, 0, 0)));
        DateTime cutoffDatetime = DateTime.newInstanceGmt(orderDateFromDS, cutOffTime);
        cutoffDatetime = DateTime.newInstance(cutoffDatetime.getTime() + (tz.getOffset(cutoffDatetime) + -1 * GMTToTimeZoneOffset));
        cutoffDatetime = cutoffDatetime.addMinutes(-90);

        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_OrderUtil:CDC-TimeZone', tz.getDisplayName());
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_OrderUtil:currTimeAtDC', currTimeAtDC);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_OrderUtil:cutOffDateTime', cutoffDatetime);

        if (currTimeAtDC <= cutoffDatetime) {
            currOrder.ccrz__OrderDate__c = orderDateFromDS;
        }

        currOrder.SBUX_B2B_ShipDate__c = shipDateFromDS;
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_OrderUtil:getCDCOrderDate');
    }

    /**
     * @description Calculates the orderDate and shipDate for a RDC Order.
     */
    private static void getRDCOrderDate(ccrz__E_Order__c currOrder, Time cutOffTime, Date orderDateFromDS, Date shipDateFromDS) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_OrderUtil:getRDCOrderDate');
        TimeZone tz = TimeZone.getTimeZone(PACIFIC_TIME_ZONE_ID);
        Datetime currPacificTime = Datetime.newInstance(System.now().getTime() + tz.getOffset(System.now()));
        DateTime cutoffDatetime = DateTime.newInstance(orderDateFromDS, cutOffTime);
        cutoffDatetime = DateTime.newInstance(cutoffDatetime.getTime() + UserInfo.getTimeZone().getOffset(cutoffDatetime));
        cutoffDatetime = cutoffDatetime.addDays(-1);

        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_OrderUtil:currPacificTime', currPacificTime);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_OrderUtil:cutOffDateTime', cutoffDatetime);

        if (currPacificTime < cutoffDatetime) {
            currOrder.ccrz__OrderDate__c = orderDateFromDS;
        }

        currOrder.SBUX_B2B_ShipDate__c = shipDateFromDS;
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_OrderUtil:getRDCOrderDate');
    }

    /**
     * @description Constructs CC Orders for all the different cart item groups.
     */
    private static Map<String, Object> buildOrderHeaders(ccrz__E_Cart__c currCart, Map<String, Object> deliveryDatesByDC) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_OrderUtil:buildOrderHeaders');
        // Maps to hold new orders for each cart item group.
        // CC Cart Item Group => New CC Order
        Map<String, Object> cartItemGroupToOrderMap = new Map<String, Object> ();
        Store__c currStore = [
                SELECT Id, Country__c
                FROM Store__c
                WHERE Id = :currCart.SBUX_B2B_Store__c
        ];
        List<ccrz__E_Order__c> ordersToInsert = new List<ccrz__E_Order__c>();

        if (!currCart.ccrz__E_CartItemGroups__r.isEmpty()) {
            for (ccrz__E_CartItemGroup__c cig : currCart.ccrz__E_CartItemGroups__r) {
                ccrz__E_Order__c currOrder = new ccrz__E_Order__c();
                currOrder.ccrz__OriginatedCart__c = currCart.Id;
                currOrder.ccrz__ShipStructure__c = currCart.ccrz__ShipStructure__c;
                currOrder.ccrz__BillTo__c = currCart.ccrz__BillTo__c;
                currOrder.ccrz__ShipTo__c = cig.ccrz__ShipTo__c;
                currOrder.ccrz__ShipMethod__c = cig.ccrz__ShipMethod__c;
                currOrder.ccrz__RequestDate__c = cig.ccrz__RequestDate__c;
                currOrder.ccrz__Name__c = cig.ccrz__GroupName__c;
                currOrder.SBUX_B2B_ReasonCode__c = cig.SBUX_B2B_ExpeditedReasonCode__c;
                currOrder.SBUX_B2B_ReasonComment__c = cig.SBUX_B2B_ExpeditedComment__c;
                currOrder.ccrz__OrderStatus__c = ORDER_SUBMITTED;
                currOrder.ccrz__CurrencyISOCode__c = currCart.ccrz__CurrencyISOCode__c;
                currOrder.ccrz__Storefront__c = currCart.ccrz__Storefront__c;

                // Buyer Info
                currOrder.ccrz__BuyerFirstName__c = currCart.ccrz__BuyerFirstName__c;
                currOrder.ccrz__BuyerLastName__c = currCart.ccrz__BuyerLastName__c;
                currOrder.ccrz__BuyerCompanyName__c = currCart.ccrz__BuyerCompanyName__c;
                currOrder.ccrz__BuyerEmail__c = currCart.ccrz__BuyerEmail__c;
                currOrder.ccrz__BuyerPhone__c = currCart.ccrz__BuyerPhone__c;
                currOrder.ccrz__BuyerMobilePhone__c = currCart.ccrz__BuyerMobilePhone__c;

                // Account/Contact/User
                currOrder.ccrz__Account__c = currCart.ccrz__Account__c;
                currOrder.ccrz__Contact__c = currCart.ccrz__Contact__c;
                currOrder.ccrz__User__c = currCart.ccrz__User__c;
                currOrder.SBUX_B2B_Store__c = currCart.SBUX_B2B_Store__c;

                // SBUX Fields
                currOrder.SBUX_B2B_PONumber__c = cig.SBUX_B2B_PONumber__c;
                currOrder.SBUX_B2B_Order_Source__c = ORDER_SOURCE_STOREFRONT;
                currOrder.SBUX_B2B_OrderPublishFlag__c = true;

                if (currStore.Country__c.equals(STORE_COUNTRY_US)) {
                    currOrder.SBUX_B2B_OrderType__c = ORDER_TYPE_STANDARD_ORDER + STORE_COUNTRY_US;
                } else if (currStore.Country__c.equals(STORE_COUNTRY_CA)) {
                    currOrder.SBUX_B2B_OrderType__c = ORDER_TYPE_STANDARD_ORDER + ORDER_COUNTRY_CANADA;
                }

                // Map this order to the current cart item group.
                cartItemGroupToOrderMap.put(cig.Id, currOrder);

                calculateOrderDateAndShipDate(currOrder, cig, deliveryDatesByDC);

                // Freight Terms
                if (currOrder.SBUX_B2B_ReasonCode__c != null && currOrder.SBUX_B2B_ReasonCode__c.equalsIgnoreCase(CUSTOMER_REQUEST)){
                    currOrder.SBUX_B2B_FreightTerms__c = PREPAY_ADD;
                } else if (currOrder.SBUX_B2B_ReasonCode__c != null){
                    currOrder.SBUX_B2B_FreightTerms__c = PREPAID;
                }

                // Stage for insert.
                ordersToInsert.add(currOrder);
            }
            insert ordersToInsert;
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_OrderUtil:buildOrderHeaders');
        return cartItemGroupToOrderMap;
    }

    /**
     * @description Constructs CC Order Item Group for the current order.
     */
    private static ccrz__E_OrderItemGroup__c buildOrderItemGroup(ccrz__E_Order__c currOrder) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_OrderUtil:buildOrderItemGroup');
        ccrz__E_OrderItemGroup__c orderItemGroup = new ccrz__E_OrderItemGroup__c();
        orderItemGroup.ccrz__Order__c = currOrder.Id;
        orderItemGroup.ccrz__GroupName__c = currOrder.ccrz__Name__c;
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_OrderUtil:buildOrderItemGroup');
        return orderItemGroup;
    }

    /**
     * @description Constructs CC Order Item for the current Cart Item
     */
    private static ccrz__E_OrderItem__c buildOrderItem(ccrz__E_Order__c currOrder, ccrz__E_OrderItemGroup__c currOrderItemGroup, ccrz__E_CartItem__c currCartItem) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_OrderUtil:buildOrderItem');
        ccrz__E_OrderItem__c orderItem = new ccrz__E_OrderItem__c();

        orderItem.ccrz__Order__c = currOrder.Id;
        orderItem.ccrz__OrderItemGroup__c = currOrderItemGroup.Id;
        orderItem.ccrz__Product__c = currCartItem.ccrz__Product__c;
        orderItem.ccrz__Price__c = currCartItem.ccrz__Price__c;
        orderItem.ccrz__OrderLineType__c = currCartItem.ccrz__cartItemType__c;
        orderItem.ccrz__Quantity__c = currCartItem.ccrz__Quantity__c;
        orderItem.ccrz__OriginalItemPrice__c = currCartItem.ccrz__OriginalItemPrice__c;
        orderItem.ccrz__OriginalQuantity__c = currCartItem.ccrz__OriginalQuantity__c;
        orderItem.ccrz__UnitOfMeasure__c = currCartItem.ccrz__UnitOfMeasure__c;
        orderItem.ccrz__SubAmount__c = currCartItem.ccrz__SubAmount__c;
        orderItem.ccrz__ItemStatus__c = currCartItem.ccrz__ItemStatus__c;
        orderItem.ccrz__ProductType__c = SIMPLE_PRODUCT;

        try {
            if (currCartItem.ccrz__Product__r.SBUX_B2B_UOMConv__c != null && currCartItem.ccrz__Product__r.SBUX_B2B_PrimaryUOM__c != null) {
                List<Object> UOMConversionMapList = (List<Object>) JSON.deserializeUntyped(currCartItem.ccrz__Product__r.SBUX_B2B_UOMConv__c);
                for (Object convMap : UOMConversionMapList) {
                    Map<String, Object> currConversionMap = (Map<String, Object>) convMap;
                    if (currConversionMap.containsKey(UOM_CONVERSION_TO_CODE)
                            && currConversionMap.containsKey(UOM_CONVERSION_FROM_CODE)
                            && currConversionMap.containsKey(UOM_CONVERSION_CONVERSION_FACTOR)
                            && ((String) currConversionMap.get(UOM_CONVERSION_FROM_CODE)).equalsIgnoreCase(currCartItem.ccrz__Product__r.SBUX_B2B_PrimaryUOM__c)
                            && ((String) currConversionMap.get(UOM_CONVERSION_TO_CODE)).equalsIgnoreCase(currCartItem.ccrz__UnitOfMeasure__c)) {
                        Integer conversionFactor = (Integer) currConversionMap.get(UOM_CONVERSION_CONVERSION_FACTOR);
                        if (conversionFactor != null) {
                            orderItem.SBUX_B2B_Primary_UOM_Quantity__c = conversionFactor * orderItem.ccrz__Quantity__c;
                            orderItem.SBUX_Primary_UOM__c = currCartItem.ccrz__Product__r.SBUX_B2B_PrimaryUOM__c;
                        }
                    }
                }
            }
        } catch (Exception e) {
            // This is for bad UOM Conversion data. Ex: Bad JSON.
        }

        // Fallback: Primary UOM Qty = Regular quantity
        if (orderItem.SBUX_B2B_Primary_UOM_Quantity__c == null) {
            orderItem.SBUX_B2B_Primary_UOM_Quantity__c = orderItem.ccrz__Quantity__c;
            orderItem.SBUX_Primary_UOM__c = currCartItem.ccrz__UnitOfMeasure__c;
        }

        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_OrderUtil:buildOrderItem');
        return orderItem;
    }

    /**
     * @description Constructs CC Order Items for the current order and assigns them the default order item group.
     */
    private static List<ccrz__E_OrderItem__c> buildOrderItems(List<ccrz__E_CartItem__c> cartItems, Map<String, Object> cartItemGroupToOrderMap) {
        // Map to hold order Item group for each order
        // CC Order => CC Order Item Group
        Map<String, Object> orderToOrderItemGroupMap = new Map<String, Object> ();
        List<ccrz__E_OrderItem__c> orderItemsToInsert = new List<ccrz__E_OrderItem__c>();

        for (ccrz__E_CartItem__c currCartItem : cartItems) {
            // Get the order for this cart Item.
            ccrz__E_Order__c associatedOrder = (ccrz__E_Order__c) cartItemGroupToOrderMap.get(currCartItem.ccrz__CartItemGroup__c);

            // Get the order Item group. If null, create new.
            ccrz__E_OrderItemGroup__c associatedOrderItemGroup = (ccrz__E_OrderItemGroup__c) orderToOrderItemGroupMap.get(associatedOrder.Id);
            if (associatedOrderItemGroup == null) {
                associatedOrderItemGroup = buildOrderItemGroup(associatedOrder);
                insert associatedOrderItemGroup;
                orderToOrderItemGroupMap.put(associatedOrder.Id, associatedOrderItemGroup);
            }

            ccrz__E_OrderItem__c currOrderItem = buildOrderItem(associatedOrder, associatedOrderItemGroup, currCartItem);
            orderItemsToInsert.add(currOrderItem);
        }
        return orderItemsToInsert;
    }

    /**
     * @description Breaks a CC Cart into multiple orders for each of the different cart item group.
     */
    public static String convertCartToMultipleOrders() {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_OrderUtil:convertCartToMultipleOrders');
        String placeTargetOrderSFID = '';
        Map<String, Object> cartFetchResponse = fetchCart();

        //check the fetch response to see if cart data was returned
        if (!((Boolean) cartFetchResponse.get(ccrz.ccAPI.SUCCESS)) || !cartFetchResponse.containsKey(ccrz.ccAPICart.CART_OBJLIST) || ((List<ccrz__E_Cart__c>) cartFetchResponse.get(ccrz.ccAPICart.CART_OBJLIST) == null) || ((List<ccrz__E_Cart__c>) cartFetchResponse.get(ccrz.ccAPICart.CART_OBJLIST)).isEmpty()) {
            return placeTargetOrderSFID;
        }
        Map<String, List<ccrz__E_CartItem__c>> cartItemsByCartId = (Map<String, List<ccrz__E_CartItem__c>>) cartFetchResponse.get(ccrz.ccAPICart.CARTITEMSBYID);
        List<ccrz__E_Cart__c>cartList = (List<ccrz__E_Cart__c>) cartFetchResponse.get(ccrz.ccAPICart.CART_OBJLIST);

        //grab the first cart and its cart Items
        ccrz__E_Cart__c currCart = cartList[0];
        List<ccrz__E_CartItem__c> cartItems = cartItemsByCartId.get(currCart.Id);

        Map<String, Object> deliveryDatesByDC = getDeliveryDatesByDC();

        // Maps to hold new orders for each cart item group.
        // CC Cart Item Group => New CC Order
        Map<String, Object> cartItemGroupToOrderMap = buildOrderHeaders(currCart, deliveryDatesByDC);

        List<ccrz__E_OrderItem__c> orderItemsToInsert = buildOrderItems(cartItems, cartItemGroupToOrderMap);
        insert orderItemsToInsert;

        // Close Cart.
        currCart.ccrz__ActiveCart__c = false;
        currCart.ccrz__CartStatus__c = CLOSED;
        update currCart;

        // Get return URL
        ccrz__E_Order__c orderToReturn = [
                SELECT ccrz__EncryptedId__c
                FROM ccrz__E_Order__c
                WHERE ccrz__OriginatedCart__c = :currCart.Id
                LIMIT 1
        ];

        PageReference viewPage = Page.ccrz__OrderConfirmation;
        viewPage.getParameters().put('o', orderToReturn.ccrz__EncryptedId__c);
        String placeTarget = viewPage.getURL().removeStart('/apex/');

        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_OrderUtil:convertCartToMultipleOrders');
        return placeTarget;
    }

    /**
     * @description Constructs a Map of delivery date to SBUX_B2B_DeliverySchedule__c, grouped by DC type.
     */
    public static Map<String, Object> getDeliveryDatesByDC() {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_OrderUtil:getDeliveryDatesByDC');

        Map<String, Object> result = new Map<String, Object> ();

        List<SBUX_B2B_DeliverySchedule__c> deliveryScheduleList = SBUX_B2B_StorefrontUtil.fetchStoreDeliverySchedule();

        for (SBUX_B2B_DeliverySchedule__c ds : deliveryScheduleList) {
            String currDC = String.valueOf(ds.SBUX_B2B_DPNumber__c).substring(0, 3);

            if (!SUPPORTED_DC_TYPES.contains(currDC)) {
                continue;
            }

            Map<String, Object> enabledDaysForCurrDC = (Map<String, Object>) result.get(currDC);
            if (enabledDaysForCurrDC == null) {
                enabledDaysForCurrDC = new Map<String, Object> ();
                result.put(currDC, enabledDaysForCurrDC);
            }
            Date currDate = ds.SBUX_B2B_DeliveryDate__c;
            if (currDate >= Date.today() && currDate <= Date.today().addMonths(1)) {
                Datetime dt = Datetime.newInstance(currDate.year(), currDate.month(), currDate.day());
                Date orderDate = ds.SBUX_B2B_OrderDate__c;
                if ((currDC.equalsIgnoreCase(CDC) || currDC.equalsIgnoreCase(KIT)) && orderDate >= System.today()){
                    enabledDaysForCurrDC.put(dt.format(DATE_FORMAT), ds);
                } else if (currDC.equalsIgnoreCase(RDC) && orderDate > System.today()){
                    enabledDaysForCurrDC.put(dt.format(DATE_FORMAT), ds);
                }
            }
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_OrderUtil:getDeliveryDatesByDC');
        return result;
    }
}