/**
 * Created by dgajwani on 5/21/20.
 */
@IsTest
public with sharing class SBUX_B2B_ccLogicCartGetDeliveryDatesTest {

    public static Map<String, Object> testData;
    public static Store__c testStore;
            public static List<ccrz__E_Product__c> testProducts;

    public static void setupTestData() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        testStore = (Store__c) testData.get(SBUX_B2B_TestDataFactory.TEST_STORE);
        testProducts = (List<ccrz__E_Product__c>) testData.get(SBUX_B2B_TestDataFactory.TEST_PRODUCTS);
    }

    @isTest
    public static void testDeliveryDatesAllTypesWithODS() {
        setupTestData();
        SBUX_B2B_TestDataFactory.createInsertItemDCSourcing(testProducts[0]);
        SBUX_B2B_TestDataFactory.createInsertDeliverySchedules(testStore);
        SBUX_B2B_TestDataFactory.createInsertStoreDCSourcing(testStore);

        Map<String, Object> deliveryDatesResponse;
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        Test.startTest();
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            ctx.userLocale = 'en_US';
            ctx.userIsoCode = 'USD';

            ccrz.cc_CallContext.init(ctx);

            Map<String, Object> deliveryDatesRequest = new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccApiCart.SHIPPING_ADDRLIST => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                    SBUX_B2B_ccLogicCartGetDeliveryDates.SHIP_ADDRESS => new Map<String, Object>{
                                            SBUX_B2B_ccLogicCartGetDeliveryDates.SFID => 'COGS_RDC',
                                            SBUX_B2B_ccLogicCartGetDeliveryDates.SHIPPING_COMMENTS => 'COGS_RDC'
                                    }
                            },
                            new Map<String, Object>{
                                    SBUX_B2B_ccLogicCartGetDeliveryDates.SHIP_ADDRESS => new Map<String, Object>{
                                            SBUX_B2B_ccLogicCartGetDeliveryDates.SFID => 'COGS_CDC',
                                            SBUX_B2B_ccLogicCartGetDeliveryDates.SHIPPING_COMMENTS => 'COGS_CDC'
                                    }
                            },
                            new Map<String, Object>{
                                    SBUX_B2B_ccLogicCartGetDeliveryDates.SHIP_ADDRESS => new Map<String, Object>{
                                            SBUX_B2B_ccLogicCartGetDeliveryDates.SFID => SBUX_B2B_ccLogicCartGetDeliveryDates.ORDER_TYPE_EMERGENCY,
                                            SBUX_B2B_ccLogicCartGetDeliveryDates.SHIPPING_COMMENTS => SBUX_B2B_ccLogicCartGetDeliveryDates.ORDER_TYPE_EMERGENCY
                                    }
                            }
                    }
            };
            deliveryDatesResponse = ccrz.ccApiCart.getDeliveryDates(deliveryDatesRequest);
        }
        Test.stopTest();

        System.assertNotEquals(null, deliveryDatesResponse);
        System.assertEquals(true, deliveryDatesResponse.containsKey(SBUX_B2B_ccLogicCartGetDeliveryDates.SHIPPING_ADDR_LST));
        Map<String, Object> addressListMap = (Map<String, Object>) deliveryDatesResponse.get(SBUX_B2B_ccLogicCartGetDeliveryDates.SHIPPING_ADDR_LST);
        System.debug(System.LoggingLevel.DEBUG, 'testDeliveryDatesAllTypesWithODS:addressListMap: ' + JSON.serialize(addressListMap));
        System.assertEquals(3, addressListMap.size());
        for (String currAddressSfid : addressListMap.keySet()){
            Map<String, Object> currAddressRequestDataMap = (Map<String, Object>) addressListMap.get(currAddressSfid);
            System.assertEquals(true, currAddressRequestDataMap.containsKey(SBUX_B2B_ccLogicCartGetDeliveryDates.START_DATE));
            System.assertEquals(true, currAddressRequestDataMap.containsKey(SBUX_B2B_ccLogicCartGetDeliveryDates.END_DATE));
            if (currAddressSfid.equalsIgnoreCase(SBUX_B2B_ccLogicCartGetDeliveryDates.ORDER_TYPE_EMERGENCY)){
                System.assertEquals(false, currAddressRequestDataMap.containsKey(SBUX_B2B_ccLogicCartGetDeliveryDates.ENABLED_DAYS));
            } else {
                System.assertEquals(true, currAddressRequestDataMap.containsKey(SBUX_B2B_ccLogicCartGetDeliveryDates.ENABLED_DAYS));
                Set<String> enabledDays = (Set<String>) currAddressRequestDataMap.get(SBUX_B2B_ccLogicCartGetDeliveryDates.ENABLED_DAYS);
                System.assertNotEquals(0, enabledDays.size());
            }
        }
    }

    @IsTest
    public static void testDeliveryDatesAllTypesWithoutODS() {
        setupTestData();

        Map<String, Object> deliveryDatesResponse;
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        Test.startTest();
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            ctx.userLocale = 'en_US';
            ctx.userIsoCode = 'USD';

            ccrz.cc_CallContext.init(ctx);

            Map<String, Object> deliveryDatesRequest = new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccApiCart.SHIPPING_ADDRLIST => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                    SBUX_B2B_ccLogicCartGetDeliveryDates.SHIP_ADDRESS => new Map<String, Object>{
                                            SBUX_B2B_ccLogicCartGetDeliveryDates.SFID => 'COGS_RDC',
                                            SBUX_B2B_ccLogicCartGetDeliveryDates.SHIPPING_COMMENTS => 'COGS_RDC'
                                    }
                            },
                            new Map<String, Object>{
                                    SBUX_B2B_ccLogicCartGetDeliveryDates.SHIP_ADDRESS => new Map<String, Object>{
                                            SBUX_B2B_ccLogicCartGetDeliveryDates.SFID => 'COGS_CDC',
                                            SBUX_B2B_ccLogicCartGetDeliveryDates.SHIPPING_COMMENTS => 'COGS_CDC'
                                    }
                            },
                            new Map<String, Object>{
                                    SBUX_B2B_ccLogicCartGetDeliveryDates.SHIP_ADDRESS => new Map<String, Object>{
                                            SBUX_B2B_ccLogicCartGetDeliveryDates.SFID => SBUX_B2B_ccLogicCartGetDeliveryDates.ORDER_TYPE_EMERGENCY,
                                            SBUX_B2B_ccLogicCartGetDeliveryDates.SHIPPING_COMMENTS => SBUX_B2B_ccLogicCartGetDeliveryDates.ORDER_TYPE_EMERGENCY
                                    }
                            }
                    }
            };
            deliveryDatesResponse = ccrz.ccApiCart.getDeliveryDates(deliveryDatesRequest);
        }
        Test.stopTest();

        System.assertNotEquals(null, deliveryDatesResponse);
        System.assertEquals(true, deliveryDatesResponse.containsKey(SBUX_B2B_ccLogicCartGetDeliveryDates.SHIPPING_ADDR_LST));
        Map<String, Object> addressListMap = (Map<String, Object>) deliveryDatesResponse.get(SBUX_B2B_ccLogicCartGetDeliveryDates.SHIPPING_ADDR_LST);
        System.assertEquals(3, addressListMap.size());
        for (String currAddressSfid : addressListMap.keySet()){
            Map<String, Object> currAddressRequestDataMap = (Map<String, Object>) addressListMap.get(currAddressSfid);
            System.assertEquals(true, currAddressRequestDataMap.containsKey(SBUX_B2B_ccLogicCartGetDeliveryDates.START_DATE));
            System.assertEquals(true, currAddressRequestDataMap.containsKey(SBUX_B2B_ccLogicCartGetDeliveryDates.END_DATE));
            System.assertEquals(true, currAddressRequestDataMap.containsKey(SBUX_B2B_ccLogicCartGetDeliveryDates.ENABLED_DAYS));
            Set<String> enabledDays = (Set<String>) currAddressRequestDataMap.get(SBUX_B2B_ccLogicCartGetDeliveryDates.ENABLED_DAYS);
            System.assertEquals(0, enabledDays.size());
        }
    }

}