@isTest
public class FeedbackControllerTest {
    @isTest
    static void testgetLinkedFeedbacksId(){
        List<Feedback__c> feedbacks = FeedbackTestDataFactory.createFeedbacks(10);
        List<Related_Feedback__c> relatedFeedbacks = FeedbackTestDataFactory.relateFeedbacks(feedbacks);
        Feedback__c baseFeedback = feedbacks.get(0);
        List<Feedback__c> feedbackUnderTest = FeedbackController.getLinkedFeedbacksId(baseFeedback.Id);
        
        system.assert(feedbackUnderTest != null);
    }
}