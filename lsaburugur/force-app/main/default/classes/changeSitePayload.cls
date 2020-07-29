/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description generate XML payload body for Change Site
*/

public with sharing class changeSitePayload {

     /*
    @class: ChangestatusDetails 
    @description: generate XML node for Change site request
    */
    
     public class ChangestatusDetails{
        
        public String stagename;
        public String reasoncode;
        public String atlasstatuscomments;

        public ChangestatusDetails(Opportunity opp, String status) {
            if(status.equals('Promote')){
                if(opp.StageName !=null && ( String.valueOf(opp.StageName).equals('In Approval')|| String.valueOf(opp.StageName).equals('In Development') ) )
                this.stagename = 'Promote';
                this.reasoncode = '';
            }
            else if(status.equals('Deactivate')){
                this.stagename ='Deactivate';
                this.reasoncode = UtilityMethod.getinput(opp.Reason_Code__c);
            } 
            
            this.atlasstatuscomments = UtilityMethod.getinput(opp.Atlas_Status_Comments__c);
        }

        public void addToXmlDoc(Dom.XmlNode parentNode) {
          parentNode.addChildElement('statusChange', null, null)
            .addTextNode(this.stagename);
          parentNode.addChildElement('reason', null, null)
            .addTextNode(this.reasoncode);
            parentNode.addChildElement('notes', null, null)
            .addTextNode(this.atlasstatuscomments);
        }

    }

    /*
    @Method: generateXMLChangeSite 
    @description: generate XML node for Change site request
    */
    public static String generateXMLChangeSite(String opportunityId,String status){

        if(opportunityId !=null){

            Opportunity opportunityrecord = getSOQLs.getSingleOpportunityStore(opportunityId);
            ChangestatusDetails statusdetails = new ChangestatusDetails(opportunityrecord,status); 
            Dom.Document requestDoc = new DOM.Document();
            Dom.XmlNode requestMessageNode = requestDoc.createRootElement('retailSite', null, null);
            statusdetails.addToXmlDoc(requestMessageNode);
            return requestDoc.toXmlString();

        }
        else{
            return 'OpportunityId Is Null';
        }

    }
}