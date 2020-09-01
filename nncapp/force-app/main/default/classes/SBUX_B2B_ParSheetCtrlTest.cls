@IsTest
private with sharing class SBUX_B2B_ParSheetCtrlTest 
{
    private static Map<String, Object> testData;
    private static  final String PAR_QTY = '100';
    private static  final String ONHAND_QTY = '20';

    private static void setupTestData() 
    {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
    }

    @IsTest
    private static void testGetCurrentStoreID()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        Store__c testStore =   (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        
        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        
        ccrz.cc_CallContext.init(ctx);
        ccrz.cc_CallContext.currAccountId = testAccount.Id;

        String storeId = SBUX_B2B_ParSheetCtrl.getCurrentStoreID(JSON.serialize(ctx));

        System.assertEquals(storeId,testStore.Id);       

        Test.stopTest();
    }


    @IsTest
    private static void testGetParSheetCategory()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        Store__c testStore =   (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        
        SBUX_B2B_TestDataFactory.createParSheet(testStore.Id);

        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        
        ccrz.cc_CallContext.init(ctx);
        ccrz.cc_CallContext.currAccountId = testAccount.Id;

        List<String> parSheetCategory = SBUX_B2B_ParSheetCtrl.getParSheetCategory(testStore.Id);

         System.assertNotEquals(parSheetCategory.size(),0); 

         Test.stopTest();
    }





    @IsTest
    private static void testResetOnHandQty()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        Store__c testStore =   (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        
        SBUX_B2B_PARSheet__c parSheet = SBUX_B2B_TestDataFactory.createParSheet(testStore.Id);
        List<SBUX_B2B_PARSheetItem__c> parSheetItemList  = SBUX_B2B_TestDataFactory.createParSheetItems(parSheet,testProductList);

        List<String> itemIdList = new List<String>();

        for (SBUX_B2B_PARSheetItem__c parSheetItem : parSheetItemList)
        {
            itemIdList.add(parSheetItem.Id);
        }
        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        
        ccrz.cc_CallContext.init(ctx);
        ccrz.cc_CallContext.currAccountId = testAccount.Id;

         SBUX_B2B_ParSheetCtrl.resetOnHandValues(JSON.serialize(ctx),itemIdList);

         List<SBUX_B2B_PARSheetItem__c> updatedItemList = SBUX_B2B_ParSheetCtrl.fetchParSheetItemsWithIDs(itemIdList);

         SBUX_B2B_PARSheetItem__c firstParSheetItem = updatedItemList[0];
         System.assertEquals(firstParSheetItem.SBUX_B2B_OnHandQty__c,null); 
         System.assertEquals(firstParSheetItem.SBUX_B2B_OrderQty__c,null); 

         Test.stopTest();
    }





    @IsTest
    private static void testResetPARQty()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        Store__c testStore =   (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        
        SBUX_B2B_PARSheet__c parSheet = SBUX_B2B_TestDataFactory.createParSheet(testStore.Id);
        List<SBUX_B2B_PARSheetItem__c> parSheetItemList  = SBUX_B2B_TestDataFactory.createParSheetItems(parSheet,testProductList);

        List<String> itemIdList = new List<String>();

        for (SBUX_B2B_PARSheetItem__c parSheetItem : parSheetItemList)
        {
            itemIdList.add(parSheetItem.Id);
        }

        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        
        ccrz.cc_CallContext.init(ctx);
        ccrz.cc_CallContext.currAccountId = testAccount.Id;

        SBUX_B2B_ParSheetCtrl.resetParValues(JSON.serialize(ctx),itemIdList);

        List<SBUX_B2B_PARSheetItem__c> updatedItemList = SBUX_B2B_ParSheetCtrl.fetchParSheetItemsWithIDs(itemIdList);

        SBUX_B2B_PARSheetItem__c firstParSheetItem = updatedItemList[0];
        System.assertEquals(firstParSheetItem.SBUX_B2B_ParQty__c,null); 
        System.assertEquals(firstParSheetItem.SBUX_B2B_OrderQty__c,null); 

        Test.stopTest();
    }



    @IsTest
    private static void testGetParItemsWithoutEntitlements()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        Store__c testStore =   (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        
        List<SBUX_B2B_CatalogEntitlementRule__c> catalogRules = (List<SBUX_B2B_CatalogEntitlementRule__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_RULES);
        delete catalogRules;

        SBUX_B2B_PARSheet__c parSheet = SBUX_B2B_TestDataFactory.createParSheet(testStore.Id);
        List<SBUX_B2B_PARSheetItem__c> parSheetItemList  = SBUX_B2B_TestDataFactory.createParSheetItems(parSheet,testProductList);

        List<String> itemIdList = new List<String>();

        for (SBUX_B2B_PARSheetItem__c parSheetItem : parSheetItemList)
        {
            itemIdList.add(parSheetItem.Id);
        }

        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        
        ccrz.cc_CallContext.init(ctx);
        ccrz.cc_CallContext.currAccountId = testAccount.Id;

        List<String> selectedCategories  = new List<String>();
        selectedCategories.add(SBUX_B2B_TestDataFactory.BEVERAGE_AND_FOOD_CATEGORY);

        Map<String, Object> parItemsData = SBUX_B2B_ParSheetCtrl.getParItems(JSON.serialize(ctx), 50,selectedCategories, testStore.Id, null);
        List<SBUX_B2B_PARSheetItem__c> parItemsList = (List<SBUX_B2B_PARSheetItem__c>)parItemsData.get('parItemList');
        Decimal totalNumberOfRows = (Decimal)parItemsData.get('totalNumberOfRows');

        System.assertEquals(parItemsList.size(),0); 
        System.assertEquals(totalNumberOfRows,0); 

        Test.stopTest();
    }


    @IsTest
    private static void testGetParItemsWithEntitlement()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        Store__c testStore =   (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
    
        SBUX_B2B_PARSheet__c parSheet = SBUX_B2B_TestDataFactory.createParSheet(testStore.Id);
        List<SBUX_B2B_PARSheetItem__c> parSheetItemList  = SBUX_B2B_TestDataFactory.createParSheetItems(parSheet,testProductList);

        List<String> itemIdList = new List<String>();

        for (SBUX_B2B_PARSheetItem__c parSheetItem : parSheetItemList)
        {
            itemIdList.add(parSheetItem.Id);
        }

        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        
        ccrz.cc_CallContext.init(ctx);
        ccrz.cc_CallContext.currAccountId = testAccount.Id;

        List<String> selectedCategories  = new List<String>();
        selectedCategories.add(SBUX_B2B_TestDataFactory.BEVERAGE_AND_FOOD_CATEGORY);

        Map<String, Object> parItemsData = SBUX_B2B_ParSheetCtrl.getParItems(JSON.serialize(ctx), 50,selectedCategories, testStore.Id, null);
        List<SBUX_B2B_PARSheetItem__c> parItemsList = (List<SBUX_B2B_PARSheetItem__c>)parItemsData.get('parItemList');
        Decimal totalNumberOfRows = (Decimal)parItemsData.get('totalNumberOfRows');

        System.assertNotEquals(parItemsList.size(),0); 
        System.assertNotEquals(totalNumberOfRows,0); 

        Test.stopTest();
    }



    @IsTest
    private static void testDeletePARItems()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        Store__c testStore =   (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        
        SBUX_B2B_PARSheet__c parSheet = SBUX_B2B_TestDataFactory.createParSheet(testStore.Id);
        List<SBUX_B2B_PARSheetItem__c> parSheetItemList  = SBUX_B2B_TestDataFactory.createParSheetItems(parSheet,testProductList);

        List<String> itemIdList = new List<String>();

        for (SBUX_B2B_PARSheetItem__c parSheetItem : parSheetItemList)
        {
            itemIdList.add(parSheetItem.Id);
        }
        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        
        ccrz.cc_CallContext.init(ctx);
        ccrz.cc_CallContext.currAccountId = testAccount.Id;

         SBUX_B2B_ParSheetCtrl.deleteParItems(itemIdList);

         List<SBUX_B2B_PARSheetItem__c> itemList = SBUX_B2B_ParSheetCtrl.fetchParSheetItemsWithIDs(itemIdList);

         System.assertEquals(itemList.size(),0); 

         Test.stopTest();
    }


    @IsTest
    private static void testUpdateParSheetItems()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        Store__c testStore =   (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        
        SBUX_B2B_PARSheet__c parSheet = SBUX_B2B_TestDataFactory.createParSheet(testStore.Id);
        List<SBUX_B2B_PARSheetItem__c> parSheetItemList  = SBUX_B2B_TestDataFactory.createParSheetItems(parSheet,testProductList);

        List<String> itemIdList = new List<String>();

        Map<String, Object> updatedMap = new Map<String, Object>();

        for (SBUX_B2B_PARSheetItem__c parSheetItem : parSheetItemList)
        {
             Map<String, Object> item = new Map<String, Object>();
             item.put('Id',parSheetItem.Id);
             item.put('SBUX_B2B_ParQty__c',PAR_QTY);
             item.put('SBUX_B2B_OnHandQty__c',ONHAND_QTY);

             updatedMap.put(parSheetItem.Id,item);

             itemIdList.add(parSheetItem.Id);
        }

        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        
        ccrz.cc_CallContext.init(ctx);
        ccrz.cc_CallContext.currAccountId = testAccount.Id;

        SBUX_B2B_ParSheetCtrl.updateParSheetItems(JSON.serialize(updatedMap));

        List<SBUX_B2B_PARSheetItem__c> itemList = SBUX_B2B_ParSheetCtrl.fetchParSheetItemsWithIDs(itemIdList);

         SBUX_B2B_PARSheetItem__c firstItem = itemList[0];
         System.assertEquals(firstItem.SBUX_B2B_OrderQty__c, Decimal.valueOf(PAR_QTY) - Decimal.valueOf(ONHAND_QTY)); 

         Test.stopTest();
    }



    @IsTest
    private static void testUpdateParSheetItemsNullOrderQty()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        Store__c testStore =   (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        
        SBUX_B2B_PARSheet__c parSheet = SBUX_B2B_TestDataFactory.createParSheet(testStore.Id);
        List<SBUX_B2B_PARSheetItem__c> parSheetItemList  = SBUX_B2B_TestDataFactory.createParSheetItems(parSheet,testProductList);

        List<String> itemIdList = new List<String>();

        Map<String, Object> updatedMap = new Map<String, Object>();
        
        for (SBUX_B2B_PARSheetItem__c parSheetItem : parSheetItemList)
        {
            Map<String, Object> item = new Map<String, Object>();
            item.put('Id',parSheetItem.Id);
            item.put('SBUX_B2B_ParQty__c',PAR_QTY);
            item.put('SBUX_B2B_OnHandQty__c','');

            updatedMap.put(parSheetItem.Id,item);

            itemIdList.add(parSheetItem.Id);
        }

        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        
        ccrz.cc_CallContext.init(ctx);
        ccrz.cc_CallContext.currAccountId = testAccount.Id;

        SBUX_B2B_ParSheetCtrl.updateParSheetItems(JSON.serialize(updatedMap));

        List<SBUX_B2B_PARSheetItem__c> itemList = SBUX_B2B_ParSheetCtrl.fetchParSheetItemsWithIDs(itemIdList);

         SBUX_B2B_PARSheetItem__c firstItem = itemList[0];
         System.assertEquals(firstItem.SBUX_B2B_OrderQty__c,null); 

         Test.stopTest();
    }



    @IsTest
    private static void testGenerateParSheetItemsFirstInsert()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        Store__c testStore =   (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
       
        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        
        ccrz.cc_CallContext.init(ctx);
        ccrz.cc_CallContext.currAccountId = testAccount.Id;

        List<String> selectedCategories  = new List<String>();
        selectedCategories.add(SBUX_B2B_TestDataFactory.BEVERAGE_AND_FOOD_CATEGORY);

        Map<String, Object> generatedParSheetItems =  SBUX_B2B_ParSheetCtrl.generateParItems(JSON.serialize(ctx),selectedCategories,testStore.Id, 50);
        List<SBUX_B2B_PARSheetItem__c> parItemsList = (List<SBUX_B2B_PARSheetItem__c>)generatedParSheetItems.get('parItemList');
        Decimal totalNumberOfRows = (Decimal)generatedParSheetItems.get('totalNumberOfRows');

        System.assertEquals(parItemsList.size(),testProductList.size()); 
        System.assertEquals(totalNumberOfRows,testProductList.size()); 

         Test.stopTest();
    }


    @IsTest
    private static void testGenerateParSheetItemsAdditiveInsert()
    {
        setupTestData();

        Account testAccount = (Account) testData.get(SBUX_B2B_TestDataFactory.TEST_ACCOUNT);

        List<ccrz__E_Product__c> testProductList  = (List<ccrz__E_Product__c>)testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
        Store__c testStore =   (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        
        SBUX_B2B_PARSheet__c parSheet = SBUX_B2B_TestDataFactory.createParSheet(testStore.Id);
        List<SBUX_B2B_PARSheetItem__c> parSheetItemList  = SBUX_B2B_TestDataFactory.createParSheetItems(parSheet,testProductList);

        Test.startTest();
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
        ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
        
        ccrz.cc_CallContext.init(ctx);
        ccrz.cc_CallContext.currAccountId = testAccount.Id;

        List<String> selectedCategories  = new List<String>();
        selectedCategories.add(SBUX_B2B_TestDataFactory.BEVERAGE_AND_FOOD_CATEGORY);

        Map<String, Object> generatedParSheetItems =  SBUX_B2B_ParSheetCtrl.generateParItems(JSON.serialize(ctx),selectedCategories,testStore.Id, 50);
        List<SBUX_B2B_PARSheetItem__c> parItemsList = (List<SBUX_B2B_PARSheetItem__c>)generatedParSheetItems.get('parItemList');
        Decimal totalNumberOfRows = (Decimal)generatedParSheetItems.get('totalNumberOfRows');

        System.assertEquals(parItemsList.size(),testProductList.size()); 
        System.assertEquals(totalNumberOfRows,testProductList.size()); 

         Test.stopTest();
    }



   
}