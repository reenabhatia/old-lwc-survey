/**
 * Daily SchedulableJob that searches for AGED Autoship Headers (60days past ShipDate)
 *         and then passes to batch jobs for Forecast+Preview Data Cleanup
 * 
 * Can be scheduled from [Setup > Apex Class] or by executing below anonymous code from DevConsole
 *      SBUX_B2B_AutoshipCleanup_ForecastAge q = new SBUX_B2B_AutoshipCleanup_ForecastAge(); 
 *      String sch = '0 35 02 * * ? *';
 *      system.schedule('B2BDailyForecastAge-0235', sch, q);
 */
global class SBUX_B2B_AutoshipCleanup_ForecastAge implements Schedulable
{
    //These 'age' numbers should be NEGATIVE, since we are going days in the PAST
    public static final Integer AUTOSHIP_AGE_DAYS_LOWER = -60;
    public static final Integer AUTOSHIP_AGE_DAYS_UPPER = -68;
    public static final String  AUTOSHIP_STATUS_ORDERS_CREATED = 'Orders Created';

    global void execute(SchedulableContext sc)
    {
        //searches for AGED Autoship Headers (60+ days past FirstShipDate)
        List<SBUX_B2B_AutoShipHeader__c> agedAutoshipHeaders = new List<SBUX_B2B_AutoShipHeader__c>();
        agedAutoshipHeaders = [
            SELECT Id 
            FROM SBUX_B2B_AutoShipHeader__c 
            WHERE SBUX_B2B_AutoshipStatus__c = :AUTOSHIP_STATUS_ORDERS_CREATED
              AND SBUX_B2B_FirstShipDate__c <= :Date.Today().addDays(AUTOSHIP_AGE_DAYS_LOWER)
              AND SBUX_B2B_FirstShipDate__c >= :Date.Today().addDays(AUTOSHIP_AGE_DAYS_UPPER)
        ];
        if (agedAutoshipHeaders.size() > 0)
        {
            for(SBUX_B2B_AutoShipHeader__c header : agedAutoshipHeaders)
            {
                //send to batch jobs to delete ALL Forecast data, and DRAFT status CCOrders
                Id batchDeleteId = Database.executeBatch(new SBUX_B2B_AutoShipDeleteForecastJob(header.Id, true, false, false, false), SBUX_B2B_AutoShipUtil.DELETE_FORECAST_BATCH_SIZE);
            }
        }
        

    }
}