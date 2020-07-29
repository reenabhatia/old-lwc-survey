/**
* @author Slalom
* @date 2019
*
* @description Atlas proxy class : handler for Http Request to Atlas and Response from Atlas
*/

public with sharing class AtlasProxy {
    private static String NamedCredential_NONPROD = 'callout:Apigee_Integration';
    private static String NamedCredential_PROD = 'callout:Apigee_Production';

	/*MAIN CODE - UNCOMMENT FOR REAL CALL TO ATLAS*/    
    private static String ALGORITHM ='hmac-sha256'; // 
    
    private static String Endpoint = NamedCredential_NONPROD + '/v1/locations/retailsites';
    private static String Endpoint_PROD = NamedCredential_PROD + '/v1/locations/retailsites';
    
    /*  MOCK CALL FOR TESTING - COMMENT WHILE CALLING REAL ATLAS 

    private static String ALGORITHM ='hmac-sha256'; // 
    private static String KEY = 'SAMPLE'; // TBD by SBUX
    private static String APISECRET = 'SAMPLE'; //TBD by SBUX
    private static String Endpoint = 'https://demo7312751.mockable.io/postcreatesite';
    private static String KEY_PROD = 'SAMPLE'; // TBD by SBUX
    private static String APISECRET_PROD = 'SAMPLE'; //TBD by SBUX
    private static String Endpoint_PROD = 'https://demo7312751.mockable.io/postcreatesite';
    */

    //@description: get customized Friendly Messages based on received response code, error code and errorMessage
    
    public static String getFriendlyMessage(Integer responseCode, String errorCode, String errorMessage) {
        try {
            switch on responseCode {
                when 200 {
                    return 'Site successfully updated in Atlas';
                }
                when 201 {
                    return 'Site successfully created in Atlas';
                }
                when 404, 423, 429, 503 {
                    return 'Atlas Service Failure: Reach out to your Business Admin if errors continue.';
                }
                when 400{
                    switch on errorCode {
                        when '4001003' {
                            return 'Provided <attributeName> is not unique in Atlas. Please change Site Name and retry.'.replace('<attributeName>', errorMessage.substringAfter('Duplicate value found:'));    
                        }
                        when '4001004' {
                            return 'There is a problem with the <attributeName> value.  Please correct this value and retry.'.replace('<attributeName>', errorMessage.substringBetween('Value out of range:', 'must'));    
                        }
                        when '4001005' {
                            return 'Please remove special characters and retry.  Reach out to your Business Admin if errors continue.';    
                        }
                        when '4001006' {
                            return 'There is a problem with the address data provided. Reach out to your Business Admin if errors continue.';
                        }
                        when '4001007' {
                            return '<attributeName> is empty.  Reach out to your Business Admin if errors continue.'.replace('<attributeName>', errorMessage.substringAfter('Required attribute is null:'));
                        }
                        when '4001008' {
                            return 'Site status could not be changed in Atlas.  Please contact your Business Admin.';
                        }
                        when '4001009' {
                            return errorMessage + ' : Reach out to your Business Admin if errors continue.';
                        }
                        when '4001010' {
                            return 'Data of an incorrect type has been provided in the <attributeName> field.  Please correct and retry.'.replace('<attributeName>', errorMessage.substringBetween('Datatype mismatch:', 'must be of type'));
                        }
                        when '4001011' {
                            return 'One or more attributes required for the requested state change are null.';
                        }
                        when '4001012' {
                            return 'The requested status change is not allowed from the site\'s current status. Please contact your Business Admin.';
                        }
                        when '4001013' {
                            return 'One or more active projects exists on the site.  Please coordinate with your Store Dev rep to deactivate active projects and try again.';
                        }
                        when else {
                            return 'Unknown error code';
                        }
                    }
                }
                when else {
                    return 'Unknown response code';
                }
            } 
        }catch(Exception e) {
            //If exception parsing the data, send the original error
            return errorMessage;    
        }
    }
    // @description: static co-relation factor (x-corelation) used in Http header
    private static String correlation {
        get {
            return 'LSCRM-' + String.valueOf(System.now()) + String.valueOf(Integer.valueOf(Math.random() *10));
        }
    } 
    //@description: SOQL for Opportunity,given opp id
    public static Opportunity getOpportunity(Id oppId) {
        if(oppId==null) return new Opportunity();
        Opportunity[] opp = [SELECT Id, 
                                    Atlas_Site_ID__c,
                                    Store__c,
                                    Atlas_Lifecycle_Status__c,
                                    StageName
                             FROM Opportunity 
                             WHERE Id = :oppId LIMIT 1];
        if(!opp.isEmpty()) {
            return opp[0];
        }
        return new Opportunity(Id = oppId);  
    }
    
    //@description: get Key and Secret values required for http signature using custom metadata types: Key Value Setting
    public static Map<String, String> getKeyAndSecret() {
        Set<String> keySet = new Set<String>();
        Map<String, String> returnMap = new Map<String, String>{'KEY'=>'', 'SECRET'=>''};
        if(UtilityMethod.IsProduction()) {
        	keySet.add('Apigee_Key_PROD');
            keySet.add('Apigee_Secret_PROD');
            Endpoint = Endpoint_PROD;
        }
        else {
        	keySet.add('Apigee_Key_NONPROD');
            keySet.add('Apigee_Secret_NONPROD');    
        }
        Key_Value_Setting__mdt[] settings = [SELECT DeveloperName, Value__c,Description__c,Filter_Criteria__c
                                              FROM Key_Value_Setting__mdt 
                                              where DeveloperName in: keySet]; 
        
        for(Key_Value_Setting__mdt s:settings) {
            if(s.DeveloperName.tolowerCase().equals('Apigee_Key_PROD'.toLowerCase()) || s.DeveloperName.tolowerCase().equals('Apigee_Key_NONPROD'.toLowerCase())) {
             	returnMap.put('KEY', s.Value__c);   
            }    
            if(s.DeveloperName.tolowerCase().equals('Apigee_Secret_PROD'.toLowerCase()) || s.DeveloperName.tolowerCase().equals('Apigee_Secret_NONPROD'.toLowerCase())) {
             	returnMap.put('SECRET', s.Value__c);   
            }
        }
        return returnMap;
    }
    
    // @description: generate Http Request for create site, update site and change site and deactivate site
    public static HttpRequest generateRequest(String method, String body, Opportunity opp, String status) {
        String httpsignature;
        String updateEndpoint = '';
        String promoteEndpoint = '';
        HttpRequest req = new HttpRequest();
        List<String> required = new List<String>();
        required.add('date');
        required.add('digest');
        required.add('(request-target)');
        
		Map<String, String> keyAndSecret = AtlasProxy.getKeyAndSecret();
        final HttpSignature signature = new HttpSignature(keyAndSecret.get('KEY'), ALGORITHM, '', required);
        final Signer signer = new Signer(signature,ALGORITHM,keyAndSecret.get('SECRET'));
        String response;
        String digest = SitecallHandler.createdigest(body);
        DateTime myDateTime = System.now();
        String formatteddate = myDateTime.formatGMT('EEE, dd MMM yyyy HH:mm:ss') + ' ' + 'GMT';

        if(method.equals('POST') && status !='Promote' && status != 'Deactivate')
        httpsignature = SitecallHandler.createsitesignature(signature,signer,opp,formatteddate,digest);  // get http signature for create site
        if(method.equals('PUT') && status !='Promote' && status != 'Deactivate'){
            
            httpsignature = SitecallHandler.updatesitesignature(signature,signer,opp,formatteddate,digest);   // get http signature for update site
            updateEndpoint = Endpoint + '/'+ opp.Atlas_Site_ID__c;
            system.debug('update Endpoint>>>>>' + updateEndpoint);
        }
        if(method.equals('POST') && (status.equals('Promote') || status.equals('Deactivate'))) {
            
            httpsignature = SitecallHandler.changesitestatussignature(signature,signer,opp,formatteddate,digest);  // get http signature for change site
            promoteEndpoint = Endpoint + '/'+ opp.Atlas_Site_ID__c + '/status';
            system.debug('changesite Endpoint>>>>>' + promoteEndpoint);
        }

        Map<String,String> headers = new Map<String,String>();
        headers.put('formatteddate', formatteddate);
        headers.put('digest',digest);
        headers.put('httpsignature',httpsignature);
        headers.put('correlation', AtlasProxy.correlation);

        if(method.equals('PUT') && status !='Promote' && status != 'Deactivate')
        return UtilityMethod.httpRequestGenerator(method,updateEndpoint,headers,body);
        else if(method.equals('POST') && (status.equals('Promote') || status.equals('Deactivate')))
        return UtilityMethod.httpRequestGenerator(method,promoteEndpoint,headers,body);
        else 
        return UtilityMethod.httpRequestGenerator(method,Endpoint,headers,body);
    }
    
    public static ReturnMessage createSite(Id oppId) {
        return callAtlasInsertUpdateChangeSite(oppId, 'POST','');   
    }
    
    public static ReturnMessage updateSite(Id oppId) {
        return callAtlasInsertUpdateChangeSite(oppId, 'PUT','');    
    }

    public static ReturnMessage promoteSite(Id oppId) {
        return callAtlasInsertUpdateChangeSite(oppId, 'POST','Promote');   
    }

    public static ReturnMessage deactivateSite(Id oppId) {
        return callAtlasInsertUpdateChangeSite(oppId, 'POST','Deactivate');   
    }
    
    /*
    @method : callAtlasInsertUpdateChangeSite
    @description : Send Http request to Atlas and receive response back, 
                  based on response add record to log object,error or success response to log records
    */
    private static ReturnMessage callAtlasInsertUpdateChangeSite(Id oppId, String method,String status) {
        ReturnMessage rm = new ReturnMessage();
        String body;
        try{
            Opportunity opp = getOpportunity(oppId);
            if(status != '')
                body = changeSitePayload.generateXMLChangeSite(opp.Id,status);
            else
                body = AtlasPayload.generateXMLPayload(opp.Id);
            HttpRequest req = generateRequest(method, body, opp,status);
            system.debug('req>>>>>'+req);
    
            //if([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox)
            //req.setEndpoint('callout:Apigee_Dev/locations/retailSites');
            //else
            //req.setEndpoint('callout:Apigee_Production/locations/retailSites');
            Http http = new Http();
            HttpResponse resp = http.send(req);
            //DMLs can happen after the callout
            if(!System.isBatch()) {
            	sdk_LoggerHelper.info('Integration Message','AtlasProxy:Request',req.getBody(), String.valueOf(oppId));
            }
            else {
                rm.requestData = req.getBody();
            }
            
            system.debug('REQUEST >>>' + req.getBody());
            system.debug('RESPONSE CODE >>>>> '+resp.getStatusCode());
            system.debug(resp.getBody());

            String response = resp.getBody();
            if(resp.getStatusCode() == 200 || resp.getStatusCode() == 201){
                system.debug('response>>>>>>' + response);
                rm.isSuccess = True;
                rm.data = response;
                rm.successMessage = AtlasProxy.getFriendlyMessage(resp.getStatusCode(), null, null);
                if(resp.getStatusCode() == 201)
                parseAtlasResponse(rm, resp.getStatusCode(), response);
                if(!System.isBatch()) {
                	sdk_LoggerHelper.info('Integration Message','AtlasProxy:Response:' + resp.getStatusCode(),resp.getBody(), String.valueOf(oppId));
                }
            
            }else{
                system.debug('response>>>>'+response);
                rm.isSuccess = false;
                rm.data = response;
                AtlasProxy.parseErrors(rm, resp.getStatusCode(), response);
                if(!System.isBatch()) {
                	sdk_LoggerHelper.error('Integration Message','AtlasProxy:Error:' + resp.getStatusCode(),resp.getBody(), String.valueOf(oppId));
                }
            }
        
        } catch(Exception e){
            rm.isSuccess = false;
            rm.errorMessage ='An exception has been encountered while calling out to integration '+ e.getMessage();
            if(!System.isBatch()) {
            	sdk_LoggerHelper.error('Integration Message','AtlasProxy:UnhandledError:',e.getMessage(), String.valueOf(oppId));
            }
        }
        return rm;
    }
    
     /*
    @method : parseErrors
    @description : Parse the received error response XML 
    */
    private static void parseErrors(ReturnMessage rm, Integer responseCode, String xmlResponse) {
        rm.data = xmlResponse;
        rm.responseCode = responseCode;
        Dom.Document doc = new Dom.Document();
        String errorCode = '';
        String errorMessage = '';
        try {
            doc.load(xmlResponse);
            //Retrieve the root element for this document.
            Dom.XMLNode ErrorNode = doc.getRootElement();
            errorCode = ErrorNode.getChildElement('code', null).getText();
        	errorMessage = ErrorNode.getChildElement('message', null).getText();
        } catch(Exception e) {
            //don't do anything if we have an XML parsing error, at least pass through the response
        }
        
        rm.errorMessage = AtlasProxy.getFriendlyMessage(responseCode, errorCode, errorMessage);
    }
    
    /*
    @method : parseAtlasResponse
    @description : Parse the received Success response XML for Create Site
    */
    private static void parseAtlasResponse(ReturnMessage rm, Integer responseCode, String xmlResponse) {
        rm.data = xmlResponse;
        rm.responseCode = responseCode;
        Dom.Document doc = new Dom.Document();
        doc.load(xmlResponse);
        //Retrieve the root element for this document.
        Dom.XMLNode detailsNode = doc.getRootElement();
        sObject dataObject = new Opportunity();
        dataObject.put('Atlas_Site_ID__c', detailsNode.getChildElement('retailSiteID', null).getText());
        rm.returnedObjects.add(dataObject);
    }
}