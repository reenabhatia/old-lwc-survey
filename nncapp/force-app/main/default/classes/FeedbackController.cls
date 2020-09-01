/***********************************
 * Author : Rohit Kaushal
 * @Description : Get Linked Feedbacks
 ***********************************/ 
public with sharing class FeedbackController {
    
    @AuraEnabled
    public static List<Feedback__c> getLinkedFeedbacksId(Id id){
        List<Feedback__c> list1 = [Select f.Name from Feedback__c f 
                                   where f.Id IN (select lf.Related_To__c from Related_Feedback__c lf where lf.Source_Feedback__c = :id)];
        
        List<Feedback__c> list2 = [Select f.Name from Feedback__c f 
                                   where f.Id IN (select lf.Source_Feedback__c  from Related_Feedback__c lf where lf.Related_To__c = :id)];
        
        List<Feedback__c> combinedList = new List<Feedback__c>() ;
        combinedList.addAll(list1);
        combinedList.addAll(list2);
        return combinedList;        
    }
    
    @AuraEnabled
    public static Boolean isLinkCreatable(){
        Boolean ans = Schema.sObjectType.Related_Feedback__c.isCreateable();
        return ans;
    }
}