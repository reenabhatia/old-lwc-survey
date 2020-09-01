/**
 * Created by dgajwani on 5/6/20.
 */
@IsTest
public with sharing class SBUX_B2B_ccLogicGetShippingOptionsTest {
    public static Map<String, Object> testData;

    public static void setupTestData() {
        testData = SBUX_B2B_TestDataFactory.setupAccountContactUser();
        SBUX_B2B_TestDataFactory.createInsertShippingRates();
    }

    @isTest
    public static void testShippingOptions() {
        setupTestData();

        Map<String, Object> shippingOptionsResponse;
        String currCartENCID;

        Test.startTest();
        User testUser = (User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER);
        System.runAs(testUser) {
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = (String) testData.get(SBUX_B2B_TestDataFactory.TEST_STOREFRONT);
            ctx.portalUserId = ((User) testData.get(SBUX_B2B_TestDataFactory.TEST_USER)).Id;
            ctx.userLocale = 'en_US';
            ctx.userIsoCode = 'USD';

            ccrz.cc_CallContext.init(ctx);

            Map<String, Object> addToCartResult = ccrz.ccApiCart.addTo(new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccApiCart.LINE_DATA => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                    ccrz.ccApiCart.LINE_DATA_SKU => SBUX_B2B_TestDataFactory.TEST_SKU + 1,
                                    ccrz.ccApiCart.LINE_DATA_QUANTITY => 3
                            }
                    }
            });

            currCartENCID = (String) addToCartResult.get(ccrz.ccApiCart.CART_ENCID);

            ccrz__E_Cart__c currCart = [
                    SELECT Id
                    FROM ccrz__E_Cart__c
                    WHERE ccrz__EncryptedId__c = :currCartENCID
            ];

            shippingOptionsResponse = ccrz.ccApiCart.getShippingOptions(new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccApiCart.CART_ID => currCart.Id,
                    ccrz.ccApiCart.SHIPPING_ADDRLIST => new List<Map<String, Object>>{
                            new Map<String, Object> {
                                    'sfid' => SBUX_B2B_TestDataFactory.createInsertTestContactAddress().Id,
                                    'countryISOCode' => SBUX_B2B_TestDataFactory.PARENT_BILL_COUNTRY,
                                    'postalCode' => SBUX_B2B_TestDataFactory.PARENT_BILL_POSTAL_CODE,
                                    'stateISOCode' => SBUX_B2B_TestDataFactory.PARENT_BILL_STATE
                            }
                    }
            });
        }

        Test.stopTest();

        Map<String, Object> returnedShipOptions= (Map<String, Object>)shippingOptionsResponse.get(ccrz.ccApiCart.SHIPPING_OPTIONS);
        System.assertNotEquals(null, shippingOptionsResponse);
        System.assertNotEquals(null, returnedShipOptions);
        System.assertNotEquals(0, returnedShipOptions.size());

        // Currently present ship rates.
        Map<String, Object> serviceName2ShipperMap = new Map<String, Object> ();
        List<ccrz__E_ShippingRate__c> allShippingRates = [
                SELECT Id, Name, ccrz__Shipper__c
                FROM ccrz__E_ShippingRate__c
        ];
        if (allShippingRates.size() > 0) {
            for (ccrz__E_ShippingRate__c sr : allShippingRates) {
                serviceName2ShipperMap.put(sr.ccrz__Shipper__c, sr.Name);
            }
        }

        for (String addressId : returnedShipOptions.keySet()) {
            List<Object> shipOptions = (List<Object>) returnedShipOptions.get(addressId);
            for (Object so : shipOptions){
                Map<String, Object> currShipOption = (Map<String, Object>) so;
                String shipper = (String) currShipOption.get('provider');
                String serviceName = (String) currShipOption.get('serviceName');
                System.assertEquals(serviceName2ShipperMap.get(shipper), serviceName);
            }
        }
    }
}