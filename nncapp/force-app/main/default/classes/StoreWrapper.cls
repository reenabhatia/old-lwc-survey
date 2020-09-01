/*****************************
@Author: Nita Disale - Slalom
@Description : Wrapper class to contain Contract JSON body for Atlas Inbound API 
******************************/
public with sharing class StoreWrapper {

    public String STATUS_INDICATOR;
    public String SITE_STATUS;
    public String ATLAS_SITE_ID;
    public String STORE_TYPE;
    public String RADIUS_RESTRICTION_CHECK_CODE;
    public String LR_DATE;
    public String IMDS_REVIEW;
    public String IMDS_NOTES;
    public String IMDS_APPROVAL;
    public String AGREEMENT;
    public String STORE_NUM;
    public String ESTIMATED_OPEN_DATE;
    public String DEAD_DATE;
    public String RELO_IND;
    public String SITE_NAME;
    public String STORE_PROFILE_TYPE;
    public String COUNTRY;
    public Decimal PLANNED_SQ_FEET;
    public Double LONGITUDE;
    public Double LATTITUDE;
    public String ADDRESS1;
    public String ADDRESS2;
    public String CITY;
    public String STATE_PROVINCE;
    public String POSTAL_CODE;
    public String LR_COMMENT;
    public String SITE_COMMENTS;
    public String ENGINE_TYPE;
    public String PRIMARY_STORE_FLAG;
    public String RELO_ATLAS_ID;
    public String STATE_WAIVER_RESTRICTION;
    public String EXTERNAL_PRESENCE;
    public String SEGMENT;
    public String SUBSEGMENT;
    public String SITE_ID;
    public String CRM_ID;
    public String RELOCATION_STATUS;
    
/*@Method: parse
* @description: Parse the JSON body received from Atlas Inbound Call
*/
    public static StoreWrapper parse(RestRequest req) {
        String jsonbody = req.requestBody.toString();
        return (StoreWrapper) System.JSON.deserialize(jsonbody, StoreWrapper.class);
    }

/*@Method: storeValues
* @description: Update the Store Record values based on received values from Atlas Inbound API call
*/

    public static Store__c storeValues(Store__c storeobj,StoreWrapper wraper){

        storeobj.Atlas_Status_Indicator__c = wraper.STATUS_INDICATOR;
        storeobj.Atlas_Lifecycle_Status__c = wraper.SITE_STATUS;
        storeobj.Atlas_Site_ID__c = wraper.ATLAS_SITE_ID;
        storeobj.Store_Type__c = wraper.STORE_TYPE;
        storeobj.Store_Number__c = wraper.STORE_NUM;
        if(!String.isBlank(wraper.ESTIMATED_OPEN_DATE)) {
        	storeobj.Estimated_Open_Date__c = Date.valueOf(wraper.ESTIMATED_OPEN_DATE);
        }
        storeobj.Relo_Indicator__c = wraper.RELO_IND;
        storeobj.Site_Name__c = wraper.SITE_NAME;
        storeobj.Store_Profile_Type__c = wraper.STORE_PROFILE_TYPE;
        storeobj.Country__c = wraper.COUNTRY;
        if(wraper.PLANNED_SQ_FEET != null)
        storeobj.Planned_Store_Size__c = String.valueOf(wraper.PLANNED_SQ_FEET);
        else
        storeobj.Planned_Store_Size__c =null;

        storeobj.Address_1__c = wraper.ADDRESS1;
        storeobj.Address_2__c = wraper.ADDRESS2;
        storeobj.City__c = wraper.CITY;
        storeobj.State__c = wraper.STATE_PROVINCE;
        storeobj.Postal_Code__c = wraper.POSTAL_CODE;
        storeobj.Relocation_Status__c = wraper.RELOCATION_STATUS;

        Schema.DescribeFieldResult fieldResult = Store__c.Engine_Type__c.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        if(wraper.ENGINE_TYPE != null){
            for( Schema.PicklistEntry v : values) {
            if(v.getValue().equals(wraper.ENGINE_TYPE))
            storeobj.Engine_Type__c  = v.getValue();
          }
        }
        else storeobj.Engine_Type__c = null;
        
        //storeobj.Engine_Type__c = StoreWrapper.getEngineType(wraper.ENGINE_TYPE);
        storeobj.Primary_Store_Flag__c = wraper.PRIMARY_STORE_FLAG;
        storeobj.Relocation_ID__c = wraper.RELO_ATLAS_ID;
        storeobj.External_Presence__c = wraper.EXTERNAL_PRESENCE;
        storeobj.Atlas_Segment__c = wraper.SEGMENT;
        storeobj.Atlas_Subsegment__c = wraper.SUBSEGMENT;
        storeobj.Site_ID__c = wraper.SITE_ID;
        storeobj.Store_Geolocation__Latitude__s = wraper.LATTITUDE;
        storeobj.Store_Geolocation__Longitude__s = wraper.LONGITUDE;
       
        return storeobj;

    }


/*@Method: updateOpp
* @description: Update the Opportunity Record values based on received values from Atlas Inbound API call
*/

    public static Opportunity updateOpp(Opportunity opp,StoreWrapper wraper){
        opp.Atlas_Status_Indicator__c = wraper.STATUS_INDICATOR;
        opp.Atlas_Lifecycle_Status__c = wraper.SITE_STATUS;
        opp.Atlas_Site_ID__c = wraper.ATLAS_SITE_ID;
        opp.Store_Type__c = wraper.STORE_TYPE;
        opp.Radius_Restriction__c = wraper.RADIUS_RESTRICTION_CHECK_CODE;

        if(wraper.LR_DATE !=null)
        opp.Radius_Date__c = Date.valueOf(wraper.LR_DATE);
        else opp.Radius_Date__c = null;

        opp.IMDS_Approval__c = wraper.IMDS_REVIEW;
        opp.IMDS_Notes__c = wraper.IMDS_NOTES;

        if(wraper.IMDS_APPROVAL !=null)
        opp.IMDS_Approval_Date__c = Date.valueOf(wraper.IMDS_APPROVAL);
        else opp.IMDS_Approval_Date__c = null;

        if(wraper.AGREEMENT !=null)
        opp.MLA__c = Boolean.valueOf(wraper.AGREEMENT);
        else opp.MLA__c = False;
        //opp.Store__c = wraper.STORE_NUM;
        if(!String.isBlank(wraper.ESTIMATED_OPEN_DATE)) {
        	opp.CloseDate = Date.valueOf(wraper.ESTIMATED_OPEN_DATE);  //Required and Estimated win date should not be in past
    	}
        if(wraper.DEAD_DATE !=null)
        opp.Atlas_Dead_Date__c = Date.valueOf(wraper.DEAD_DATE);
        else opp.Atlas_Dead_Date__c = null;

        opp.Relo_Indicator__c = wraper.RELO_IND;
        opp.Site_Name__c = wraper.SITE_NAME;
        opp.Store_Profile_Type__c = wraper.STORE_PROFILE_TYPE;
        if(wraper.COUNTRY !=null)
        opp.Country__c = wraper.COUNTRY;
        opp.Planned_Store_Size_ft__c = wraper.PLANNED_SQ_FEET;
        if(wraper.ADDRESS1!=null)
        opp.Address_1__c = wraper.ADDRESS1;  // Required field
        opp.Address_2__c = wraper.ADDRESS2;
        if(wraper.CITY !=null)
        opp.City__c = wraper.CITY;
        if(wraper.STATE_PROVINCE !=null)
        opp.State_Province__c = wraper.STATE_PROVINCE;
        if(wraper.POSTAL_CODE !=null)
        opp.Postal_Code__c = wraper.POSTAL_CODE;
        opp.Radius_Notes__c = wraper.LR_COMMENT;
        opp.Comments__c = wraper.SITE_COMMENTS;

        // Update Engine Type

        Schema.DescribeFieldResult fieldResult = Opportunity.Engine_Type__c.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        system.debug('size>>>>'+ values.size());
        if(wraper.ENGINE_TYPE !=null){
            for( Schema.PicklistEntry v : values) {
            if(v.getValue().equals(wraper.ENGINE_TYPE))
                opp.Engine_Type__c  = v.getValue();
           }
        }
        else opp.Engine_Type__c =null;
        
        opp.Primary_Store_Flag__c = wraper.PRIMARY_STORE_FLAG;
        opp.Relocation_ID__c = wraper.RELO_ATLAS_ID;
        opp.State_Waiver_Restriction__c = wraper.STATE_WAIVER_RESTRICTION;
        opp.External_Presence__c = wraper.EXTERNAL_PRESENCE;
        opp.Atlas_Segment__c = wraper.SEGMENT;
        opp.Atlas_Subsegment__c = wraper.SUBSEGMENT;
        opp.Site_ID__c = wraper.SITE_ID;

        return opp;

    }

    /*public static String getEngineType(String Apiname){

        Schema.DescribeFieldResult fieldResult = Opportunity.Engine_Type__c.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        system.debug('size>>>>'+ values.size());
        Map<String,String> enginetypemap = new Map<String,String>();
        for( Schema.PicklistEntry v : values) {

            enginetypemap.put(v.getValue(),v.getLabel());
        }
        return enginetypemap.get(Apiname);
    }*/

}