@isTest
private class TriggerFactoryHandlerBaseTest {
    
    static testMethod void TriggerFactoryHandlerBase_Test() {
        TriggerFactoryHandlerBase objTFHB = new TriggerFactoryHandlerBase();
    }
    
    static testMethod void TriggerFactoryHandlerBase_TestStaticMethods() {
        TriggerFactoryHandlerBase.setByPassTriggerTrue();
        System.Assert(TriggerFactoryHandlerBase.getByPassTriggerContext(), 'Should be set to true');
        
        TriggerFactoryHandlerBase.setByPassTriggerFalse();
        System.Assert(TriggerFactoryHandlerBase.getByPassTriggerContext()==FALSE, 'Should be set to false');
        
        TriggerFactoryHandlerBase.setByPassTrigger(true);
        System.Assert(TriggerFactoryHandlerBase.getByPassTriggerContext(), 'Should be set to true');
        
        TriggerFactoryHandlerBase.OnAfterInsertAsync(null);
        TriggerFactoryHandlerBase.OnAfterUpdateAsync(null);
        TriggerFactoryHandlerBase.OnAfterDeleteAsync(null);
    }
    
    static testMethod void TriggerFactoryHandlerBase_TestAllMethods() {
        TriggerFactoryHandlerBase objTFHB = new TriggerFactoryHandlerBase();
        objTFHB.setParameters(false, 200);
        System.Assert(objTFHB.GetIsExecuting()==false, 'Should be set to false');
        
        objTFHB.SetIsExecuting(true);
        System.Assert(objTFHB.GetIsExecuting()==true, 'Should be set to true');
        
        System.Assert(objTFHB.GetBatchSize()==200, 'Should be set to initial value');
        
        objTFHB.SetBatchSize(100);
        System.Assert(objTFHB.GetBatchSize()==100, 'Should be set to new value');
        
        objTFHB.OnBeforeInsert(null);
        objTFHB.OnAfterInsert(null);
        
        objTFHB.OnBeforeUpdate(null, null, null, null);
        objTFHB.OnAfterUpdate(null, null, null, null);
        
        objTFHB.OnBeforeDelete(null, null);
        objTFHB.OnAfterDelete(null, null);
        
        objTFHB.OnUndelete(null);
        
        boolean testvar = objTFHB.IsTriggerContext;
        testvar = objTFHB.IsVisualforcePageContext;
        testvar = objTFHB.IsWebServiceContext;
        testvar = objTFHB.IsExecuteAnonymousContext;
        
    }

    static testMethod void TriggerFactoryHandlerBase_TestTriggerBypass() {

        // test when bypass trigger is not set
        
        System.Assert(TriggerFactoryHandlerBase.getByPassTriggerContext()==FALSE, 'Should be set to false');

        // test when bypass trigger is set to org-wide true
        Bypass_Triggers__c theBypass = Bypass_Triggers__c.getOrgDefaults();
        theBypass.Bypass_All_Objects__c = true;
        upsert theBypass Bypass_Trigger__c.Id;

        System.Assert(TriggerFactoryHandlerBase.getByPassTriggerContext(), 'Should be set to true');

        // test when you override the org wide bypass more specifically as the running user.
        Bypass_Triggers__c theUserBypass = new Bypass_Triggers__c(SetupOwnerId=UserInfo.getUserId(), Bypass_All_Objects__c=false);
        insert theUserBypass;

        System.Assert(TriggerFactoryHandlerBase.getByPassTriggerContext()==FALSE, 'Should be set to false');
    }
}