public with sharing class SBUX_B2B_ItemDCSourcingHandler 
{
    public static final Decimal LOWER_BOUND_THRESHOLD = 20;
    public static final Decimal UPPER_BOUND_THRESHOLD = 100;
 

    public static void processItemSourcing(List<SBUX_B2B_ItemDCSourcing__c> newItemSourcingList, boolean isInsert)
    {
        List<String> skuList = new List<String>();

        for ( SBUX_B2B_ItemDCSourcing__c itemSourcing : newItemSourcingList )
        {
            skuList.add( itemSourcing.SBUX_B2B_ItemNumber__c);
        }

        List <ccrz__E_Product__c> productList =  [SELECT ID, ccrz__SKU__c FROM ccrz__E_Product__c WHERE ccrz__SKU__c IN :skuList];

        Map<String, List<ccrz__E_Product__c>> prodMap = Collection.of(productList).groupByStrings('ccrz__SKU__c');

        for ( SBUX_B2B_ItemDCSourcing__c itemSourcing : newItemSourcingList )
        {
            List<ccrz__E_Product__c> prodListFromMap = (List<ccrz__E_Product__c>)prodMap.get(itemSourcing.SBUX_B2B_ItemNumber__c);
            
            if(isInsert)
            {
                itemSourcing.SBUX_B2B_UpperThreshold__c = UPPER_BOUND_THRESHOLD;
                itemSourcing.SBUX_B2B_LowerThreshold__c = LOWER_BOUND_THRESHOLD;
            }
            if (prodListFromMap != null && !prodListFromMap.isEmpty())
            {
                itemSourcing.SBUX_B2B_Item__c = prodListFromMap[0].Id;
            }
            else 
            {
                itemSourcing.SBUX_B2B_ItemNumber__c.addError('The provided Item Number ' + itemSourcing.SBUX_B2B_ItemNumber__c + ' is invalid');
            }
        }
    }
}