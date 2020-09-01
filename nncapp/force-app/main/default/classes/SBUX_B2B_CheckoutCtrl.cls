/**
 * Created by dgajwani on 5/4/20.
 */

global with sharing class SBUX_B2B_CheckoutCtrl {

    private static final String CHECKOUT_DELIVERY_DATE_EXPIRED = 'Checkout_DeliveryDateExpired';
    private static final String CHECKOUT_MESSAGING_CSS_CLASS = 'messagingSection-Error-';

    /**
     * @description Converts the cart into multiple orders based on cart item groups.
     */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult placeOrder(ccrz.cc_RemoteActionContext ctx){
        Savepoint s = Database.setSavepoint();
        ccrz.cc_RemoteActionResult result = ccrz.cc_CallContext.init(ctx);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_CheckoutCtrl:placeOrder');
        result.success = false;
        try{
            result.data = SBUX_B2B_OrderUtil.convertCartToMultipleOrders();
            result.success = true;
        } catch(SBUX_B2B_OrderUtil.DeliveryDateExpiredException e){
            ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_CheckoutCtrl:placeOrder:Delivery cutoff has passed.');
            ccrz.cc_bean_Message newMessage = new ccrz.cc_bean_Message();
            newMessage.type = ccrz.cc_bean_Message.MessageType.CUSTOM;
            newMessage.severity = ccrz.cc_bean_Message.MessageSeverity.ERROR;
            newMessage.classToAppend = CHECKOUT_MESSAGING_CSS_CLASS + e.getMessage();
            newMessage.labelId = CHECKOUT_DELIVERY_DATE_EXPIRED;
            result.messages.add(newMessage);
            Database.rollback(s);
        } catch(Exception e){
            ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_CheckoutCtrl:placeOrder:ExceptionMessage', e.getMessage() + ' Line Number: ' + e.getLineNumber() + ' StackTrace: ' + e.getStackTraceString());
            Database.rollback(s);
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_CheckoutCtrl:placeOrder');
        ccrz.ccLog.close(result);
        return result;
    }

}