public virtual class TriggerFactoryHandlerBase
{
    public static boolean firstRun = true;
    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
    
    //If we want to create/update objects in Test classes, we can use this flag to insert the core records without logic running on them, 
    //then change the flag back
    @TestVisible private static boolean byPassTrigger = false;
 
    //method used to grab the byPassTrigger current context
    public static Boolean getByPassTriggerContext() { 
        //first respect the global trigger bypass, if set.
        if(triggersAreBypassed()) return true;
        return byPassTrigger;
    }
    
    //method used to set the byPassTrigger to false which could be used when we don't want a trigger to fire                 
    public static void setByPassTriggerFalse(){
       byPassTrigger = false;
    }

    //method used to set the byPassTrigger context back to true which can be used when more than 1 DML operation is executed within a single test method context                  
    public static void setByPassTriggerTrue(){ 
        byPassTrigger = true;
    }
 
    //method used to set the byPassTrigger context back to true which can be used when more than 1 DML operation is executed within a single test method context                  
    public static void setByPassTrigger(boolean value){ 
        byPassTrigger = value;
    }

    private static boolean triggersAreBypassed(){

        // if bypassing all objects then just return true
        if (Bypass_Triggers__c.getInstance().Bypass_All_Objects__c) return true;

        // otherwise, look to see if any sobject only triggers are disabled
        // if not then no triggers are disabled
        if (String.isBlank(Bypass_Triggers__c.getInstance().Disable_Specific_SObjects__c)) {
            return false;
        } else {

            // otherwise look to see if the trigger for this sObject should be disabled
            List<String> sObjectNamesToBypassRaw = Bypass_Triggers__c.getInstance().Disable_Specific_SObjects__c.split(',');
            Set<String> sObjectNamesToBypass = new Set<String>();

            // clean up any whitespace
            for (String s: sObjectNamesToBypassRaw) {
                sObjectNamesToBypass.add(s.trim().toLowerCase());
            }

            String sObjectNameForTrigger;

            // determine the sObjectName of the trigger we are dealing with
            if(Trigger.new != NULL && Trigger.new[0] != NULL) {
                sObjectNameForTrigger = Trigger.new[0].getSObjectType().getDescribe().getName().toLowerCase();
            }
            else {
                sObjectNameForTrigger = Trigger.old[0].getSObjectType().getDescribe().getName().toLowerCase();
            }

            // return true if we find ourselves in the list
            return sObjectNamesToBypass.contains(sObjectNameForTrigger);

        }   

    }
    
    public TriggerFactoryHandlerBase()
    {
        firstRun = true;
        BatchSize = 0;
    }
    
    public void setParameters(boolean isExecuting, integer size)
    {
        this.m_isExecuting = isExecuting;
        this.BatchSize = size;
    }
    
    public virtual Boolean GetIsExecuting() { return m_isExecuting; }
    public virtual void SetIsExecuting(Boolean bExecuting) { m_isExecuting = bExecuting; }
    
    public virtual Integer GetBatchSize() { return BatchSize; }
    public virtual void SetBatchSize(Integer bSize) { BatchSize = bSize; }
              
    public virtual void OnBeforeInsert(List<SObject> newList){}
    
    public virtual void OnAfterInsert(List<SObject> newList){}
    
    @future 
    public static void OnAfterInsertAsync(Set<Id> newIdSet){}
    
    public virtual void OnBeforeUpdate(List<SObject> oldList, List<SObject> newList, Map<Id,SObject> oldMap, Map<Id,SObject> newMap){}
    
    public virtual void OnAfterUpdate(List<SObject> oldList, List<SObject> newList, Map<Id,SObject> oldMap, Map<Id,SObject> newMap){}
    
    @future 
    public static void OnAfterUpdateAsync(Set<Id> updatedIdSet){}
    
    public virtual void OnBeforeDelete(List<SObject> oldList, Map<Id,SObject> oldMap){}
    
    public virtual void OnAfterDelete(List<SObject> oldList, Map<Id,SObject> oldMap){}
    
    @future 
    public static void OnAfterDeleteAsync(Set<Id> deletedIdSet){}
    
    public virtual void OnUndelete(List<SObject> restoredMappings){}
    
    public virtual void BulkBefore(){}      
    
    public virtual void BulkAfter(){}       
    
    public virtual void cleanUp(){}    
    
    public boolean IsTriggerContext
    {
        get{ return m_isExecuting;}
    }
    
    public boolean IsVisualforcePageContext
    {
        get{ return !IsTriggerContext;}
    }
    
    public boolean IsWebServiceContext
    {
        get{ return !IsTriggerContext;}
    }
    
    public boolean IsExecuteAnonymousContext
    {
        get{ return !IsTriggerContext;}
    }


}