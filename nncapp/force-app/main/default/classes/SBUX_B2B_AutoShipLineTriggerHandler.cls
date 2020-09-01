public with sharing class SBUX_B2B_AutoShipLineTriggerHandler
{
    public static void generateExternalID(List<SBUX_B2B_AutoShipLine__c> newAutoShipLines)
    {
        for ( SBUX_B2B_AutoShipLine__c autoshipLine : newAutoShipLines )
        {
            if (String.isBlank(autoshipLine.sbux_b2b_externalid__c))
            {
                  setExternalId(autoshipLine);
            }
         }
        
    }

    public static void updateExternalID(List<SBUX_B2B_AutoShipLine__c> newAutoShipLines,
                                        Map<Id, SBUX_B2B_AutoShipLine__c> oldMap,
                                        Map<Id, SBUX_B2B_AutoShipLine__c> newMap)
    {            
        for ( SBUX_B2B_AutoShipLine__c autoshipLine : newAutoShipLines )
        {
            SBUX_B2B_AutoShipLine__c oldAutoLine = oldMap.get(autoshipLine.Id);
            SBUX_B2B_AutoShipLine__c newAutoLine = newMap.get(autoshipLine.Id);

            if (newAutoLine.SBUX_B2B_LSCategory__c != oldAutoLine.SBUX_B2B_LSCategory__c
                || newAutoLine.SBUX_B2B_AssortmentSize__c != oldAutoLine.SBUX_B2B_AssortmentSize__c)
            {
                    setExternalId(autoshipLine);
            }
        }
    }




    private static void setExternalId(SBUX_B2B_AutoShipLine__c autoshipLine)
    {
        String sku = autoshipLine.SBUX_B2B_ItemSKU_Summary__c.substringBefore('-').trim();

           if(autoshipLine.sbux_b2b_assortmentsize__c != null 
                            && String.isNotBlank(autoshipLine.sbux_b2b_assortmentsize__c))
            {  
                autoshipLine.put('sbux_b2b_externalid__c', sku + autoshipLine.SBUX_B2B_LSCategory__c + autoshipLine.sbux_b2b_assortmentsize__c+ autoshipLine.sbux_b2b_autoshipheader__c) ;
            }
            if (autoshipLine.sbux_b2b_storeattribute__c != null 
                    && String.isNotBlank(autoshipLine.sbux_b2b_storeattribute__c)
                    && String.isNotBlank(autoshipLine.sbux_b2b_storeattributevalue__c))
            {
                autoshipLine.put('sbux_b2b_externalid__c', sku + autoshipLine.sbux_b2b_storeattribute__c + autoshipLine.sbux_b2b_storeattributevalue__c + autoshipLine.sbux_b2b_autoshipheader__c) ;
            } 
    }
}