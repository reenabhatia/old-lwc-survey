//Purpose: queries for DeliverySchedule data based on currentAccount, and passes to MyAccount page
//      Note: to change date range, modify the "NEXT_N_DAYS:..." line in query
global with sharing class SBUX_B2B_MyDeliveryScheduleCtrl{

    public static final Integer ORDER_HISTORY_N_DAYS = 28;
    private static final String DP_NAME = 'dpName';
    private static final String ORDER_DATE = 'orderDate';
    private static final String DELIVERY_DATE = 'deliveryDate';
    private static final String SCHEDULE_TYPE = 'scheduleType';
    private static final String CUTOFF_HOURS = 'cutoffTimeHours';
    private static final String CUTOFF_MINUTES = 'cutoffTimeMins';
    private static final String CUTOFF_TIMEZONE = 'cutoffTimeZone';
    private static final String CDC_KEY = 'CDC';
    private static final String RDC_KEY = 'RDC';
    private static final String KIT_KEY = 'KIT';
    private static final String DEFAULT_SCHEDULE_TYPE = 'Standard';
    private static final String PACIFIC_TIME_ZONE = '-07:00';

    /**
    * @description attempts to grab DeliverySchedule data w/ transform for current User+Account over next [n] order days
    *
    * @return result.success = boolean flag indicating success/failure
    * @return result.data = List<Map<String,Object>> representing delivery schedule data
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getDeliveryData(ccrz.cc_RemoteActionContext ctx, String AccountId){
        ccrz.cc_RemoteActionResult result = ccrz.cc_CallContext.init(ctx);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:E', 'SBUX_B2B_MyDeliveryScheduleCtrl:getDeliveryData');
        
        try{
            // get all deliveries for Store
            List<SBUX_B2B_DeliverySchedule__c> fullDeliverySch = SBUX_B2B_StorefrontUtil.fetchStoreDeliverySchedule();
            if(fullDeliverySch <> null && fullDeliverySch.size() <> null)
            {                
                //filter results for next 28 days + modify RDC DeliveryDate
                List<SBUX_B2B_DeliverySchedule__c> filteredDeliverySch = new List<SBUX_B2B_DeliverySchedule__c>();
                if(!fullDeliverySch.isEmpty()) {
                    for (SBUX_B2B_DeliverySchedule__c deliv : fullDeliverySch)
                    {
                        //subtract 1 day from RDC
                        if(deliv.SBUX_B2B_DPNumber__c.contains(RDC_KEY)) {
                            deliv.SBUX_B2B_OrderDate__c = deliv.SBUX_B2B_OrderDate__c.addDays(-1);
                        }
                        //add to 'filtered' schedule list IF orderDate >= today AND <= 28 days out
                        //  CUSTOM: ignore any KIT delivery schedules
                        if(deliv.SBUX_B2B_OrderDate__c >= Date.today() && deliv.SBUX_B2B_OrderDate__c <= Date.today().addDays(ORDER_HISTORY_N_DAYS)
                                && !deliv.SBUX_B2B_DPNumber__c.contains(KIT_KEY)) {
                            filteredDeliverySch.add(deliv);
                        }
                    }
                }

                //null check of NEW filtered list
                if(!filteredDeliverySch.isEmpty())
                {
                    //build DPNumberList
                    List<String> DPNumbers = new List<String>();
                    for (SBUX_B2B_DeliverySchedule__c deliv : filteredDeliverySch) {
                        DPNumbers.add(deliv.SBUX_B2B_DPNumber__c);
                    }
                    
                    //get cutoffMap
                    Map<String,SBUX_B2B_ItemDCSourcing__c> cutoffMap = getCutoffMap(DPNumbers);                    

                    //get DPMapping
                    Map<String, String> dpMap = getDPMappings(DPNumbers);

                    //build return map with merged data
                    List<Map<String,Object>> deliverySchList = new List<Map<String,Object>>();
                    for (SBUX_B2B_DeliverySchedule__c deliv : filteredDeliverySch)
                    {
                        //null checks
                        if(deliv.SBUX_B2B_DPNumber__c <> null && deliv.SBUX_B2B_OrderDate__c <> null && deliv.SBUX_B2B_DeliveryDate__c <> null)
                        {
                            //translate DPNumber -> DPName via metadata type
                            String DPName = dpMap.get(deliv.SBUX_B2B_DPNumber__c) != null ? dpMap.get(deliv.SBUX_B2B_DPNumber__c) : deliv.SBUX_B2B_DPNumber__c;

                            //build delivery map
                            Map<String,Object> singleDeliveryMap = new Map<String,Object>();
                            singleDeliveryMap.put(DP_NAME,DPName);
                            singleDeliveryMap.put(ORDER_DATE,deliv.SBUX_B2B_OrderDate__c);
                            singleDeliveryMap.put(DELIVERY_DATE,deliv.SBUX_B2B_DeliveryDate__c);
                            
                            //set Schedule Type
                            if(deliv.SBUX_B2B_ScheduleType__c <> null){
                                singleDeliveryMap.put(SCHEDULE_TYPE, deliv.SBUX_B2B_ScheduleType__c);
                            } else {
                                singleDeliveryMap.put(SCHEDULE_TYPE, DEFAULT_SCHEDULE_TYPE);
                            }

                            //set cutoff time
                            //CUSTOM: RDC - set cutoff to 11:59pm PST
                            if(deliv.SBUX_B2B_DPNumber__c.contains(RDC_KEY)) {
                                singleDeliveryMap.put(CUTOFF_HOURS,     23);
                                singleDeliveryMap.put(CUTOFF_MINUTES,   59);
                                singleDeliveryMap.put(CUTOFF_TIMEZONE,  PACIFIC_TIME_ZONE);
                            }
                            else if(cutoffMap.get(deliv.SBUX_B2B_DPNumber__c) <> null){
                                Time cutoff = cutoffMap.get(deliv.SBUX_B2B_DPNumber__c).SBUX_B2B_CutoffTime__c;
                                //CUSTOM: CDC - remove 90 mins from cutoff
                                if(deliv.SBUX_B2B_DPNumber__c.contains(CDC_KEY)) {
                                    cutoff = cutoff.addMinutes(-90);
                                }
                                singleDeliveryMap.put(CUTOFF_HOURS,     cutoff.hour());
                                singleDeliveryMap.put(CUTOFF_MINUTES,   cutoff.minute());
                                singleDeliveryMap.put(CUTOFF_TIMEZONE,  cutoffMap.get(deliv.SBUX_B2B_DPNumber__c).SBUX_B2B_CuttoffTimeZone__c);
                            }
                            //add to ScheduleList
                            deliverySchList.add(singleDeliveryMap);
                        }
                    }

                    result.data = deliverySchList;
                    result.success = true;
                }
                else{
                    //no delivery schedules found for Store
                    result.success = false;
                }
            }
            else {
                //no store found
                result.success = false;
            }
        } catch(Exception e) {
            result.success = false;
        } finally {
            ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'M:X', 'SBUX_B2B_MyDeliveryScheduleCtrl:getDeliveryData');
            ccrz.ccLog.close(result);
        }
        return result;
    }

    /**
    * @description Creates a map of cutoff Times based on inputted DeliverySchedule list
    *
    * @return Map<String,SBUX_B2B_ItemDCSourcing__c> representing cutoffTimes by DPNumber
    */
    public static Map<String, SBUX_B2B_ItemDCSourcing__c> getCutoffMap(List<String> DPNumbers) {
        Map<String,SBUX_B2B_ItemDCSourcing__c> cutoffMap = new Map<String,SBUX_B2B_ItemDCSourcing__c>();
        for(SBUX_B2B_ItemDCSourcing__c cutoff :[
                SELECT SBUX_B2B_DPNumber__c,SBUX_B2B_CutoffTime__c,SBUX_B2B_CuttoffTimeZone__c
                FROM SBUX_B2B_ItemDCSourcing__c
                WHERE SBUX_B2B_DPNumber__c IN :DPNumbers])
        {
            if(!cutoffMap.containsKey(cutoff.SBUX_B2B_DPNumber__c)){
                cutoffMap.put(cutoff.SBUX_B2B_DPNumber__c,cutoff);
            }
        }
        return cutoffMap;
    }

    /**
    * @description Creates a map representing dpNumber => dpName for building MyDeliverySchedule response
    *
    * @return Map<String,Object> representing dpNumber => dpName
    */
    public static Map<String, String> getDPMappings(List<String> DPNumbers) {
        Map<String, String> dpMap = new Map<String, String> ();
        for (SBUX_B2B_StoreDPMapping__mdt DPOption : [
                SELECT Id, SBUX_B2B_dpName__c, SBUX_B2B_dpNumber__c
                FROM SBUX_B2B_StoreDPMapping__mdt
                WHERE SBUX_B2B_dpNumber__c IN :DPNumbers])
        {
            dpMap.put(DPOption.SBUX_B2B_dpNumber__c, DPOption.SBUX_B2B_dpName__c);
        }
        return dpMap;
    }
}