trigger countAttachments on ContentDocumentLink (after insert, after update, after undelete) {
  Map<Id,List<ContentDocumentLink>> parentMap = new Map<Id,List<ContentDocumentLink>>();
  set<id> attIds = new set<id>();
     
   if(Trigger.new<>null){
       for(ContentDocumentLink c:Trigger.new){
           if(c.LinkedEntityId != null)
               attIds.add(c.LinkedEntityId);
       }
           
   }else if(Trigger.old != null){
       for(ContentDocumentLink c:Trigger.old){
           if(c.LinkedEntityId<>null)      
               attIds.add(Trigger.oldMap.get(c.id).LinkedEntityId);
       }
   }
   if(attIds.size()>0){
       try{
           List<ContentDocumentLink> attachList = new List<ContentDocumentLink>();
           Map<id,Non_Compliance_Item__c> nonCompMap = new Map<id,Non_Compliance_Item__c>([select id,Number_of_attachments__c from Non_Compliance_Item__c where id IN: attIds]);
           attachList = [select id,LinkedEntityId from ContentDocumentLink where LinkedEntityId IN:attIds];
           
           for(ContentDocumentLink at: attachList){
               List<ContentDocumentLink> cDocList = new List<ContentDocumentLink>();
               if(parentMap.get(at.LinkedEntityId) == null){
                   cDocList = new List<ContentDocumentLink>();
                   cDocList.add(at);
                   parentMap.put(at.LinkedEntityId,cDocList);
               }else if(parentMap.get(at.LinkedEntityId) != null){
                   cDocList = new List<ContentDocumentLink>();
                   cDocList = parentMap.get(at.LinkedEntityId);
                   cDocList.add(at);
                   parentMap.put(at.LinkedEntityId,cDocList);
               }
           }
           
           for(Id i: attIds){
               if(nonCompMap.get(i) != null && parentMap.get(i) != null){
                  nonCompMap.get(i).Number_of_attachments__c = parentMap.get(i).size(); 
               
               }else if(nonCompMap.get(i) != null && parentMap.get(i) == null){
                  nonCompMap.get(i).Number_of_attachments__c = 0; 
               }
           }
       
           update nonCompMap.values();
           System.Debug(nonCompMap.values());
       }catch(Exception e){
           System.Debug(e);
       }
    }

}