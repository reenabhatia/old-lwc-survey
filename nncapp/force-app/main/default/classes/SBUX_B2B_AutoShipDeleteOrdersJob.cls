/**
 * Deletes CCOrders(Status='Draft') associated with a single AutoshipHeader record
 *
 *   (optional) Trigger successive "ProcessOrder" jobs (Generate Forecast,Generate Preview,Submit Orders)
 */

public with sharing class SBUX_B2B_AutoShipDeleteOrdersJob implements Database.Batchable<SObject> {

    public static final String ORDER_STATUS_DRAFT = 'Draft';

    public final String autoShipHeaderId;
    public final Boolean triggerProcessorJob;
    public final Boolean processSplits;
    public final Boolean finalizeOrders;

    /*
     * Constructor
     */
    public SBUX_B2B_AutoShipDeleteOrdersJob(String autoShipHeaderId, Boolean triggerProcessorJob, Boolean processSplits,Boolean finalizeOrders) {
        this.autoShipHeaderId = autoShipHeaderId;
        this.triggerProcessorJob = triggerProcessorJob;
        this.processSplits = processSplits;
        this.finalizeOrders = finalizeOrders;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
            return Database.getQueryLocator([
                SELECT Id 
                FROM ccrz__E_Order__c 
                WHERE SBUX_B2B_AutoShipHeader__c = :autoShipHeaderId AND ccrz__OrderStatus__c = :ORDER_STATUS_DRAFT
            ]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> CCOrderList) {
        try {
            delete CCOrderList;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    public void finish(Database.BatchableContext BC) {
        //call AutoShipProcessorJob to generate new data
        if(triggerProcessorJob)
        {
            Id processorJobId = Database.executeBatch(new SBUX_B2B_AutoShipProcessorJob(autoShipHeaderId,processSplits,finalizeOrders), SBUX_B2B_AutoShipUtil.PROCESSOR_BATCH_SIZE);
        }
        
    }
}