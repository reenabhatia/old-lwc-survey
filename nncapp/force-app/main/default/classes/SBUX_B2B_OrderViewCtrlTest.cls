@isTest
private class SBUX_B2B_OrderViewCtrlTest{

    private static final String ORDER_STATUS_ORDER_SUBMITTED = 'Order Submitted';
    private static final String ORDER_TYPE_RETURN = 'RMA Cr Only - US';
    private static final String ORDER_ITEM_RETURN_REASON = 'DAMAGE';
    public static Map<String, Object> testData;

    public static void setupTestData(){
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        SBUX_B2B_TestDataFactory.createInsertTestOrder(testData);
    }

    @IsTest
    public static void testSubmit(){
        setupTestData();

        Map<String, Object> orderFetchRequest = new Map<String, Object> {
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccAPIOrder.PARAM_ORDER_STATUS => ORDER_STATUS_ORDER_SUBMITTED
        };
        Map<String, Object> orderFetchResponse;

        Test.startTest();
        orderFetchResponse = ccrz.ccAPIOrder.fetch(orderFetchRequest);

        //get ids from fetch response
        List<Map<String, Object>> orderList = (List<Map<String, Object>>) orderFetchResponse.get(ccrz.ccAPIOrder.ORDERLIST);
        String orderId = (String)orderList[0].get('sfid');
        List<Map<String,Object>> orderItemList = (List<Map<String,Object>>)orderList[0].get('EOrderItemsS');
        String orderItemId = (String)orderItemList[0].get('sfid');

        //replicate returnLineMap as it would come from OrderViewCtrl
        Map<String,Object> returnLineMap = new Map<String,Object>();
        returnLineMap.put('sfid',orderItemId);
        returnLineMap.put('rtnQty',1);
        returnLineMap.put('rtnReason',ORDER_ITEM_RETURN_REASON);
        returnLineMap.put('price',50);
        
        //emulate map from HTML
        Map<String,Map<String,Object>> returnLinesMap = new Map<String,Map<String,Object>>();
        returnLinesMap.put(orderItemId,returnLineMap);
        String returnLinesJSON = JSON.serialize(returnLinesMap);
        
        //call controller
        ccrz.cc_RemoteActionContext remoteCtx = new ccrz.cc_RemoteActionContext();
        SBUX_B2B_OrderViewCtrl ctrl = new SBUX_B2B_OrderViewCtrl();
        SBUX_B2B_OrderViewCtrl.createReturnOrder(remoteCtx, orderId, returnLinesJSON);
        Test.stopTest();
        
        //validate controller DMLs
        System.assertEquals(1, [select count() from ccrz__E_Order__c where ccrz__Order__c =: orderId AND SBUX_B2B_OrderType__c =:ORDER_TYPE_RETURN]);
        System.assertEquals(1, [select count() from ccrz__E_OrderItem__c where ccrz__ParentOrderItem__c = :orderItemId AND SBUX_B2B_Return_Reason_Code__c =: ORDER_ITEM_RETURN_REASON]);

    }
    
}