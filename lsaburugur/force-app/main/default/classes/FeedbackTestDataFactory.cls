/*****************************
Author: Rohit Kaushal
@Description : This is a factory class used to create Feedbacks for testing purpose

Create n feedback
Link every other link to first generated feedback
******************************/
@isTest
// Generate Feedback  
public with sharing class FeedbackTestDataFactory {
    public static List<Feedback__c> createFeedbacks(integer count){
        if (count < 5){
            count = 5;
        }
        List<Feedback__c> newFeedbacks = new List<Feedback__c>();
        for(Integer i = 0;i<count ;i++){
            Feedback__c feedback = new Feedback__c();
            feedback.Name = 'Feedback Title for Test'+i;
            feedback.I_d_Like_To__c='Request a change to existing feature';
            feedback.Related_To__c='Opportunities';
            feedback.Request_Details__c='This is sample request detail for testing with ID ' + i;
            newFeedbacks.add(feedback);
        }
        if (newFeedbacks.size()>0){
            insert newFeedbacks;
        }
        return newFeedbacks;
    }

// Related Feedback    
    public static List<Related_Feedback__c> relateFeedbacks(List<Feedback__c> feedbacks){
        List<Related_Feedback__c> relatedFeedbacks = new List<Related_Feedback__c>();
        Feedback__c baseFeedback = feedbacks.get(0);
        for(Integer i = 1;i<feedbacks.size() ;i++){
            Related_Feedback__c relatedFeeback = new Related_Feedback__c();
            relatedFeeback.Source_Feedback__c = baseFeedback.Id;
            relatedFeeback.Related_To__c = feedbacks.get(i).Id;
            relatedFeedbacks.add(relatedFeeback);
        }
        if(relatedFeedbacks.size()>0){
            insert relatedFeedbacks;
        }
        return relatedFeedbacks;
    }
}