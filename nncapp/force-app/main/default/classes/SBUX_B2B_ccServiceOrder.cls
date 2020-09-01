/**
 * Created by dgajwani on 3/18/20.
 */

global with sharing class SBUX_B2B_ccServiceOrder extends ccrz.ccServiceOrder {

    private static final String ORDER_HISTORY_LAST_N_DAYS = '90';
    public static final String CHECKOUT_PAGE = 'ccrz__Checkout';
    private static final String ORDER_ITEM_GROUP_SUBQUERY = '(SELECT Order__c,GroupName__c,Note__c,RequestDate__c,ShipAmount__c,ShipTo__c,ShipMethod__c, Order__r.ShipMethod__c,Order__r.SBUX_B2B_PONumber__c, Order__r.Name,Order__r.ccrz__RequestDate__c,Order__r.SBUX_B2B_ReasonCode__c,Order__r.SBUX_B2B_ReasonComment__c FROM E_OrderItemGroups__r)';
    public static final String ORDER_PUBLISH_FLAG_KEY = 'SBUXB2BOrderPublishFlag';
    public static final String ORDER_PULL_REST_API_FLAG = 'orderPullRESTAPICall';
    public static final String ORDER_PUBLISH_FLAG_FILTER = 'orderPublishFlagFilter';
    private static final String EXTERNAL_ORDER_STATUS_FILTER = 'externalOrderStatusFilter';
    private static final String ORDER_TYPE_RETURN_US = 'RMA Cr Only - US';
    private static final String ORDER_TYPE_RETURN_CAN = 'RMA Cr Only - CAN';
    private static final String ORDER_STATUS_CANCELLED = 'Cancelled';
    public static final String ORDER_CONFIRMATION_PAGE = 'ccrz__OrderConfirmation';
    public static final String ORDER_ITEMS = 'EOrderItemsS';
    public static final String ORDER_ITEM_GROUPS = 'EOrderItemGroupsS';
    private static final String PRODUCT_LIST = 'productList';
    private static final String ORDER_ITEM_GROUP_SUBQUERY_KEY = 'E_OrderItemGroups__r';
    public static final String STOREFRONT_ORDERVIEW_PAGENAME = 'ccrz__OrderView';
    public static final String STOREFRONT_MYACCOUNT_PAGENAME = 'ccrz__MyAccount';
    private static final String ORDER_DATE_FILTER = 'orderDateAgeFilter';
    public static final String INVOICE_KEY = 'invoiceBase64';
    private static final String EO_REASON_LABEL = 'label';
    private static final String EO_REASON_VALUE = 'value';
    private static final String EO_REASON_CODES = 'availableReasonCodes';
    private static final String SITE_ID_FILTER = 'siteIDCheck';
    private static final String ADDRESS_CHECK = 'addressCheck';
    private static final String OWNER_ID_FILTER = 'ownerId';

    /**
     * @description Fetches custom fields from the CC Order object.
     */
    global override Map<String, Object> getFieldsMap(Map<String, Object> inputData) {
        // Get OOTB Fields Map.
        Map<String, Object> outputData = super.getFieldsMap(inputData);

        // Add custom fields
        String fields = (String) outputData.get(ccrz.ccService.OBJECTFIELDS);
        fields += ',SBUX_B2B_OrderPublishFlag__c';
        fields += ',SBUX_B2B_OrderExternalStatus__c';
        fields += ',SBUX_B2B_OrderType__c';
        fields += ',SBUX_B2B_PONumber__c';
        fields += ',SBUX_B2B_ReasonCode__c';
        fields += ',SBUX_B2B_ReasonComment__c';
        fields += ',SBUX_B2B_ShipDate__c';
        fields += ',SBUX_B2B_ShipPriority__c';
        fields += ',SBUX_B2B_FreightTerms__c';
        fields += ',SBUX_B2B_Order_Source__c';
        fields += ',ccrz__ShipTo__r.SBUX_B2B_AccountNumber__c';
        fields += ',ccrz__ShipTo__r.SBUX_B2B_SiteId__c';
        fields += ',ccrz__BillTo__r.SBUX_B2B_AccountNumber__c';
        fields += ',ccrz__BillTo__r.SBUX_B2B_SiteId__c';
        fields += ',SBUX_B2B_Distribution_Center_Code__c';

        outputData.put(ccrz.ccService.OBJECTFIELDS, fields);
        return outputData;
    }

    global override Map<String, Object> getSubQueryMap(Map<String, Object> inputData) {
        Map<String, Object> subQueryMap = super.getSubQueryMap(inputData);
        String cartItemGroupSubQuery = ORDER_ITEM_GROUP_SUBQUERY;
        subQueryMap.put(ORDER_ITEM_GROUP_SUBQUERY_KEY, cartItemGroupSubQuery);
        return subQueryMap;
    }

    /**
     * @description Adds additional filters on CC Order queries as required by the REST API integrations.
     */
    global override Map<String, Object> getFilterMap(Map<String, Object> inputData) {
        // Get OOTB Filter Map.
        Map<String, Object> outputData = super.getFilterMap(inputData);

        // Add special flag for Order Pull Integration into Oracle.
        if (inputData.containsKey(ORDER_PULL_REST_API_FLAG) && (Boolean) inputData.get(ORDER_PULL_REST_API_FLAG)) {
            // Check for Order Publish Flag, if we have it, add it to the filter map.
            if (inputData.containsKey(ORDER_PUBLISH_FLAG_KEY)) {
                outputData.put(ORDER_PUBLISH_FLAG_FILTER, ' AND SBUX_B2B_OrderPublishFlag__c = :SBUXB2BOrderPublishFlag');
            }
            // Check External Order Status
            outputData.put(EXTERNAL_ORDER_STATUS_FILTER, ' AND (SBUX_B2B_OrderExternalStatus__c = NULL OR SBUX_B2B_OrderExternalStatus__c = \'ERROR-NEEDS ATTENTION\')');
        } else {
            // Apply these only if its for the storefront user.
            // If the contact's address field is populated, we remove the order ownership check and use this instead
            Contact currContact = [
                    SELECT Id, SBUX_B2B_Store_ShipTo_Address__c, SBUX_B2B_Store_ShipTo_Address__r.Site_Id__c
                    FROM Contact
                    WHERE Id = :ccrz.cc_CallContext.currContact.Id
            ];
            ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_ccServiceOrder:getFilterMap:currContact', currContact);
            // Check if we have an address populated on the contact, if we do use that to filter instead of owner.
            if (currContact != null && currContact.SBUX_B2B_Store_ShipTo_Address__c != null && currContact.SBUX_B2B_Store_ShipTo_Address__r.Site_Id__c != null){
                outputData.remove(OWNER_ID_FILTER);
                inputData.put(SITE_ID_FILTER, currContact.SBUX_B2B_Store_ShipTo_Address__r.Site_Id__c);
                outputData.put(ADDRESS_CHECK, ' AND ccrz__ShipTo__r.SBUX_B2B_SiteId__c = :siteIDCheck');
            }
        }

        //cap orderList by OrderDate(Age)
        outputData.put(ORDER_DATE_FILTER, ' AND CreatedDate = LAST_N_DAYS:' + ORDER_HISTORY_LAST_N_DAYS);

        return outputData;
    }

    /**
     * @description Adds additional mapping for OrderView page - calcs ReturnQtys for the CreditRequest process
     */
    global override Map<String, Object> fetch(Map<String, Object> inputData) {
        Map<String, Object> outputData = super.fetch(inputData);
        addRelatedOrdersToFetchForOrderConfirmation(inputData);
        if (ccrz.cc_CallContext.currPageName <> null && ccrz.cc_CallContext.currPageName == STOREFRONT_ORDERVIEW_PAGENAME) {
            outputData = addReturnQtyTotal(outputData);
        }
        addRelatedInvoiceContent(outputData);
        includeEOReasonCodeLabels(outputData);
        return outputData;
    }

    public static void includeEOReasonCodeLabels(Map<String, Object> outputData) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccServiceOrder:includeEOReasonCodeLabels');
        List<Map<String, Object>> availableEOReasonCodes = new List<Map<String, Object>>();
        Schema.DescribeFieldResult reasonCodeDescribe = ccrz__E_Order__c.SBUX_B2B_ReasonCode__c.getDescribe();
        List<Schema.PicklistEntry> reasonCodePicklistValues = reasonCodeDescribe.getPicklistValues();
        for (Schema.PicklistEntry plValue : reasonCodePicklistValues) {
            availableEOReasonCodes.add(new Map<String, Object>{
                    EO_REASON_LABEL => plValue.getLabel(),
                    EO_REASON_VALUE => plValue.getValue()
            });
        }
        outputData.put(EO_REASON_CODES, availableEOReasonCodes);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccServiceOrder:includeEOReasonCodeLabels');
    }

    /**
     * @description Calculates 'Credit Qty Total' from related 'Credit' Orders by Line
     */
    private Map<String, Object> addReturnQtyTotal(Map<String, Object> outputdata) {
        List<Map<String, Object>> orderList = (List<Map<String, Object>>) outputData.get('orderList');

        if (orderList <> null && orderList.size() > 0) {
            Map<String, Object> currOrder = orderList[0];
            List<Map<String, Object>> currLines = (List<Map<String, Object>>) currOrder.get('EOrderItemsS');

            //get originalOrderId
            String originalOrderId = (String) currOrder.get('sfid');

            //query for related returned lines (non-cancelled)
            List<ccrz__E_OrderItem__c> returnLines = new List<ccrz__E_OrderItem__c>([
                    SELECT Id,Name,ccrz__ParentOrderItem__c,ccrz__Quantity__c,ccrz__OrderItemStatus__c
                    FROM ccrz__E_OrderItem__c
                    WHERE ccrz__Order__r.ccrz__Order__c = :originalOrderId AND
                    ccrz__OrderItemStatus__c <> :ORDER_STATUS_CANCELLED AND
                    (ccrz__Order__r.SBUX_B2B_OrderType__c = :ORDER_TYPE_RETURN_US OR
                    ccrz__Order__r.SBUX_B2B_OrderType__c = :ORDER_TYPE_RETURN_CAN)
            ]);

            if (returnLines.size() > 0) {
                for (Map<String, Object> line : currLines) {
                    String originalLineId = (String) line.get('sfid');

                    //get returnQty total for this original order line
                    Decimal returnQtyTotal = 0;
                    for (ccrz__E_OrderItem__c returnLine : returnLines) {
                        if (returnLine.ccrz__ParentOrderItem__c == originalLineId && returnLine.ccrz__Quantity__c <> null) {
                            if (returnLine.ccrz__Quantity__c > 0)
                                returnQtyTotal += returnLine.ccrz__Quantity__c;
                            if (returnLine.ccrz__Quantity__c < 0)
                                returnQtyTotal -= returnLine.ccrz__Quantity__c;
                        }
                    }

                    //set totalReturn (by line)
                    line.put('returnQtyTotal', returnQtyTotal);
                }
            }
        }
        return outputData;
    }

    /**
     * @description Fetches related orders for the order confirmation page.
     */
    private static void addRelatedOrdersToFetchForOrderConfirmation(Map<String, Object> inputData) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccServiceOrder:addRelatedOrdersToFetchForOrderConfirmation');
        if (ccrz.cc_CallContext.currPageName != null && ccrz.cc_CallContext.currPageName == ORDER_CONFIRMATION_PAGE) {
            if (inputData.containsKey(ccrz.ccAPIOrder.PARAM_ORDER_ENCID)) {
                // Get the current order
                ccrz__E_Order__c currOrder = [
                        SELECT Id, ccrz__OriginatedCart__c
                        FROM ccrz__E_Order__c
                        WHERE ccrz__EncryptedId__c = :(String) inputData.remove(ccrz.ccAPIOrder.PARAM_ORDER_ENCID)
                        LIMIT 1
                ];

                // Check for related orders.
                Set<String> orderEncIdsToFetch = new Set<String>();
                if (currOrder.ccrz__OriginatedCart__c != null) {
                    List<ccrz__E_Order__c> relatedOrders = [
                            SELECT Id, ccrz__EncryptedId__c
                            FROM ccrz__E_Order__c
                            WHERE ccrz__OriginatedCart__c = :currOrder.ccrz__OriginatedCart__c
                            AND Id != :currOrder.Id
                    ];

                    for (ccrz__E_Order__c relatedOrder : relatedOrders) {
                        orderEncIdsToFetch.add(relatedOrder.ccrz__EncryptedId__c);
                    }

                }

                if (!orderEncIdsToFetch.isEmpty()) {
                    // Gather the OrderList, OrderItemsList, ProductList from the original fetch. All related order data will be appended.
                    List<Map<String, Object>> originalOrderList = (List<Map<String, Object>>) inputData.get(ccrz.ccAPIOrder.ORDERLIST);
                    Map<String, Object> originalOrder = originalOrderList[0];
                    List<Map<String, Object>> originalOrderItems = (List<Map<String, Object>>) originalOrder.get(ORDER_ITEMS);
                    List<Map<String, Object>> originalOrderItemGroups = (List<Map<String, Object>>) originalOrder.get(ORDER_ITEM_GROUPS);
                    List<Map<String, Object>> originalProductList = (List<Map<String, Object>>) inputData.get(PRODUCT_LIST);

                    Map<String, Object> relatedOrdersFetch = ccrz.ccAPIOrder.fetch(new Map<String, Object>{
                            ccrz.ccAPI.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                            ccrz.ccAPIOrder.PARAM_ORDER_ENCID_LIST => orderEncIdsToFetch
                    });

                    if ((Boolean) relatedOrdersFetch.get(ccrz.ccApi.SUCCESS) && relatedOrdersFetch.containsKey(ccrz.ccAPIOrder.ORDERLIST)) {
                        List<Map<String, Object>> relatedOrderData = (List<Map<String, Object>>) relatedOrdersFetch.get(ccrz.ccAPIOrder.ORDERLIST);
                        for (Map<String, Object> relatedOrder : relatedOrderData) {
                            List<Map<String, Object>> currOrderItems = (List<Map<String, Object>>) relatedOrder.get(ORDER_ITEMS);
                            List<Map<String, Object>> currOrderItemGroups = (List<Map<String, Object>>) relatedOrder.get(ORDER_ITEM_GROUPS);

                            originalOrderItems.addAll(currOrderItems);
                            originalOrderItemGroups.addAll(currOrderItemGroups);
                        }
                        List<Map<String, Object>> currProductList = (List<Map<String, Object>>) relatedOrdersFetch.get(PRODUCT_LIST);
                        originalProductList.addAll(currProductList);
                    }
                }
            }
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccServiceOrder:addRelatedOrdersToFetchForOrderConfirmation');
    }

    /**
     * @description Fetches related InvoicePDF ContentDocuments for OrderHistory/OrderView
     *      ContentDocument MUST be of type 'PDF'
     *      AT LEAST 1 ContentVersion MUST have 'isMajorVersion = true'
     */
    private static void addRelatedInvoiceContent(Map<String, Object> outputdata) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccServiceOrder:addRelatedInvoiceContent');
        List<Object> orderObjectList = outputData.containsKey('orderList') ? (List<Object>) outputData.get('orderList') : null;

        //check if (OrderView) || (MyAccount && NOT(single orderId))
        if (ccrz.cc_CallContext.currPageName != null && outputData.containsKey('orderList') &&
                (ccrz.cc_CallContext.currPageName == STOREFRONT_ORDERVIEW_PAGENAME ||
                        (ccrz.cc_CallContext.currPageName == STOREFRONT_MYACCOUNT_PAGENAME && orderObjectList.size() > 1))) {
            //get all orderIds
            List<Map<String, Object>> orderList = (List<Map<String, Object>>) outputData.get('orderList');
            if (orderList <> null && !orderList.isEmpty()) {
                //build list of orderIds
                List<String> orderIdList = new List<String>();
                for (Map<String, Object> order : orderList) {
                    String orderId = (String) order.get('sfid');
                    orderIdList.add(orderId);
                }

                if (!orderIdList.isEmpty()) {
                    //query for related ContentDocuments (PDFs Only)
                    List<ContentDocumentLink> documentList = [
                            SELECT ContentDocumentId, LinkedEntityId, ContentDocument.title, ContentDocument.FileType, ContentDocument.createdDate
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN :orderIdList
                            AND ContentDocument.FileType = 'PDF'
                            ORDER BY ContentDocument.createdDate DESC
                    ];
                    //build documentMap with ONE (most recent) PDF file for each Order, and linkedDocList of their id's
                    Map<String, String> documentMap = new Map<String, String>();
                    List<String> linkedDocList = new List<String>();
                    for (ContentDocumentLink cdl : documentList) {
                        if (!documentMap.containsKey(cdl.LinkedEntityId)) {
                            documentMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                            linkedDocList.add(cdl.ContentDocumentId);
                        }
                    }

                    //build Map ContentVersion(UTF-8), isMajorVersions Only, by ContentDocumentId
                    Map<String, Object> versionMap = new Map<String, Object>();
                    for (ContentVersion version : [
                            SELECT Id, ContentDocumentId, VersionData
                            FROM ContentVersion
                            WHERE ContentDocumentId IN :linkedDocList
                            AND IsMajorVersion = true
                    ]) {
                        //convert VersionData to base64, place in Map by ContentDocId
                        String base64value = EncodingUtil.base64Encode(version.VersionData);
                        versionMap.put(version.ContentDocumentId, base64value);
                    }

                    //put contentVersion.base64 String into matching orderMap
                    for (Map<String, Object> order : orderList) {
                        String orderId = (String) order.get('sfid');
                        if (documentMap.containsKey(orderId)) {
                            order.put(INVOICE_KEY, versionMap.get(documentMap.get(orderId)));
                        }
                    }
                }
            }
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccServiceOrder:addRelatedInvoiceContent');
    }
}