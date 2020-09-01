/**  
  * Class TriggerFactory  
  * Used to instantiate and execute Trigger Handlers associated with sObjects.  
 */
public with sharing class TriggerFactory extends TriggerFactoryHandlerBase {
    
    public enum OperationState { BEFORE, AFTER }
    public enum Operation { TRIGGER_INSERT, TRIGGER_UPDATE, TRIGGER_DELETE }

    public static Map<String,TriggerExecutionInstance> TRIGGER_EXECUTION_MAP = new Map<String,TriggerExecutionInstance>();

    public static Boolean triggerExecutionInstanceExists(TriggerExecutionInstance triggerExecutionInstance) {
        if (TRIGGER_EXECUTION_MAP.containsKey(triggerExecutionInstance.Key) && TRIGGER_EXECUTION_MAP.get(triggerExecutionInstance.Key) == triggerExecutionInstance) {
            return true;
        }
        else {
            TRIGGER_EXECUTION_MAP.put(triggerExecutionInstance.Key, triggerExecutionInstance);
            return false;
        }
    }
    
    public static Boolean triggerExecutionInstanceExists(Id recordId, String methodName) {
        TriggerExecutionInstance triggerExecutionInstance = new TriggerExecutionInstance(recordId, methodName);
        return triggerExecutionInstanceExists(triggerExecutionInstance);
    }

    public static void createHandler() {  
        // Get a handler appropriate to the object being processed  
        TriggerFactoryHandlerBase handler = getHandler(Trigger.old, Trigger.new ,'No override');  
        if(!TriggerFactoryHandlerBase.getByPassTriggerContext()) { 
            execute(handler);  
        }
    }

    /*public static void createHandler(String overrideHandlerClass) {  
        // Get a handler appropriate to the object being processed  
        TriggerFactoryHandlerBase handler = getHandler(Trigger.old, Trigger.new,overrideHandlerClass);
        if(!TriggerFactoryHandlerBase.getByPassTriggerContext()) { 
            execute(handler);  
        }
    }*/
    
    //private static method to control the execution of the handler  
    private static void execute(TriggerFactoryHandlerBase handler) {
        if(Trigger.isBefore) {
            // Call the bulk before to handle any caching of data and enable bulkification 
            handler.BulkBefore();
            
            // Call the beforeDelete method of the handler
            if(Trigger.isDelete) {
                handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
            }
            
            // Call the beforeInsert method of the handler
            if(Trigger.isInsert) {               
                handler.OnBeforeInsert(Trigger.new);
            }
            
            //Call the beforeUpdate method of the handler
            if(Trigger.isUpdate) {               
                handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            }
        }
        else if(Trigger.isAfter) {
            // Call the bulk before to handle any caching of data and enable bulkification 
            handler.BulkAfter();
            
            // Call the afterDelete method of the handler
            if(Trigger.isDelete) {
                handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
            }
            
            // Call the afterinsert method of the Handler
            if(Trigger.isInsert) {               
                handler.OnAfterInsert(Trigger.new); 
            }
            
            // call the afterUpdate method of the handler
            if(Trigger.isUpdate) {
                handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            }
        }
        else if(Trigger.isUnDelete) {
            handler.OnUnDelete(Trigger.new);            
        }
        
        //call the cleaup method
        handler.cleanUp();
    }
    
    @testVisible
    // For this to work on any trigger you create your handler class must be the object name
    // underscores removed with _TriggerHandler appended on the end of the name
    // Example:
    // Object Name: Asset
    // Handler class name: Asset_TriggerHandler
    private static TriggerFactoryHandlerBase getHandler(List<sObject> oldList, List<sObject> newList , String overrideHandlerClass) {  
        String sObjectName;

        if(newList!=NULL && newList[0]!=NULL) {
            sObjectName = newList[0].getSObjectType().getDescribe().getName();
        }
        else if(oldList!=NULL && oldList[0] != NULL){
            sObjectName = oldList[0].getSObjectType().getDescribe().getName();
        }
        TriggerFactoryHandlerBase handler = null;
        Type t = null;

        sObjectName = sObjectName.replaceAll('__c', '');
        sObjectName = sObjectName.replaceAll('_', '');

        if(overrideHandlerClass != 'No override'){
            t = Type.forName(overrideHandlerClass); 
        }
        else{
             t = Type.forName(sObjectName + '_TriggerHandler');
        }

        if(t==null) {
            //create instance of the default class
            t = Type.forName('TriggerFactoryHandlerBase');
        }
        handler = (TriggerFactoryHandlerBase) t.newInstance();
    
        return handler;  
    }     
}