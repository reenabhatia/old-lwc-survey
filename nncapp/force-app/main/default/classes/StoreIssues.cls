public class StoreIssues {
    @AuraEnabled
	public list<Issue__c> issuesList;
    @AuraEnabled
	public map<string,string> storeRelatedIds;
    @AuraEnabled
	public map<string,string> storeStatus;
}