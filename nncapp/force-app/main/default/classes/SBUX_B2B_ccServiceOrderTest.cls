/**
 * Created by dgajwani on 3/24/20.
 */
@isTest
public with sharing class SBUX_B2B_ccServiceOrderTest {

    private static final String ORDER_STATUS_ORDER_SUBMITTED = 'Order Submitted';
    private static final String ORDER_TYPE_RETURN = 'RMA Cr Only - US';
    private static final String ORDER_ITEM_RETURN_REASON = 'DAMAGE';
    private static final String STOREFRONT_DEFAULT = 'DefaultStore';


    public static Map<String, Object> testData;

    public static void setupTestData() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        Store__c testStore = (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        List<ccrz__E_Product__c> testProducts = (List<ccrz__E_Product__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        SBUX_B2B_TestDataFactory.createInsertItemDCSourcing(testProducts[0]);
        SBUX_B2B_TestDataFactory.createInsertDeliverySchedules(testStore);
        SBUX_B2B_TestDataFactory.createInsertStoreDCSourcing(testStore);
    }

    @IsTest
    public static void testOrderFetchPublishFlagN() {
        setupTestData();
        SBUX_B2B_TestDataFactory.createInsertTestOrder(testData);

        Map<String, Object> orderFetchRequest = new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccAPIOrder.PARAM_ORDER_STATUS => ORDER_STATUS_ORDER_SUBMITTED,
                SBUX_B2B_ccServiceOrder.ORDER_PULL_REST_API_FLAG => true,
                SBUX_B2B_ccServiceOrder.ORDER_PUBLISH_FLAG_KEY => false
        };
        Map<String, Object> orderFetchResponse;

        Test.startTest();
        orderFetchResponse = ccrz.ccAPIOrder.fetch(orderFetchRequest);
        Test.stopTest();

        System.assertNotEquals(null, orderFetchResponse);
        System.assertEquals(true, (Boolean) orderFetchResponse.get(ccrz.ccAPI.SUCCESS));
        System.assertNotEquals(false, orderFetchResponse.containsKey(ccrz.ccAPIOrder.ORDERLIST));

        List<Map<String, Object>> orderList = (List<Map<String, Object>>) orderFetchResponse.get(ccrz.ccAPIOrder.ORDERLIST);
        System.assertEquals(1, orderList.size());
    }

    @IsTest
    public static void testOrderFetchPublishFlagY() {
        setupTestData();
        SBUX_B2B_TestDataFactory.createInsertTestOrder(testData);

        Map<String, Object> orderFetchRequest = new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccAPIOrder.PARAM_ORDER_STATUS => ORDER_STATUS_ORDER_SUBMITTED,
                SBUX_B2B_ccServiceOrder.ORDER_PULL_REST_API_FLAG => true,
                SBUX_B2B_ccServiceOrder.ORDER_PUBLISH_FLAG_KEY => true
        };
        Map<String, Object> orderFetchResponse;

        Test.startTest();
        orderFetchResponse = ccrz.ccAPIOrder.fetch(orderFetchRequest);
        Test.stopTest();

        System.assertNotEquals(null, orderFetchResponse);
        System.assertEquals(true, (Boolean) orderFetchResponse.get(ccrz.ccAPI.SUCCESS));
        System.assertNotEquals(false, orderFetchResponse.containsKey(ccrz.ccAPIOrder.ORDERLIST));

        List<Map<String, Object>> orderList = (List<Map<String, Object>>) orderFetchResponse.get(ccrz.ccAPIOrder.ORDERLIST);
        System.assertEquals(0, orderList.size());
    }

    @isTest
    public static void testFetchRelatedOrdersForOrderConfirmation() {
        setupTestData();

        Map<String, Object> orderFetchRequest;
        String currCartENCID;

        Test.startTest();
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            ctx.userLocale = 'en_US';
            ctx.userIsoCode = 'USD';
            ctx.currentPageName = SBUX_B2B_ccServiceOrder.ORDER_CONFIRMATION_PAGE;

            ccrz.cc_CallContext.init(ctx);

            Map<String, Object> addToCartResult = ccrz.ccApiCart.addTo(new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccApiCart.LINE_DATA => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                    ccrz.ccApiCart.LINE_DATA_SKU => SBUX_B2B_TestDataFactory.TEST_SKU + 0,
                                    ccrz.ccApiCart.LINE_DATA_QUANTITY => 3
                            },
                            new Map<String, Object>{
                                    ccrz.ccApiCart.LINE_DATA_SKU => SBUX_B2B_TestDataFactory.TEST_SKU + 1,
                                    ccrz.ccApiCart.LINE_DATA_QUANTITY => 1
                            }
                    }
            });

            currCartENCID = (String) addToCartResult.get(ccrz.ccApiCart.CART_ENCID);

            // Mark a cart item EO.
            List<ccrz__E_CartItem__c> currCartItems = [
                    SELECT Id
                    FROM ccrz__E_CartItem__c
                    WHERE ccrz__Product__r.ccrz__SKU__c = :SBUX_B2B_TestDataFactory.TEST_SKU + 1
            ];
            currCartItems[0].SBUX_B2B_Is_Emergency__c = true;
            update currCartItems[0];

            ccrz.ccApiCart.initItemGroups(new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccAPICart.CART_ENCID => currCartENCID
            });

            List<ccrz__E_CartItemGroup__c> cartItemGroups = [
                    SELECT Id
                    FROM ccrz__E_CartItemGroup__c
                    WHERE ccrz__Cart__r.ccrz__EncryptedId__c = :currCartENCID
            ];
            for (ccrz__E_CartItemGroup__c cig : cartItemGroups){
                cig.ccrz__RequestDate__c = Date.today().addDays(12);
            }
            update cartItemGroups;

            SBUX_B2B_CheckoutCtrl.placeOrder(ctx);

            ccrz__E_Order__c currOrder = [
                    SELECT Id, ccrz__EncryptedId__c
                    FROM ccrz__E_Order__c
                    LIMIT 1
            ];

            orderFetchRequest = ccrz.ccApiOrder.fetch(new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccAPIOrder.PARAM_ORDER_ENCID => currOrder.ccrz__EncryptedId__c
            });
        }

        Test.stopTest();

        // Verify 2 orders
        List<ccrz__E_Order__c> allOrders = [SELECT Id FROM ccrz__E_Order__c];
        System.assertEquals(2, allOrders.size());

        System.assertEquals(true, (Boolean) orderFetchRequest.get(ccrz.ccApi.SUCCESS));

        List<Map<String, Object>> originalOrderList = (List<Map<String, Object>>) orderFetchRequest.get(ccrz.ccAPIOrder.ORDERLIST);
        System.assertEquals(1, originalOrderList.size());

        Map<String, Object> originalOrder = originalOrderList[0];
        List<Map<String, Object>> originalOrderItems = (List<Map<String, Object>>) originalOrder.get(SBUX_B2B_ccServiceOrder.ORDER_ITEMS);
        List<Map<String, Object>> originalOrderItemGroups = (List<Map<String, Object>>) originalOrder.get(SBUX_B2B_ccServiceOrder.ORDER_ITEM_GROUPS);

        System.assertEquals(2, originalOrderItems.size());
        System.assertEquals(2, originalOrderItemGroups.size());
    }

    @IsTest
    public static void testOrderFetchCalculateReturnQty() {
        setupTestData();
        SBUX_B2B_TestDataFactory.createInsertTestOrder(testData);

        Map<String, Object> orderFetchRequest = new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccAPIOrder.PARAM_ORDER_STATUS => ORDER_STATUS_ORDER_SUBMITTED
        };
        Map<String, Object> orderFetchResponse;

        Test.startTest();
        orderFetchResponse = ccrz.ccAPIOrder.fetch(orderFetchRequest);

        List<Map<String, Object>> orderList = (List<Map<String, Object>>) orderFetchResponse.get(ccrz.ccAPIOrder.ORDERLIST);
        String orderId = (String) orderList[0].get('sfid');
        List<Map<String, Object>> orderItemList = (List<Map<String, Object>>) orderList[0].get('EOrderItemsS');

        //replicate returnLineMap as it would come from OrderViewCtrl
        Map<String, Object> returnLineMap = new Map<String, Object>();
        Map<String, Map<String, Object>> returnLinesMap = new Map<String, Map<String, Object>>();
        returnLineMap.put('sfid', (String) orderItemList[0].get('sfid'));
        returnLineMap.put('rtnQty', 1);
        returnLineMap.put('rtnReason', ORDER_ITEM_RETURN_REASON);
        returnLineMap.put('price', 50);
        returnLinesMap.put((String) orderItemList[0].get('sfid'), returnLineMap);

        //call controller to create credit order w/ matching line item
        ccrz.cc_RemoteActionContext remoteCtx = new ccrz.cc_RemoteActionContext();
        remoteCtx.currentPageName = SBUX_B2B_ccServiceOrder.STOREFRONT_ORDERVIEW_PAGENAME;
        remoteCtx.storefront = STOREFRONT_DEFAULT;
        SBUX_B2B_OrderViewCtrl.createReturnOrder(remoteCtx, orderId, JSON.serialize(returnLinesMap));

        //fetch both orders
        Map<String, Object> creditFetchRequest = new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION
        };
        Map<String, Object> creditFetchResponse;
        creditFetchResponse = ccrz.ccAPIOrder.fetch(creditFetchRequest);
        Test.stopTest();

        //get return list with original order + credit order, search for rtnQty
        List<Map<String, Object>> returnList = (List<Map<String, Object>>) creditFetchResponse.get(ccrz.ccAPIOrder.ORDERLIST);
        Decimal returnQtyCheck;
        for (Map<String, Object> returnOrder : returnList) {
            List<Map<String, Object>> returnItemList = (List<Map<String, Object>>) returnOrder.get('EOrderItemsS');
            if (returnItemList[0].get('returnQtyTotal') <> null)
                returnQtyCheck = (Decimal) returnItemList[0].get('returnQtyTotal');
        }

        //validate returnQtyTotal got populated (from our line item on the credit order)
        system.assert(returnQtyCheck > 0);
    }

    @IsTest
    public static void testOrderFetchInvoicePDF() {
        setupTestData();
        Map<String, Object> orderResponse = SBUX_B2B_TestDataFactory.createInsertTestOrder(testData);
        String orderId = (String)orderResponse.get('orderId');

        //prep fetch + set call context
        Map<String, Object> orderFetchRequest = new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccAPIOrder.PARAM_ORDER_STATUS => ORDER_STATUS_ORDER_SUBMITTED
        };
        Map<String, Object> orderFetchResponse;

        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        ctx.currentPageName = SBUX_B2B_ccServiceOrder.STOREFRONT_ORDERVIEW_PAGENAME;
        ccrz.cc_CallContext.init(ctx);

        //insert test ContentVersion & ContentLink
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;

        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1];
        //List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id =: contentVersionSelect.ContentDocumentId];

        ContentDocumentLink contentLinkInsert = new ContentDocumentLink(
            LinkedEntityId = orderId,
            ContentDocumentId = contentVersionSelect.ContentDocumentId
        );
        insert contentLinkInsert;

        //fetch order (w invoice)
        Test.startTest();
        orderFetchResponse = ccrz.ccAPIOrder.fetch(orderFetchRequest);
        Test.stopTest();
        
        //asserts
        System.assertEquals(true, (Boolean) orderFetchRequest.get(ccrz.ccApi.SUCCESS));
        List<Map<String, Object>> orderList = (List<Map<String, Object>>) orderFetchRequest.get(ccrz.ccAPIOrder.ORDERLIST);
        Map<String, Object> fetchOrder = orderList[0];
        System.assert(fetchOrder.get(SBUX_B2B_ccServiceOrder.INVOICE_KEY) <> null);
    }

}