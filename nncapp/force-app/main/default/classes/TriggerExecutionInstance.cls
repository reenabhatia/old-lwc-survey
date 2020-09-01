global class TriggerExecutionInstance {
	
    public Id recordId { get; private set; }
    public String methodName { get; private set; }
    public TriggerFactory.OperationState operationState { get; private set; }
    public TriggerFactory.Operation operation { get; private set; }
    public Map<String,Object> fieldValuesMap { get; private set; }

    public TriggerExecutionInstance(Id recordId, String methodName, TriggerFactory.OperationState operationState, TriggerFactory.Operation operation, Map<String,Object> fieldValuesMap) {
        this.recordId = recordId;
        this.methodName = methodName;
        this.operationState = operationState;
        this.operation = operation;
        this.fieldValuesMap = fieldValuesMap;
    }
    
    public TriggerExecutionInstance(Id recordId, String methodName) {
        this.recordId = recordId;
        this.methodName = methodName;
        this.operationState = null;
        this.operation = null;
        this.fieldValuesMap = null;
        TriggerFactory.TRIGGER_EXECUTION_MAP.put(this.Key, this);
    }


    public String Key {
        get {
            return String.format('{0}-{1}-{2}-{3}', new String[]{
                String.valueOf(recordId),
                methodName,
                operationState != null ? String.valueOf(operationState) : 'null',
                operation      != null ? String.valueOf(operation)      : 'null'
            });
        }
    }

    public Boolean equals(Object compareToTriggerExecutionInstance) {

        return compareToTriggerExecutionInstance instanceof TriggerExecutionInstance
            && this.recordId       == ((TriggerExecutionInstance)compareToTriggerExecutionInstance).recordId
            && this.methodName     == ((TriggerExecutionInstance)compareToTriggerExecutionInstance).methodName
            && this.operationState == ((TriggerExecutionInstance)compareToTriggerExecutionInstance).operationState
            && this.operation      == ((TriggerExecutionInstance)compareToTriggerExecutionInstance).operation
            && fieldValueMapsEqual(this.fieldValuesMap, ((TriggerExecutionInstance)compareToTriggerExecutionInstance).fieldValuesMap);
    }

    private Boolean fieldValueMapsEqual(Map<String,Object> instanceMap, Map<String,Object> compareToMap) {
        if (instanceMap==null || compareToMap==null) {return true;}
        if (instanceMap.size() != compareToMap.size()) { return false; }
        for (String instanceKey :instanceMap.keySet()) {
            if (compareToMap.containsKey(instanceKey)) {
                Object instanceValue = instanceMap.get(instanceKey);
                Object compareToValue = compareToMap.get(instanceKey);
                if (instanceValue == compareToValue) {
                	continue;
                } else { return false; }
            } else { return false; }
        }
        return true;
    }
}