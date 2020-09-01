@isTest
public with sharing class TriggerFactoryTest {
	@isTest
	public static void testtriggerExecutionInstanceExists(){

		List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
		Id recordId = opps[0].id;
		String methodName = 'methodName';
		List<TriggerFactory.OperationState> operationState = TriggerFactory.OperationState.values();
		List<TriggerFactory.Operation> operation = TriggerFactory.Operation.values();
		Map<String,Object> fieldValuesMap = new Map<String,Object>();
		fieldValuesMap.put('1', 'insertcheck');
		fieldValuesMap.put('2', 'deletecheck');
		TriggerExecutionInstance obj1 = new TriggerExecutionInstance(recordId,methodName,operationState[1],operation[2],fieldValuesMap);

        Test.startTest();
		Boolean b1 = TriggerFactory.triggerExecutionInstanceExists(obj1);
		Boolean b2 = TriggerFactory.triggerExecutionInstanceExists(recordId,methodName);
		List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
		opps[0].Store__c = stores[0].id;
        update opps[0];
        Opportunity opp = new Opportunity();
        opp = opps[0];
        delete opp;
        
		Test.stopTest();

	}
 
}