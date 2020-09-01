@isTest
private with sharing class SBUX_B2B_ccProductOnUpsertTest {


    @IsTest
    private static void testProductUpdateRestriction() {
        final String NAME = 'New Name';
        final String PIM_DESC = 'New Description';
        final String UOM = 'New UOM';
        final String UOM_CONV = '[]';
        final String PROD_STATUS = 'Not Orderable';

        List<ccrz__E_Product__c> productList = SBUX_B2B_TestDataFactory.createInsertTestProducts(1);
        ccrz__E_Product__c product = productList.get(0);

        product.Name = NAME;
        product.SBUX_B2B_PIMDescription__c = PIM_DESC;
        product.ccrz__UnitOfMeasure__c = UOM ;
        product.SBUX_B2B_UOMConv__c = UOM_CONV;
        product.ccrz__ProductStatus__c = PROD_STATUS;

        update product;

        Test.startTest();

        ccrz__E_Product__c fetchProduct = [
                SELECT
                        Name,
                        SBUX_B2B_PIMDescription__c,
                        ccrz__UnitOfMeasure__c,
                        SBUX_B2B_UOMConv__c,
                        ccrz__ProductStatus__c
                FROM ccrz__E_Product__c
                WHERE
                        ID = :product.ID
        ];

        String contextPath = System.URL.getCurrentRequestUrl().getPath();

        //TODO - use a regular expression to match the fully qualified context path
        if (contextPath.contains('/services/data/')) {
            System.assertNotEquals(UOM, fetchProduct.ccrz__UnitOfMeasure__c);
            System.assertNotEquals(PROD_STATUS, fetchProduct.ccrz__ProductStatus__c);
            System.assertNotEquals(NAME, fetchProduct.Name);
        } else {
            System.assertEquals(UOM, fetchProduct.ccrz__UnitOfMeasure__c);
            System.assertEquals(PROD_STATUS, fetchProduct.ccrz__ProductStatus__c);
            System.assertEquals(NAME, fetchProduct.Name);
        }
        Test.stopTest();
    }

    @IsTest
    private static void testProductCreateUOMConversion() {
        List<ccrz__E_Product__c> productList;
        Test.startTest();
        productList = SBUX_B2B_TestDataFactory.createInsertTestProducts(1);
        Test.stopTest();
        System.assertNotEquals(0, productList.size());
        ccrz__E_Product__c currProduct = [
                SELECT SBUX_B2B_Orderable_UOM_Conversion_Factor__c
                FROM ccrz__E_Product__c
                WHERE Id = :productList[0].Id
        ];
        System.assertEquals(6, currProduct.SBUX_B2B_Orderable_UOM_Conversion_Factor__c);
    }

    @IsTest
    private static void testProductUpdateUOMConversion() {
        List<ccrz__E_Product__c> productList = SBUX_B2B_TestDataFactory.createInsertTestProducts(1);
        Test.startTest();
        ccrz__E_Product__c currProduct = productList[0];
        currProduct.SBUX_B2B_UOMConv__c = '[ { "convRt" : 6, "fromCode" : "CS", "toCode" : "EA"}, { "convRt" : 4, "fromCode" : "EA", "toCode" : "CS"} ]';
        update currProduct;
        Test.stopTest();

        System.assertNotEquals(0, productList.size());
        currProduct = [
                SELECT SBUX_B2B_Orderable_UOM_Conversion_Factor__c
                FROM ccrz__E_Product__c
                WHERE Id = :productList[0].Id
        ];
        System.assertEquals(4, currProduct.SBUX_B2B_Orderable_UOM_Conversion_Factor__c);
    }
}