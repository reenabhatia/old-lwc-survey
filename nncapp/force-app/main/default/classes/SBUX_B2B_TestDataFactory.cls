/**
 * Created by dgajwani on 3/23/20.
 */
@IsTest
public with sharing class SBUX_B2B_TestDataFactory {
    public static final String TEST_STOREFRONT = 'DefaultStore';
    public static final String TEST_STOREFRONT_USER_PROFILE = 'LS Barista';

    // Parent Billing Address
    public static final String PARENT_BILL_STREET = 'Parent Billing Address';
    public static final String PARENT_BILL_CITY = 'New York';
    public static final String PARENT_BILL_STATE = 'NY';
    public static final String PARENT_BILL_COUNTRY = 'US';
    public static final String PARENT_BILL_POSTAL_CODE = '67890';

    // Parent Shipping Address
    public static final String PARENT_SHIP_STREET = 'Parent Shipping Address';
    public static final String PARENT_SHIP_CITY = 'New York';
    public static final String PARENT_SHIP_STATE = 'NY';
    public static final String PARENT_SHIP_COUNTRY = 'US';
    public static final String PARENT_SHIP_POSTAL_CODE = '67890';

    public static final String TEST_LICENSEE_ACCOUNT = 'TestLicenseeAccount';
    public static final String TEST_ACCOUNT = 'TestAccount';
    public static final String TEST_STORE = 'TestStore';
    public static final String TEST_CONTACT = 'TestContact';
    public static final String TEST_USER = 'TestUser';
    public static final String TEST_PRODUCTS = 'TestProducts';
    public static final String TEST_SKU = 'TestSKU';
    public static final String PRODUCT_TYPE_PRODUCT = 'Product';
    public static final String PRODUCT_STATUS_RELEASED = 'Released';
    public static final Integer TEST_PRODUCT_PRICE = 50;
    public static final String TEST_CURRENCY_CODE = 'USD';
    public static final String TEST_STORE_NUMBER = '12345';
    private static final String TEST_RDC = '1025';
    private static final String TEST_STORE_SEGMENT = 'Travel';
    private static final String TEST_STORE_SUBSEGMENT = 'Airport';
    private static final String TEST_STORE_COUNTRY = 'US';
    private static final String TEST_ASSORTMENT_SIZE = 'US Grande';
    private static final String LS_CATEGORY_BEVERAGE = 'Beverage';
    public static final String TEST_RULES = 'TestRules';
    public static final String TEST_CATEGORY = 'TestCategory';
    public static final String TEST_PRODCAT = 'TestProdCat';
    public static final String TEST_PRICELIST = 'TestPriceList';
    private static final String PACIFIC_TIME_ZONE_GMT_OFFSET = '-07:00';
    public static final String BEVERAGE_AND_FOOD_CATEGORY = '1.01';
    public static final String COFFEE_5LB_CATEGORY = '2.02';
    /**
     * @description Setups a test storefront.
     */
    public static void initCCSettings() {
        ccrz.cc_util_Reflection.createStorefrontSetting(TEST_STOREFRONT);
        Map<String, Map<String, Object>> ccSettings = new Map<String, Map<String, Object>>{
                ccrz.ccApiTestData.SERVICE_SETTINGS => new Map<String, Object>{
                        TEST_STOREFRONT => new Map<String, Object>{
                                'ccServiceOrder' => 'c.SBUX_B2B_ccServiceOrder',
                                'ccServiceOrderItem' => 'c.SBUX_B2B_ccServiceOrderItem',
                                'ccServiceProduct' => 'c.SBUX_B2B_ccServiceProduct',
                                'ccServiceCart' => 'c.SBUX_B2B_ccServiceCart',
                                'ccServiceCartItem' => 'c.SBUX_B2B_ccServiceCartItem',
                                'ccServiceCartItemGroup' => 'c.SBUX_B2B_ccServiceCartItemGroup',
                                'ccServicePLI' => 'c.SBUX_B2B_ccServicePLI',
                                'ccServiceAccount' => 'c.SBUX_B2B_ccServiceAccount'
                        }
                },
                ccrz.ccApiTestData.LOGIC_SETTINGS => new Map<String, Object>{
                        TEST_STOREFRONT => new Map<String, Object>{
                                'ccLogicCartGetShippingOptions' => 'c.SBUX_B2B_ccLogicCartGetShippingOptions',
                                'ccLogicCartInitItemGroups' => 'c.SBUX_B2B_ccLogicCartInitItemGroups',
                                'ccLogicCartCreate' => 'c.SBUX_B2B_ccLogicCartCreate',
                                'ccLogicProductPricing' => 'c.SBUX_B2B_ccLogicProductPricing',
                                'ccLogicCartGetDeliveryDates' => 'c.SBUX_B2B_ccLogicCartGetDeliveryDates',
                                'ccLogicCartValidate' => 'c.SBUX_B2B_ccLogicCartValidate',
                                'ccLogicPIFetchEntitled' => 'c.SBUX_B2B_ccLogicPIFetchEntitled'
                        }
                },
                ccrz.ccApiTestData.HOOK_SETTINGS => new Map<String, Object>{
                        TEST_STOREFRONT => new Map<String, Object>{
                                'cc_hk_Catalog' => 'c.SBUX_B2B_cc_hk_Catalog'
                        }
                }
        };
        ccrz.ccApiTestData.setupData(ccSettings);
    }

    /**
     * @description Returns a test Licensee Account.
     */
    public static Account createInsertTestLicenseeAccount() {
        Account testAcc = new Account();
        testAcc.Name = 'Test Licensee Account';
        testAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Licensee').getRecordTypeId();
        testAcc.Is_a_Licensee__c = 'Yes';
        testAcc.Licensee_Code__c = 'Test';
        testAcc.Licensee_Status__c = 'Active';
        testAcc.Is_a_Store__c = 'No';
        insert testAcc;
        return testAcc;
    }

    /**
     * @description Returns a test Store Account.
     */
    public static Account createInsertTestStoreAccount(ccrz__E_AccountGroup__c accountGroup, Account licenseeAccount) {
        Account testAcc = new Account();
        testAcc.Name = 'Test Parent Account';
        testAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Non-Licensee').getRecordTypeId();
        testAcc.ccrz__E_AccountGroup__c = accountGroup.Id;
        if (licenseeAccount != null) {
            testAcc.ParentId = licenseeAccount.Id;
        }
        insert testAcc;
        return testAcc;
    }

    /**
     * @description Creates a test account group.
     */
    public static ccrz__E_AccountGroup__c createInsertTestAccountGroup() {
        ccrz__E_AccountGroup__c accGroup = new ccrz__E_AccountGroup__c(
                Name = 'Default Account Group',
                ccrz__PriceListSelectionMethod__c = 'Best Price'
        );
        insert accGroup;
        return accGroup;
    }

    /**
     * @description Creates a test user.
     */
    public static User createDefaultUser(Contact contact) {
        Profile profile = [SELECT Id FROM Profile WHERE Name = :TEST_STOREFRONT_USER_PROFILE LIMIT 1];
        User u = new User(
                LastName = 'SMITH',
                FirstName = 'JOHN',
                Alias = 'main',
                Email = 'testuser@testfactory.com',
                Phone = '1234567890',
                Username = 'testuser@testfactory.com.' + Math.random(),
                TimeZoneSidKey = UserInfo.getTimeZone().toString(),
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LocaleSidKey = 'en_US',
                ContactId = contact.Id,
                ProfileId = profile.Id
        );
        insert u;
        return u;
    }

    /**
     * @description Creates a test contact.
     */
    public static Contact createInsertDefaultContact(Account account) {

        Contact contact = new Contact(
                AccountId = account.Id,
                FirstName = 'Default Contact',
                LastName = 'Default Contact',
                Email = 'defaultcontact@domain.com',
                MailingStreet = 'testMailingStreet',
                MailingPostalCode = '90210',
                MailingCity = 'testMailingCity'
        );
        insert contact;
        return contact;
    }

    /**
     * @description Creates and returns a test price list.
     */
    public static ccrz__E_PriceList__c createInsertTestPricelist() {
        ccrz__E_PriceList__c priceList = new ccrz__E_PriceList__c(
                Name = 'Autoship US',
                ccrz__CurrencyISOCode__c = TEST_CURRENCY_CODE,
                ccrz__Enabled__c = true,
                ccrz__Storefront__c = TEST_STOREFRONT,
                ccrz__StartDate__c = System.today().addYears(-1)
        );
        insert priceList;
        return priceList;
    }

    /**
     * @description Associates the pricelist to an account group.
     */
    public static ccrz__E_AccountGroupPriceList__c createInsertTestAccountGroupPriceList(ccrz__E_AccountGroup__c accountGroup, ccrz__E_PriceList__c priceList) {
        ccrz__E_AccountGroupPriceList__c accountGroupPriceList = new ccrz__E_AccountGroupPriceList__c(
                ccrz__AccountGroup__c = accountGroup.Id,
                ccrz__Pricelist__c = priceList.Id,
                ccrz__StartDate__c = System.today().addYears(-1),
                ccrz__Enable__c = true

        );
        insert accountGroupPriceList;
        return accountGroupPriceList;
    }

    /**
     * @description Creates and inserts price list items.
     */
    public static void createInsertPriceListItems(List<ccrz__E_Product__c> products, ccrz__E_PriceList__c pricelist) {

        List<ccrz__E_PriceListItem__c> items = new List<ccrz__E_PriceListItem__c>();

        for (ccrz__E_Product__c product : products) {
            ccrz__E_PriceListItem__c priceListItem = new ccrz__E_PriceListItem__c(
                    ccrz__Price__c = TEST_PRODUCT_PRICE,
                    ccrz__Product__c = product.Id,
                    ccrz__Pricelist__c = pricelist.Id,
                    ccrz__StartDate__c = System.today().addYears(-1)
            );
            items.add(priceListItem);

        }
        insert items;
    }

    /**
     * @description Creates and Returns the specified number of CC products.
     */
    public static List<ccrz__E_Product__c> createInsertTestProducts(Integer size) {
        List<ccrz__E_Product__c> products = new List<ccrz__E_Product__c>();

        for (Integer i = 0; i < size; i++) {
            ccrz__E_Product__c product = new ccrz__E_Product__c(
                    Name = TEST_SKU + i,
                    ccrz__SKU__c = TEST_SKU + i,
                    ccrz__ProductStatus__c = PRODUCT_STATUS_RELEASED,
                    ccrz__ProductType__c = PRODUCT_TYPE_PRODUCT,
                    ccrz__Storefront__c = TEST_STOREFRONT,
                    ccrz__ShortDesc__c = TEST_SKU,
                    ccrz__ShortDescRT__c = TEST_SKU,
                    ccrz__StartDate__c = System.today().addYears(-1),
                    ccrz__EndDate__c = System.today().addYears(+1),
                    ccrz__ShippingWeight__c = 1,
                    SBUX_B2B_AutoShipLSCategory__c = LS_CATEGORY_BEVERAGE,
                    SBUX_B2B_PIMDescription__c = 'Description',
                    ccrz__UnitOfMeasure__c = 'CS',
                    SBUX_B2B_PrimaryUOM__c = 'EA',
                    SBUX_B2B_UOMConv__c = '[ { "convRt" : 6, "fromCode" : "CS", "toCode" : "EA"}, { "convRt" : 6, "fromCode" : "EA", "toCode" : "CS"} ]',
                    SBUX_B2B_ItemSource__c = 'RDC',
                    SBUX_B2B_CogsSupply__c = 'COGS',
                    SBUX_B2B_Max_Orderable_Qty__c = 2
            );

            products.add(product);

        }

        insert products;
        return products;
    }

    public static SBUX_B2B_ProductExceptionRule__c createInsertTestProductExceptionRules(Account licenseeAccount, ccrz__E_Product__c testProduct) {
        SBUX_B2B_ProductExceptionRule__c result = new SBUX_B2B_ProductExceptionRule__c();
        result.SBUX_B2B_Account__c = licenseeAccount.Id;
        result.SBUX_B2B_Product__c = testProduct.Id;
        result.SBUX_B2B_CogsSupplyException__c = 'Supply';
        insert result;
        return result;
    }

    public static Opportunity createInsertTestOpportunity(Account licenseeAccount) {
        Opportunity o = new Opportunity(
                Name = 'TestOpportunity',
                AccountId = licenseeAccount.Id,
                Atlas_Status_Indicator__c = '10',
                Atlas_Lifecycle_Status__c = 'Prospect',
                Store_Type__c = 'Cafe',
                Radius_Date__c = System.today(),
                MLA__c = TRUE,
                CloseDate = System.today(),
                Atlas_Dead_Date__c = System.today(),
                Relo_Indicator__c = 'Y',
                Site_Name__c = 'TestSite',
                Store_Profile_Type__c = 'Concept',
                Country__c = 'US',
                Planned_Store_Size_ft__c = 14.6,
                Address_1__c = 'abc',
                Address_2__c = 'xyz',
                City__c = 'Seattle',
                State_Province__c = 'WA',
                Postal_Code__c = '13210',
                Atlas_Segment__c = 'GROCERY',
                Atlas_Subsegment__c = 'Grocery',
                Site_ID__c = '12345',
                StageName = 'Target',
                Estimated_Average_Weekly_Sales__c = 44.4,
                Currency__c = 'USD',
                Segment__c = 'Travel',
                Subsegment__c = 'Travel Plaza',
                Reason_Code__c = 'High Rent',
                Atlas_Status_Comments__c = 'High Rent Indeed',
                Engine_Type__c = 'Doppio',
                External_Presence__c = 'Low',
                OwnerId = UserInfo.getUserId()
        );
        insert o;
        return o;
    }

    /**
     * @description Creates Account, Account group, Users, PriceLists, Products, PriceListItems.
     */
    public static Map<String, Object> setupAccountContactUser() {

        initCCSettings();

        Account testLicenseeAccount;
        Account testStoreAccount;
        Contact testContact;
        User testUser;
        Opportunity testOpportunity;

        //Account/Contact/User details
        ccrz__E_AccountGroup__c accountGroup = createInsertTestAccountGroup();

        testLicenseeAccount = createInsertTestLicenseeAccount();
        testOpportunity = createInsertTestOpportunity(testLicenseeAccount);
        testStoreAccount = createInsertTestStoreAccount(accountGroup, testLicenseeAccount);
        testContact = createInsertDefaultContact(testStoreAccount);
        testUser = createDefaultUser(testContact);

        //PriceLists
        ccrz__E_PriceList__c pricelist = createInsertTestPricelist();
        createInsertTestAccountGroupPriceList(accountGroup, pricelist);

        //Products and PriceListItems
        List<ccrz__E_Product__c> products = createInsertTestProducts(2);
        createInsertPriceListItems(products, pricelist);

        ccrz__E_Category__c category = SBUX_B2B_TestDataFactory.createCategory(SBUX_B2B_TestDataFactory.BEVERAGE_AND_FOOD_CATEGORY);

        List <ccrz__E_ProductCategory__c> prodCatList = SBUX_B2B_TestDataFactory.createProductCategory(category, products);

        //Store
        Store__c testStore = createInsertTestStore(testLicenseeAccount, testStoreAccount,testOpportunity);

        List <Store__c> storeList = new List<Store__c>();
        storeList.add(testStore);

        List<SBUX_B2B_CatalogEntitlementRule__c> catalogRules = createCatalogEntitlementRule(products, storeList, 'Include');

        return new Map<String, Object>{
                TEST_LICENSEE_ACCOUNT => testLicenseeAccount,
                TEST_ACCOUNT => testStoreAccount,
                TEST_CONTACT => testContact,
                TEST_USER => testUser,
                TEST_PRODUCTS => products,
                TEST_STORE => testStore,
                TEST_RULES => catalogRules,
                TEST_CATEGORY => category,
                TEST_PRODCAT => prodCatList,
                TEST_PRICELIST => pricelist
        };
    }

    public static Map<String, Object> createInsertTestOrder(Map<String, Object> testData) {
        User testUser = (User) testData.get(TEST_USER);

        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.portalUserId = testUser.Id;
        ctx.storefront = TEST_STOREFRONT;
        ccrz.cc_CallContext.init(ctx);

        Map<String, Object> addToCartResult = ccrz.ccApiCart.addTo(new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccApiCart.LINE_DATA => new List<Map<String, Object>>{
                        new Map<String, Object>{
                                ccrz.ccApiCart.LINE_DATA_SKU => TEST_SKU + 1,
                                ccrz.ccApiCart.LINE_DATA_QUANTITY => 3
                        }
                }
        });

        // Place Order
        return ccrz.ccApiCart.place(new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccAPICart.CART_ENCID => (String) addToCartResult.get(ccrz.ccApiCart.CART_ENCID),
                ccrz.ccApiCart.SKIP_VALID_CHECK => true
        });

    }

    /**
     * @description Creates and inserts a test store attribute.
     */
    public static Store_Attribute__c createInsertTestStoreAttribute(String programType, Store__c store) {
        Store_Attribute__c currStoreAttribute = new Store_Attribute__c();
        currStoreAttribute.RecordTypeId = Schema.SObjectType.Store_Attribute__c.getRecordTypeInfosByName().get('Autoship').getRecordTypeId();
        currStoreAttribute.Store__c = store.Id;
        currStoreAttribute.Autoship_Program_Type__c = programType;
        currStoreAttribute.Coffee_For_Brewing__c = TEST_ASSORTMENT_SIZE;
        currStoreAttribute.Coffee_For_Brewing_Qty__c = 1;
        currStoreAttribute.Beverage_Autoship__c = TEST_ASSORTMENT_SIZE;
        currStoreAttribute.Beverage_Autoship_Qty__c = 1;
        currStoreAttribute.Retail_Whole_Bean_Coffee__c = TEST_ASSORTMENT_SIZE;
        currStoreAttribute.Retail_Whole_Bean_Coffee_Qty__c = 1;
        currStoreAttribute.Merchandise__c = TEST_ASSORTMENT_SIZE;
        currStoreAttribute.Merchandise_Qty__c = 1;
        currStoreAttribute.Gift_Card_Participation__c = TEST_ASSORTMENT_SIZE;
        currStoreAttribute.Gift_Card_Participation_Qty__c = 1;
        currStoreAttribute.Local_Product_Size__c = TEST_ASSORTMENT_SIZE;
        currStoreAttribute.Local_Product_Qty__c = 1;
        currStoreAttribute.Smallware_Supply_Qty__c = 1;
        currStoreAttribute.Ships_Promotion_Elsewhere__c = 'No';

        insert currStoreAttribute;
        return currStoreAttribute;
    }

    public static void createBillToAndShipToAddressForStore(Store__c testStore) {
        Address__c billTo = new Address__c();
        billTo.RecordTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByName().get('BillTo').getRecordTypeId();
        billTo.Store__c = testStore.Id;
        billTo.Address_Type__c = 'BillTo';
        billTo.Address_1__c = PARENT_BILL_STREET;
        billTo.Address_2__c = 'test';
        billTo.Address_3__c = 'test';
        billTo.City__c = 'test';
        billTo.Country__c = 'test';
        billTo.Postal_Code__c = '12345';
        billTo.State_Province__c = 'AL';
        billTo.Site_Id__c = '12345';
        billTo.Status__c = 'Y';
        billTo.Store_Number__c = '12345';
        insert billTo;

        Address__c shipTo = new Address__c();
        shipTo.RecordTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByName().get('ShipTo').getRecordTypeId();
        shipTo.Store__c = testStore.Id;
        shipTo.Address_Type__c = 'ShipTo';
        shipTo.Address_1__c = PARENT_SHIP_STREET;
        shipTo.Address_2__c = 'test';
        shipTo.Address_3__c = 'test';
        shipTo.City__c = 'test';
        shipTo.Country__c = 'test';
        shipTo.Postal_Code__c = '12345';
        shipTo.State_Province__c = 'AL';
        shipTo.Site_Id__c = '67890';
        shipTo.Billto_Site_Number__c = '12345';
        shipTo.Status__c = 'Y';
        shipTo.Primary__c = 'Y';
        billTo.Store_Number__c = '12345';
        insert shipTo;
    }

    /**
     * @description Creates and inserts a test store.
     */
    public static Store__c createInsertTestStore(Account licenseeAccount, Account storeAccount, Opportunity testOpportunity) {
        Store__c currStore = new Store__c();
        currStore.RecordTypeId = Schema.SObjectType.Store__c.getRecordTypeInfosByName().get('Store').getRecordTypeId();
        currStore.Licensee__c = licenseeAccount.Id;
        currStore.Store_Account__c = storeAccount.Id;
        currStore.Segment__c = TEST_STORE_SEGMENT;
        currStore.Subsegment__c = TEST_STORE_SUBSEGMENT;
        currStore.RDC__c = TEST_RDC;
        currStore.Country__c = TEST_STORE_COUNTRY;
        currStore.Commissary_Status__c = 'Is_Not_Commissary';
        currStore.Status__c = 'Open to the Public';
        currStore.Site_Name__c = testOpportunity.Site_Name__c;
        currStore.Address_1__c = testOpportunity.Address_1__c;
        currStore.Address_2__c = testOpportunity.Address_2__c;
        currStore.City__c = testOpportunity.City__c;
        currStore.State__c = testOpportunity.State_Province__c;
        currStore.Postal_Code__c = testOpportunity.Postal_Code__c;
        currStore.Country__c = testOpportunity.Country__c;
        currStore.Store_Type__c = testOpportunity.Store_Type__c;
        currStore.Licensee_Store_Number__c = '123';
        currStore.External_Presence__c = 'Low';
        currStore.Engine_Type__c = 'Drive Thru';
        currStore.Planned_Store_Size__c = String.valueOf(testOpportunity.Planned_Store_Size_ft__c);
        currStore.Store_Profile_Type__c = testOpportunity.Store_Profile_Type__c;
        currStore.Store_Account__c = storeAccount.Id;

        insert currStore;
        currStore.Store_Number__c = TEST_STORE_NUMBER;
        update currStore;
        createBillToAndShipToAddressForStore(currStore);
        return currStore;
    }

    /**
     * @description Creates and inserts a test autoship header.
     */
    public static SBUX_B2B_AutoShipHeader__c createInsertTestAutoShipHeader() {
        SBUX_B2B_AutoShipHeader__c testAutoShipHeader = new SBUX_B2B_AutoShipHeader__c();

        testAutoShipHeader.SBUX_B2B_Description__c = 'FALL FY 19 WAVE 1';
        testAutoShipHeader.SBUX_B2B_AutoshipType__c = 'Billing';
        testAutoShipHeader.SBUX_B2B_AutoshipStatus__c = 'Draft';
        testAutoShipHeader.SBUX_B2B_PromoLaunch__c = System.today();
        testAutoShipHeader.SBUX_B2B_PromoEnd__c = System.today().addYears(1);
        testAutoShipHeader.SBUX_B2B_FirstShipDate__c = System.today();
        testAutoShipHeader.SBUX_B2B_LongLeadFirstShipDate__c = System.today();
        testAutoShipHeader.SBUX_B2B_FreightTerms__c = 'Prepaid';
        testAutoShipHeader.SBUX_B2B_ShipPriority__c = 'Cutover';
        testAutoShipHeader.SBUX_B2B_OrderType__c = 'Standard Order';

        insert testAutoShipHeader;
        return testAutoShipHeader;
    }

    /**
     * @description Creates and inserts test autoship header lines.
     */
    public static List<SBUX_B2B_AutoShipLine__c> createInsertTestAutoShipLines(SBUX_B2B_AutoShipHeader__c testAutoShipHeader, List<ccrz__E_Product__c> testProducts) {
        List<SBUX_B2B_AutoShipLine__c> testAutoShipLines = new List<SBUX_B2B_AutoShipLine__c>();

        for (ccrz__E_Product__c p : testProducts) {
            SBUX_B2B_AutoShipLine__c currLine = new SBUX_B2B_AutoShipLine__c();
            currLine.RecordTypeId = Schema.SObjectType.SBUX_B2B_AutoShipLine__c.getRecordTypeInfosByName().get('Assortment Size').getRecordTypeId();
            currLine.SBUX_B2B_AutoshipHeader__c = testAutoShipHeader.Id;
            currLine.SBUX_B2B_ItemSKU__c = p.Id;
            currLine.SBUX_B2B_LineQty__c = 1;
            currLine.SBUX_B2B_LSCategory__c = LS_CATEGORY_BEVERAGE;
            currLine.SBUX_B2B_AssortmentSize__c = TEST_ASSORTMENT_SIZE;
            testAutoShipLines.add(currLine);
        }

        SBUX_B2B_AutoShipLine__c currLine = new SBUX_B2B_AutoShipLine__c();
        currLine.RecordTypeId = Schema.SObjectType.SBUX_B2B_AutoShipLine__c.getRecordTypeInfosByName().get('Assortment Size').getRecordTypeId();
        currLine.SBUX_B2B_AutoshipHeader__c = testAutoShipHeader.Id;
        currLine.SBUX_B2B_ItemSKU__c = testProducts[0].Id;
        currLine.SBUX_B2B_LineQty__c = 1;
        currLine.SBUX_B2B_LSCategory__c = 'Merchandise';
        currLine.SBUX_B2B_AssortmentSize__c = 'US All';
        testAutoShipLines.add(currLine);

        SBUX_B2B_AutoShipLine__c storeSpecificLine = new SBUX_B2B_AutoShipLine__c();
        storeSpecificLine.RecordTypeId = Schema.SObjectType.SBUX_B2B_AutoShipLine__c.getRecordTypeInfosByName().get('Store Attribute').getRecordTypeId();
        storeSpecificLine.SBUX_B2B_AutoshipHeader__c = testAutoShipHeader.Id;
        storeSpecificLine.SBUX_B2B_ItemSKU__c = testProducts[0].Id;
        storeSpecificLine.SBUX_B2B_LineQty__c = 1;
        storeSpecificLine.SBUX_B2B_StoreAttribute__c = 'Store_Number__c';
        storeSpecificLine.SBUX_B2B_StoreAttributeValue__c = TEST_STORE_NUMBER;
        testAutoShipLines.add(storeSpecificLine);

        insert testAutoShipLines;
        return testAutoShipLines;
    }

    public static ContentVersion createInsertTestContent() 
    {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Document';
        contentVersion.PathOnClient = 'TestDocument.csv';
        contentVersion.VersionData = Blob.valueOf(createContentData());
        contentVersion.IsMajorVersion = true;

        insert contentVersion;

        return [
                select
                        Id,
                        VersionData,
                        ContentDocumentId
                FROM
                        ContentVersion
                WHERE
                        Id = :contentVersion.id
        ];
    }



     public static String createContentData()
     {
        String header = 'sbux_b2b_itemsku__c,sbux_b2b_lineqty__c,sbux_b2b_assortmentsize__c,sbux_b2b_storeattribute__c,sbux_b2b_storeattributevalue__c' + '\r\n';

        List<ccrz__E_Product__c> productList = SBUX_B2B_TestDataFactory.createInsertTestProducts(2);

        String assortmentRow = productList[0].ccrz__SKU__c.trim() + ',' + '5' + ',' + TEST_ASSORTMENT_SIZE.trim() + ',' + ',' + '\r\n';
        String storeAttributeRow = productList[1].ccrz__SKU__c.trim() + ',' + '5' + ',' + ',' + 'Store_Number__c' + ',' + TEST_STORE.trim();

        return header + assortmentRow + storeAttributeRow;
    }



     


    public static SBUX_B2B_AutoShipLine__c createBeverageAutoshipLine(SBUX_B2B_AutoShipHeader__c testAutoShipHeader, ccrz__E_Product__c testProduct) {
        SBUX_B2B_AutoShipLine__c currLine = new SBUX_B2B_AutoShipLine__c();
        currLine.RecordTypeId = Schema.SObjectType.SBUX_B2B_AutoShipLine__c.getRecordTypeInfosByName().get('Assortment Size').getRecordTypeId();
        currLine.SBUX_B2B_AutoshipHeader__c = testAutoShipHeader.Id;
        currLine.SBUX_B2B_ItemSKU__c = testProduct.Id;
        currLine.SBUX_B2B_LineQty__c = 1;
        currLine.SBUX_B2B_LSCategory__c = LS_CATEGORY_BEVERAGE;
        currLine.SBUX_B2B_AssortmentSize__c = TEST_ASSORTMENT_SIZE;

        insert currLine;
        return currLine;
    }




    /**
     * @description Creates and inserts a test contact address record.
     */
    public static ccrz__E_ContactAddr__c createInsertTestContactAddress() {
        ccrz__E_ContactAddr__c testAddress = new ccrz__E_ContactAddr__c();
        testAddress.ccrz__FirstName__c = 'Test';
        testAddress.ccrz__LastName__c = 'Test';
        testAddress.ccrz__AddressFirstline__c = PARENT_BILL_STREET;
        testAddress.ccrz__City__c = PARENT_BILL_CITY;
        testAddress.ccrz__StateISOCode__c = PARENT_BILL_STATE;
        testAddress.ccrz__Country__c = PARENT_BILL_COUNTRY;
        testAddress.ccrz__CountryISOCode__c = PARENT_BILL_COUNTRY;
        testAddress.ccrz__PostalCode__c = PARENT_BILL_POSTAL_CODE;

        insert testAddress;
        return testAddress;
    }

    /**
     * @description Creates and inserts a test CC Ship Rates
     */
    public static List<ccrz__E_ShippingRate__c> createInsertShippingRates() {
        List<ccrz__E_ShippingRate__c> testShippingRateList = new List<ccrz__E_ShippingRate__c>();

        ccrz__E_ShippingRate__c shipRate1 = new ccrz__E_ShippingRate__c();
        shipRate1.ccrz__Shipper__c = 'Shipper1';
        shipRate1.Name = 'Ground';
        shipRate1.ccrz__Ground__c = true;
        shipRate1.ccrz__ShippingRate__c = 10;
        shipRate1.ccrz__Storefront__c = TEST_STOREFRONT;
        shipRate1.ccrz__MinWeight__c = 0;
        shipRate1.ccrz__MaxWeight__c = 9999;
        shipRate1.ccrz__CurrencyISOCode__c = TEST_CURRENCY_CODE;
        shipRate1.ccrz__Sequence__c = 1;

        ccrz__E_ShippingRate__c shipRate2 = new ccrz__E_ShippingRate__c();
        shipRate2.ccrz__Shipper__c = 'Shipper2';
        shipRate2.Name = 'Ground';
        shipRate2.ccrz__ShippingRate__c = 10;
        shipRate2.ccrz__Storefront__c = TEST_STOREFRONT;
        shipRate2.ccrz__MinWeight__c = 0;
        shipRate2.ccrz__MaxWeight__c = 9999;
        shipRate2.ccrz__CurrencyISOCode__c = TEST_CURRENCY_CODE;
        shipRate2.ccrz__Sequence__c = 2;

        testShippingRateList.add(shipRate1);
        testShippingRateList.add(shipRate2);

        insert testShippingRateList;
        return testShippingRateList;
    }

    public static List<Store__c> createInsertTestStoreList(Account storeAccount, Account testLicenseeAccount) {
        List<Store__c> storeList = new List<Store__c>();

        Store__c currStore = new Store__c();
        currStore.RecordTypeId = Schema.SObjectType.Store__c.getRecordTypeInfosByName().get('Store').getRecordTypeId();
        currStore.Store_Account__c = storeAccount.Id;
        currStore.Licensee__c = testLicenseeAccount.Id;
        currStore.Segment__c = TEST_STORE_SEGMENT;
        currStore.Subsegment__c = TEST_STORE_SUBSEGMENT;
        currStore.RDC__c = TEST_RDC;
        currStore.Country__c = TEST_STORE_COUNTRY;
        currStore.City__c = 'Chicago';
        currStore.Status__c = 'Open to the Public';
        currStore.Commissary_Status__c = 'Is_Not_Commissary';

        Store__c currStore1 = new Store__c();
        currStore1.RecordTypeId = Schema.SObjectType.Store__c.getRecordTypeInfosByName().get('Store').getRecordTypeId();
        currStore1.Store_Account__c = storeAccount.Id;
        currStore1.Licensee__c = testLicenseeAccount.Id;
        currStore1.Segment__c = TEST_STORE_SEGMENT;
        currStore1.Subsegment__c = TEST_STORE_SUBSEGMENT;

        currStore1.RDC__c = TEST_RDC;
        currStore1.Country__c = TEST_STORE_COUNTRY;
        currStore1.City__c = 'Houston';
        currStore1.Status__c = 'Open to the Public';
        currStore1.Commissary_Status__c = 'Is_Not_Commissary';

        Store__c currStore2 = new Store__c();
        currStore2.RecordTypeId = Schema.SObjectType.Store__c.getRecordTypeInfosByName().get('Store').getRecordTypeId();
        currStore2.Store_Account__c = storeAccount.Id;
        currStore2.Licensee__c = testLicenseeAccount.Id;
        currStore2.Segment__c = TEST_STORE_SEGMENT;
        currStore2.Subsegment__c = TEST_STORE_SUBSEGMENT;
        currStore2.RDC__c = TEST_RDC;
        currStore2.Country__c = TEST_STORE_COUNTRY;
        currStore2.City__c = 'Florida';
        currStore2.Status__c = 'Open to the Public';
        currStore2.Commissary_Status__c = 'Is_Not_Commissary';

        storeList.add(currStore);
        storeList.add(currStore1);
        storeList.add(currStore2);

        insert storeList;

        currStore.Store_Number__c = TEST_STORE_NUMBER;
        currStore1.Store_Number__c = TEST_STORE_NUMBER + 1;
        currStore2.Store_Number__c = TEST_STORE_NUMBER + 2;

        update storeList;

        return storeList;
    }

    public static List<SBUX_B2B_StoreSourcing__c> createInsertStoreDCSourcing(Store__c testStore) {
        List<SBUX_B2B_StoreSourcing__c> storeDCSourcingRecordsToInsert = new List<SBUX_B2B_StoreSourcing__c>();

        SBUX_B2B_StoreSourcing__c RDCRecord = new SBUX_B2B_StoreSourcing__c();
        RDCRecord.SBUX_B2B_StoreNumber__c = testStore.Store_Number__c;
        RDCRecord.SBUX_B2B_DistributionCenter__c = 'RDC100';
        RDCRecord.SBUX_B2B_DPNumber__c = 'RDC100';

        storeDCSourcingRecordsToInsert.add(RDCRecord);

        SBUX_B2B_StoreSourcing__c CDCRecord = new SBUX_B2B_StoreSourcing__c();
        CDCRecord.SBUX_B2B_StoreNumber__c = testStore.Store_Number__c;
        CDCRecord.SBUX_B2B_DistributionCenter__c = 'CDC100';
        CDCRecord.SBUX_B2B_DPNumber__c = 'CDC100';

        storeDCSourcingRecordsToInsert.add(CDCRecord);

        insert storeDCSourcingRecordsToInsert;
        return storeDCSourcingRecordsToInsert;
    }

    public static List<SBUX_B2B_DeliverySchedule__c> createInsertDeliverySchedules(Store__c testStore) {
        List<SBUX_B2B_DeliverySchedule__c> deliveryScheduleRecordsToInsert = new List<SBUX_B2B_DeliverySchedule__c>();

        SBUX_B2B_DeliverySchedule__c RDCRecord = new SBUX_B2B_DeliverySchedule__c();
        RDCRecord.SBUX_B2B_StoreNumber__c = testStore.Store_Number__c;
        RDCRecord.SBUX_B2B_DistributionCenter__c = 'RDC100';
        RDCRecord.SBUX_B2B_DPNumber__c = 'RDC100';
        RDCRecord.SBUX_B2B_OrderDate__c = Date.today().addDays(4);
        RDCRecord.SBUX_B2B_ShipDate__c = Date.today().addDays(8);
        RDCRecord.SBUX_B2B_DeliveryDate__c = Date.today().addDays(12);
        RDCRecord.SBUX_B2B_CustomerSiteNumber__c = '12345';

        deliveryScheduleRecordsToInsert.add(RDCRecord);

        SBUX_B2B_DeliverySchedule__c CDCRecord = new SBUX_B2B_DeliverySchedule__c();
        CDCRecord.SBUX_B2B_StoreNumber__c = testStore.Store_Number__c;
        CDCRecord.SBUX_B2B_DistributionCenter__c = 'CDC100';
        CDCRecord.SBUX_B2B_DPNumber__c = 'CDC100';
        CDCRecord.SBUX_B2B_OrderDate__c = Date.today().addDays(4);
        CDCRecord.SBUX_B2B_ShipDate__c = Date.today().addDays(8);
        CDCRecord.SBUX_B2B_DeliveryDate__c = Date.today().addDays(12);
        CDCRecord.SBUX_B2B_CustomerSiteNumber__c = '12345';

        deliveryScheduleRecordsToInsert.add(CDCRecord);

        insert deliveryScheduleRecordsToInsert;
        return deliveryScheduleRecordsToInsert;
    }

    public static List<SBUX_B2B_ItemDCSourcing__c> createInsertItemDCSourcing(ccrz__E_Product__c testProduct) {
        List<SBUX_B2B_ItemDCSourcing__c> itemDCSourcingsRecordsToInsert = new List<SBUX_B2B_ItemDCSourcing__c>();

        SBUX_B2B_ItemDCSourcing__c RDCRecord = new SBUX_B2B_ItemDCSourcing__c();
        RDCRecord.SBUX_B2B_CutoffTime__c = Time.newInstance(2, 0, 0, 0);
        RDCRecord.SBUX_B2B_CuttoffTimeZone__c = PACIFIC_TIME_ZONE_GMT_OFFSET;
        RDCRecord.SBUX_B2B_ItemNumber__c = testProduct.ccrz__SKU__c;
        RDCRecord.SBUX_B2B_DistributionCenter__c = 'RDC100';
        RDCRecord.SBUX_B2B_DPNumber__c = 'RDC100';

        itemDCSourcingsRecordsToInsert.add(RDCRecord);

        SBUX_B2B_ItemDCSourcing__c CDCRecord = new SBUX_B2B_ItemDCSourcing__c();
        CDCRecord.SBUX_B2B_CutoffTime__c = Time.newInstance(4, 30, 0, 0);
        CDCRecord.SBUX_B2B_CuttoffTimeZone__c = PACIFIC_TIME_ZONE_GMT_OFFSET;
        CDCRecord.SBUX_B2B_ItemNumber__c = testProduct.ccrz__SKU__c;
        CDCRecord.SBUX_B2B_DistributionCenter__c = 'CDC100';
        CDCRecord.SBUX_B2B_DPNumber__c = 'CDC100';

        itemDCSourcingsRecordsToInsert.add(CDCRecord);

        insert itemDCSourcingsRecordsToInsert;
        return itemDCSourcingsRecordsToInsert;
    }

    /**
     * @description Creates and Returns the specified number of Catalog rules.
     */
    public static List<SBUX_B2B_CatalogEntitlementRule__c> createCatalogEntitlementRule(List<ccrz__E_Product__c> productList, List<Store__c> stores, String ruleType) {
        List<SBUX_B2B_CatalogEntitlementRule__c> ruleList = new List<SBUX_B2B_CatalogEntitlementRule__c>();

        for (ccrz__E_Product__c product : productList) {
            SBUX_B2B_CatalogEntitlementRule__c rule = new SBUX_B2B_CatalogEntitlementRule__c(
                    SBUX_B2B_City__c = stores[0].City__c,
                    SBUX_B2B_Country__c = stores[0].Country__c,
                    SBUX_B2B_StoreNumber__c = stores[0].Store_Number__c,
                    SBUX_B2B_SkuList__c = product.ccrz__SKU__c,
                    SBUX_B2B_StartDate__c = System.today(),
                    SBUX_B2B_ProductCategory__c = BEVERAGE_AND_FOOD_CATEGORY,
                    SBUX_B2B_EndDate__c = System.today().addYears(+1),
                    SBUX_B2B_RuleType__c = ruleType) ;

            ruleList.add(rule);
        }

        insert ruleList;
        return ruleList;
    }

    public static ccrz__E_Category__c createCategory(String categoryID) {
        ccrz__E_Category__c category = new ccrz__E_Category__c(
                Name = 'Merchandise / Local',
                ccrz__CategoryID__c = categoryID,
                ccrz__StartDate__c = Date.today().addDays(-1),
                ccrz__EndDate__c = Date.today().addDays(1)
        );
        insert category;
        return category;
    }

    public static List <ccrz__E_ProductCategory__c> createProductCategory(ccrz__E_Category__c category, List <ccrz__E_Product__c> productList) {
        List <ccrz__E_ProductCategory__c> prodCatToInsert = new List<ccrz__E_ProductCategory__c>();

        for (ccrz__E_Product__c product : productList) {
            ccrz__E_ProductCategory__c prodCat = new ccrz__E_ProductCategory__c (
                    ccrz__Product__c = product.ID,
                    ccrz__Category__c = category.ID,
                    ccrz__StartDate__c = Date.today().addDays(-1),
                    ccrz__EndDate__c = Date.today().addDays(1)
            );
            prodCatToInsert.add(prodCat);
        }

        insert prodCatToInsert;

        return prodCatToInsert;
    }

    public static List <SBUX_B2B_ItemDCSourcing__c> createItemSourcing(List <ccrz__E_Product__c> productList) {
        List <SBUX_B2B_ItemDCSourcing__c> itemSourcingToInsert = new List<SBUX_B2B_ItemDCSourcing__c>();

        for (ccrz__E_Product__c product : productList) {
            SBUX_B2B_ItemDCSourcing__c itemSourcing = new SBUX_B2B_ItemDCSourcing__c (SBUX_B2B_ItemNumber__c = product.ccrz__SKU__c);
            itemSourcingToInsert.add(itemSourcing);
        }

        insert itemSourcingToInsert;

        return itemSourcingToInsert;
    }

    public static SBUX_B2B_PARSheet__c createParSheet(String storeId) {
        SBUX_B2B_PARSheet__c parSheet = new SBUX_B2B_PARSheet__c(
                SBUX_B2B_Category__c = BEVERAGE_AND_FOOD_CATEGORY,
                SBUX_B2B_Store__c = storeId
        );

        insert parSheet;
        return parSheet;
    }

    public static List <SBUX_B2B_PARSheetItem__c> createParSheetItems(SBUX_B2B_PARSheet__c parSheet, List <ccrz__E_Product__c> productList) {
        List <SBUX_B2B_PARSheetItem__c> parSheetItemToInsert = new List<SBUX_B2B_PARSheetItem__c>();

        for (ccrz__E_Product__c product : productList) {
            SBUX_B2B_PARSheetItem__c parSheetItem = new SBUX_B2B_PARSheetItem__c (
                    SBUX_B2B_ProductItem__c = product.ID,
                    SBUX_B2B_OnHandQty__c = 20,
                    SBUX_B2B_OrderQty__c = 10,
                    SBUX_B2B_ParQty__c = 30,
                    SBUX_B2B_PARSheet__c = parSheet.ID
            );
            parSheetItemToInsert.add(parSheetItem);
        }

        insert parSheetItemToInsert;

        return parSheetItemToInsert;
    }

    public static List<ccrz__E_ProductIndex__c> createProductIndices(Map<String, Object> testData) {
        List<ccrz__E_ProductIndex__c> newProductIndices = new List<ccrz__E_ProductIndex__c>();

        ccrz__E_Category__c category = (ccrz__E_Category__c) testData.get(TEST_CATEGORY);

        ccrz__E_PriceList__c pricelist = (ccrz__E_PriceList__c) testData.get(TEST_PRICELIST);

        Decimal count = 0;

        for (ccrz__E_Product__c product : (List<ccrz__E_Product__c>) testData.get(TEST_PRODUCTS)) {
            for (ccrz__E_ProductCategory__c productCategory : (List<ccrz__E_ProductCategory__c>) testData.get(TEST_PRODCAT)) {
                newProductIndices.add(new ccrz__E_ProductIndex__c(
                        ccrz__ProductCategory__c = productCategory.Id,
                        ccrz__ProductCategoryStartDate__c = productCategory.ccrz__StartDate__c,
                        ccrz__ProductCategoryEndDate__c = productCategory.ccrz__EndDate__c,
                        ccrz__ProductCategorySequence__c = productCategory.ccrz__Sequence__c,
                        ccrz__Category__c = category.Id,
                        ccrz__CategoryStartDate__c = category.ccrz__StartDate__c,
                        ccrz__CategoryEndDate__c = category.ccrz__EndDate__c,
                        ccrz__PriceLists__c = pricelist.Id,
                        ccrz__Locale__c = 'en_US',
                        ccrz__Product__c = product.Id,
                        ccrz__ProductName__c = product.Name,
                        ccrz__ProductStatus__c = product.ccrz__ProductStatus__c,
                        ccrz__Storefront__c = TEST_STOREFRONT,
                        ccrz__ProductStartDate__c = product.ccrz__StartDate__c,
                        ccrz__ProductEndDate__c = product.ccrz__EndDate__c,
                        ccrz__ShortDescription__c = 'TEST',
                        ccrz__SKU__c = product.ccrz__SKU__c,
                        ccrz__IndexPrice__c = String.valueOf(count).leftPad(19, '0'),
                        ccrz__Active__c = TRUE,
                        ccrz__IndexCurrency__c = 'USD'
                ));
                count++;
            }
        }

        insert newProductIndices;

        return newProductIndices;
    }

}