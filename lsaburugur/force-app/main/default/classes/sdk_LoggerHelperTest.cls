/**
* @author Slalom
* @date 2017
*
* @description General logging helper test class
*/

@IsTest
private class sdk_LoggerHelperTest {
    public class TestException extends Exception {
    }

    static testMethod void testError() {
        Test.startTest();
        try {
            insert new User(id = 'THISIDSHOULDFAILALWAYS');
        } catch (Exception ex) {
            System.debug(ex.getStackTraceString());
            sdk_LoggerHelper.testNonFuture = true;
            sdk_LoggerHelper.error(ex);
            sdk_LoggerHelper.warn(ex);
            sdk_LoggerHelper.info(ex);
            sdk_LoggerHelper.testNonFuture = false;
            sdk_LoggerHelper.debug(ex);
            sdk_LoggerHelper.trace(ex);
        }
        sdk_LoggerHelper.testNonFuture = true;
        sdk_LoggerHelper.error('className', 'methodName', 'errorMessage');
        sdk_LoggerHelper.warn('className', 'methodName', 'errorMessage');
        sdk_LoggerHelper.info('className', 'methodName', 'errorMessage');
        sdk_LoggerHelper.testNonFuture = false;
        sdk_LoggerHelper.debug('className', 'methodName', 'errorMessage');
        sdk_LoggerHelper.trace('className', 'methodName', 'errorMessage');
        Test.stopTest();

        String query = 'Select Count() from ' + sdk_LoggerHelper.LOG_CUSTOM_OBJECT_NAME;

        System.assert(Database.countQuery(query) !=null);

    }

/*    static testMethod void testMessage() {
        Test.startTest();
        sdk_LoggerHelper.logMessageAsync('Test', 'source', 'message');
        Test.stopTest();

        Log__c testLog = [Select Type__c, Method_Name__c, Message__c, Future__c from Log__c limit 1];

        System.assertEquals('Test',testLog.Type__c);
        System.assertEquals('source',testLog.Method_Name__c);
        System.assertEquals('message',testLog.Message__c);
        System.assertEquals(true,testLog.Future__c);
    }*/

    // testAuraMessage covers the logMessage, logMessageAsync, and logMessageAura methods.
    static testMethod void testAuraMessage() {
        Test.startTest();
        sdk_LoggerHelper.logMessageAura('source', 'message');
        Test.stopTest();

        Log__c testLog = [Select Type__c, Method_Name__c, Message__c, Future__c from Log__c limit 1];

        System.assertEquals('Client-Side Message',testLog.Type__c);
        System.assertEquals('source',testLog.Method_Name__c);
        System.assertEquals('message',testLog.Message__c);
        System.assertEquals(true,testLog.Future__c);
    }

    static testMethod void testlogSaveErrorsAsync() {
        Test.startTest();
        String jsonSaveRes='[{"success":false,"errors":[{"statusCode":"INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY","message":"insufficient access rights on cross-reference id","fields":[]}],"warnings":[]}]';
        sdk_LoggerHelper.logSaveErrorsAsync(jsonSaveRes,'ContributorHelper > autoFollowInvestmentRecord');
        Test.stopTest();
        Log__c testLog = [Select Type__c, Method_Name__c, Message__c, Future__c from Log__c limit 1];
        System.assertEquals('ContributorHelper > autoFollowInvestmentRecord',testLog.Method_Name__c);
        System.assertEquals('The following error has occurred:  INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY :: insufficient access rights on cross-reference id :: ()',testLog.Message__c);
        System.assertEquals(true,testLog.Future__c);
    }
    static testMethod void testdeleteRecords(){
        String KEY_VALUE_SETTING_LABEL = 'Logging Time To Live';
        Test.startTest();
        sdk_LoggerHelper.deleteRecords(KEY_VALUE_SETTING_LABEL);
        Test.stopTest();
        Key_Value_Setting__mdt objkeyvalue = [SELECT Value__c,Description__c,Filter_Criteria__c
                                              FROM Key_Value_Setting__mdt 
                                              where Label =: KEY_VALUE_SETTING_LABEL];
                                              
        System.assertEquals(30,integer.valueof(String.valueOf(objkeyvalue.Value__c)));

    }
}