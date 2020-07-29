/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description Create signer : signature – The Base64 encoded result of 
   signing the ‘signing string’ using the hmac-sha256 algorithm and the provided secret key
*/


public with sharing class Signer {

    public final HttpSignature signature;
    public final String algorithm;
    public final String key;


    public Signer(HttpSignature signature, String algorithm,String key) {

        this.signature = signature;
        this.algorithm = algorithm;  
        this.key = key;   // provided secret key
    }



    public HttpSignature sign(final String method, final String uri, final Map<String, String> headers){
        final String signedAndEncodedString;

        try{
            
            final String signingString = createSigningString(method, uri, headers);

            Blob hmacData = Crypto.generateMac(this.algorithm, Blob.valueOf(signingString), Blob.valueOf(this.key));

            signedAndEncodedString = System.encodingUtil.base64Encode(hmacData);

        }catch(Exception ex){
            system.debug('Exception>>>>' + ex.getMessage());

        }
        return new HttpSignature(signature.getKeyId(), signature.getAlgorithm(), signedAndEncodedString, signature.getHeaders());
    }




    public String createSigningString(String method,String uri, Map<String, String> headers) {
        return Signer.createSigningString(signature.getHeaders(), method, uri, headers);
    }


     public static String createSigningString(List<String> required, String method,String uri, Map<String, String> headers) {
        
        headers = lowercase(headers);
        List<String> listheaders = new List<String>();

        for (String key : required) {
            if ('(request-target)'.equals(key)) {
                method = lowercase(method);
                listheaders.add('(request-target):'+ ' '+ method + ' ' + uri);
         
            }else {
                if(headers.containsKey(key)){            
                    String value = headers.get(key);
                    if(value!=null)
                        listheaders.add(key + ': ' + value);
                }           
            }    
        }

        system.debug('createSigningString>>>>>>'+ String.join(listheaders,'\n'));

        return String.join(listheaders,'\n');
    }


    public static Map<String, String> lowercase(Map<String, String> headers) {
        Map<String, String> headersmap = new Map<String, String>();
        for (String entry : headers.keySet()) {
            headersmap.put(entry.toLowerCase(), headers.get(entry));
        }

        return headersmap;
    }

    public static String lowercase(String spec) {
        return spec.toLowerCase();
    }

}