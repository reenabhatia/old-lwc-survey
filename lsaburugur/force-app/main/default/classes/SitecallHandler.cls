/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description Create Site, Update Site and Change site status
*/

public with sharing class SitecallHandler {

    private static String METHOD;
    private static String URI;
    private static String DIGESTALGORITHM = 'sha-256';

/*@Method: createsitesignature
* @description: generate the http Signature for create site call
*/

    public static String createsitesignature(HttpSignature signature,Signer signer,Opportunity opp,String dateval,String digest){

        METHOD ='POST';
        URI ='/v1/locations/retailsites';
        Map<String,String> headers = new Map<String,String>();
        headers.put('Date', dateval);
        headers.put('Digest', digest);
        final HttpSignature signed = signer.sign(method, uri, headers);
        System.debug('createsitesignature>>>>>>>>>'+ signed.getAuthorizationHeader());
        return signed.getAuthorizationHeader();
    }



/*@Method: updatesitesignature
* @description: generate the http Signature for Update site API call
*/
    public static String updatesitesignature(HttpSignature signature,Signer signer,Opportunity opp,String dateval,String digest){

        METHOD ='PUT';
        URI ='/v1/locations/retailsites/'+ opp.Atlas_Site_ID__c;
        Map<String,String> headers = new Map<String,String>();
        headers.put('Date', dateval);
        headers.put('Digest', digest);
        final HttpSignature signed = signer.sign(method, uri, headers);
        System.debug('updatesitesignature>>>>>>>>>'+ signed.getAuthorizationHeader());
        return signed.getAuthorizationHeader();
    }


/*@Method: changesitestatussignature
* @description: generate the http Signature for Change site API call
*/
     public static String changesitestatussignature(HttpSignature signature,Signer signer,Opportunity opp,String dateval,String digest){

        METHOD ='POST';
        URI ='/v1/locations/retailsites/'+ opp.Atlas_Site_ID__c + '/status';
        Map<String,String> headers = new Map<String,String>();
        headers.put('Date', dateval);
        headers.put('Digest', digest);
        final HttpSignature signed = signer.sign(method, uri, headers);
        System.debug('changesitestatussignature>>>>>>>>>'+ signed.getAuthorizationHeader());
        return signed.getAuthorizationHeader();
    }

/*@Method: createdigest
* @description: generate the digest using provided payload
*/
    public static String createdigest(String payload){

        Blob b = Crypto.generateDigest(DIGESTALGORITHM, Blob.valueOf(payload));
        return 'sha-256='+ System.encodingUtil.base64Encode(b);
    }

    
}