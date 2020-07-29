/****************************************************************
 * @name:       ReturnMessage
 * @author  	andyj@slalom.com
 * @desc:       Custom class that holds returned objects and success/ failure status of Operation
 * @param       data - List<SObject>, success - Boolean , errorMessage - String ,  successMessage - String
 * @return      ReturnMessage - custom class containing returned object and success / failure status
 ****************************************************************/
public class ReturnMessage {
    @AuraEnabled public Boolean isSuccess;
    @AuraEnabled public String errorMessage; 
    @AuraEnabled public String successMessage; 
    @AuraEnabled public Integer responseCode;
    @AuraEnabled public List<SObject> returnedObjects; 
    @AuraEnabled public string data; 
    @AuraEnabled public string requestData; 
    
    public ReturnMessage(){
        isSuccess = true;
        errorMessage = '';
        successMessage = '';
        returnedObjects = new List<SObject>();
        data = '';
        responseCode = 0;
        requestData = '';
    }
}