public with sharing class SBUX_B2B_StoreRulesBuildJob implements Database.Batchable<SObject>
{
    private List<SObject> listToBuild;


   public SBUX_B2B_StoreRulesBuildJob(List<SObject> objList)
   {
      this.listToBuild = objList;
   }


    public List<SObject> start(Database.BatchableContext info)
    {
        return this.listToBuild;
    }

    public void execute(Database.BatchableContext batchableCtx, List<SObject> scope) 
    {  
        if (scope != null)
        {
            insert scope;
        }
     }

     public void finish(Database.BatchableContext batchableCtx) 
     {
       // empty for now
     }
}