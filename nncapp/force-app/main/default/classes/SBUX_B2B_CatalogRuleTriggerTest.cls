@IsTest
private with sharing class SBUX_B2B_CatalogRuleTriggerTest
{
    @IsTest
    private static void testProcessCatalogRuleForInsert()
    {
        ccrz__E_AccountGroup__c accountGroup = SBUX_B2B_TestDataFactory.createInsertTestAccountGroup();
        Account testLicenseeAccount = SBUX_B2B_TestDataFactory.createInsertTestLicenseeAccount();
        Account testAccount = SBUX_B2B_TestDataFactory.createInsertTestStoreAccount(accountGroup,testLicenseeAccount);

        List<ccrz__E_Product__c> productList  = SBUX_B2B_TestDataFactory.createInsertTestProducts(4);

        List<Store__c> storeList =   SBUX_B2B_TestDataFactory.createInsertTestStoreList(testAccount,testLicenseeAccount);
        List<SBUX_B2B_CatalogEntitlementRule__c> ruleList  = SBUX_B2B_TestDataFactory.createCatalogEntitlementRule(productList,storeList, 'Include');

        List <String> ruleIDs = new List<String>();

        for (SBUX_B2B_CatalogEntitlementRule__c  catalogRule :ruleList)
        {
            ruleIDs.add(catalogRule.ID);
        }
        
        List <SBUX_B2B_ProductEntitlementRule__c> prodEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_ProductEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        List <SBUX_B2B_StoreEntitlementRule__c> storeEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_StoreEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];

        Test.startTest();

        System.assertEquals(ruleList.size(), 4);
        System.assertEquals(prodEntitlementRules.size(), 4);
        System.assertEquals(storeEntitlementRules.size(), 4);

        Test.stopTest();
    }


    

    @IsTest
    
    private static void testRuleWithDeletionOfEntries()
    {
        ccrz__E_AccountGroup__c accountGroup = SBUX_B2B_TestDataFactory.createInsertTestAccountGroup();
        Account testLicenseeAccount = SBUX_B2B_TestDataFactory.createInsertTestLicenseeAccount();
        Account testAccount = SBUX_B2B_TestDataFactory.createInsertTestStoreAccount(accountGroup,testLicenseeAccount);

        List<ccrz__E_Product__c> productList  = SBUX_B2B_TestDataFactory.createInsertTestProducts(4);

        List<Store__c> storeList =   SBUX_B2B_TestDataFactory.createInsertTestStoreList(testAccount,testLicenseeAccount);
        List<SBUX_B2B_CatalogEntitlementRule__c> ruleList  = SBUX_B2B_TestDataFactory.createCatalogEntitlementRule(productList,storeList, 'Include');

        List <String> ruleIDs = new List<String>();
        
        List<SBUX_B2B_CatalogEntitlementRule__c> ruleToUpdate = new List<SBUX_B2B_CatalogEntitlementRule__c>();

        for (SBUX_B2B_CatalogEntitlementRule__c  catalogRule :ruleList)
        {
            catalogRule.SBUX_B2B_SkuList__c = null;
            catalogRule.SBUX_B2B_StoreNumber__c = null;
            catalogRule.SBUX_B2B_Country__c = null;
            catalogRule.SBUX_B2B_City__c = null;

            ruleToUpdate.add(catalogRule);

            ruleIDs.add(catalogRule.ID);
        }
        
        update ruleToUpdate;

        Test.startTest();

        List <SBUX_B2B_ProductEntitlementRule__c> prodEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_ProductEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        List <SBUX_B2B_StoreEntitlementRule__c> storeEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_StoreEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];

        System.assertEquals(ruleList.size(), 4);
        System.assertEquals(prodEntitlementRules.size(), 0);
        System.assertEquals(storeEntitlementRules.size(), 0);

        Test.stopTest();
    }




    

    @IsTest
    private static void testProcessCatalogRuleForStoreUpdate()
    {
        ccrz__E_AccountGroup__c accountGroup = SBUX_B2B_TestDataFactory.createInsertTestAccountGroup();
        Account testLicenseeAccount = SBUX_B2B_TestDataFactory.createInsertTestLicenseeAccount();
        Account testAccount = SBUX_B2B_TestDataFactory.createInsertTestStoreAccount(accountGroup,testLicenseeAccount);

        List<ccrz__E_Product__c> productList  = SBUX_B2B_TestDataFactory.createInsertTestProducts(4);

        List<Store__c> storeList =   SBUX_B2B_TestDataFactory.createInsertTestStoreList(testAccount,testLicenseeAccount);
        List<SBUX_B2B_CatalogEntitlementRule__c> ruleList  = SBUX_B2B_TestDataFactory.createCatalogEntitlementRule(productList,storeList, 'Include');

        List <String> ruleIDs = new List<String>();

        for (SBUX_B2B_CatalogEntitlementRule__c  catalogRule :ruleList)
        {
            ruleIDs.add(catalogRule.ID);
        }
        
        SBUX_B2B_CatalogEntitlementRule__c firstRule = ruleList[0];
        firstRule.SBUX_B2B_StoreNumber__c = storeList[1].Store_Number__c;

        update firstRule;

        Test.startTest();

        List <SBUX_B2B_ProductEntitlementRule__c> prodEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_ProductEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        List <SBUX_B2B_StoreEntitlementRule__c> storeEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_StoreEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];

        System.assertEquals(ruleList.size(), 4);
        System.assertEquals(prodEntitlementRules.size(), 4);
        System.assertEquals(storeEntitlementRules.size(), 5);

        Test.stopTest();
    }



    @IsTest
    private static void testProcessCatalogRuleForProdUpdate()
    {
        ccrz__E_AccountGroup__c accountGroup = SBUX_B2B_TestDataFactory.createInsertTestAccountGroup();
        Account testLicenseeAccount = SBUX_B2B_TestDataFactory.createInsertTestLicenseeAccount();
        Account testAccount = SBUX_B2B_TestDataFactory.createInsertTestStoreAccount(accountGroup,testLicenseeAccount);

        List<ccrz__E_Product__c> productList  = SBUX_B2B_TestDataFactory.createInsertTestProducts(4);

        List<Store__c> storeList =   SBUX_B2B_TestDataFactory.createInsertTestStoreList(testAccount,testLicenseeAccount);
        List<SBUX_B2B_CatalogEntitlementRule__c> ruleList  = SBUX_B2B_TestDataFactory.createCatalogEntitlementRule(productList,storeList, 'Include');

        List <String> ruleIDs = new List<String>();

        for (SBUX_B2B_CatalogEntitlementRule__c  catalogRule :ruleList)
        {
            ruleIDs.add(catalogRule.ID);
        }
        
        SBUX_B2B_CatalogEntitlementRule__c firstRule = ruleList[0];
        firstRule.SBUX_B2B_SkuList__c = productList[0].ccrz__SKU__c + ', ' + productList[1].ccrz__SKU__c + ', ' +productList[2].ccrz__SKU__c;

        update firstRule;

        Test.startTest();

        List <SBUX_B2B_ProductEntitlementRule__c> prodEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_ProductEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        List <SBUX_B2B_StoreEntitlementRule__c> storeEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_StoreEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];

        System.assertEquals(ruleList.size(), 4);
        System.assertEquals(prodEntitlementRules.size(), 6);
        System.assertEquals(storeEntitlementRules.size(), 4);

        Test.stopTest();
    }


    @IsTest
    private static void testProcessCatalogRuleForStoreAndProdUpdate()
    {
        ccrz__E_AccountGroup__c accountGroup = SBUX_B2B_TestDataFactory.createInsertTestAccountGroup();
        Account testLicenseeAccount = SBUX_B2B_TestDataFactory.createInsertTestLicenseeAccount();
        Account testAccount = SBUX_B2B_TestDataFactory.createInsertTestStoreAccount(accountGroup,testLicenseeAccount);

        List<ccrz__E_Product__c> productList  = SBUX_B2B_TestDataFactory.createInsertTestProducts(4);

        List<Store__c> storeList =   SBUX_B2B_TestDataFactory.createInsertTestStoreList(testAccount,testLicenseeAccount);
        List<SBUX_B2B_CatalogEntitlementRule__c> ruleList  = SBUX_B2B_TestDataFactory.createCatalogEntitlementRule(productList,storeList, 'Include');

        List <String> ruleIDs = new List<String>();

        for (SBUX_B2B_CatalogEntitlementRule__c  catalogRule :ruleList)
        {
            ruleIDs.add(catalogRule.ID);
        }
        
        SBUX_B2B_CatalogEntitlementRule__c firstRule = ruleList[0];
        firstRule.SBUX_B2B_StoreNumber__c = storeList[1].Store_Number__c;
        firstRule.SBUX_B2B_SkuList__c = productList[0].ccrz__SKU__c + ', ' + productList[1].ccrz__SKU__c + ', ' +productList[2].ccrz__SKU__c;

        update firstRule;

        Test.startTest();

        List <SBUX_B2B_ProductEntitlementRule__c> prodEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_ProductEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        List <SBUX_B2B_StoreEntitlementRule__c> storeEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_StoreEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];

        System.assertEquals(ruleList.size(), 4);
        System.assertEquals(prodEntitlementRules.size(), 6);
        System.assertEquals(storeEntitlementRules.size(), 5);

        Test.stopTest();
    }

}