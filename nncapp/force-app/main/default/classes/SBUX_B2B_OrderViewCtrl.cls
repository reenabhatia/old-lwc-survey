/*
 * Created 2020-04-22 by alangston
 * Tickets: NGO-298 - Credit Request
 * Purpose: handles the DMLs for the "Submit Credit" button on OrderView subscriber code
 */
global with sharing class SBUX_B2B_OrderViewCtrl {

    global boolean isCredit { get; set; }
    global String returnReasonCodeString { get; set; }

    private static final String ORDER_TYPE_RETURN_US = 'RMA Cr Only - US';
    private static final String ORDER_TYPE_RETURN_CAN = 'RMA Cr Only - CAN';
    private static final String ORDER_TYPE_CAN_KEY = 'CAN';
    private static final String ORDER_SOURCE = 'Credit';
    private static final String ORDER_ITEM_STATUS = 'Order Submitted';
    private static final String ORDER_ITEM_TYPE = 'Major';
    private static final String ORDERGROUP_GROUPNAME = 'Credit Request Order';
    private static final String ORDER_SHIPSTRUCTURE = 'LLI';
    private static final String CR_REASON_LABEL = 'label';
    private static final String CR_REASON_VALUE = 'value';

    //constructor
	global SBUX_B2B_OrderViewCtrl() {
        isCredit = Apexpages.currentPage().getParameters().get('credReq') != null ? true : false;
        returnReasonCodeString = JSON.serialize(getReturnReasonCodes());
	}

    //returnLineMaps = <originalLineId, <fieldName,fieldValue>>
    @RemoteAction
    global static ccrz.cc_RemoteActionResult createReturnOrder(ccrz.cc_RemoteActionContext ctx, Id originalOrderId, String returnLinesJSON){
        ccrz.cc_RemoteActionResult result = ccrz.cc_CallContext.init(ctx);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_OrderViewCtrl:createReturnOrder');

        //convert upper JSON to map
        Map<String,Object> returnLinesMap = (Map<String,Object>) JSON.deserializeUntyped(returnLinesJSON);

        List<ccrz__E_OrderItem__c> orderLinesToInsert = new List<ccrz__E_OrderItem__c>();

        //get originalOrder object
        List<ccrz__E_Order__c> originalOrderList = new List<ccrz__E_Order__c>([
            SELECT Id,ccrz__Account__c,ccrz__CurrencyISOCode__c,ccrz__BillTo__c,ccrz__ShipTo__c,SBUX_B2B_OrderType__c,
                ccrz__Storefront__c,ccrz__User__c,ccrz__Contact__c
            FROM ccrz__E_Order__c
            WHERE Id =: originalOrderId
        ]);
        ccrz__E_Order__c originalOrder = new ccrz__E_Order__c();
        originalOrder = originalOrderList[0];
        
        //create base Order w/ static mapping
        ccrz__E_Order__c returnOrder = new ccrz__E_Order__c(
            ccrz__Order__c              = originalOrder.Id,
            ccrz__Account__c            = originalOrder.ccrz__Account__c,
            ccrz__CurrencyISOCode__c    = originalOrder.ccrz__CurrencyISOCode__c,
            ccrz__BillTo__c             = originalOrder.ccrz__BillTo__c,
            ccrz__ShipTo__c             = originalOrder.ccrz__ShipTo__c,
            ccrz__ShipStructure__c      = ORDER_SHIPSTRUCTURE,
            SBUX_B2B_Order_Source__c    = ORDER_SOURCE,
            ccrz__Name__c               = ORDERGROUP_GROUPNAME,
            ccrz__RequestDate__c        = system.today(),
            ccrz__OrderDate__c          = system.today(),
            SBUX_B2B_OrderPublishFlag__c = true,
            ccrz__Storefront__c         = originalOrder.ccrz__Storefront__c,
            ccrz__Contact__c            = originalOrder.ccrz__Contact__c,
            ccrz__User__c               = originalOrder.ccrz__User__c
        );

        //set return order type based on original order type
        if(originalOrder.SBUX_B2B_OrderType__c <> null && originalOrder.SBUX_B2B_OrderType__c.contains(ORDER_TYPE_CAN_KEY))
        {
            returnOrder.SBUX_B2B_OrderType__c = ORDER_TYPE_RETURN_CAN;
        }
        else
        {
            returnOrder.SBUX_B2B_OrderType__c = ORDER_TYPE_RETURN_US;
        }

        try{
            //insert new return Order
            insert returnOrder;

            //create + insert OrderItemGroup
            ccrz__E_OrderItemGroup__c returnOrderItemGroup = new ccrz__E_OrderItemGroup__c(
                ccrz__GroupName__c  = ORDERGROUP_GROUPNAME,
                ccrz__Order__c      = returnOrder.Id
            );
            insert returnOrderItemGroup;

            //get encyptedId of newly inserted return order (is returned to page)
            List<ccrz__E_Order__c> grabReturnOrderList = new List<ccrz__E_Order__c>([
                SELECT Id,ccrz__EncryptedId__c FROM ccrz__E_Order__c WHERE Id =: returnOrder.Id
            ]);
            result.data = grabReturnOrderList[0].ccrz__EncryptedId__c;

            //loop through credit map
            for(String originalLineId : returnLinesMap.keyset())
            {
                Map<String,Object> rtnLine = (Map<String,Object>)returnLinesMap.get(originalLineId);

                //create base OrderLine
                ccrz__E_OrderItem__c newLine = new ccrz__E_OrderItem__c(
                    ccrz__Order__c                  = returnOrder.Id,
                    ccrz__OrderItemGroup__c         = returnOrderItemGroup.Id,
                    ccrz__ParentOrderItem__c        = originalLineId,
                    SBUX_B2B_Return_Reason_Code__c  = (String)rtnLine.get('rtnReason'),
                    ccrz__Quantity__c               = (Integer)rtnLine.get('rtnQty'),
                    SBUX_B2B_Primary_UOM_Quantity__c = (Integer)rtnLine.get('rtnQty'),
                    ccrz__Product__c                = (String)rtnLine.get('product'),
                    ccrz__UnitOfMeasure__c          = (String)rtnLine.get('primaryUOM'),
                    SBUX_Primary_UOM__c             = (String)rtnLine.get('primaryUOM'),
                    ccrz__Price__c                  = (Double)rtnLine.get('price'),
                    ccrz__ProductType__c            = (String)rtnLine.get('productType'),
                    ccrz__OrderItemStatus__c        = ORDER_ITEM_STATUS,
                    ccrz__OrderLineType__c          = ORDER_ITEM_TYPE
                );

                //check passed-in price for conversion
                if(rtnLine.get('itemTotal') <> null && rtnLine.get('primaryUOMQty') <> null) {
                    if(newLine.ccrz__UnitOfMeasure__c <> (String)rtnLine.get('priceUOM')) {
                        newLine.ccrz__Price__c = (Double)rtnLine.get('itemTotal') / (Double)rtnLine.get('primaryUOMQty');
                    }
                }

                //set qty to Negative (needed for ERP)
                if(newLine.ccrz__Quantity__c > 0)
                    newLine.ccrz__Quantity__c = newLine.ccrz__Quantity__c * -1;
                if(newLine.SBUX_B2B_Primary_UOM_Quantity__c > 0)
                    newLine.SBUX_B2B_Primary_UOM_Quantity__c = newLine.SBUX_B2B_Primary_UOM_Quantity__c * -1;
                
                //set subAmount
                newLine.ccrz__SubAmount__c = newLine.ccrz__Quantity__c * newLine.ccrz__Price__c;

                //add newLine to running List
                orderLinesToInsert.add(newLine);
            }

            //insert Order Lines
            if(orderLinesToInsert.size()>0)
            {
                insert orderLinesToInsert;
                result.success = true;
            }
            else
            {
                result.success = false;
            }
        }catch(Exception e){
            result.success = false;
        }

        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_OrderViewCtrl:createReturnOrder');
        ccrz.ccLog.close(result);
        return result;
    }

    //get picklist values for ReturnReasonCode field for user-input
    global static List<Map<String,Object>> getReturnReasonCodes(){
        List<Map<String,Object>> reasonCodeList = new List<Map<String,Object>>();
        Schema.DescribeFieldResult fieldResult = ccrz__E_OrderItem__c.SBUX_B2B_Return_Reason_Code__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple){
            reasonCodeList.add(new Map<String,Object>{
                CR_REASON_LABEL => pickListVal.getLabel(),
                CR_REASON_VALUE => pickListVal.getValue()
            });
        }

        return reasonCodeList;
    }
}