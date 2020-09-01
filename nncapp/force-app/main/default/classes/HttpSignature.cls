/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description  : Create HttpSignature for authentication
*/

public with sharing class HttpSignature  {

    private final String keyId;
    private final String algorithm;
    private final String signature;
    private final List<String> headers;


    public HttpSignature(final String keyId, final String algorithm,final String signature,final List<String> headers) {

        this.keyId = keyId;
        this.algorithm = algorithm;
        this.headers = lowercase(headers);  
        this.signature = signature;     
    }
     
     public String getKeyId() {
        return keyId;
    }

    public String getAlgorithm() {
        return algorithm;
    }

     public List<String> getHeaders() {
        return headers;
    }

    public String getSignature() {
        return signature;
    }

    public String getAuthorizationHeader(){

        return 'Signature ' +
               'keyId=\"' + keyId + '\"' +
               ',algorithm=\"' + algorithm + '\"' +
               ',headers=\"' + String.join(headers,' ') + '\"' +
               ',signature=\"' + signature + '\"';

    }

     private List<String> lowercase(List<String> headers) {
        final List<String> listheaders = new List<String>();
        for (String header : headers) {
            listheaders.add(header.toLowerCase());
        }
        return listheaders;
    }

   
}