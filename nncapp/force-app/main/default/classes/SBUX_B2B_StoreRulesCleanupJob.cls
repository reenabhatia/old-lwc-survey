public with sharing class SBUX_B2B_StoreRulesCleanupJob implements Database.Batchable<SObject>
{
   private List<SObject> listToCleanUp;
   private List<SObject> listToBuild;
   private static final Integer BATCH_SIZE = 2000;

   public SBUX_B2B_StoreRulesCleanupJob(List<SObject> objList, List<SObject> otherList)
   {
      this.listToCleanUp =  objList;
      this.listToBuild  =   otherList;
   }


    public List<SObject> start(Database.BatchableContext info)
    {
        return this.listToCleanUp;
    }
    
    public void execute(Database.BatchableContext batchableCtx, List<SObject> scope) 
    {  
        if (scope != null)
        {
            delete scope;
            
           DataBase.emptyRecycleBin(scope); 
        }
     }


     public void finish(Database.BatchableContext batchableCtx) 
     {
        if (this.listToBuild != null && !this.listToBuild.isEmpty())
        {
         SBUX_B2B_StoreRulesBuildJob storeRuleBuild = new SBUX_B2B_StoreRulesBuildJob(this.listToBuild);
         Database.executebatch(storeRuleBuild,BATCH_SIZE);
        }
     }


}