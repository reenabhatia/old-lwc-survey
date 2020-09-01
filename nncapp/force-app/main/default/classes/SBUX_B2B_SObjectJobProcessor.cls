public with sharing class SBUX_B2B_SObjectJobProcessor implements Database.Batchable<SObject>
{
    private List<SObject> batchList;

    public SBUX_B2B_SObjectJobProcessor(List<SObject> objList) 
    {
        this.batchList =  objList;
    }
    

    public List<SObject> start(Database.BatchableContext batchCtx)
    {
        return this.batchList;
     }    

           
    public void execute(Database.BatchableContext batchableCtx, List<SObject> scope) 
     {  
        if (scope instanceof List<SBUX_B2B_AutoShipLine__c>)
        {
            upsert (List<SBUX_B2B_AutoShipLine__c>)scope sbux_b2b_externalid__c;
        }
        
     }



     public void finish(Database.BatchableContext batchableCtx) 
     {
         // empty for now
     }

}