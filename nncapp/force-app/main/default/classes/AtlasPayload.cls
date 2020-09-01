/**
* @author Nita Disale - Slalom
* @date 2019
*
* @description generate XML payload body for Create Site and Update Site
*/

public without sharing class AtlasPayload {

    /*
    @class: OpportunityDetails 
    @description: generate XML node for Opportunity object 
    */
    public class OpportunityDetails{
        
        public String estimatedwindate;
        public String atlasSegment;
        public String atlasSubsegment;

        public OpportunityDetails(Opportunity opp) {
         if(opp.CloseDate !=null)
         this.estimatedwindate = UtilityMethod.getinput(String.valueOf(opp.CloseDate));
         else this.estimatedwindate = '';
         this.atlasSegment = UtilityMethod.getinput(opp.Atlas_Segment__c);
         this.atlasSubsegment = UtilityMethod.getinput(opp.Atlas_Subsegment__c);
        }

        public void addToXmlDoc(Dom.XmlNode parentNode) {
          parentNode.addChildElement('estimatedOpenDate', null, null)
            .addTextNode(estimatedwindate);
          parentNode.addChildElement('segmentCode', null, null)
            .addTextNode(atlasSegment);
          parentNode.addChildElement('subSegmentCode', null, null)
            .addTextNode(atlasSubsegment);
        }

    }


  // @description: Generate XML node for starbuckks team object
    public class StarbucksTeamDetails{
        
        public String loginId;
        public String name;
        public String title;

        public StarbucksTeamDetails(Starbucks_Team__c team) {
            this.loginId = UtilityMethod.getinput(team.User__r.Network_ID__c);
            this.name = UtilityMethod.getinput(team.User__r.Name);
            if(UtilityMethod.getinput(team.User__r.Sbux_Title__c).equals('Sr BDM'))
            this.title = 'BDM';
            else if(UtilityMethod.getinput(team.User__r.Sbux_Title__c).equals('Sr NAE'))
            this.title = 'NAE';
            else 
            this.title = UtilityMethod.getinput(team.User__r.Sbux_Title__c);         
        }

        public void addToXmlDoc(Dom.XmlNode parentNode) {

          Dom.XmlNode assignedPartnernode = parentNode.addChildElement('assignedPartner',null,null);
          assignedPartnernode.addChildElement('id', null, null)
            .addTextNode(this.loginId);
          assignedPartnernode.addChildElement('name', null, null)
            .addTextNode(this.name);
          assignedPartnernode.addChildElement('role', null, null)
            .addTextNode(this.title);
        }

    }

    //@description:generate XML node for Store Object

    public class StoreDetails{

        public String sitename;
        public string address1;
        public String address2;
        public String city;
        public string state;
        public string postalcode;
        public string country;
        public String storetype;
        public String brandCode;
        public String ownershipType;
        public String storeId;
        public String licenseecode;
        public String licensee;
        public String storenumber;
        public String externalpresence;
        public String enginetype;
        public String plannedStoreSize;
        public String storeprofileType;


        public StoreDetails(Opportunity opportunityrecord) {
            this.sitename = UtilityMethod.getinput(opportunityrecord.Store__r.Site_Name__c);
            this.address1 = UtilityMethod.getinput(opportunityrecord.Store__r.Address_1__c);
            this.address2 = UtilityMethod.getinput(opportunityrecord.Store__r.Address_2__c);
            this.city = UtilityMethod.getinput(opportunityrecord.Store__r.City__c);
            this.state = UtilityMethod.getinput(opportunityrecord.Store__r.State__c);
            
            String postal = UtilityMethod.getinput(opportunityrecord.Store__r.Postal_Code__c);
            if(postal.contains('-')) postal = postal.replaceAll('-', '');
            if(postal.length() > 9) postal = postal.substring(0,9);
            this.postalcode = postal;
          
            this.country = UtilityMethod.countrycode(UtilityMethod.getinput(opportunityrecord.Store__r.Country__c));
            this.storetype = UtilityMethod.getinput(opportunityrecord.Store__r.Store_Type__c);
            this.brandCode = 'SBUX';
            this.ownershipType = 'LS';
            this.storeId = UtilityMethod.getinput(opportunityrecord.Store__r.CRM_ID__c);
            this.licenseecode = UtilityMethod.getinput(opportunityrecord.Store__r.Licensee__r.Licensee_Code__c);
            if(opportunityrecord.Store__r.Licensee__c!=null){
                String code = UtilityMethod.getinput(opportunityrecord.Store__r.Licensee__r.Licensee_Code__c);
                if(code.equals('NEWLICEN'))
                this.licensee = 'New Licensee';
                else
                this.licensee = UtilityMethod.getinput(String.valueOf(opportunityrecord.Store__r.Licensee__r.name));
            }
            else this.licensee = '';
            //system.debug('this.licensee>>>>>>'+this.licensee);
            String storenumberval = UtilityMethod.getinput(opportunityrecord.Store__r.Licensee_Store_Number__c);
            if(storenumberval != null || storenumberval != '')
            if(storenumberval.length() > 15) storenumberval = storenumberval.substring(0,15);
            this.storenumber = storenumberval;

            this.externalpresence = UtilityMethod.getinput(opportunityrecord.Store__r.External_Presence__c);
            if(opportunityrecord.Store__r.Engine_Type__c !=null)
            this.enginetype = UtilityMethod.getinput(String.valueOf(opportunityrecord.Store__r.Engine_Type__c));
            else this.enginetype = '';
            if(opportunityrecord.Store__r.Planned_Store_Size__c!=null)
            this.plannedStoreSize = UtilityMethod.getinput(String.valueOf(opportunityrecord.Store__r.Planned_Store_Size__c));
            else this.plannedStoreSize = '';
            this.storeprofileType = UtilityMethod.getinput(opportunityrecord.Store__r.Store_Profile_Type__c);
      
        }

        public void addToXmlDoc(Dom.XmlNode parentNode) {

            Dom.XmlNode namesnode = parentNode.addChildElement('names',null,null);
            Dom.XmlNode namenode = namesnode.addChildElement('name',null,null);

            namenode.addChildElement('value', null, null)
            .addTextNode(sitename);
            namenode.addChildElement('type', null, null)
            .addTextNode('Global');

            Dom.XmlNode addressesnode = parentNode.addChildElement('addresses',null,null);
            Dom.XmlNode addresseschild = addressesnode.addChildElement('address',null,null);

            addresseschild.addChildElement('line1', null, null)
            .addTextNode(address1);
            addresseschild.addChildElement('line2', null, null)
            .addTextNode(address2);
            addresseschild.addChildElement('line3', null, null)
            .addTextNode('');
            addresseschild.addChildElement('city', null, null)
            .addTextNode(city);
            addresseschild.addChildElement('countrySubdivisionCode', null, null)
            .addTextNode(state);
            addresseschild.addChildElement('countryCode', null, null)
            .addTextNode(country);
            addresseschild.addChildElement('postalCode', null, null)
            .addTextNode(postalcode);
            addresseschild.addChildElement('type', null, null)
            .addTextNode('Global');
            parentNode.addChildElement('type', null, null)
            .addTextNode(storetype);
            parentNode.addChildElement('brandCode', null, null)
            .addTextNode(brandCode);
            parentNode.addChildElement('ownershipType', null, null)
            .addTextNode(ownershipType);
            parentNode.addChildElement('sourceId', null, null)
            .addTextNode(storeId);

            Dom.XmlNode ownernode = parentNode.addChildElement('owner',null,null);

            ownernode.addChildElement('code', null, null)
            .addTextNode(licenseecode);
            ownernode.addChildElement('name', null, null)
            .addTextNode(licensee);
            ownernode.addChildElement('storeNumber', null, null)
            .addTextNode(storenumber);

            parentNode.addChildElement('externalVisibilityCode', null, null)
            .addTextNode(externalpresence);
            parentNode.addChildElement('structureType', null, null)
            .addTextNode(enginetype);
            parentNode.addChildElement('squareFootageMeas', null, null)
            .addTextNode(plannedStoreSize);
            parentNode.addChildElement('profileType', null, null)
            .addTextNode(storeprofileType);
            
        }

    }

   // @description: return XML string by passing opp id 
    public static String generateXMLPayload(String opportunityId){

        if(opportunityId !=null){

            Opportunity opportunityrecord = getSOQLs.getSingleOpportunityStore(opportunityId);
            OpportunityDetails opp = new OpportunityDetails(opportunityrecord);
                StoreDetails storeDetails = new StoreDetails(opportunityrecord);

                Dom.Document requestDoc = new DOM.Document();
                Dom.XmlNode requestMessageNode = requestDoc.createRootElement('retailSite', null, null);
                storeDetails.addToXmlDoc(requestMessageNode);
                opp.addToXmlDoc(requestMessageNode);

                Map<String,Starbucks_Team__c> newmap = new Map<String,Starbucks_Team__c>();
                List<Starbucks_Team__c> newlist = new List<Starbucks_Team__c>();
                newmap = getSOQLs.getRecentBDMAndNAE(opportunityrecord.Store__r.id);
                if(newmap.containsKey('BDM')) newlist.add(newmap.get('BDM'));
                if(newmap.containsKey('NAE')) newlist.add(newmap.get('NAE'));
                if(newmap.containsKey('Sr BDM')) newlist.add(newmap.get('Sr BDM'));
                if(newmap.containsKey('Sr NAE')) newlist.add(newmap.get('Sr NAE'));
            
                Dom.XmlNode teamsdetails = requestMessageNode.addChildElement('assignedPartners',null,null);

                for(Starbucks_Team__c team : newlist){
                    StarbucksTeamDetails details = new StarbucksTeamDetails(team);
                    details.addToXmlDoc(teamsdetails);
                }

                system.debug('value>>>>>'+ requestDoc.toXmlString());
                return requestDoc.toXmlString();

            }
            else
            return 'Opportunity ID Is Null';
            
    }


}