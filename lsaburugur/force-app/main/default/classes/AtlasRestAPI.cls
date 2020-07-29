/*****************************
@Author: Nita Disale - Slalom
@Description : Atlas Inbound Rest API update Contract Build
******************************/
@RestResource(urlMapping='/Store__c/*')

global with sharing class AtlasRestAPI {

    @HttpGet
    global static Store__c geSiteById() {
        RestRequest request = RestContext.request;
        // grab the Store ID from the end of the URL
        String storeid = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);
        Store__c result = getSOQLs.getStore(storeid);     
        return result;
    }
    
     /*
    @method : updateStore
    @description : Inbound REST API 'PUT' to update the store and opportunity record based on received request
    */

   @HttpPut
    global static String updateStore() {
       
        RestRequest request = RestContext.request;
        String storeid = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);
        Store__c storeobj = new Store__c();
        Opportunity opp = new Opportunity();
        StoreWrapper wraper = StoreWrapper.parse(request);
        if(storeid != '' && wraper.CRM_ID !=null){
            storeobj = getSOQLs.getStore(storeid);
            opp = getSOQLs.getOpportunitywithStores(storeid);
        }

        if(opp!=null && wraper!=null)
        opp = StoreWrapper.updateOpp(opp,wraper);
        if(opp!=null && opp.id != null)
        update opp;

        if(storeobj!=null && wraper!=null)
        storeobj = StoreWrapper.storeValues(storeobj,wraper);
        if(storeobj!=null)
        update storeobj;

        // Return the Store ID
        return storeobj.CRM_ID__c;

    }

}