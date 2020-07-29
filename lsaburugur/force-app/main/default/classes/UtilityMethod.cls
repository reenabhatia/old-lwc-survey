/*****************************
Author: Nita Disale - Slalom
Description: The purpose of this class is to hold all methods that can be shared across classes and triggers
******************************/
public with sharing class UtilityMethod {
    
	public static User getuser(String name){
      User user = [select id,username from User where Name =: name];
      return user;
    }


    /*public static String getEnvType(String labelenv){
      String envtype;

      if([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox){
           
           Salesforce_Instance__mdt objval = [SELECT Environment__c FROM Salesforce_Instance__mdt where Label =: labelenv];                                               
           envtype = objval.Environment__c;     
       }
      else envtype = 'prod';

      return envtype; 
    }*/  

/*@Method: getinput
* @description: return empty string if input is null
*/
    public static String getinput(String input) {
      return input == null ? '' : input;
    }

/*@Method: countrycode
* @description: return countrycode USA and CAN based on condition
*/
     public static String countrycode(String code){
      if(code.equals('US')) return 'USA';
      else
      if(code.equals('CA')) return 'CAN';
      else 
      return 'Invalid countrycode';
     }

/*@Method: httpRequestGenerator
* @description: Http request generator
*/
     public static HttpRequest httpRequestGenerator(String reqMethod, String endpoint, Map<String,String> headers, String reqBody){
        
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod(reqMethod);
        httpRequest.setEndpoint(endpoint);
        httpRequest.setHeader('Date', headers.get('formatteddate'));
        httpRequest.setHeader('Digest', headers.get('digest'));
        httpRequest.setHeader('Content-type', 'application/xml');
        httpRequest.setHeader('Accept', 'application/xml');
        httpRequest.setHeader('Authorization', headers.get('httpsignature'));
        httpRequest.setHeader('x-correlation-id', headers.get('correlation'));
        httpRequest.setBody(reqBody);
        return httpRequest;
    }

    public static Task createActivityOnDeactivate(Id oppid){
        if(oppid == null) return new Task();
        RecordType rt = UtilityMethod.getRecordTypesByDeveloperName(Task.SObjectType.getDescribe()).get('Ls_Activities');
        
        User user =  UtilityMethod.getuser('SYSTEM');

        Task tsk = new Task(
            whatID = oppid,
            Ownerid = user.Id,
            Queue_Name__c ='LS CR Queue',
            Type ='Deactivate - Close Projects',
            Task_Type__c ='Deactivate - Close Projects',
            Status ='Not Started',
            Subject = 'Deactivate - Close Projects',
            RecordTypeId = rt.Id,
            Reason_Code__c = 'Deactivation',
            Description = 'Deactivate - Close Projects'
        );

        insert tsk;
        return tsk;
    }
    
    //For testing purposes, you can set the Production override by setting this static variable
    public static boolean isProductionOverride = false;
    //For testing purposes, you can set this fakeTestOrg, to fake being in a test org when running tests in Prod
    public static boolean isTestOverride = false;
    public static boolean IsProduction() {
        if(isProductionOverride) {
            return true;
        }
        else if (isTestOverride) {
            return false;
        }
        else {
            return (![Select IsSandbox from Organization limit 1].IsSandbox);
        }
    }
    
    /**
    * @description Retrieve a Map of RecordType Names for a given SObjectType
    * @param objectType SObjectType to retrieve record types for
    * @return A Map of RecordType developer names to RecordType
    */ 
    private static Map<String, Map<String, RecordType>> recordTypesByDeveloperNameMap = new Map<String, Map<String, RecordType>>();
    public static Map<String, Schema.RecordType> getRecordTypesByDeveloperName(Schema.SObjectType objectType) {
        Schema.DescribeSObjectResult objectTypeDescribe = objectType.getDescribe();

        if (recordTypesByDeveloperNameMap.get(String.valueOf(objectTypeDescribe.getKeyPrefix())) == null) {
            Map<String,Schema.RecordTypeInfo> developerNameToSchemaRecordTypeInfoMap = objectTypeDescribe.getRecordTypeInfosByDeveloperName();
            
            Map<String, RecordType> rtMap = new Map<String, RecordType>();
            for (Schema.RecordTypeInfo rti :developerNameToSchemaRecordTypeInfoMap.values()) {
                RecordType rt = new RecordType(
                    Id = rti.getRecordTypeId(),
                    Name = rti.getName(),
                    DeveloperName = rti.getDeveloperName(),
                    IsActive = rti.isActive()
                );
                rtMap.put(rt.DeveloperName, rt);
            }
            recordTypesByDeveloperNameMap.put(String.valueOf(objectTypeDescribe.getKeyPrefix()), rtMap);
        }

        return recordTypesByDeveloperNameMap.get(String.valueOf(objectTypeDescribe.getKeyPrefix()));
    }

    public static Map<String, RecordType> getRecordTypesByDeveloperName(Schema.DescribeSObjectResult objectType) {
        return getRecordTypesByDeveloperName(objectType.getSObjectType());
    }
}