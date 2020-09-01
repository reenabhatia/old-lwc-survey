@isTest
public with sharing class Account_TriggerHandlerTest {
	@isTest
	public static void checkconditionallyCallAtlasUpdateSite(){
		 Account[] acct = TestDataFactory.createAccounts('Licensee',4, 'Acc', TRUE);
		 acct[0].Licensee_Code__c = 'Acc Code';
		 update acct[0];
	}
	
}