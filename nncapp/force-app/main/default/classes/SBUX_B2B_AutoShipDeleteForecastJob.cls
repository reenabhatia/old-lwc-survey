/**
 * Deletes + HardDeletes AutoshipForecast records associated with a single AutoshipHeader record
 *
 *   (optional) Trigger successive "DeleteOrders" & "ProcessOrder" jobs (Generate Forecast,Generate Preview,Submit Orders)
 */

public with sharing class SBUX_B2B_AutoShipDeleteForecastJob implements Database.Batchable<SObject> {

    public final String autoShipHeaderId;
    public final Boolean triggerDeleteOrdersJob;
    public final Boolean triggerProcessorJob;
    public final Boolean processSplits;
    public final Boolean finalizeOrders;

    /*
     * Constructor
     */
    public SBUX_B2B_AutoShipDeleteForecastJob(String autoShipHeaderId, Boolean triggerDeleteOrdersJob, Boolean triggerProcessorJob, Boolean processSplits,Boolean finalizeOrders) {
        this.autoShipHeaderId = autoShipHeaderId;
        this.triggerDeleteOrdersJob = triggerDeleteOrdersJob;
        this.triggerProcessorJob = triggerProcessorJob;
        this.processSplits = processSplits;
        this.finalizeOrders = finalizeOrders;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
            return Database.getQueryLocator([
                SELECT Id 
                FROM SBUX_B2B_AutoshipForecast__c 
                WHERE SBUX_B2B_Autoship_Header__c = :autoShipHeaderId
            ]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> forecastList) {
        try {
            delete forecastList;
            DataBase.emptyRecycleBin(forecastList);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    public void finish(Database.BatchableContext BC) {
        //call AutoShipProcessorJob to generate new data
        if(triggerDeleteOrdersJob)
        {
            Id processorJobId = Database.executeBatch(new SBUX_B2B_AutoShipDeleteOrdersJob(autoShipHeaderId,triggerProcessorJob,processSplits,finalizeOrders), SBUX_B2B_AutoShipUtil.DELETE_ORDERS_BATCH_SIZE);
        }
        
    }
}