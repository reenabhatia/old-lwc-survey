trigger countAttachmentDel on ContentDocument (before delete) {
    list<Non_Compliance_Item__c>nonCompList= new list<Non_Compliance_Item__c>();
    set<id> attIds = new set<id>();
    set<id> attIdsLink = new set<id>();
    integer exCount=0;
    integer delCount=0;
    integer updatedCount=0;
    map<id,list<id>> linkContentMap = new map<id,list<id>>();
    map<id,list<ContentDocumentLink>> linkContentMapExist = new map<id,list<ContentDocumentLink>>();
    if(Trigger.old != null){
        for(ContentDocument c:Trigger.old){
            
            attIds.add(c.id);
        }
    }
    if(attIds.size()>0){
        try{
            List<ContentDocumentLink> attachList = new List<ContentDocumentLink>();
            for (ContentDocumentLink cDocLink: [select id,LinkedEntityId, ContentDocumentId from ContentDocumentLink where ContentDocumentId IN:attIds]){
                 
                attIdsLink.add(cDocLink.LinkedEntityId);
                List<id> delId = new List<id>();
                if(linkContentMap.get(cDocLink.LinkedEntityId) == null){
                   delId.add(cDocLink.ContentDocumentId);
                   linkContentMap.put(cDocLink.LinkedEntityId,delId);
                }else if(linkContentMap.get(cDocLink.LinkedEntityId) != null){
                   
                    linkContentMap.get(cDocLink.LinkedEntityId).add(cDocLink.ContentDocumentId);
                }
                //system.debug('attIdsLinkFOR-- >'+attIdsLink);
            }
            
            //for (Non_Compliance_Item__c cDocLinkVal: [select id,Number_of_attachments__c,(select Id, LinkedEntityId, ContentDocumentId from ContentDocumentLinks) from Non_Compliance_Item__c where id IN :attIdsLink]){
            for (Non_Compliance_Item__c cDocLinkVal: [select id,Number_of_attachments__c,(select Id, LinkedEntityId, ContentDocumentId from ContentDocumentLinks) from Non_Compliance_Item__c where id IN :linkContentMap.KeySet()]){
                nonCompList.add(cDocLinkVal);
                //linkContentMapExist.put(cDocLinkVal.id,cDocLinkVal.ContentDocumentLinks);
            }
            
            for(Non_Compliance_Item__c nonComp:nonCompList){
                exCount = nonComp.ContentDocumentLinks.size();// existing count
                //delCount = attIds.size();// deleted record id count
                delCount = linkContentMap.get(nonComp.id).size();// deleted record id count
                updatedCount = exCount - delCount;
                nonComp.Number_of_attachments__c = updatedCount;
            }
            update nonCompList;
            System.Debug(nonCompList);
        }catch(Exception e){
            System.Debug(e);
        }
    }
    
}