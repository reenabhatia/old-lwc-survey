/*
Created By : Nita Disale -Slalom
Class: provides SOQL query results
Date: 04.10.2019
*/
 /*
    @class: getSOQLs 
    @description: Class used to retrieve all the SOQL queries required based on criteria
    */
public with sharing class getSOQLs {

    public static Opportunity getOpportunitywithStores(String crmid){
    List<Opportunity> Opportunityitems = new List<Opportunity>();

    opportunityitems = [SELECT Id,Atlas_Status_Indicator__c,Atlas_Lifecycle_Status__c,Atlas_Site_ID__c,Reason_Code__c,
                               Store_Type__c,Radius_Restriction__c,Radius_Date__c,IMDS_Approval__c,Atlas_Dead_Date__c,
                               IMDS_Notes__c,IMDS_Approval_Date__c,MLA__c,Store__c,CloseDate,Site_Name__c,Relo_Indicator__c,Store_Profile_Type__c,
                               Country__c,Planned_Store_Size_ft__c,Address_1__c,Address_2__c,City__c,State_Province__c,Postal_Code__c,
                               Radius_Notes__c,Comments__c,Engine_Type__c,Primary_Store_Flag__c,Relocation_ID__c,State_Waiver_Restriction__c,
                               External_Presence__c,Atlas_Segment__c,Atlas_Subsegment__c,Site_ID__c,StageName,Store__r.CRM_ID__c
                                 FROM Opportunity 
                               where Store__r.CRM_ID__c =: crmid
                               AND StageName <>:'Closed Won'];

    
        if(!opportunityitems.isEmpty()) {
            return opportunityitems[0];
        }
        else return new Opportunity();

    }
    public static Store__c getStore(String crmid){

        Store__c allStoresList = new Store__c();
        allStoresList = [select id,Atlas_Status_Indicator__c,Atlas_Lifecycle_Status__c,Atlas_Site_ID__c,
                       Store_Type__c,Store_Number__c,Estimated_Open_Date__c,Relo_Indicator__c,Site_Name__c,Store_Profile_Type__c,
                         Planned_Store_Size__c,Country__c,Address_1__c,Address_2__c,City__c,State__c,Postal_Code__c,Engine_Type__c,
                       Primary_Store_Flag__c,Relocation_ID__c,Site_ID__c,Store_Geolocation__Latitude__s,Store_Geolocation__Longitude__s,
                         External_Presence__c,Atlas_Segment__c,Atlas_Subsegment__c,CRM_ID__c,Licensee__r.Licensee_Code__c,Licensee__c, Relocation_Status__c
                         FROM Store__c
                         where CRM_ID__c =:crmid];

        return allStoresList;                 

    }


    public static List<Opportunity> getOpportunitylist(Id opportunityId){

      List<Opportunity> opplist = new List<Opportunity>();

      opplist = [SELECT Id,Atlas_Segment__c,Atlas_Subsegment__c,CloseDate,Store__r.Site_Name__c,Store__r.Address_1__c,
                        Store__r.Address_2__c,Store__r.City__c,Store__r.State__c,Store__r.Postal_Code__c,
                        Store__r.Store_Type__c,Store__r.Site_ID__c,Store__r.id,Store__r.Licensee__c,Store__r.Licensee__r.Licensee_Code__c,
                        Store__r.Licensee_Store_Number__c,Store__r.External_Presence__c,Store__r.Engine_Type__c,Store__r.Planned_Store_Size__c,
                        Store__r.Store_Profile_Type__c
                        FROM Opportunity 
                        where id =: opportunityId
                        AND StageName <>:'Closed Won' AND StageName <>:'Closed Lost'];

      return opplist;

    }

    public static List<Starbucks_Team__c> getstarbucksteam(Id storeid){
        List<Starbucks_Team__c> team = new List<Starbucks_Team__c>();
        team = [SELECT id,User__r.Username, User__r.Name,User__r.Title,Store__c, User__r.Sbux_Title__c,User__r.Network_ID__c From Starbucks_Team__c 
              		WHERE Store__c=: storeid ];

        return team;        
    }

    public static Map<String,Starbucks_Team__c> getRecentBDMAndNAE(Id storeid){

		    Map<String,Starbucks_Team__c> usermap = new Map<String,Starbucks_Team__c>();
        List<Starbucks_Team__c> bdmteam = new List<Starbucks_Team__c>();
      	List<Starbucks_Team__c> naeteam = new List<Starbucks_Team__c>();

        bdmteam = getSOQLs.getSbux_Title(storeid,'BDM');
      	if(bdmteam.size()>0)
      		usermap.put(String.valueOf(bdmteam[0].User__r.Sbux_Title__c), bdmteam[0]);
        else{
           bdmteam = getSOQLs.getSbux_Title(storeid,'Sr BDM');
           if(bdmteam.size() > 0) usermap.put(String.valueOf(bdmteam[0].User__r.Sbux_Title__c), bdmteam[0]);
        }
        naeteam = getSOQLs.getSbux_Title(storeid,'NAE');
        if(naeteam.size()>0)
          usermap.put(String.valueOf(naeteam[0].User__r.Sbux_Title__c), naeteam[0]);
          else {
             naeteam = getSOQLs.getSbux_Title(storeid,'Sr NAE');
            if(naeteam.size()>0)  usermap.put(String.valueOf(naeteam[0].User__r.Sbux_Title__c), naeteam[0]);
          }
        return usermap;
    }

    public static List<Starbucks_Team__c> getSbux_Title(Id storeid, String sbux_Title){

      return  new List<Starbucks_Team__c>([SELECT id,User__r.Username, User__r.Name,User__r.Title,Store__c, User__r.Sbux_Title__c,User__r.Network_ID__c 
                 From Starbucks_Team__c where Store__c=: storeid 
                 AND  User__r.Sbux_Title__c =: sbux_Title order by createdDate DESC limit 1]);
    }

    public static Opportunity getSingleOpportunityStore(String opportunityId){
        List<Opportunity> opprecord = new List<Opportunity>();
    
        opprecord = [SELECT Id,Atlas_Status_Indicator__c,Atlas_Lifecycle_Status__c,Atlas_Site_ID__c,Reason_Code__c,Atlas_Status_Comments__c,
                                   Store_Type__c,Radius_Restriction__c,Radius_Date__c,IMDS_Approval__c,Atlas_Dead_Date__c,AccountId,
                                   IMDS_Notes__c,IMDS_Approval_Date__c,MLA__c,Store__c,CloseDate,Site_Name__c,Relo_Indicator__c,Store_Profile_Type__c,
                                   Country__c,Planned_Store_Size_ft__c,Address_1__c,Address_2__c,City__c,State_Province__c,Postal_Code__c,
                                   Radius_Notes__c,Comments__c,Engine_Type__c,Primary_Store_Flag__c,Relocation_ID__c,State_Waiver_Restriction__c,
                                   External_Presence__c,Atlas_Segment__c,Atlas_Subsegment__c,Site_ID__c,StageName,Store__r.Licensee_Store_Number__c,
                                   Store__r.id,Store__r.Atlas_Status_Indicator__c,Store__r.Atlas_Lifecycle_Status__c,Store__r.Atlas_Site_ID__c,Store__r.Licensee__r.Name,
                                   Store__r.Store_Type__c,Store__r.Store_Number__c,Store__r.Estimated_Open_Date__c,Store__r.Relo_Indicator__c,Store__r.Site_Name__c,Store__r.Store_Profile_Type__c,
                                   Store__r.Planned_Store_Size__c,Store__r.Country__c,Store__r.Address_1__c,Store__r.Address_2__c,Store__r.City__c,Store__r.State__c,Store__r.Postal_Code__c,Store__r.Engine_Type__c,
                                   Store__r.Primary_Store_Flag__c,Store__r.Relocation_ID__c,Store__r.Site_ID__c,Store__r.Store_Geolocation__Latitude__s,Store__r.Store_Geolocation__Longitude__s,
                                   Store__r.External_Presence__c,Store__r.Atlas_Segment__c,Store__r.Atlas_Subsegment__c,Store__r.CRM_ID__c,Store__r.Licensee__r.Licensee_Code__c,Store__r.Licensee__c
                                   FROM Opportunity 
                                   WHERE Id =: opportunityId limit 1];
                                   //AND StageName <>:'Closed Won' AND StageName <>:'Closed Lost' limit 1];
       

        if(!opprecord.isEmpty()) {
            return opprecord[0];
        }
        else return new Opportunity();

    }
    
    public static Map<Id,Opportunity> getOpportunityfromStore(Set<Id> storeid){
        //List<Opportunity> opprecord = new List<Opportunity>();
        Map<Id,Opportunity> opprecord  = new Map<Id,Opportunity>([SELECT Id,Atlas_Status_Indicator__c,Atlas_Lifecycle_Status__c,Atlas_Site_ID__c,Reason_Code__c,Atlas_Status_Comments__c,
                               Store_Type__c,Radius_Restriction__c,Radius_Date__c,IMDS_Approval__c,Atlas_Dead_Date__c,AccountId,
                               IMDS_Notes__c,IMDS_Approval_Date__c,MLA__c,Store__c,CloseDate,Site_Name__c,Relo_Indicator__c,Store_Profile_Type__c,
                               Country__c,Planned_Store_Size_ft__c,Address_1__c,Address_2__c,City__c,State_Province__c,Postal_Code__c,
                               Radius_Notes__c,Comments__c,Engine_Type__c,Primary_Store_Flag__c,Relocation_ID__c,State_Waiver_Restriction__c,
                               External_Presence__c,Atlas_Segment__c,Atlas_Subsegment__c,Site_ID__c,StageName,Store__r.Licensee_Store_Number__c,
                               Store__r.id,Store__r.Atlas_Status_Indicator__c,Store__r.Atlas_Lifecycle_Status__c,Store__r.Atlas_Site_ID__c,Store__r.Licensee__r.Name,
                               Store__r.Store_Type__c,Store__r.Store_Number__c,Store__r.Estimated_Open_Date__c,Store__r.Relo_Indicator__c,Store__r.Site_Name__c,Store__r.Store_Profile_Type__c,
                               Store__r.Planned_Store_Size__c,Store__r.Country__c,Store__r.Address_1__c,Store__r.Address_2__c,Store__r.City__c,Store__r.State__c,Store__r.Postal_Code__c,Store__r.Engine_Type__c,
                               Store__r.Primary_Store_Flag__c,Store__r.Relocation_ID__c,Store__r.Site_ID__c,Store__r.Store_Geolocation__Latitude__s,Store__r.Store_Geolocation__Longitude__s,
                               Store__r.External_Presence__c,Store__r.Atlas_Segment__c,Store__r.Atlas_Subsegment__c,Store__r.CRM_ID__c,Store__r.Licensee__r.Licensee_Code__c,Store__r.Licensee__c
                               FROM Opportunity 
                               WHERE Store__c IN: storeid
                               AND StageName <>:'Closed Lost']);
    	return opprecord;

    }

}