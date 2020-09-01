public class GetComplianceIssues {
    @AuraEnabled(cacheable=true)
    public static list<Issue__c> getIssues(){
        list<Issue__c> issuesList= new list<Issue__c>();
        issuesList=[Select Id,Name,Long_Description__c,category__c,(select id,Action_Plan_Comments__c from Non_Compliance_Items__r) from Issue__c];
        for(Issue__c cr : issuesList){
            if(cr.Long_Description__c!=null){   
                cr.Long_Description__c = cr.Long_Description__c.replaceAll('<[^>]+>',' ');
                //system.debug(cr.Comments__c);
            }
            for(Non_Compliance_Item__c cri: cr.Non_Compliance_Items__r){
                if(cri.Action_Plan_Comments__c!=null){   
                    cri.Action_Plan_Comments__c = cri.Action_Plan_Comments__c.replaceAll('<[^>]+>',' ');
                    //system.debug(cr.Comments__c);
                }
            }
        } 
        
        return issuesList;
    }
    //For the action details
    
    /*public static List<Non_Compliance_Item__c> getActionItems(String storeId) {
List<Non_Compliance_Item__c> nonCompItemList = new List<Non_Compliance_Item__c>();
List<Non_Compliance_Item__c> nonCompItemListFil = new List<Non_Compliance_Item__c>();
list<string> raValuesList = new list<string>();
set<id> storeSpecificCompItems = new set<id>();
//nonCompItemList =[Select Id,Issue__r.Long_Description__c,Recommended_Action__r.Long_Description__c from Non_Compliance_Item__c];
for(Non_Compliance_Item__c crSpec: [Select Id,Issue__r.Long_Description__c,Additional_Recommended_Actions__c from Non_Compliance_Item__c where store__c =:storeId]){
storeSpecificCompItems.add(crSpec.Id);
nonCompItemList.add(crSpec);
raValuesList.add(crSpec.Issue__r.Long_Description__c.replaceAll('<[^>]+>',' '));
}
for(Non_Compliance_Item__c crSpecAll: [Select Id,Issue__r.Long_Description__c,Additional_Recommended_Actions__c from Non_Compliance_Item__c where store__c =null and id not in :storeSpecificCompItems]){
if(raValuesList!=null && !raValuesList.contains(crSpecAll.Issue__r.Long_Description__c.replaceAll('<[^>]+>',' '))){
nonCompItemList.add(crSpecAll);
}
}
system.debug('nonCompItemList --> '+nonCompItemList);
for(Non_Compliance_Item__c cr : nonCompItemList){
if(cr.Issue__r.Long_Description__c!=null && cr.Additional_Recommended_Actions__c!=null && cr.Additional_Recommended_Actions__c!='' && cr.Additional_Recommended_Actions__c!=' '){   
cr.Issue__r.Long_Description__c = cr.Issue__r.Long_Description__c.replaceAll('<[^>]+>',' ');
system.debug(cr.Additional_Recommended_Actions__c+' '+cr.Issue__r.Long_Description__c);

//if(cr.Recommended_Action__r.Long_Description__c!=null && cr.Recommended_Action__r.Long_Description__c!='' && cr.Recommended_Action__r.Long_Description__c!=' '){   
cr.Additional_Recommended_Actions__c = cr.Additional_Recommended_Actions__c.replaceAll('<[^>]+>',' ');
//system.debug(cr.Comments__c);
//}
nonCompItemListFil.add(cr);
}
} 

return nonCompItemListFil;
}*/
    @AuraEnabled(cacheable=true)
    public static map<string,string> getActionItems(String storeId,String viewUrl) {
        //List<Non_Compliance_Item__c> nonCompItemList = new List<Non_Compliance_Item__c>();
        //List<Non_Compliance_Item__c> nonCompItemListFil = new List<Non_Compliance_Item__c>();
        //list<string> raValuesList = new list<string>();
        //set<id> storeSpecificCompItems = new set<id>();
        map<string,string> issueRecommendationMap = new map<string,string>();
        String rAction;
        set<id> nonCompIdsSelected = new set<id>();
        
        for(Recommended_Action__c recmActions: [select id,Long_Description__c,Issue__c,Issue__r.Long_Description__c from Recommended_Action__c]){
            recmActions.Issue__r.Long_Description__c=recmActions.Issue__r.Long_Description__c.replaceAll('<[^>]+>',' ');
            recmActions.Long_Description__c=recmActions.Long_Description__c.replaceAll('<[^>]+>',' ');
            if(issueRecommendationMap==null){
                issueRecommendationMap.put(recmActions.Issue__r.Long_Description__c,recmActions.Long_Description__c);
            }
            else{
                if(!issueRecommendationMap.containsKey(recmActions.Issue__r.Long_Description__c)){
                    issueRecommendationMap.put(recmActions.Issue__r.Long_Description__c,recmActions.Long_Description__c);
                }else{
                    rAction=recmActions.Long_Description__c+';'+issueRecommendationMap.get(recmActions.Issue__r.Long_Description__c);
                    issueRecommendationMap.put(recmActions.Issue__r.Long_Description__c,rAction);
                }
            }
        }
        // Get the specific additional actions
        if(viewUrl.substringafter('c__mode=').substringBefore('&c__type')=='View'){
            for(Non_Compliance__c nonCompRec : [Select id,name,Default_Start_Date__c,Compliance_Items_Ids__c from Non_Compliance__c where Store__c =:storeId and NNC_URL__c=:viewUrl]){
                for(String sIds : nonCompRec.Compliance_Items_Ids__c.split(',')){
                    nonCompIdsSelected.add((id)sIds);
                }
            }
            system.debug('nonCompIdsSelected-- '+nonCompIdsSelected);
            
            for(Non_Compliance_Item__c recmActionsCompItem: [select id,name,Issue__r.Long_Description__c,Additional_Recommended_Actions__c from Non_Compliance_Item__c where id in:nonCompIdsSelected]){
                if (recmActionsCompItem.Additional_Recommended_Actions__c!=null){
                    recmActionsCompItem.Additional_Recommended_Actions__c=recmActionsCompItem.Additional_Recommended_Actions__c.replaceAll('<[^>]+>',' ');
                    recmActionsCompItem.Issue__r.Long_Description__c=recmActionsCompItem.Issue__r.Long_Description__c.replaceAll('<[^>]+>',' ');
                    if(issueRecommendationMap==null){
                        issueRecommendationMap.put(recmActionsCompItem.Issue__r.Long_Description__c,recmActionsCompItem.Additional_Recommended_Actions__c);
                    }
                    else{
                        if(!issueRecommendationMap.containsKey(recmActionsCompItem.Issue__r.Long_Description__c)){
                            issueRecommendationMap.put(recmActionsCompItem.Issue__r.Long_Description__c,recmActionsCompItem.Additional_Recommended_Actions__c);
                        }else{
                            rAction=recmActionsCompItem.Additional_Recommended_Actions__c+';'+issueRecommendationMap.get(recmActionsCompItem.Issue__r.Long_Description__c);
                            issueRecommendationMap.put(recmActionsCompItem.Issue__r.Long_Description__c,rAction);
                        }
                    }
                }
            }
        }       
        return issueRecommendationMap;
    }
    /*@AuraEnabled
public static String saveRecords(String json,String saveStoreId,String recordType,String sUrl) {
Id objectRecordTypeId = Schema.SObjectType.Non_Compliance__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
List<IssueActions> issueAccList=(List<IssueActions>) System.JSON.deserialize(json, List<IssueActions>.class);
system.debug('issueAccList--> '+issueAccList);
set<string> unSelectedCompIds = new set<string>();
String strIssue;
map<string,list<IssueActions.Actionitems>> checkedIdMap = new map<string,list<IssueActions.Actionitems>>();
list<Non_Compliance_Item__c> nonCompList = new list<Non_Compliance_Item__c>();
list<Non_Compliance_Item__c> nonCompListNew = new list<Non_Compliance_Item__c>();
map<string,string> mapComplainceItems = new map<string,string>();
list<Recommended_Action__c> rAcList = new list<Recommended_Action__c>();
map<string,string> isActions = new map<string,string>();
String checkedCompItemsId;
String newCompItemsId;
for (IssueActions Isa: issueAccList){
if(Isa.actionitems!=null){
for(IssueActions.Actionitems isAcItems: Isa.actionitems){
isActions.put(isAcItems.name.trim(),isAcItems.items);
system.debug('isAcItems.name--> '+isAcItems.name.trim());
}
}
if(Isa.Id!=null){
if(checkedCompItemsId==null){
checkedCompItemsId=Isa.Id;
}else{
checkedCompItemsId=checkedCompItemsId+';'+Isa.Id;
}
checkedIdMap.put(Isa.Id,Isa.Actionitems);

}
}
system.debug('checkedIdMap-- >'+ checkedIdMap);
integer i = 0;
for(Non_Compliance_Item__c cmp:[Select Id,Name,Issue__c,Issue__r.Long_Description__c,Recommended_Action__c,Recommended_Action__r.Long_Description__c,Action_Plan_Comments__c,Additional_Recommended_Actions__c from Non_Compliance_Item__c]){
if(!checkedIdMap.containsKey((string)cmp.Id)){
Non_Compliance_Item__c compItem = new Non_Compliance_Item__c(Id=cmp.Id);
unSelectedCompIds.add(cmp.Id);
compItem.Action_Plan_Comments__c='';
nonCompList.add(compItem);

}else if(checkedIdMap.containsKey((string)cmp.Id)){
i=i+1;
system.debug('checkedFOR-- >'+(string)cmp.Id);
//for(IssueActions.Actionitems issueActItems : checkedIdMap.get((string)cmp.Id)){
//Non_Compliance_Item__c compItemChck = new Non_Compliance_Item__c(Id=cmp.Id);
strIssue=cmp.Issue__r.Long_Description__c.replaceAll('<[^>]+>',' ').trim();
if(cmp.Issue__r.Long_Description__c!=null && isActions.containsKey(strIssue)){
Recommended_Action__c rAc = new Recommended_Action__c(Id=cmp.Recommended_Action__c);

//rAc.Long_Description__c = isActions.get(strIssue);
rAc.Long_Description__c=isActions.get(strIssue)+';'+cmp.Additional_Recommended_Actions__c.replaceAll('<[^>]+>',' ').trim();
//system.debug(cr.Comments__c);
rAcList.add(rAc);

}
//cmp.Recommended_Action__r.Long_Description__c = isActions.get(strIssue);
//system.debug(cr.Comments__c);
//nonCompList.add(cmp);
Non_Compliance_Item__c compItemNew = new Non_Compliance_Item__c();
//compItemNew.Name=cmp.Name+'_new'+i;
compItemNew.Store__c=(Id)saveStoreId;
compItemNew.Issue__c=cmp.Issue__c;
compItemNew.Recommended_Action__c=cmp.Recommended_Action__c;
compItemNew.Additional_Recommended_Actions__c=cmp.Additional_Recommended_Actions__c;
nonCompListNew.add(compItemNew);
}


//}

}
// Insert the new compliance items
if (nonCompListNew!=null){
insert nonCompListNew;
}
for(Non_Compliance_Item__c nCid : nonCompListNew)
{
System.debug('Non compliance items Id: ' + nCid.Id);
if(newCompItemsId==null){
newCompItemsId=(String)nCid.Id;
}else{
newCompItemsId=newCompItemsId+';'+(String)nCid.Id;
}

}
//Delete the photos

if(unSelectedCompIds!=null && !unSelectedCompIds.isEmpty()){
list<ContentDocument> cntDocList = new list<ContentDocument>();
for(ContentDocumentLink cdLink:[SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:unSelectedCompIds]){
ContentDocument cntDoc = new ContentDocument(Id=cdLink.ContentDocumentId);
cntDocList.add(cntDoc);
}
delete cntDocList;
}
system.debug('nonCompList-- >'+nonCompList);
// Insert in the Non-Compliance record
if(sUrl.substringafter('c__mode=').substringBefore('&c__type')=='Edit'){
sUrl=sUrl.replace('c__mode=Edit','c__mode=View');
}
Non_Compliance__c nonCompRecd = new Non_Compliance__c();
list<Non_Compliance__c> nonCompRec = new list<Non_Compliance__c>();
nonCompRec = [Select id,name,Default_Start_Date__c from Non_Compliance__c where Store__c =:saveStoreId and NNC_URL__c=:sUrl];
if (nonCompRec.size()==0){
nonCompRecd.Date_of_Evaluation__c=date.today();
nonCompRecd.Store__c=saveStoreId;
nonCompRecd.NNC_URL__c=sUrl;
//nonCompRecd.Compliance_Items_Ids__c=checkedCompItemsId;
nonCompRecd.Compliance_Items_Ids__c=newCompItemsId;
nonCompRecd.Status__c='Draft';
}else{
nonCompRecd = new Non_Compliance__c(Id=nonCompRec[0].Id);
if(checkedIdMap.size()>0){
//nonCompRecd.Compliance_Items_Ids__c=checkedCompItemsId;
nonCompRecd.Compliance_Items_Ids__c=newCompItemsId;
nonCompRecd.Status__c='Draft';
}
}
upsert nonCompRecd;
system.debug('nonCompRecd--> '+nonCompRecd);
upsert rAcList;
//upsert nonCompList;
return (String)nonCompRecd.Id;
}
*/
    @AuraEnabled
    public static String saveRecords(String json,String saveStoreId,String recordType,String sUrl) {
        Id objectRecordTypeId = Schema.SObjectType.Non_Compliance__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        List<IssueActions> issueAccList=(List<IssueActions>) System.JSON.deserialize(json, List<IssueActions>.class);
        system.debug('issueAccList--> '+issueAccList);
        set<string> unSelectedCompIds = new set<string>();
        String strIssue;
        map<string,list<IssueActions.Actionitems>> checkedIdMap = new map<string,list<IssueActions.Actionitems>>();
        list<Non_Compliance_Item__c> nonCompList = new list<Non_Compliance_Item__c>();
        list<Non_Compliance_Item__c> nonCompListNew = new list<Non_Compliance_Item__c>();
        map<string,string> mapComplainceItems = new map<string,string>();
        list<Recommended_Action__c> rAcList = new list<Recommended_Action__c>();
        map<string,string> isActions = new map<string,string>();
        String checkedCompItemsId;
        String newCompItemsId;
        list<Non_Compliance__c> nonCompRec = new list<Non_Compliance__c>();
        nonCompRec = [Select id,name,Default_Start_Date__c,Compliance_Items_Ids__c from Non_Compliance__c where Store__c =:saveStoreId and NNC_URL__c=:sUrl];
        // Get the selected ids of the non-compliance items
        for (IssueActions Isa: issueAccList){
            if(Isa.actionitems!=null){
                for(IssueActions.Actionitems isAcItems: Isa.actionitems){
                    isActions.put(isAcItems.name.trim(),isAcItems.items);
                    system.debug('isAcItems.name--> '+isAcItems.name.trim());
                }
            }
            if(Isa.Id!=null){
                if(checkedCompItemsId==null){
                    checkedCompItemsId=Isa.Id;
                }else{
                    checkedCompItemsId=checkedCompItemsId+','+Isa.Id;
                }
                checkedIdMap.put(Isa.Id,Isa.Actionitems);
                
            }
        }
        system.debug('checkedIdMap-- >'+ checkedIdMap);
        integer i = 0;
        for(Non_Compliance_Item__c cmp:[Select Id,Name,Issue__c,Issue__r.Long_Description__c,Recommended_Action__c,Recommended_Action__r.Long_Description__c,Action_Plan_Comments__c,Additional_Recommended_Actions__c from Non_Compliance_Item__c]){
            // For resetting the unchecked records
            if(!checkedIdMap.containsKey((string)cmp.Id)){
                Non_Compliance_Item__c compItem = new Non_Compliance_Item__c(Id=cmp.Id);
                unSelectedCompIds.add(cmp.Id);
                compItem.Action_Plan_Comments__c='';
                nonCompList.add(compItem);
                
            } // For the checked records
            else if(checkedIdMap.containsKey((string)cmp.Id)){
                system.debug('checkedFOR-- >'+(string)cmp.Id);
                
                strIssue=cmp.Issue__r.Long_Description__c.replaceAll('<[^>]+>',' ').trim();
                if(cmp.Issue__r.Long_Description__c!=null && cmp.Additional_Recommended_Actions__c!=null && cmp.Additional_Recommended_Actions__c.replaceAll('<[^>]+>',' ').trim()!=null){
                    Recommended_Action__c rAc = new Recommended_Action__c();
                    rAc.Long_Description__c=cmp.Additional_Recommended_Actions__c.replaceAll('<[^>]+>',' ').trim();
                    //Attaching the new additional recommeneded actions to the issue;
                    rAc.Issue__c=cmp.Issue__c;
                    rAcList.add(rAc);
                    
                }
                //cmp.Recommended_Action__r.Long_Description__c = isActions.get(strIssue);
                //system.debug(cr.Comments__c);
                //nonCompList.add(cmp);
                
                if(nonCompRec.size()==0){
                    Non_Compliance_Item__c compItemNew = new Non_Compliance_Item__c();
                    compItemNew.Store__c=(Id)saveStoreId;
                    compItemNew.Issue__c=cmp.Issue__c;
                    if(cmp.Additional_Recommended_Actions__c!=null){
                        compItemNew.Additional_Recommended_Actions__c=cmp.Additional_Recommended_Actions__c.replaceAll('<[^>]+>',' ').trim();
                    }
                    // Reset the old record
                    Non_Compliance_Item__c compItem = new Non_Compliance_Item__c(Id=cmp.Id);
                    compItem.Additional_Recommended_Actions__c=null;
                    nonCompList.add(compItem);
                    nonCompListNew.add(compItemNew);
                }else{
                    if(!nonCompRec[0].Compliance_Items_Ids__c.contains((String)cmp.id)){
                        Non_Compliance_Item__c compItemNew = new Non_Compliance_Item__c();
                        compItemNew.Store__c=(Id)saveStoreId;
                        compItemNew.Issue__c=cmp.Issue__c;
                        if(cmp.Additional_Recommended_Actions__c!=null){
                            compItemNew.Additional_Recommended_Actions__c=cmp.Additional_Recommended_Actions__c.replaceAll('<[^>]+>',' ').trim();
                        }
                        // Reset the old record
                        Non_Compliance_Item__c compItem = new Non_Compliance_Item__c(Id=cmp.Id);
                        compItem.Additional_Recommended_Actions__c=null;
                        nonCompList.add(compItem);
                        nonCompListNew.add(compItemNew);  
                    }else{
                        Non_Compliance_Item__c compItemUpd = new Non_Compliance_Item__c(Id=cmp.Id);
                        compItemUpd.Store__c=(Id)saveStoreId;
                        compItemUpd.Issue__c=cmp.Issue__c;
                        if(cmp.Additional_Recommended_Actions__c!=null){
                            compItemUpd.Additional_Recommended_Actions__c=cmp.Additional_Recommended_Actions__c.replaceAll('<[^>]+>',' ').trim();  
                        }
                        nonCompListNew.add(compItemUpd);
                    }
                }
                
                
            }
            
            
            //}
            
        }
        // Insert the new compliance items
        if (nonCompListNew!=null){
            upsert nonCompListNew;
        }
        for(Non_Compliance_Item__c nCid : nonCompListNew)
        {
            System.debug('Non compliance items Id: ' + nCid.Id);
            if(newCompItemsId==null){
                newCompItemsId=(String)nCid.Id;
            }else{
                newCompItemsId=newCompItemsId+','+(String)nCid.Id;
            }
            
        }
        //Delete the photos
        
        if(unSelectedCompIds!=null && !unSelectedCompIds.isEmpty()){
            list<ContentDocument> cntDocList = new list<ContentDocument>();
            for(ContentDocumentLink cdLink:[SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:unSelectedCompIds]){
                ContentDocument cntDoc = new ContentDocument(Id=cdLink.ContentDocumentId);
                cntDocList.add(cntDoc);
            }
            delete cntDocList;
        }
        system.debug('nonCompList-- >'+nonCompList);
        // Insert in the Non-Compliance record
        if(sUrl.substringafter('c__mode=').substringBefore('&c__type')=='Edit'){
            sUrl=sUrl.replace('c__mode=Edit','c__mode=View');
        }
        Non_Compliance__c nonCompRecd = new Non_Compliance__c();
        //list<Non_Compliance__c> nonCompRec = new list<Non_Compliance__c>();
        //nonCompRec = [Select id,name,Default_Start_Date__c from Non_Compliance__c where Store__c =:saveStoreId and NNC_URL__c=:sUrl];
        if (nonCompRec.size()==0){
            nonCompRecd.Date_of_Evaluation__c=date.today();
            nonCompRecd.Store__c=saveStoreId;
            nonCompRecd.NNC_URL__c=sUrl;
            //nonCompRecd.Compliance_Items_Ids__c=checkedCompItemsId;
            nonCompRecd.Compliance_Items_Ids__c=newCompItemsId;
            nonCompRecd.Status__c='Draft';
        }else{
            nonCompRecd = new Non_Compliance__c(Id=nonCompRec[0].Id);
            if(checkedIdMap.size()>0){
                //nonCompRecd.Compliance_Items_Ids__c=checkedCompItemsId;
                nonCompRecd.Compliance_Items_Ids__c=newCompItemsId;
                nonCompRecd.Status__c='Draft';
            }
        }
        upsert nonCompRecd;
        system.debug('nonCompRecd--> '+nonCompRecd);
        if(rAcList!=null){
            //upsert rAcList;
        }
        upsert nonCompList;
        return (String)nonCompRecd.Id;
    }
    
    // Send for the approval 
    @AuraEnabled
    public static String sendForApproval(String json,String storeId,String approveUrl,String approvalRecordType) {
        List<Non_Compliance_Item__c> nonComplianceItemList = new List<Non_Compliance_Item__c>();
        List<IssueActions> issueAccList=(List<IssueActions>) System.JSON.deserialize(json, List<IssueActions>.class);
        Set<Id> checkedCompItemsSet = new Set<Id>();
        Id storeIdSelected = (Id)storeId;
        Integer counter= 0;
        String checkedCompItemsId;
        for (IssueActions Isa: issueAccList){
            if(Isa.Id!=null){
                checkedCompItemsSet.add(Isa.Id); 
                if(checkedCompItemsId==null){
                    checkedCompItemsId=Isa.Id;
                }else{
                    checkedCompItemsId=checkedCompItemsId+';'+Isa.Id;
                }
            }
        }
        system.debug('storeIdSelected-> '+storeIdSelected);
        system.debug('approveUrl-> '+approveUrl);
        Non_Compliance__c nonCompRecd = new Non_Compliance__c();
        list<Non_Compliance__c> nonCompRec = new list<Non_Compliance__c>();
        nonCompRec = [Select id,name,Compliance_Items_Ids__c,Store__c,NNC_URL__c,Status__c from Non_Compliance__c where Store__c = :storeIdSelected and NNC_URL__c=:approveUrl];
        if(nonCompRec.size()==0){
            //Create a NNC record 
            //nonCompRecd.Default_Start_Date__c=date.today();
            if(approveUrl.substringafter('c__mode=').substringBefore('&c__type')=='Edit'){
                approveUrl=approveUrl.replace('c__mode=Edit','c__mode=View');
            }
            nonCompRecd.Date_of_Evaluation__c=date.today();
            nonCompRecd.Store__c=storeIdSelected;
            nonCompRecd.NNC_URL__c=approveUrl;
            nonCompRecd.Compliance_Items_Ids__c=checkedCompItemsId;
            nonCompRecd.Status__c='Sent for Approval';
        }else{
            if(checkedCompItemsSet.isEmpty()){
                for(String strId:nonCompRec[0].Compliance_Items_Ids__c.split(';')){
                    checkedCompItemsSet.add((id)strId);
                    //checkedCompItemsId=checkedCompItemsId+';'+Isa.Id;
                }
            }
            for(Non_Compliance_Item__c cmp:[Select Id,Non_Compliance__c,Issue__r.Category__c,Issue__r.Long_Description__c,Recommended_Action__r.Long_Description__c from Non_Compliance_Item__c where Id in :checkedCompItemsSet]){
                cmp.Non_Compliance__c=nonCompRec[0].Id;
                nonComplianceItemList.add(cmp);
            }
            //nonCompRecd.Compliance_Items_Ids__c
            //nonCompRecd.Compliance_Items_Ids__c=checkedCompItemsId;
            nonCompRecd = new Non_Compliance__c(Id=nonCompRec[0].Id);
            if(checkedCompItemsId!=null){
                nonCompRecd.Compliance_Items_Ids__c=checkedCompItemsId;
            }
            nonCompRecd.Status__c='Sent for Approval';
        }
        upsert nonCompRecd;
        if(nonCompRec.size()==0){
            if(checkedCompItemsSet.isEmpty()){
                for(String strId:nonCompRec[0].Compliance_Items_Ids__c.split(';')){
                    checkedCompItemsSet.add((id)strId);
                }
            }
            for(Non_Compliance_Item__c cmp:[Select Id,Non_Compliance__c,Issue__r.Category__c,Issue__r.Long_Description__c,Recommended_Action__r.Long_Description__c from Non_Compliance_Item__c where Id in :checkedCompItemsSet]){
                cmp.Non_Compliance__c=nonCompRecd.Id;
                nonComplianceItemList.add(cmp);
            }
        }
        /*nonCompRec.Category__c=null;
for(Non_Compliance_Item__c cmp:[Select Id,Issue__r.Category__c,Issue__r.Long_Description__c,Recommended_Action__r.Long_Description__c from Non_Compliance_Item__c where Id in :checkedCompItemsSet]){
counter=counter+1;
if (counter<=1){
nonCompRec.Category__c=counter+'. '+cmp.Issue__r.Category__c;
nonCompRec.Issue_Descriptions__c=counter+'. '+cmp.Issue__r.Long_Description__c.replaceAll('<[^>]+>',' ').trim();
nonCompRec.Recommended_Actions__c=counter+'. '+cmp.Recommended_Action__r.Long_Description__c.replaceAll('<[^>]+>',' ').trim();
}else{
nonCompRec.Category__c=nonCompRec.Category__c+'<br/>'+counter+'. '+cmp.Issue__r.Category__c;
nonCompRec.Issue_Descriptions__c=nonCompRec.Issue_Descriptions__c+'<br/>'+counter+'. '+cmp.Issue__r.Long_Description__c.replaceAll('<[^>]+>',' ').trim();
nonCompRec.Recommended_Actions__c=nonCompRec.Recommended_Actions__c+'<br/>'+counter+'. '+cmp.Recommended_Action__r.Long_Description__c.replaceAll('<[^>]+>',' ').trim();
system.debug('nonCompRec.Category__c--> '+nonCompRec.Category__c);
}
}*/
        upsert nonComplianceItemList;
        return (String)nonCompRecd.Id;
    }
    // New code for the store
    @AuraEnabled(cacheable=true)
    public static StoreIssues getIssuesNew(String storeIdVal,String viewUrl,String recordType){
        list<Issue__c> issuesList= new list<Issue__c>();
        list<Issue__c> issuesListFil= new list<Issue__c>();
        map<string,string> storeCompItemMap = new map<string,string>();
        map<string,string> storeCompItemMapStatus = new map<string,string>();
        set<string> issueLongDesc= new set<string>();
        map<string,Non_Compliance_Item__c> issueMap = new map<string,Non_Compliance_Item__c>();
        list<Non_Compliance_Item__c> crLst = new list<Non_Compliance_Item__c>();
        set<id> issueIds= new set<Id>();
        Id strId = (id)storeIdVal;
        set<id> nonCompIdsSelected = new set<id>();
        if(viewUrl.substringafter('c__mode=').substringBefore('&c__type')=='View'){
            for(Non_Compliance__c nonCompRec : [Select id,name,Default_Start_Date__c,Compliance_Items_Ids__c from Non_Compliance__c where Store__c =:strId and NNC_URL__c=:viewUrl]){
                for(String sIds : nonCompRec.Compliance_Items_Ids__c.split(',')){
                    nonCompIdsSelected.add((id)sIds);
                }
            }
            system.debug('nonCompIdsSelected-- '+nonCompIdsSelected);
            //issuesList=[Select Id,Name,Long_Description__c,category__c,(select id,Action_Plan_Comments__c,Store__c,Number_of_attachments__c,Non_Compliance__r.Status__c,Non_Compliance__r.Store__c,Non_Compliance__r.Compliance_Items_Ids__c,Recommended_Action__r.Long_Description__c from Non_Compliance_Items__r) from Issue__c];
            for (Issue__c crS : [Select Id,Name,Long_Description__c,category__c,(select id,Action_Plan_Comments__c,Store__c,Number_of_attachments__c,Non_Compliance__r.Status__c,Non_Compliance__r.Store__c,Non_Compliance__r.Compliance_Items_Ids__c,Recommended_Action__r.Long_Description__c,Additional_Recommended_Actions__c from Non_Compliance_Items__r where Store__c=:strId and id in:nonCompIdsSelected) from Issue__c]){
                for(Non_Compliance_Item__c cri: crS.Non_Compliance_Items__r){
                    if(cri.Store__c!=null && cri.Store__c==storeIdVal){
                        crS.Long_Description__c=crS.Long_Description__c.replaceAll('<[^>]+>',' ');
                        issueLongDesc.add(crS.Long_Description__c);
                        issueIds.add(crS.Id);
                        
                    }
                }
                //system.debug('INSIDE FOR');
                issuesList.add(crS); 
            }
        }
        //if(issuesList.size()==0){
        for(Issue__c cr : [Select Id,Name,Long_Description__c,category__c,(select id,Action_Plan_Comments__c,Store__c,Number_of_attachments__c,Non_Compliance__r.Status__c,Non_Compliance__r.Store__c,Non_Compliance__r.Compliance_Items_Ids__c,Recommended_Action__r.Long_Description__c,Additional_Recommended_Actions__c from Non_Compliance_Items__r where store__c=null) from Issue__c where id not in :issueIds]){
            /*if(cr.Long_Description__c!=null){   
cr.Long_Description__c = cr.Long_Description__c.replaceAll('<[^>]+>',' ');
//system.debug(cr.Comments__c);
}*/
            for(Non_Compliance_Item__c cri: cr.Non_Compliance_Items__r){
                if(!issueLongDesc.contains(cr.Long_Description__c.replaceAll('<[^>]+>',' ')) && cri.Store__c==null){
                    system.debug('INSIDE STORE NOT NULL');
                    if(cr.Long_Description__c!=null){
                        cr.Long_Description__c = cr.Long_Description__c.replaceAll('<[^>]+>',' ');
                        //cr.Long_Description__c = null;
                        if(cri.Action_Plan_Comments__c!=null){   
                            cri.Action_Plan_Comments__c = cri.Action_Plan_Comments__c.replaceAll('<[^>]+>',' ');
                            //system.debug(cr.Comments__c);
                        }
                        if(cri.Non_Compliance__r.Store__c!=null){
                            /*storeCompItemMapStatus.put((string)cri.Non_Compliance__r.Store__c,cri.Non_Compliance__r.Status__c);
storeCompItemMap.put((string)cri.Non_Compliance__r.Store__c,cri.Non_Compliance__r.Compliance_Items_Ids__c);*/
                        }
                        //issueLongDesc.add(cr.Long_Description__c);
                        //crLst.add(cri);
                    }
                    else{
                        //Issue__c issVal = issuesList.remove(issuesList.indexOf(cr));
                        cr.Long_Description__c = null;
                    }
                    //system.debug('ISSUE REMOVED '+cr.Non_Compliance_Items__r.size());
                    
                    
                }
                
                issuesList.add(cr);
                //issuesList.add(cr);
            }//parent for ends
            //}
            //cr.Non_Compliance_Items__r=crLst;
            //issuesListFil.add(cr);
        }
        String viewUrlRep;
        if(storeIdVal!=null&&viewUrl!=null){
            if(viewUrl.substringafter('c__mode=').substringBefore('&c__type')=='View'){
                //viewUrlRep=viewUrl.replace('c__mode=View','c__mode=Edit');
            }
            list<Non_Compliance__c> nonCompRec = new list<Non_Compliance__c>();
            system.debug('viewUrl -- '+viewUrlRep+'storeIdVal --'+storeIdVal);
            nonCompRec = [Select id,name,Compliance_Items_Ids__c,Status__c from Non_Compliance__c where Store__c =:storeIdVal and NNC_URL__c=:viewUrl];
            if(nonCompRec!=null && nonCompRec.size()>0){
                storeCompItemMapStatus.put(storeIdVal,nonCompRec[0].Status__c);
                storeCompItemMap.put(storeIdVal,nonCompRec[0].Compliance_Items_Ids__c);
            }
        }
        StoreIssues stIssue = new StoreIssues();
        stIssue.issuesList=issuesList;
        stIssue.storeRelatedIds=storeCompItemMap;
        stIssue.storeStatus=storeCompItemMapStatus;
        return stIssue;
    }
    // Get the details to view the NNC record
    @AuraEnabled
    public static string getNNCDetails(String nonComplianceId){
        Non_Compliance__c nonCompRec = [Select id,NNC_URL__c from Non_Compliance__c where id =:nonComplianceId];
        return (string)nonCompRec.NNC_URL__c;
    }
}