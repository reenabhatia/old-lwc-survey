/**
 * Schedulable Daily BatchJob that Hard-Deletes CCOrders from the recycle bin (normally takes 30 days)
 * 
 * Can be scheduled from [Setup > Apex Class] or by executing below anonymous code from DevConsole
 *      SBUX_B2B_AutoshipCleanup_OrdersPurge p = new SBUX_B2B_AutoshipCleanup_OrdersPurge(); 
 *      String sch = '0 30 02 * * ? *';
 *      system.schedule('B2BDailyOrderPurge-0230', sch, p);
 */
global class SBUX_B2B_AutoshipCleanup_OrdersPurge implements Database.Batchable<sObject>, Schedulable
{
    //Batch Method
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id 
            FROM ccrz__E_Order__c 
            WHERE isDeleted = true ALL ROWS
        ]);
    }
    global void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        if (scope <> null && scope.size() > 0)
        {
            Database.emptyRecycleBin(scope);
        }
    }
    global void finish(Database.BatchableContext BC)
    {
        //finish
    }

    //Scheduler Method
    global void execute(SchedulableContext sc)
    {
        database.executebatch(new SBUX_B2B_AutoshipCleanup_OrdersPurge(), SBUX_B2B_AutoShipUtil.PURGE_ORDERS_BATCH_SIZE);
    }
}