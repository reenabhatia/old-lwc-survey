@IsTest
private with sharing class SBUX_B2B_CatalogRulesProcessorJobTest 
{


    @IsTest
    private static void testCatalogRuleNoUpdateViaBatchJob() 
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

      
        // Execute batch job
        Test.startTest();

        SBUX_B2B_CatalogRulesProcessorJob job = new SBUX_B2B_CatalogRulesProcessorJob();
        Database.executeBatch(job, 10);

        Test.stopTest();
        
        List <SBUX_B2B_ProductEntitlementRule__c> newProdEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_ProductEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        List <SBUX_B2B_StoreEntitlementRule__c> newStoreEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_StoreEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        // Results before running the job 
        System.assertEquals(ruleList.size(), 4);
        System.assertEquals(prodEntitlementRules.size(), 4);
        System.assertEquals(storeEntitlementRules.size(), 4);

         // Results after running the job - There should be no net new change since the product/store association wasn't updated
        System.assertEquals(newProdEntitlementRules.size(), 4);
        System.assertEquals(newStoreEntitlementRules.size(), 4);
    }



    @IsTest
    private static void testCatalogRuleUpdateWithStoreChanges() 
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

        //Add a new store to the chicago area
        // This store is expected to be assigned to all the 4 rules since the entitlement rules all have 'Chicago' as the target City
        Store__c clonedStore =  storeList[0].clone(false,false);
        clonedStore.Store_Number__c = null;
        clonedStore.City__c = 'Chicago';

        insert clonedStore;
        clonedStore.Store_Number__c = SBUX_B2B_TestDataFactory.TEST_STORE_NUMBER+10;
        update clonedStore;
        
        // Execute batch job
        Test.startTest();

        SBUX_B2B_CatalogRulesProcessorJob job = new SBUX_B2B_CatalogRulesProcessorJob();
        Database.executeBatch(job, 10);

        Test.stopTest();
        
        List <SBUX_B2B_ProductEntitlementRule__c> newProdEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_ProductEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        List <SBUX_B2B_StoreEntitlementRule__c> newStoreEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_StoreEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        // Results before running the job 
        System.assertEquals(ruleList.size(), 4);
        System.assertEquals(prodEntitlementRules.size(), 4);
        System.assertEquals(storeEntitlementRules.size(), 4);

        //results after running the job
        System.assertEquals(newProdEntitlementRules.size(), 4);
        System.assertEquals(newStoreEntitlementRules.size(), 8);
    }



    @IsTest
    private static void testCatalogRuleUpdateWithStoreRuleDeletions() 
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

        //Change the properties of the store previously associated to the catalog rule
        Store__c clonedStore =  storeList[0];
        clonedStore.Store_Number__c = null;
        clonedStore.City__c = null;
        clonedStore.Country__c=null;

       // insert clonedStore;
       // clonedStore.Store_Number__c = SBUX_B2B_TestDataFactory.TEST_STORE_NUMBER+10;
        update clonedStore;
        
        // Execute batch job
        Test.startTest();

        SBUX_B2B_CatalogRulesProcessorJob job = new SBUX_B2B_CatalogRulesProcessorJob();
        Database.executeBatch(job, 10);

        Test.stopTest();
        
        List <SBUX_B2B_ProductEntitlementRule__c> newProdEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_ProductEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        List <SBUX_B2B_StoreEntitlementRule__c> newStoreEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_StoreEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        // Results before running the job 
        System.assertEquals(ruleList.size(), 4);
        System.assertEquals(prodEntitlementRules.size(), 4);
        System.assertEquals(storeEntitlementRules.size(), 4);

        //results after running the job
        System.assertEquals(newProdEntitlementRules.size(), 4);
        System.assertEquals(newStoreEntitlementRules.size(), 0);
    }



    

    @IsTest
    private static void testCatalogRuleUpdateWithProdCategoryChanges() 
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

         //Add a new product to the BEVERAGE_AND_FOOD_CATEGORY category 
        // This product is expected to be assigned to all the 4 rules since the entitlement rules all have 'BEVERAGE_AND_FOOD_CATEGORY' as the target  category
        ccrz__E_Product__c clonedProduct =  productList[0].clone(false,false);
        clonedProduct.ccrz__SKU__c = SBUX_B2B_TestDataFactory.TEST_SKU +100;
        insert clonedProduct;

        List<ccrz__E_Product__c> newProdList = new List<ccrz__E_Product__c>();
        newProdList.add(clonedProduct) ;

        ccrz__E_Category__c category  = SBUX_B2B_TestDataFactory.createCategory(SBUX_B2B_TestDataFactory.BEVERAGE_AND_FOOD_CATEGORY);

        SBUX_B2B_TestDataFactory.createProductCategory(category,newProdList);

        // Execute batch job
        Test.startTest();

        SBUX_B2B_CatalogRulesProcessorJob job = new SBUX_B2B_CatalogRulesProcessorJob();
        Database.executeBatch(job, 10);

        

        Test.stopTest();
        
        List <SBUX_B2B_ProductEntitlementRule__c> newProdEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_ProductEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        List <SBUX_B2B_StoreEntitlementRule__c> newStoreEntitlementRules =  [SELECT
                                                                                ID
                                                                                FROM 
                                                                                    SBUX_B2B_StoreEntitlementRule__c 
                                                                                WHERE 
                                                                                    SBUX_B2B_CatalogRule__c IN :(ruleIDs) LIMIT 10];
        // Results before running the job 
        System.assertEquals(ruleList.size(), 4);
        System.assertEquals(prodEntitlementRules.size(), 4);
        System.assertEquals(storeEntitlementRules.size(), 4);

         // Results after running the job - There should be no 4 additional prod entitlement rule records since all the 
         // 4 rules are   assigned to the BEVERAGE_AND_FOOD_CATEGORY
        System.assertEquals(newProdEntitlementRules.size(), 8);
        System.assertEquals(newStoreEntitlementRules.size(), 4);
    }




   

}