@isTest
public with sharing class TriggerExecutionInstanceTest {
	@isTest
	public static void testequals(){
		List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
		Id recordId = opps[0].id;
		String methodName = 'methodName';
		List<TriggerFactory.OperationState> operationState = TriggerFactory.OperationState.values();
		List<TriggerFactory.Operation> operation = TriggerFactory.Operation.values();
		Map<String,Object> fieldValuesMap = new Map<String,Object>();
		fieldValuesMap.put('1', 'insertcheck');
		fieldValuesMap.put('2', 'deletecheck');
		
		Test.startTest();
		TriggerExecutionInstance obj1 = new TriggerExecutionInstance(recordId,methodName,operationState[0],operation[0],fieldValuesMap);
	    TriggerExecutionInstance obj2 = new TriggerExecutionInstance(recordId,methodName,operationState[0],operation[0],fieldValuesMap);
	    TriggerExecutionInstance obj3 = new TriggerExecutionInstance(recordId,methodName);
	    TriggerExecutionInstance obj4 = new TriggerExecutionInstance(recordId,methodName,operationState[1],operation[2],fieldValuesMap);
	    TriggerExecutionInstance obj5 = new TriggerExecutionInstance(recordId,methodName,operationState[1],operation[2],fieldValuesMap);

	    Boolean val1 = obj1.equals(obj2);
	    Boolean val2 = obj4.equals(obj5);
	    system.assertEquals(True,val1);
	    system.assertEquals(True,val2);
	    Test.stopTest();

	}

}