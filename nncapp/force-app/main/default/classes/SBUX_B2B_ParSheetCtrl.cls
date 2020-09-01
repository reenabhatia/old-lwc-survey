public with sharing class SBUX_B2B_ParSheetCtrl 
{
    @AuraEnabled(Cacheable=true)
	public static String getCurrentStoreID(String ctx)
    { 
        String storeID = '';

        setContext(ctx);

        Store__c currentStore = SBUX_B2B_StorefrontUtil.fetchCurrentStore();

        if ( currentStore != null)
        {
            storeID = currentStore.Id ;
        }
        return storeID;
    }

   



    @AuraEnabled(Cacheable=true)
	public static List<String> getParSheetCategory(String storeId)
    {
        List<String> selectedCategories = new List<String>();

        List<SBUX_B2B_PARSheet__c>  parSheetList = getParSheetForStore(storeId);

        if (parSheetList != null && !parSheetList.isEmpty())
        {
            SBUX_B2B_PARSheet__c parSheet =  parSheetList[0];

             String categories = parSheet.SBUX_B2B_Category__c ;

             if ( categories != null && String.isNotBlank(categories))
             {
                selectedCategories =  categories.split(';');
             }
            
        }
        return selectedCategories;
    }




    public static List<SBUX_B2B_PARSheetItem__c> fetchEligibleParSheetItems(String storeId, Set<String> prodIds, Integer queryLimit,String recId)
    {
        String PARSHEET_ITEMS_QUERY = 'SELECT Id' +
                                    ',SBUX_B2B_OnHandQty__c' +
                                    ',SBUX_B2B_OrderQty__c' +
                                    ',SBUX_B2B_ParQty__c' +
                                    ',SBUX_B2B_PARSheet__c' +
                                    ',SBUX_B2B_PARSheet__r.SBUX_B2B_Category__c' +
                                    ',SBUX_B2B_PARSheet__r.SBUX_B2B_Store__c' +
                                    ',SBUX_B2B_ProductItem__c' +
                                    ',SBUX_B2B_ProductItem__r.ccrz__SKU__c'+
                                    ',SBUX_B2B_ProductItem__r.ccrz__UnitOfMeasure__c'+
                                    ',SBUX_B2B_ProductItem__r.SBUX_B2B_PrimaryUOM__c'+
                                    ',SBUX_B2B_ProductItem__r.SBUX_B2B_UOMConv__c' +
                                    ',SBUX_B2B_ProductItem__r.Name' +
                                    ',SBUX_B2B_ExternalID__c' +
                                    ' FROM SBUX_B2B_PARSheetItem__c ' +
                                    ' WHERE ' +
                                    ' SBUX_B2B_PARSheet__r.SBUX_B2B_Store__c = :storeId';
                                    
    
        if (prodIds != null )
        {
            PARSHEET_ITEMS_QUERY += ' AND SBUX_B2B_ProductItem__c IN  :prodIds' ;
        }
        if (recId != null && String.isNotBlank(recId))
        {
            PARSHEET_ITEMS_QUERY += ' AND ID > :recId ' ;
        }

        PARSHEET_ITEMS_QUERY += ' ORDER BY ID ASC NULLS LAST ';

        if (queryLimit != null)
        {
            PARSHEET_ITEMS_QUERY += ' LIMIT ' + queryLimit ;
        }

        return Database.query(PARSHEET_ITEMS_QUERY);
    }



    @AuraEnabled(Cacheable=true)
    public static Map<String, Object> getParItems(String ctx, Integer queryLimit,List<String> selectedCategories, 
                                                  String storeId, String recId)
    {
        setContext(ctx);

        Map<String, Object> parItemsData = new  Map<String, Object>();

        List <SBUX_B2B_PARSheetItem__c> eligibleParItems =  new List<SBUX_B2B_PARSheetItem__c>();

        Set <String> elligibleProdList = new Set<String>();

        if (selectedCategories != null && !selectedCategories.isEmpty())
        {  
            elligibleProdList = processSkuEligibility( storeId, selectedCategories,ctx);

            eligibleParItems =  fetchEligibleParSheetItems(storeId,elligibleProdList, queryLimit,recId);
        }
        
        parItemsData.put('parItemList', eligibleParItems);
        parItemsData.put('totalNumberOfRows', getTotalCountOfElibileItems(elligibleProdList,storeId));

        return parItemsData;
    }





    @AuraEnabled
    public static  Map<String, Object> generateParItems(String ctx, List<String> selectedCategories, 
                                                        String storeId, Integer queryLimit)
    {
        setContext(ctx);

        Map<String, Object> parItemsData = new  Map<String, Object>();

        Set <String> elligibleProdList = processSkuEligibility( storeId, selectedCategories,ctx);

        List <SBUX_B2B_PARSheetItem__c> eligibleParItems =  createEligibleParItems(elligibleProdList,selectedCategories, storeId, ctx, queryLimit);

        parItemsData.put('parItemList',eligibleParItems);
        parItemsData.put('totalNumberOfRows', getTotalCountOfElibileItems(elligibleProdList,storeId));

        return parItemsData;
    }


    private static Integer getTotalCountOfElibileItems(Set <String> elligibleProdList, String storeId)
    {
        Integer totalCount = 0;

        if (elligibleProdList.isEmpty())
        {
            totalCount = 0;
        }
        else
         {
            String query = 'SELECT count() FROM SBUX_B2B_PARSheetItem__c WHERE SBUX_B2B_ProductItem__c IN  :elligibleProdList AND SBUX_B2B_PARSheet__r.SBUX_B2B_Store__c = :storeId';

            totalCount =  Database.countQuery(query);
         }
        return totalCount;
    }


    private static Set<String> processSkuEligibility(String storeId,List<String> selectedCategories, String ctx)
    {
        setContext(ctx);

        String categoryIds =  '\'' + String.join(selectedCategories,',').replace(',', '\',' + '\'') + '\''; //add quote before and after each string

        categoryIds = categoryIds.trim().replaceAll('(\\s+)', ''); // Remove any  whitespace

        List<SBUX_B2B_StoreEntitlementRule__c> storeRules = SBUX_B2B_StorefrontUtil.fetchStoreRuleList(storeId);

        Set <String> elligibleProdList = new Set<String>();

        Set<String> productIds =  new Set<String>();

        if (storeRules != null && !storeRules.isEmpty())
        {
            List <String> storeRulesIdList = new List <String>();

            for (SBUX_B2B_StoreEntitlementRule__c storeRRule :storeRules)
            {
                storeRulesIdList.add(storeRRule.SBUX_B2B_CatalogRule__c);
            }

            List <ccrz__E_ProductCategory__c> prodCategoryList = findProdViaCategoryId(categoryIds);

            for (ccrz__E_ProductCategory__c  prodCat : prodCategoryList)
            {
                productIds.add(prodCat.ccrz__Product__c);
            }

            elligibleProdList = SBUX_B2B_StorefrontUtil.generateEligibleSKUList(storeRulesIdList,productIds,elligibleProdList,ccrz.ccAPIProduct.PRODUCTIDLIST,null); 
        }

        return elligibleProdList;
    }



    private static  List <SBUX_B2B_PARSheetItem__c> createEligibleParItems(Set <String> elligibleProdList,
                                                                            List<String> selectedCategories, 
                                                                           String storeId,String ctx, Integer queryLimit)
    {
        List<SBUX_B2B_PARSheetItem__c> eligibleParItemsList = new List<SBUX_B2B_PARSheetItem__c>();

        List <SBUX_B2B_PARSheetItem__c> newParItemsToInsert = new List<SBUX_B2B_PARSheetItem__c>();

        List <SBUX_B2B_PARSheetItem__c> existingParItems = fetchEligibleParSheetItems(storeId, null, null,null);

        SBUX_B2B_PARSheet__c  parSheet = retrieveAndUpdateParSheet(selectedCategories,storeId);

        if (elligibleProdList != null && !elligibleProdList.isEmpty())
        {
            for (String prodId : elligibleProdList)
            {
                SBUX_B2B_PARSheetItem__c parItem = new SBUX_B2B_PARSheetItem__c();
                parItem.SBUX_B2B_PARSheet__c = parSheet.Id;
                parItem.SBUX_B2B_ProductItem__c = prodId;
                parItem.SBUX_B2B_ExternalID__c = prodId + parSheet.Id;

                newParItemsToInsert.add(parItem);
            }
        }
        processItemsToInsertOrDelete(newParItemsToInsert,existingParItems);

        if ( elligibleProdList != null && !elligibleProdList.isEmpty())
        {
            eligibleParItemsList = fetchEligibleParSheetItems(storeId,elligibleProdList, queryLimit, null);
        }
    
       return eligibleParItemsList;
    }



    private static void processItemsToInsertOrDelete(List <SBUX_B2B_PARSheetItem__c> newParItemsToInsert,
                                                     List <SBUX_B2B_PARSheetItem__c> existingParItems)
    {
        if (!newParItemsToInsert.isEmpty())
        {
            List <SBUX_B2B_PARSheetItem__c> itemsToDelete = new List<SBUX_B2B_PARSheetItem__c>();

            List <SBUX_B2B_PARSheetItem__c> itemsToInsert = new List<SBUX_B2B_PARSheetItem__c>();

            if (existingParItems != null && !existingParItems.isEmpty())
            {
                Map<String, List<SBUX_B2B_PARSheetItem__c>> newParSheetItemListMap = Collection.of(newParItemsToInsert).groupByStrings('SBUX_B2B_ExternalID__c');
                Map<String, List<SBUX_B2B_PARSheetItem__c>> existingParItemMap = Collection.of(existingParItems).groupByStrings('SBUX_B2B_ExternalID__c');

                Integer existingListSize = existingParItems.size();

                for(Integer i = 0; i < existingListSize; i++)
                {
                    SBUX_B2B_PARSheetItem__c existingParSheetItem = existingParItems.get(i);
    
                    if (newParSheetItemListMap.containsKey(existingParSheetItem.SBUX_B2B_ExternalID__c ))
                    {
                        newParSheetItemListMap.remove(existingParSheetItem.SBUX_B2B_ExternalID__c);
                    }
                    else 
                    {
                        itemsToDelete.add(existingParSheetItem);
                    }
                }
                
                if (!itemsToDelete.isEmpty())
                {
                    delete itemsToDelete;
                }
                if (!newParSheetItemListMap.isEmpty())
                {
                    for  (String key : newParSheetItemListMap.keySet())
                    {
                        List<SBUX_B2B_PARSheetItem__c> itemsFromMap = (List<SBUX_B2B_PARSheetItem__c>)newParSheetItemListMap.get(key);
                        
                        itemsToInsert.addAll(itemsFromMap);
                    }
                    insert itemsToInsert;
                } 
            }
          }
          // We probably will never hit this condition because of the validation on the UI 
          if (newParItemsToInsert.isEmpty() && !existingParItems.isEmpty())
          {
              delete existingParItems;
          }
          if (existingParItems.isEmpty() && !newParItemsToInsert.isEmpty())
          {
              insert newParItemsToInsert;
          }
    }



    private static SBUX_B2B_PARSheet__c retrieveAndUpdateParSheet(List<String> selectedCategories, String storeId)
    {   
        String formatCategories =  null;

        if (selectedCategories != null && !selectedCategories.isEmpty())
        {
            formatCategories = String.join(selectedCategories,';');
            formatCategories = formatCategories.trim().replaceAll('(\\s+)', ''); // remove white space
        }
        List<SBUX_B2B_PARSheet__c> parSheetList =  getParSheetForStore(storeId); 
                                                                        
        if (parSheetList != null && !parSheetList.isEmpty())
        {
            SBUX_B2B_PARSheet__c parSheet =  parSheetList[0];
            parSheet.SBUX_B2B_Category__c = formatCategories;

            update parSheet;

            return parSheet;
        }  
        else 
        {
            SBUX_B2B_PARSheet__c newParSheet = new SBUX_B2B_PARSheet__c();
            newParSheet.SBUX_B2B_Store__c = storeId;
            newParSheet.SBUX_B2B_Category__c = formatCategories;

            insert newParSheet;

            return newParSheet;
        }                         
    }




    public static List<ccrz__E_ProductCategory__c> findProdViaCategoryId(String categoryIds)
    {
        String PROD_CATEGORY_QUERY = 'SELECT Id' +
                                    ',ccrz__Product__c' +
                                    ',ccrz__Product__r.ccrz__SKU__c' +
                                    ',ccrz__Category__r.Name' +
                                    ',ccrz__Category__c' +
                                    ',ccrz__EndDate__c' +
                                    ',ccrz__StartDate__c' +
                                    ' FROM ccrz__E_ProductCategory__c ' +
                                    ' WHERE ' +
                                    ' ((ccrz__StartDate__c <= TODAY  OR  ccrz__StartDate__c = NULL) AND (ccrz__EndDate__c >= TODAY  OR  ccrz__EndDate__c = NULL) )' +
                                    ' AND (ccrz__Product__r.ccrz__ProductStatus__c = \'Released\' OR ccrz__Product__r.ccrz__ProductStatus__c = \'Not Orderable\')' +
                                    ' AND ccrz__Category__r.ccrz__CategoryID__c IN (' + categoryIds + ') LIMIT 10000 ';

      return Database.query(PROD_CATEGORY_QUERY);
    }



    @TestVisible
    private static List<SBUX_B2B_PARSheetItem__c> fetchParSheetItemsWithIDs(List<String> itemIds)
    {
        return [SELECT ID,
                        SBUX_B2B_OrderQty__c,
                        SBUX_B2B_ParQty__c,
                        SBUX_B2B_OnHandQty__c,
                        SBUX_B2B_PARSheet__c,
                        SBUX_B2B_PARSheet__r.SBUX_B2B_Category__c,
                        SBUX_B2B_PARSheet__r.SBUX_B2B_Store__c,
                        SBUX_B2B_ProductItem__c,
                        SBUX_B2B_ProductItem__r.ccrz__SKU__c,
                        SBUX_B2B_ProductItem__r.ccrz__UnitOfMeasure__c,
                        SBUX_B2B_ProductItem__r.SBUX_B2B_PrimaryUOM__c,
                        SBUX_B2B_ProductItem__r.SBUX_B2B_UOMConv__c,
                        SBUX_B2B_ProductItem__r.Name
                    FROM 
                         SBUX_B2B_PARSheetItem__c 
                    WHERE
                          ID IN :itemIds ] ;
    }



    @AuraEnabled
	public static List<SBUX_B2B_PARSheetItem__c> resetParValues(String ctx,  List<String> selectedParItemIds)
    {
        List<SBUX_B2B_PARSheetItem__c> itemsToUpdate = new List<SBUX_B2B_PARSheetItem__c>();

        if (selectedParItemIds != null && !selectedParItemIds.isEmpty())
        {
            for ( SBUX_B2B_PARSheetItem__c partSheetItem : fetchParSheetItemsWithIDs(selectedParItemIds))
            {
                partSheetItem.SBUX_B2B_ParQty__c = null;
                partSheetItem.SBUX_B2B_OrderQty__c =  null;

                itemsToUpdate.add(partSheetItem);
            }
            update itemsToUpdate;
        }

        return itemsToUpdate;
    }







    @AuraEnabled
	public static List<SBUX_B2B_PARSheetItem__c> resetOnHandValues(String ctx,  List<String> selectedParItemIds )
    {
        List<SBUX_B2B_PARSheetItem__c> itemsToUpdate = new List<SBUX_B2B_PARSheetItem__c>();

        if (selectedParItemIds != null && !selectedParItemIds.isEmpty())
        {
            for ( SBUX_B2B_PARSheetItem__c partSheetItem : fetchParSheetItemsWithIDs(selectedParItemIds))
            {
                partSheetItem.SBUX_B2B_OnHandQty__c = null;
                partSheetItem.SBUX_B2B_OrderQty__c =  null;

                itemsToUpdate.add(partSheetItem);
            }
            update itemsToUpdate;
        }

        return itemsToUpdate;
    }


    @AuraEnabled
    public static List<SBUX_B2B_PARSheetItem__c> updateParSheetItems(String itemsFromUI )
    {
        List <SBUX_B2B_PARSheetItem__c> itemsToUpdate = new List<SBUX_B2B_PARSheetItem__c>();

        if ( itemsFromUI != null && String.isNotBlank(itemsFromUI))
        {
            Map<String,Object> itemsToBeUpdated = (Map<String,Object>) JSON.deserializeUntyped(itemsFromUI);

            Set<String> parItemIds = (Set<String>)itemsToBeUpdated.keySet();

            for (SBUX_B2B_PARSheetItem__c fetchedParSheetItem : fetchParSheetItemsWithIDs(new List<String>(parItemIds)))
            {   
                Object userUpdatedItemObject = (Object)itemsToBeUpdated.get(fetchedParSheetItem.Id);

                Map<String,Object> itemObjectMap = (Map<String,Object>)userUpdatedItemObject;

                if (ccrz.ccUtil.isKeyValued(itemObjectMap, 'SBUX_B2B_ParQty__c') )
                {
                    String parQty  = (String)itemObjectMap.get('SBUX_B2B_ParQty__c');
                    fetchedParSheetItem.SBUX_B2B_ParQty__c = parQty.isNumeric() ? Decimal.valueOf(parQty): null ;
                }
                if (ccrz.ccUtil.isKeyValued(itemObjectMap, 'SBUX_B2B_OnHandQty__c') )
                {
                    String onHandQty  = (String)itemObjectMap.get('SBUX_B2B_OnHandQty__c');
                    fetchedParSheetItem.SBUX_B2B_OnHandQty__c = onHandQty.isNumeric() ? Decimal.valueOf(onHandQty): null ;
                }

                fetchedParSheetItem.SBUX_B2B_OrderQty__c = evaluateOrderQuantity(fetchedParSheetItem);

                itemsToUpdate.add(fetchedParSheetItem);
            }
         }
         if (!itemsToUpdate.isEmpty())
         {
            update itemsToUpdate;
         }
        
        return itemsToUpdate;
    }


    private static Decimal evaluateOrderQuantity(SBUX_B2B_PARSheetItem__c parSheetItem)
    {
        Decimal orderQty = null;

        if (parSheetItem.SBUX_B2B_ParQty__c != null && parSheetItem.SBUX_B2B_OnHandQty__c != null)
        {
             orderQty = parSheetItem.SBUX_B2B_ParQty__c  - parSheetItem.SBUX_B2B_OnHandQty__c ;
             orderQty = (orderQty > 0) ? orderQty : 0;
        }
        
        return orderQty;
    }


    @AuraEnabled
	public static void deleteParItems( List<String> selectedParItemIds)
    {  
        if (!selectedParItemIds.isEmpty())
        {
          delete [SELECT ID FROM SBUX_B2B_PARSheetItem__c WHERE ID IN :(selectedParItemIds) LIMIT 10000];
        }
    }



    public static void setContext(String ctx) 
    {
        if (String.isNotBlank(ctx)) 
        {
            ccrz.cc_RemoteActionContext remoteContext = (ccrz.cc_RemoteActionContext) JSON.deserialize(ctx, ccrz.cc_RemoteActionContext.class);
            
            if(null == remoteContext.queryParams)
            {
				remoteContext.queryParams = new Map<String,String>();
			}
            try
            {
                if(String.isBlank(remoteContext.storefront))
                {
					remoteContext.storefront = ccrz.cc_util_Storefront.getStoreName();
				}
            }
            catch(Exception e)
            {
				//Ignore for now
			}

			ccrz.cc_CallContext.initRemoteContext(remoteContext);
		}
    }
    



    private static List<SBUX_B2B_PARSheet__c> getParSheetForStore(String storeId)
    {
        return [SELECT 
                ID,
                SBUX_B2B_Store__c,
                SBUX_B2B_Category__c
            FROM SBUX_B2B_PARSheet__c
            WHERE  
             SBUX_B2B_Store__c =:storeId LIMIT 1]; 
    }
    
   
}