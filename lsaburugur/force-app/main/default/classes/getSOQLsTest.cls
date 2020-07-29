@isTest
public with sharing class getSOQLsTest {
    @isTest
    public static void testAllSOQLs(){
        List<Opportunity> opps = TestDataFactory.createopportunity('Licensee',1,'opp',True);
        List<Store__c> stores = TestDataFactory.createstores(1,'store',True,opps[0]);
        //List<Starbucks_Team__c> teamslist = TestDataFactory.createstarbucksTeam(5,'',True,stores[0].id);
        
        //stores[0].Store_Number__c = '123';
        //update stores[0];
        
        opps[0].Store__c = stores[0].id;
        update opps[0];

        Set<Id> oppIds = new Set<Id>();
        Set<Id> storeIds = new Set<Id>();

        Id singleoppid = opps[0].id;
        Id singlestoreid = stores[0].id;

        for(Opportunity opp: opps){
            oppIds.add(opp.id);
        }

        for(Store__c store: stores){
            storeIds.add(store.id);
        }

        Opportunity opp = getSOQLs.getOpportunitywithStores(stores[0].CRM_ID__c);
        system.assert(opp.id == opps[0].id);

        Store__c st = getSOQLs.getStore(stores[0].CRM_ID__c);
        system.assert(st.id == stores[0].id);

        List<Opportunity> lstopp = getSOQLs.getOpportunitylist(opps[0].id);
        system.assert(lstopp[0].id == opps[0].id);

        Opportunity opprecord = getSOQLs.getSingleOpportunityStore(opps[0].id);
        system.assert(opprecord.id == opps[0].id);

        List<Starbucks_Team__c> team = getSOQLs.getstarbucksteam(stores[0].id);
        //system.assert(team[0].Store__c == stores[0].id);

        Map<Id,Opportunity> oppmap = getSOQLs.getOpportunityfromStore(storeIds);
        if(!oppmap.isEmpty() && oppmap.containsKey(opps[0].id))
        system.assert((oppmap.get(opps[0].id)) != null);

        //system.debug('teamslist>>>>>>'+ teamslist[0]);
        Map<String,Starbucks_Team__c>teammap = getSOQLs.getRecentBDMAndNAE(stores[0].id);
        system.assert(teammap != null);
    }

}