/*******
 * @description  Batch class runs daily to populate the Store_Hierarchy__c table with Stores and their corresponding User Hierarchy.
 * @author andyj@slalom.com
 * @version 1.0
 * @date 5/8/2019
 * @group LSCRM
 ******/
global class Batch_DRM_StoreHierarchy  implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //Select All Address Records where Primary = Y and Active = true
        return Database.getQueryLocator([Select Id, 
                                            Primary__c,
                                            Account_Number__c,
                                            Site_Id__c,
                                            Store__c,
                                            Store__r.CRM_ID__c,
                                            Store__r.Store_Number__c
                                         FROM Address__c 
                                            WHERE Primary__c = 'Y' 
                                                AND Status__c = 'Y'
                                                AND Store__c != null]);
    }
    
    global void execute(Database.BatchableContext bc, List<Address__c> scope) {
        //Assemble the Store Records based on Addresses
        Set<Id> storeIds = new Set<Id>();
        Map<Id, List<Address__c>> storeToAddressMap = new Map<Id, List<Address__c>>();
        for(Address__c a:scope) {
            storeIds.add(a.Store__c);
            if(storeToAddressMap.get(a.Store__c)==null) {
                storeToAddressMap.put(a.Store__c, new List<Address__c>());
            }
            storeToAddressMap.get(a.Store__c).add(a);
        }
        try {
            //Get all of the Starbucks Team Records
            List<Starbucks_Team__c> st = [SELECT Store__c, 
                                            SBUX_Title__c,
                                            User__r.SBUX_Title__c, //L1
                                            User__r.Network_ID__c, //L1
                                            User__r.FirstName, //L1
                                            User__r.LastName, //L1
                                            User__r.Id, //L1
                                            User__r.Region__c, //L1
                                            User__r.ManagerId, //L2
                                            User__r.Manager.SBUX_Title__c, //L2
                                            User__r.Manager.Network_ID__c, //L2
                                            User__r.Manager.FirstName, //L2
                                            User__r.Manager.LastName, //L2
                                            User__r.Manager.Region__c, //L2
                                            User__r.Manager.ManagerId, //L3
                                            User__r.Manager.Manager.SBUX_Title__c, //L3
                                            User__r.Manager.Manager.Network_ID__c, //L3
                                            User__r.Manager.Manager.FirstName, //L3
                                            User__r.Manager.Manager.LastName, //L3
                                            User__r.Manager.Manager.Region__c, //L3
                                            User__r.Manager.Manager.ManagerId, //L4
                                            User__r.Manager.Manager.Manager.SBUX_Title__c, //L4
                                            User__r.Manager.Manager.Manager.Network_ID__c, //L4
                                            User__r.Manager.Manager.Manager.FirstName, //L4
                                            User__r.Manager.Manager.Manager.LastName, //L4
                                            User__r.Manager.Manager.Manager.Region__c, //L4
                                            User__r.Manager.Manager.Manager.ManagerId, //L5
                                            User__r.Manager.Manager.Manager.Manager.SBUX_Title__c, //L5
                                            User__r.Manager.Manager.Manager.Manager.Network_ID__c, //L5
                                            User__r.Manager.Manager.Manager.Manager.FirstName, //L5
                                            User__r.Manager.Manager.Manager.Manager.LastName, //L5
                                            User__r.Manager.Manager.Manager.Manager.Region__c, //L5
                                            User__r.Manager.Manager.Manager.Manager.ManagerId, //L6
                                            User__r.Manager.Manager.Manager.Manager.Manager.SBUX_Title__c, //L6
                                            User__r.Manager.Manager.Manager.Manager.Manager.Network_ID__c, //L6
                                            User__r.Manager.Manager.Manager.Manager.Manager.FirstName, //L6
                                            User__r.Manager.Manager.Manager.Manager.Manager.LastName, //L6
                                            User__r.Manager.Manager.Manager.Manager.Manager.Region__c //L6
                                            FROM Starbucks_Team__c
                                            WHERE Store__c in :storeIds
                                                AND User__r.SBUX_Title__c in ('BDM', 'NAE', 'Sr BDM', 'Sr NAE')];
            Map<Id, List<Starbucks_Team__c>> storeToStarbucksTeamMap = new Map<Id, List<Starbucks_Team__c>>();
            for(Starbucks_Team__c s:st) {
                if(storeToStarbucksTeamMap.get(s.Store__c)==null) {
                    storeToStarbucksTeamMap.put(s.Store__c, new List<Starbucks_Team__c>());
                }   
                storeToStarbucksTeamMap.get(s.Store__c).add(s);
            }
            //now that we have all the data, loop through all addresses and build the Store_Hierarchy__c records
            List<Store_Hierarchy__c> insertList = new List<Store_Hierarchy__c>();
            for(Address__c a:scope) {
                if(storeToStarbucksTeamMap.get(a.Store__c)==null) {
                    insertList.add(getStoreHierarchy(a, null));
                    continue;
                }
                for(Starbucks_Team__c s:storeToStarbucksTeamMap.get(a.Store__c)) {
                    insertList.add(getStoreHierarchy(a, s));
                }
            }
            if(!insertList.isEmpty()) {
                insert insertList;
            }
        }catch(Exception e) {
                sdk_LoggerHelper.error('Exception','DRM:UnhandledError:',e.getMessage(), '');
        }
    }
    
    global void finish(Database.BatchableContext bc) {
    
    }
    
    private void setStoreHierarchyLevel(Store_Hierarchy__c sh, Integer level,
                                            String firstName, String lastName, String jobTitle, String loginId,
                                            String crmId, String roleName) {
        
        sh.put('Level' + String.valueOf(level) + '_Employee_First_Name__c', firstName);
        sh.put('Level' + String.valueOf(level) + '_Employee_Last_Name__c', lastName);
        sh.put('Level' + String.valueOf(level) + '_Job_Title__c', jobTitle);
        sh.put('Level' + String.valueOf(level) + '_User_Login_ID__c', loginId);
        sh.put('Level' + String.valueOf(level) + '_User_LSCRM_ID__c', crmId.length()<=15?crmId:String.valueOf(crmId).substring(0, 15));
        sh.put('Level' + String.valueOf(level) + '_User_Role_Name__c', roleName);
    }
    
    private void setDefaultBDMHierarchy(Store_Hierarchy__c sh) {
        setStoreHierarchyLevel(sh, 1, 'TBD BDM', 'LS', 'BDM', 'TBDBDMLS', 'TBDBDMLS', 'TBD BDM');
        setStoreHierarchyLevel(sh, 2, 'TBD RM', 'LS', 'RM', 'TBDRMLS', 'TBDRMLS', 'TBD RM');
        setStoreHierarchyLevel(sh, 3, 'TBD DIR', 'LS', 'Director', 'TBDDIRLS', 'TBDDIRLS', 'TBD DIR');
        setStoreHierarchyLevel(sh, 4, 'TBD VP', 'LS', 'VP', 'TBDVPLS', 'TBDVPLS', 'TBD VP');
    }
    
    public String getJobRole(String region, String sbuxTitle) {
        String returnString = sbuxTitle;
        if(sbuxTitle.equalsIgnoreCase('BDM') || sbuxTitle.equalsIgnoreCase('Sr BDM')
            || sbuxTitle.equalsIgnoreCase('NAE') || sbuxTitle.equalsIgnoreCase('Sr NAE')
            || sbuxTitle.equalsIgnoreCase('RM')) {
                returnString = region + ' ' + returnString;    
           }
        return returnString;
    }
    
    private Store_Hierarchy__c getStoreHierarchy(Address__c a, Starbucks_Team__c st) {
        Store_Hierarchy__c sh = new Store_Hierarchy__c();
        sh.LSCRM_Account_ID__c = a.Store__r.CRM_ID__c;
        sh.Account_Number__c = a.Account_Number__c;
        sh.Site_ID__c = a.Site_Id__c;
        sh.Store_Number__c = a.Store__r.Store_Number__c;
        sh.Primary__c = a.Primary__c;
        if(st==null) {
            //If no Starbucks Team, then only send default BDM values
            setDefaultBDMHierarchy(sh);
            return sh;
        }
        //branch based on BDM, Sr BDM or NAE, Sr NAE
        if(st.SBUX_Title__c=='BDM' || st.SBUX_Title__c=='Sr BDM') {
            setDefaultBDMHierarchy(sh);
            //L1
            setStoreHierarchyLevel(sh, 1, st.User__r.FirstName, st.User__r.LastName, st.User__r.SBUX_Title__c, st.User__r.Network_ID__c, st.User__r.Id, st.User__r.Region__c + ' ' + st.User__r.SBUX_Title__c);
            //L2
            if(st.User__r.ManagerId!=NULL) {
                string jobRole = getJobRole(st.User__r.Manager.Region__c, st.User__r.Manager.SBUX_Title__c);
                setStoreHierarchyLevel(sh, 2, st.User__r.Manager.FirstName, st.User__r.Manager.LastName, st.User__r.Manager.SBUX_Title__c, st.User__r.Manager.Network_ID__c, st.User__r.Manager.Id, jobRole);
            }
            //L3
            if(st.User__r.Manager.ManagerId!=NULL) {
                setStoreHierarchyLevel(sh, 3, st.User__r.Manager.Manager.FirstName, st.User__r.Manager.Manager.LastName, st.User__r.Manager.Manager.SBUX_Title__c, st.User__r.Manager.Manager.Network_ID__c, st.User__r.Manager.Manager.Id, st.User__r.Manager.Manager.SBUX_Title__c);
            }
            //L4
            if(st.User__r.Manager.Manager.ManagerId!=NULL) {
                setStoreHierarchyLevel(sh, 4, st.User__r.Manager.Manager.Manager.FirstName, st.User__r.Manager.Manager.Manager.LastName, st.User__r.Manager.Manager.Manager.SBUX_Title__c, st.User__r.Manager.Manager.Manager.Network_ID__c, st.User__r.Manager.Manager.Manager.Id, st.User__r.Manager.Manager.Manager.SBUX_Title__c);
            }
        }
        else if (st.SBUX_Title__c=='NAE' || st.SBUX_Title__c=='Sr NAE' ) {
            //L1
            setStoreHierarchyLevel(sh, 1, st.User__r.FirstName, st.User__r.LastName, st.User__r.SBUX_Title__c, st.User__r.Network_ID__c, st.User__r.Id, st.User__r.Region__c + ' ' + st.User__r.SBUX_Title__c);
            //L2
            if(st.User__r.ManagerId!=NULL) {
                string jobRole = getJobRole(st.User__r.Manager.Region__c, st.User__r.Manager.SBUX_Title__c);
                setStoreHierarchyLevel(sh, 2, st.User__r.Manager.FirstName, st.User__r.Manager.LastName, st.User__r.Manager.SBUX_Title__c, st.User__r.Manager.Network_ID__c, st.User__r.Manager.Id, jobRole);
            }
            else {
                setStoreHierarchyLevel(sh, 2, 'TBD SR NAE', 'LS', 'Sr NAE', 'TBDSRNAELS', 'TBDSRNAELS', 'TBD SR NAE');
            }
            //L3
            if(st.User__r.Manager.ManagerId!=NULL) {
                setStoreHierarchyLevel(sh, 3, st.User__r.Manager.Manager.FirstName, st.User__r.Manager.Manager.LastName, st.User__r.Manager.Manager.SBUX_Title__c, st.User__r.Manager.Manager.Network_ID__c, st.User__r.Manager.Manager.Id, st.User__r.Manager.Manager.SBUX_Title__c);
                if(st.User__r.Manager.Manager.SBUX_Title__c=='VP') {
                    //bail here if level three is a VP
                    return sh;
                }
            }
            else {
                setStoreHierarchyLevel(sh, 3, 'TBD DIR', 'LS', 'Director', 'TBDDIRLS', 'TBDDIRLS', 'TBD DIR');
            }
            //L4
            if(st.User__r.Manager.Manager.ManagerId!=NULL) {
                setStoreHierarchyLevel(sh, 4, st.User__r.Manager.Manager.Manager.FirstName, st.User__r.Manager.Manager.Manager.LastName, st.User__r.Manager.Manager.Manager.SBUX_Title__c, st.User__r.Manager.Manager.Manager.Network_ID__c, st.User__r.Manager.Manager.Manager.Id, st.User__r.Manager.Manager.Manager.SBUX_Title__c);
            }
            else {
                setStoreHierarchyLevel(sh, 4, 'TBD VP', 'LS', 'VP', 'TBDVPLS', 'TBDVPLS', 'TBD VP');
            }   
        }
        
        return sh;
    }
}