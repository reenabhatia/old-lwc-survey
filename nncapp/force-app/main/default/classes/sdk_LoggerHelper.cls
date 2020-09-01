/**
* @author Slalom
* @date 2017
*
* @group Helper
*
* @description General logging helper class
*/
public without sharing class sdk_LoggerHelper {
    
    public static String TYPE_EXCEPTION;
    public static String TYPE_CLIENTSIDEMESSAGE;
    public static String TYPE_SERVERSIDEMESSAGE;
    public static String TYPE_INTEGRATIONMESSAGE;

    static {
        TYPE_EXCEPTION          = 'Exception';
        TYPE_CLIENTSIDEMESSAGE  = 'Client-Side Message';
        TYPE_SERVERSIDEMESSAGE  = 'Server-Side Message';
        TYPE_INTEGRATIONMESSAGE = 'Integration Message';
    }

    /* for test coverage */
    @TestVisible
    private static Boolean testNonFuture = false;
    /**
     * {@value #LOG_CUSTOM_OBJECT_NAME} Custom object in salesforce
     */
    @TestVisible
    private static String LOG_CUSTOM_OBJECT_NAME = 'Log__c';
    /**
     * {@value #LOG_CLASS_NAME_FIELD} ClassName Field API
     */
    private static String LOG_CLASS_NAME_FIELD = 'Class_Name__c';
    /**
     * {@value #LOG_METHOD_NAME_FIELD} MethodName Field API
     */
    private static String LOG_METHOD_NAME_FIELD = 'Method_Name__c';
    /**
     * {@value #LOG_RECORD_ID_FIELD} RecordId Field API
     */
    private static String LOG_RECORD_ID_FIELD = 'Record_ID__c';
    /**
     * {@value #LOG_ERROR_TYPE_FIELD} ErrorType Field API
     */
    private static String LOG_ERROR_TYPE_FIELD = 'Error_Type__c';
    /**
     * {@value #LOG_ERROR_LINE_FIELD} ErrorLine Field API
     */
    private static String LOG_ERROR_LINE_FIELD = 'Error_Line__c';
    /**
     * {@value #LOG_ERROR_MESSAGE_FIELD} ErrorMessage Field API
     */
    private static String LOG_ERROR_MESSAGE_FIELD = 'Error_Message__c';
    /**
     * {@value #LOG_STACKTRACE_FIELD} StackTrace Field API
     */
    private static String LOG_STACKTRACE_FIELD = 'Stack_Trace__c';
    /**
     * {@value #LOG_SEVERITY_FIELD} Severity Field API
     */
    private static String LOG_SEVERITY_FIELD = 'Severity__c';
    /**
     * {@value #LOG_SEVERITY_FIELD} Severity Field API
     */
    private static String LOG_TYPE_FIELD = 'Type__c';
    /**
     * {@value #LOG_SEVERITY_FIELD} Severity Field API
     */
    private static String LOG_MESSAGE_FIELD = 'Message__c';
    /**
     * {@value #LOG_FUTURE_FLAG_FIELD} Async Flag Field API
     */
    private static String LOG_FUTURE_FLAG_FIELD = 'Future__c';
    /**
     * {@value #KEY_VALUE_SETTING_LABEL} Key Value setting label value
     */
     private static String KEY_VALUE_SETTING_LABEL = 'Logging Time To Live';
    
    /**
    *@description enum matching Severity picklist
    */
    private enum SEVERITY {
        ERROR,
        INFO,
        DEBUG,
        TRACE,
        WARN
    }

    /**
    * @description Log Error exception to custom table
    * @param ex         Exception
    * @return Void
    */
    public static void error(Exception ex) {
        logException(ex, SEVERITY.ERROR);
    }
    /**
    * @description Log Info exception to custom table
    * @param ex         Exception
    * @return Void
    */
    public static void info(Exception ex) {
        logException(ex, SEVERITY.INFO);
    }
    /**
    * @description Log Debug exception to custom table
    * @param ex         Exception
    * @return Void
    */
    public static void debug(Exception ex) {
        logException(ex, SEVERITY.DEBUG);
    }
    /**
    * @description Log Trace exception to custom table
    * @param ex         Exception
    * @return Void
    */
    public static void trace(Exception ex) {
        logException(ex, SEVERITY.TRACE);
    }
    /**
    * @description Log Warning exception to custom table
    * @param ex         Exception
    * @return Void
    */
    public static void warn(Exception ex) {
        logException(ex, SEVERITY.WARN);
    }
    
    /**
    * @description Log manual error message to custom logging table
    * @param className     Class Name
    * @param methodName    Method Name
    * @param errorMessage  Error Message
    * @param errorMessage  Error Message
    * @return Void
    */
    public static void error(String className, String methodName, String errorMessage, String recordId) {
        logException(className, methodName, errorMessage, SEVERITY.ERROR, recordId);
    }

  /**
    * @description Log manual error message to custom logging table
    * @param className     Class Name
    * @param methodName    Method Name
    * @param errorMessage  Error Message
    * @return Void
    */
    public static void error(String className, String methodName, String errorMessage) {
        error(className, methodName, errorMessage, '');
    }
  /**
    * @description Log manual info message to custom logging table
    * @param className     Class Name
    * @param methodName    Method Name
    * @param errorMessage  Error Message
    * @return Void
    */
    public static void info(String className, String methodName, String errorMessage) {
        info(className, methodName, errorMessage, '');
    }
    
    /**
    * @description Log manual info message to custom logging table
    * @param className     Class Name
    * @param methodName    Method Name
    * @param errorMessage  Error Message
    * @param recordId  	   Record Id
    * @return Void
    */
    public static void info(String className, String methodName, String errorMessage, String recordId) {
        logException(className, methodName, errorMessage, SEVERITY.INFO, recordId);
    }
  /**
    * @description Log manual debug message to custom logging table
    * @param className     Class Name
    * @param methodName    Method Name
    * @param errorMessage  Error Message
    * @return Void
    */
    public static void debug(String className, String methodName, String errorMessage) {
        logException(className, methodName, errorMessage, SEVERITY.DEBUG, '');
    }
  /**
    * @description Log manual trace message to custom logging table
    * @param className     Class Name
    * @param methodName    Method Name
    * @param errorMessage  Error Message
    * @return Void
    */
    public static void trace(String className, String methodName, String errorMessage) {
        logException(className, methodName, errorMessage, SEVERITY.TRACE, '');
    }
  /**
    * @description Log manual warning message to custom logging table
    * @param className     Class Name
    * @param methodName    Method Name
    * @param errorMessage  Error Message
    * @return Void
    */
    public static void warn(String className, String methodName, String errorMessage) {
        logException(className, methodName, errorMessage, SEVERITY.WARN, '');
    }

    /**
    * @description Log exception to custom table
    * @param ex         Exception 
    * @param severity   enum for severity
    * @return Void
    */
    private static void logException(Exception ex, SEVERITY severity) {
        Set<Id> objectsIdsToDelete = new Set<Id>();
        String stackTrace = ex.getStackTraceString();
        String errorMessage = ex.getMessage();
        String exceptionType = ex.getTypeName();
        Integer lineNumber = ex.getLineNumber();
        String className = stackTrace.startsWith('Class.') ? stackTrace.substringBetween('Class.', '.') : 'Class Undefined';
        String methodName = stackTrace.startsWith('Class.') ? stackTrace.substringBetween(className + '.', ':') : 'Method Undefined';
        if ((!System.isBatch() && !System.isFuture()) || (Test.isRunningTest() && testNonFuture)) {
            logExceptionAsync(className, methodName, errorMessage, exceptionType, stackTrace, lineNumber, severity.name(), '');
            objectsIdsToDelete = deleteRecords(KEY_VALUE_SETTING_LABEL);
            if(!objectsIdsToDelete.isEmpty()) 
            deleteRecordsAsync(objectsIdsToDelete);
        } else {
            logException(className, methodName, errorMessage, exceptionType, stackTrace, lineNumber, severity.name(), '');
            objectsIdsToDelete = deleteRecords(KEY_VALUE_SETTING_LABEL);
            if(!objectsIdsToDelete.isEmpty()) 
            deleteRecordsSync(objectsIdsToDelete);
        }
    }

    /**
    * @description Log manual message to custom logging table
    * @param className     Class Name
    * @param methodName    Method Name
    * @param errorMessage  Error Message
    * @param severity      enum for severity
    * @return Void
    */
    private static void logException(String className, String methodName, String errorMessage, SEVERITY severity, String recordId) {
        Set<Id> objectsIdsToDelete = new Set<Id>();
        if ((!System.isBatch() && !System.isFuture())  || (Test.isRunningTest() && testNonFuture)) {
            logExceptionAsync(className, methodName, errorMessage, null, null, null, severity.name(), recordId);
            objectsIdsToDelete = deleteRecords(KEY_VALUE_SETTING_LABEL);
            if(!objectsIdsToDelete.isEmpty()) 
            deleteRecordsAsync(objectsIdsToDelete);
        } else {
            logException(className, methodName, errorMessage, null, null, null, severity.name(), recordId);
            objectsIdsToDelete = deleteRecords(KEY_VALUE_SETTING_LABEL);
            if(!objectsIdsToDelete.isEmpty()) 
            deleteRecordsSync(objectsIdsToDelete);
        }
    }

    /**
    * @description Log message to custom logging table
    * @param className      Class Name
    * @param methodName     Method Name
    * @param errorMessage   Error Message
    * @param exceptionType  Method Name
    * @param stackTrace     Error Message
    * @param lineNumber     Line Number
    * @param severity       enum string for severity
    * @return Void
    */
    private static void logException(String className, String methodName, String errorMessage, String exceptionType, String stackTrace,
            Integer lineNumber, String severity, String recordId) {

        Schema.SObjectType exceptionLogObjDesc = Schema.getGlobalDescribe().get(LOG_CUSTOM_OBJECT_NAME);
        SObject exceptionLogObj = exceptionLogObjDesc.newSObject();

        exceptionLogObj.put(LOG_CLASS_NAME_FIELD, className);
        exceptionLogObj.put(LOG_METHOD_NAME_FIELD, methodName);
        exceptionLogObj.put(LOG_ERROR_TYPE_FIELD, exceptionType);
        exceptionLogObj.put(LOG_ERROR_LINE_FIELD, lineNumber);
        exceptionLogObj.put(LOG_ERROR_MESSAGE_FIELD, errorMessage);
        exceptionLogObj.put(LOG_STACKTRACE_FIELD, stackTrace);
        exceptionLogObj.put(LOG_SEVERITY_FIELD, severity);
        exceptionLogObj.put(LOG_FUTURE_FLAG_FIELD, true);
        exceptionLogObj.put(LOG_RECORD_ID_FIELD, recordId);

        Database.insert(exceptionLogObj, false);
    }
    
    /**
    * @description Log message to custom logging table Asyncronously
    * Future methods doesn't support passing in an enum so using String instead for severity
    * @param className      Class Name
    * @param methodName     Method Name
    * @param errorMessage   Error Message
    * @param exceptionType  Method Name
    * @param stackTrace     Error Message
    * @param lineNumber     Line Number
    * @param severity       enum string for severity
    * @return Void
    */
    @Future
    private static void logExceptionAsync(String className, String methodName, String errorMessage, String exceptionType, String stackTrace,
            Integer lineNumber, String severity, String recordId) {

        Schema.SObjectType exceptionLogObjDesc = Schema.getGlobalDescribe().get(LOG_CUSTOM_OBJECT_NAME);
        SObject exceptionLogObj = exceptionLogObjDesc.newSObject();

        exceptionLogObj.put(LOG_CLASS_NAME_FIELD, className);
        exceptionLogObj.put(LOG_METHOD_NAME_FIELD, methodName);
        exceptionLogObj.put(LOG_ERROR_TYPE_FIELD, exceptionType);
        exceptionLogObj.put(LOG_ERROR_LINE_FIELD, lineNumber);
        exceptionLogObj.put(LOG_ERROR_MESSAGE_FIELD, errorMessage);
        exceptionLogObj.put(LOG_STACKTRACE_FIELD, stackTrace);
        exceptionLogObj.put(LOG_SEVERITY_FIELD, severity);
        exceptionLogObj.put(LOG_FUTURE_FLAG_FIELD, true);
        exceptionLogObj.put(LOG_RECORD_ID_FIELD, recordId);

        Database.insert(exceptionLogObj, false);
    }

    /**
    * @description Log non-exception message to custom logging table
    * @param messageType    Type - Client Side, Server Side, Exception, etc.
    * @param source         Component or module the message originates from
    * @param message        The message
    * @return Void
    */
    public static void logMessage(String messageType, String source, String message) {

        Boolean future = System.isFuture();
        logMessage(messageType, source, message, future);
    }

    /**
    * @description Log non-exception message to custom logging table
    *              May be used to record future or non-future context based on logFuture flag.
    * @param messageType    Type - Client Side, Server Side, Exception, etc.
    * @param source         Component or module the message originates from
    * @param message        The message
    * @param logFuture      Records the future vs not future context
    * @return Void
    */
    private static void logMessage(String messageType, String source, String message, Boolean logFuture) {

        Schema.SObjectType logObjDesc = Schema.getGlobalDescribe().get(LOG_CUSTOM_OBJECT_NAME);
        SObject logObj = logObjDesc.newSObject();

        logObj.put(LOG_METHOD_NAME_FIELD, source);
        logObj.put(LOG_TYPE_FIELD, messageType);
        logObj.put(LOG_MESSAGE_FIELD, message);
        logObj.put(LOG_FUTURE_FLAG_FIELD, logFuture);

        Database.insert(logObj, false);
    }

    /**
    * @description Log non-exception message to custom logging table Asyncronously
    * @param messageType    Type - Client Side, Server Side, Exception, etc.
    * @param source         Component or module the message originates from
    * @param message        The message
    * @return Void
    */
    @Future
    public static void logMessageAsync(String messageType, String source, String message) {

        logMessage(messageType, source, message);
    }

    /**
    * @description Log non-exception message from Aura/Lightning component for async logging.
    * @param source         Component or module the message originates from
    * @param message        The message
    * @return Void
    */
    @AuraEnabled
    public static void logMessageAura(String source, String message) {
        String messageType = 'Client-Side Message';
        logMessageAsync(messageType, source, message);
    }

    /**
    * @description Log an errors if any after a database save
    * @param Database.SaveResult[] and Source Class + method
    * @return null
    */ 
    @future
    public static void logSaveErrorsAsync(String dbSaveResults,string source){
        List<Database.SaveResult> saveResults = (List<Database.SaveResult>) JSON.deserialize (dbSaveResults, List<Database.SaveResult>.class);
        List<String> errorMessage = new List<String>();
        for (Database.SaveResult saveRes : saveResults) {
            if (!saveRes.isSuccess()) {
                errorMessage.add('The following error has occurred: ');
                for(Database.Error error : saveRes.getErrors()) {
                    errorMessage.add(error.getStatusCode() + ' :: ' + error.getMessage()+' :: '+error.getFields()+  '\n' );
                }
                logMessage('DML Save', source, String.join(errorMessage,' '));
            }
        }
        String errorMessageToLog = String.join(errorMessage,' ');
        if(errorMessage.size()> 0) logMessage('DML Save', source, (errorMessageToLog.length() > 32000 ? errorMessageToLog.substring(0,32000) : errorMessageToLog ));
    }  



 
       public static Integer getRemainingQueryRows(){
            return Limits.getLimitQueryRows() - Limits.getQueryRows();
            //return Limits.getLimitDMLRows() - Limits.getDMLRows();
        }

    /**
    * @description method deletes log records based on criteria
    * @param string label value of key value setting custom metadata
    * @return null
    */ 
    public static Set<Id> deleteRecords(String labelvalue) {
        set<Id> objectsIdsToDelete = new Set<Id>();
        Key_Value_Setting__mdt objkeyvalue = [SELECT Value__c,Description__c,Filter_Criteria__c
                                              FROM Key_Value_Setting__mdt 
                                              where Label =: labelvalue];  // can add Filter_Criteria__c if needed
        Date d = System.today() - integer.valueof(String.valueOf(objkeyvalue.Value__c));
        Map<Id,Log__c> deleteRecordsMap = new Map<Id,Log__c>(
                                                              [Select id from Log__c 
                                                              where CreatedDate < :d
                                                              LIMIT : getRemainingQueryRows()]);

         objectsIdsToDelete = deleteRecordsMap.keySet();
         return objectsIdsToDelete;                                
       }

       @future
       public static void deleteRecordsAsync(Set<Id> objectsIdsToDelete){

              if(!objectsIdsToDelete.isEmpty())
              delete [Select Id from Log__c where Id in : objectsIdsToDelete];
       }

       public static void deleteRecordsSync(Set<Id> objectsIdsToDelete){

              if(!objectsIdsToDelete.isEmpty())
              delete [Select Id from Log__c where Id in : objectsIdsToDelete];
       }


}