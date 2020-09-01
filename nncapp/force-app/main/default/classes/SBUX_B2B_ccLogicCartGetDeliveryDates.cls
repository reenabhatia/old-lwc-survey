/**
 * Created by dgajwani on 5/18/20.
 */

global with sharing class SBUX_B2B_ccLogicCartGetDeliveryDates extends ccrz.ccLogicCartGetDeliveryDates {

    public static final String START_DATE = 'startDate';
    public static final String END_DATE = 'endDate';
    private static final String DATE_FORMAT = 'MM/dd/yyyy';
    public static final String ENABLED_DAYS = 'enabledDays';
    private static final String CDC = 'CDC';
    private static final String RDC = 'RDC';
    private static final String KIT = 'KIT';
    private static final Set<String> SUPPORTED_DC_TYPES = new Set<String>{CDC, RDC, KIT};
    public static final String SHIPPING_ADDR_LST = 'shippingAddrLst';
    public static final String SFID = 'sfid';
    public static final String SHIP_ADDRESS = 'shipAddress';
    private static final String PACIFIC_TIME_ZONE_ID = 'America/Los_Angeles';
    public static final String SHIPPING_COMMENTS = 'shippingComments';
    public static final String ORDER_TYPE_EMERGENCY = 'Emergency_Order';
    private static final String SATURDAY = 'Sat';
    private static final String SUNDAY = 'Sun';


    global override Map<String, Object> getDeliveryDates(Map<String, Object> inputData) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartGetDeliveryDates:getDeliveryDates');
        List<Object> shippingAddrLst = (List<Object>) inputData.get(SHIPPING_ADDR_LST);

        Map<String, Object> requestDateInfo = new Map<String, Object> ();
        Map<String, Object> deliveryDatesByDC = getDeliveryDatesByDC();

        for (Object currShippingAddr : shippingAddrLst) {
            Map<String, Object> currShippingAddrMap = (Map<String, Object>) currShippingAddr;
            currShippingAddrMap = (Map<String, Object>) currShippingAddrMap.get(SHIP_ADDRESS);
            String orderType = (String) currShippingAddrMap.get(SHIPPING_COMMENTS);
            String addressSFID = (String) currShippingAddrMap.get(SFID);

            Map<String, Object> currAddrMap = new Map<String, Object> ();
            currAddrMap.put(START_DATE, Datetime.now().format(DATE_FORMAT));
            currAddrMap.put(END_DATE, Datetime.now().addDays(21).format(DATE_FORMAT));
            currAddrMap.put(ENABLED_DAYS, new Set<String>());

            if (orderType.equalsIgnoreCase(ORDER_TYPE_EMERGENCY) && !deliveryDatesByDC.isEmpty() && deliveryDatesByDC.containsKey(RDC)){
                Datetime startDate = getEOStartDate();
                currAddrMap.put(START_DATE, startDate.format(DATE_FORMAT));
                currAddrMap.remove(ENABLED_DAYS);
            } else if (orderType!= null && orderType.contains('_')){
                String currDC = orderType.split('_')[1];
                if (deliveryDatesByDC != null && deliveryDatesByDC.containsKey(currDC)){
                    Set<String> enabledDates = (Set<String>) deliveryDatesByDC.get(currDC);
                    if (enabledDates != null && !enabledDates.isEmpty()){
                        List<String> enabledDatesList = new List<String>(enabledDates);
                        enabledDatesList.sort();
                        currAddrMap.put(START_DATE, enabledDatesList[0]);
                        currAddrMap.put(ENABLED_DAYS, enabledDates);
                    }
                }
            }
            requestDateInfo.put(addressSFID, currAddrMap);
        }

        inputData.put(SHIPPING_ADDR_LST, requestDateInfo);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartGetDeliveryDates:getDeliveryDates');
        return inputData;
    }

    private static Datetime getEOStartDate() {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartGetDeliveryDates:getEOStartDate');
        Datetime startDate = Datetime.newInstance(Date.today().addDays(1), Time.newInstance(0, 0, 0, 0));

        TimeZone tz = TimeZone.getTimeZone(PACIFIC_TIME_ZONE_ID);
        Datetime currPacificTime = Datetime.newInstance(System.now().getTime() + tz.getOffset(System.now()));

        Datetime cutOffTime = Datetime.newInstance(Date.today(), Time.newInstance(11, 0, 0, 0));
        // Need to re-init since times are automatically converted to user's local time.
        cutOffTime = DateTime.newInstance(cutOffTime.getTime() + UserInfo.getTimeZone().getOffset(cutOffTime));

        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_ccLogicCartGetDeliveryDates:getDeliveryDates:currPacificTime', currPacificTime);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_ccLogicCartGetDeliveryDates:getDeliveryDates:cutOffTime', cutOffTime);

        if (currPacificTime > cutOffTime) {
            ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_ccLogicCartGetDeliveryDates:getDeliveryDates', 'CutOff Has passed');
            startDate = startDate.addDays(1);
            // CutOff has passed
            if (startDate.format('E').equalsIgnoreCase(SATURDAY)) {
                ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_ccLogicCartGetDeliveryDates:getEOStartDate:', 'Adding 2 days for Sat');
                startDate = startDate.addDays(2);
            } else if (startDate.format('E').equalsIgnoreCase(SUNDAY)) {
                ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_ccLogicCartGetDeliveryDates:getEOStartDate:', 'Adding 1 day for Sun');
                startDate = startDate.addDays(1);
            }
            ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SBUX_B2B_ccLogicCartGetDeliveryDates:getDeliveryDates:startDate', startDate);
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartGetDeliveryDates:getEOStartDate');
        return startDate;
    }

    public static Map<String, Object> getDeliveryDatesByDC() {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_ccLogicCartGetDeliveryDates:getDeliveryDatesByDC');

        Map<String, Object> result = new Map<String, Object> ();

        List<SBUX_B2B_DeliverySchedule__c> deliveryScheduleList = SBUX_B2B_StorefrontUtil.fetchStoreDeliverySchedule();
        for (SBUX_B2B_DeliverySchedule__c ds : deliveryScheduleList) {
            String currDC = String.valueOf(ds.SBUX_B2B_DPNumber__c).substring(0, 3);

            if (!SUPPORTED_DC_TYPES.contains(currDC)){
                continue;
            }

            Date currDate = ds.SBUX_B2B_DeliveryDate__c;
            if (currDate >= Date.today() && currDate <= Date.today().addDays(21)){
                Set<String> enabledDaysForCurrDC = (Set<String>) result.get(currDC);
                if (enabledDaysForCurrDC == null){
                    enabledDaysForCurrDC = new Set<String>();
                    result.put(currDC, enabledDaysForCurrDC);
                }
                Datetime dt = Datetime.newInstance(currDate.year(), currDate.month(),currDate.day());

                Date orderDate = ds.SBUX_B2B_OrderDate__c;
                if ((currDC.equalsIgnoreCase(CDC) || currDC.equalsIgnoreCase(KIT)) && orderDate >= System.today()){
                    enabledDaysForCurrDC.add(dt.format(DATE_FORMAT));
                } else if (currDC.equalsIgnoreCase(RDC) && orderDate > System.today()){
                    enabledDaysForCurrDC.add(dt.format(DATE_FORMAT));
                }
            }
        }
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_ccLogicCartGetDeliveryDates:getDeliveryDatesByDC');
        return result;
    }
}