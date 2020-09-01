public with sharing class SBUX_B2B_CatalogEntitlementRuleHandler 
    {
        public static Map<String, Object> processCatalogRules(List<SBUX_B2B_CatalogEntitlementRule__c> newCatalogRules,
                                               Map<Id, SBUX_B2B_CatalogEntitlementRule__c> oldMap,
                                               Map<Id, SBUX_B2B_CatalogEntitlementRule__c> newMap,
                                               boolean isUpdate)
        {     
            Map<String, Object> retData = new Map<String, Object>();

            Map<String, Object> aggregatedFilterMap = new Map<String, Object>();
    
            Map<String, Object> catalogRuleFilterMap = new Map<String, Object>();
            
            List <String> storeRulesToCheck = new List <String> ();

            for ( SBUX_B2B_CatalogEntitlementRule__c catalogRule : newCatalogRules )
            {
                storeRulesToCheck.add(catalogRule.Id); 

                evaluateFilterForStoreSearch(catalogRule,catalogRuleFilterMap,aggregatedFilterMap);
                
                if (isUpdate)
                {
                    SBUX_B2B_CatalogEntitlementRule__c oldRule = oldMap.get(catalogRule.Id); // Specific to record updates
                    SBUX_B2B_CatalogEntitlementRule__c newRule = newMap.get(catalogRule.Id); // Specific to record updates
                    addChangedValueToMap(oldRule,newRule,catalogRuleFilterMap); // Specific to record updates
                }
            }
            Map<String, Object> localProductStoresMap = prepareLocalProductData(aggregatedFilterMap);
            Map<String, Object> programStoresMap =    prepareProgramTypeData(aggregatedFilterMap);
    
            Map<String, Object> resultsMap = queryForStores(catalogRuleFilterMap,aggregatedFilterMap,localProductStoresMap,programStoresMap);
    
            List <SBUX_B2B_StoreEntitlementRule__c> storeEntitlementRules = new List <SBUX_B2B_StoreEntitlementRule__c> ();
    
            String storeQueryString = (String)resultsMap.remove('STORE_QUERY');
            
            for (Store__c store  : Database.query(storeQueryString))
            {
                for (String calatogRuleKey : catalogRuleFilterMap.keySet())
                {
                    Object storeFilterValuesObject = catalogRuleFilterMap.get(calatogRuleKey);
    
                    Map <String,Object> storeFilterValues = (Map <String,Object>)storeFilterValuesObject;

                    if (matchRuleToStore(storeFilterValues,store,localProductStoresMap,programStoresMap))
                    {
                        populateStoreRuleRecords(store.ID,calatogRuleKey,storeEntitlementRules);
                    }
                }
            }
            addProdRulesToMap(catalogRuleFilterMap,isUpdate,aggregatedFilterMap,retData);
            addEligbleStoreRulesToMap(storeEntitlementRules,storeRulesToCheck,retData);

            return retData;
        }
    
        
         /**
         * This method populates the Product rule records while ensuring that any stale/existing records
         * that no longer match the selected or entered SKU/Category  criteria will be deleted.
         * It also ensures we are not deleting any existing prod rule records should they be valid still 
         */
       private static void addProdRulesToMap( Map<String, Object> catalogRuleFilterMap,boolean isUpdate,
                                              Map<String, Object> aggregatedFilterMap,Map<String, Object> retData)
       {
            List <SBUX_B2B_ProductEntitlementRule__c> prodEntitlementRules = new List <SBUX_B2B_ProductEntitlementRule__c> ();
    
            List <String> prodRulesToCheck = new List <String> (); 
    
            Map<String, Object> prodCategoryData = findProdViaCategory(aggregatedFilterMap);  
    
            Map<String, Object> prodSkuMap = findProdWithSKU(aggregatedFilterMap);
    
            for (String calatogRuleKey : catalogRuleFilterMap.keySet())
            {
                Object storeFilterValuesObject = catalogRuleFilterMap.get(calatogRuleKey);
    
                Map <String,Object> storeFilterValues = (Map <String,Object>)storeFilterValuesObject;
    
                if ( !isUpdate || (isUpdate && storeFilterValues.containsKey('CheckProducts'))) 
                {
                    populateProdRuleRecords(calatogRuleKey,prodEntitlementRules,storeFilterValues,prodCategoryData,prodSkuMap);
                    
                    prodRulesToCheck.add(calatogRuleKey); 
                }
            }
            processProdRuleItems(prodEntitlementRules,prodRulesToCheck,retData); 
       }
    

    
        
        


        /**
         * This method adds the eligible store rule records that will be inserted and/or deleted to a map 
         */
        private static void addEligbleStoreRulesToMap(List <SBUX_B2B_StoreEntitlementRule__c> storeEntitlementRules,
                                                      List <String> storeRulesToCheck,
                                                      Map<String, Object> retData)
        {
             List <SBUX_B2B_StoreEntitlementRule__c> existingStoreRules = new List <SBUX_B2B_StoreEntitlementRule__c> (fetchExistingStoreRules(storeRulesToCheck));

             List <SBUX_B2B_StoreEntitlementRule__c> itemsToDelete = new List<SBUX_B2B_StoreEntitlementRule__c>();
    
             List <SBUX_B2B_StoreEntitlementRule__c> itemsToInsert = new List<SBUX_B2B_StoreEntitlementRule__c>(); 

             if (existingStoreRules != null && !existingStoreRules.isEmpty() && !storeEntitlementRules.isEmpty()) 
             {
                 Integer existingListSize = existingStoreRules.size();
             
                 Map<String, List<SBUX_B2B_StoreEntitlementRule__c>> newStoreEntRulesListMap = Collection.of(storeEntitlementRules).groupByStrings('SBUX_B2B_CatalogRuleExternalID__c');
             
                 //Loop over existing store rules to determine which net new ones to add and those to delete
                 for(Integer i = 0; i < existingListSize; i++)
                 {
                    SBUX_B2B_StoreEntitlementRule__c existingStoreRule = existingStoreRules.get(i);
     
                     if (newStoreEntRulesListMap.containsKey(existingStoreRule.SBUX_B2B_CatalogRuleExternalID__c) )
                     {
                        newStoreEntRulesListMap.remove(existingStoreRule.SBUX_B2B_CatalogRuleExternalID__c);
                     }
                     else 
                     {
                         itemsToDelete.add(existingStoreRule);
                     }
                 }
                 if (!newStoreEntRulesListMap.isEmpty())
                 {
                     for  (String key : newStoreEntRulesListMap.keySet())
                     {
                         List<SBUX_B2B_StoreEntitlementRule__c> itemsFromMap = (List<SBUX_B2B_StoreEntitlementRule__c>)newStoreEntRulesListMap.get(key);
                         
                         itemsToInsert.addAll(itemsFromMap);
                     }
                 } 
             }
             if (storeEntitlementRules.isEmpty() && existingStoreRules != null && !existingStoreRules.isEmpty())
             {
                 itemsToDelete.addAll(existingStoreRules);
             }
             if ((existingStoreRules == null || existingStoreRules.isEmpty()) && !storeEntitlementRules.isEmpty())
             {
                 itemsToInsert.addAll(storeEntitlementRules);
             }

              retData.put('storeRulesToDelete', itemsToDelete);
              retData.put('storeRulesToInsert', itemsToInsert); 
        }
    




        //TODO - Evaluate checking the size of  this list against a threshold and have a batch job handle it
        // This might not be necessary as the number of entries will not exceed the acceptable limit of 10000
        public static void deleteInsertStoreRules(Map<String, Object> retData)
        {
            List <SBUX_B2B_StoreEntitlementRule__c> storeRulesToDelete = new List <SBUX_B2B_StoreEntitlementRule__c>();
            List <SBUX_B2B_StoreEntitlementRule__c> storeRulesToInsert = new List <SBUX_B2B_StoreEntitlementRule__c>();

            if (retData != null && !retData.isEmpty())
            {
               if (ccrz.ccUtil.isKeyValued(retData, 'storeRulesToDelete'))
               {
                   storeRulesToDelete =  (List <SBUX_B2B_StoreEntitlementRule__c>)retData.get('storeRulesToDelete');

                   if (!storeRulesToDelete.isEmpty())
                   {
                     delete storeRulesToDelete;
                   }
               }
               if (ccrz.ccUtil.isKeyValued(retData, 'storeRulesToInsert'))
               {
                    storeRulesToInsert =  (List <SBUX_B2B_StoreEntitlementRule__c>)retData.get('storeRulesToInsert');

                    if (!storeRulesToInsert.isEmpty())
                    {
                        insert storeRulesToInsert;
                    }
               }
            }
        }
         



    

        public static void deleteInsertProdRules(Map<String, Object> retData)
        {
            if (retData != null && !retData.isEmpty())
            {
                if (ccrz.ccUtil.isKeyValued(retData, 'prodRulesToDelete'))
                {
                    List <SBUX_B2B_ProductEntitlementRule__c> prodRulesToDelete =  (List <SBUX_B2B_ProductEntitlementRule__c>)retData.get('prodRulesToDelete');

                    if (prodRulesToDelete != null && !prodRulesToDelete.isEmpty())
                    {
                        delete prodRulesToDelete;
                    }
                }
                if (ccrz.ccUtil.isKeyValued(retData, 'prodRulesToInsert'))
                {
                    List <SBUX_B2B_ProductEntitlementRule__c> prodRulesToInsert =  (List <SBUX_B2B_ProductEntitlementRule__c>)retData.get('prodRulesToInsert');

                    if (prodRulesToInsert != null && !prodRulesToInsert.isEmpty())
                    {
                        insert prodRulesToInsert;
                    }
                }
            }
        }

    
       



       /**
        * This method helps ensures the update path for rule modification accounts for cases where the updated SKU/Category on the form 
        * did not necessitate the deletion of existing prod rule records and hence those will need to be left untouched and not deleted 
        * nor attempted to be re-inserted 
        */
        private static void processProdRuleItems(List <SBUX_B2B_ProductEntitlementRule__c> prodEntitlementRules,
                                                 List <String> prodRulesToCheck,
                                                 Map<String, Object> retData)
        {     

            List <SBUX_B2B_ProductEntitlementRule__c> existingProdEntitlementRules = fetchExistingProdRule(prodRulesToCheck); 

            List <SBUX_B2B_ProductEntitlementRule__c> itemsToDelete = new List<SBUX_B2B_ProductEntitlementRule__c>();
    
            List <SBUX_B2B_ProductEntitlementRule__c> itemsToInsert = new List<SBUX_B2B_ProductEntitlementRule__c>(); 

            if (!prodEntitlementRules.isEmpty() && existingProdEntitlementRules != null && !existingProdEntitlementRules.isEmpty()) 
            {
                Integer existingListSize = existingProdEntitlementRules.size();
            
                Map<String, List<SBUX_B2B_ProductEntitlementRule__c>> newProdEntRulesListMap = Collection.of(prodEntitlementRules).groupByStrings('SBUX_B2B_ProductRuleExternalID__c');
    
                //Loop over existing prod rules to determine which net new ones to add and those to delete
                for(Integer i = 0; i < existingListSize; i++)
                {
                    SBUX_B2B_ProductEntitlementRule__c existingProdRule = existingProdEntitlementRules.get(i);
    
                    if (newProdEntRulesListMap.containsKey(existingProdRule.SBUX_B2B_ProductRuleExternalID__c) )
                    {
                        newProdEntRulesListMap.remove(existingProdRule.SBUX_B2B_ProductRuleExternalID__c);
                    }
                    else 
                    {
                        itemsToDelete.add(existingProdRule);
                    }
                }
                if (!newProdEntRulesListMap.isEmpty())
                {
                    for  (String key : newProdEntRulesListMap.keySet())
                    {
                        List<SBUX_B2B_ProductEntitlementRule__c> itemsFromMap = (List<SBUX_B2B_ProductEntitlementRule__c>)newProdEntRulesListMap.get(key);
                        
                        itemsToInsert.addAll(itemsFromMap);
                    }
                } 
            }
            if (prodEntitlementRules.isEmpty() && existingProdEntitlementRules != null && !existingProdEntitlementRules.isEmpty())
            {
                itemsToDelete.addAll(existingProdEntitlementRules);
            }
            if ((existingProdEntitlementRules == null || existingProdEntitlementRules.isEmpty()) && !prodEntitlementRules.isEmpty())
            {
                itemsToInsert.addAll(prodEntitlementRules);
            }

            retData.put('prodRulesToInsert',itemsToInsert);
            retData.put('prodRulesToDelete',itemsToDelete);
        }                                                                   
    
    
    

    
        private static List<SBUX_B2B_ProductEntitlementRule__c> fetchExistingProdRule(List<String> ruleIds)
        {
            List<SBUX_B2B_ProductEntitlementRule__c> prodRulesToCheck = null;

            if (!ruleIDs.isEmpty())
            {
                prodRulesToCheck =  new List<SBUX_B2B_ProductEntitlementRule__c>([SELECT ID,SBUX_B2B_ProductRuleExternalID__c FROM SBUX_B2B_ProductEntitlementRule__c WHERE SBUX_B2B_CatalogRule__c IN :(ruleIds)]);
            }

            return prodRulesToCheck;
        }
    
    

        


        private static List<SBUX_B2B_StoreEntitlementRule__c> fetchExistingStoreRules(List <String> ruleIDs)
        {
            List<SBUX_B2B_StoreEntitlementRule__c> storeRulesToCheck = null;

            if (!ruleIDs.isEmpty())
            {
                storeRulesToCheck =  new List<SBUX_B2B_StoreEntitlementRule__c>([SELECT ID,SBUX_B2B_CatalogRuleExternalID__c FROM SBUX_B2B_StoreEntitlementRule__c WHERE SBUX_B2B_CatalogRule__c IN :(ruleIDs)]);
            }

            return storeRulesToCheck;
        }
    


        private static void addChangedValueToMap(SBUX_B2B_CatalogEntitlementRule__c oldRule,
                                                 SBUX_B2B_CatalogEntitlementRule__c newRule,
                                                 Map<String,Object> catalogRuleFilterMap)
        {
            if (!catalogRuleFilterMap.isEmpty())
            {
                Map<String,Object> ruleChangeMap = (Map<String,Object>)catalogRuleFilterMap.get(newRule.Id);
    
                isRuleStringAttributeChanged(oldRule,newRule,ruleChangeMap,'SBUX_B2B_StoreNumber__c');
                isRuleStringAttributeChanged(oldRule,newRule,ruleChangeMap,'SBUX_B2B_LicenseeAccount__c');
                isRuleStringAttributeChanged(oldRule,newRule,ruleChangeMap,'SBUX_B2B_State__c');
                isRuleStringAttributeChanged(oldRule,newRule,ruleChangeMap,'SBUX_B2B_EngineType__c');
                isRuleStringAttributeChanged(oldRule,newRule,ruleChangeMap,'SBUX_B2B_LocalProduct__c');
                isRuleStringAttributeChanged(oldRule,newRule,ruleChangeMap,'SBUX_B2B_ProgramType__c');
                isRuleStringAttributeChanged(oldRule,newRule,ruleChangeMap,'SBUX_B2B_City__c');
                isRuleStringAttributeChanged(oldRule,newRule,ruleChangeMap,'SBUX_B2B_Country__c');
                isRuleStringAttributeChanged(oldRule,newRule,ruleChangeMap,'SBUX_B2B_SkuList__c');
                isRuleStringAttributeChanged(oldRule,newRule,ruleChangeMap,'SBUX_B2B_ProductCategory__c');
    
                determineLevelOfChange(ruleChangeMap );
            }
        }
        
        
    


        private static void isRuleStringAttributeChanged(SBUX_B2B_CatalogEntitlementRule__c oldRule,
                                                         SBUX_B2B_CatalogEntitlementRule__c newRule,
                                                         Map<String,Object> ruleChangeMap,
                                                         String currentField)
        {
            String oldValue  = (String)oldRule.get(currentField);
            String newValue = (String)newRule.get(currentField);
    
            if ((oldValue != null && newValue == null)
                || (newValue != null && oldValue == null)
                || (oldValue != null & newValue != null && !oldValue.equalsIgnoreCase(newValue) ))
            {
                ruleChangeMap.put('Change' + currentField ,true);
            }
        }
        



        private static void determineLevelOfChange(Map<String,Object> ruleChangeMap )
        {
            if (ruleChangeMap.containsKey('ChangeSBUX_B2B_SkuList__c') 
                || ruleChangeMap.containsKey('ChangeSBUX_B2B_ProductCategory__c'))
            {
                ruleChangeMap.put('CheckProducts', true);
            }
        }
    
    
    
    


        private static void populateStoreRuleRecords(ID storeId, String calatogRuleId,
                                                     List <SBUX_B2B_StoreEntitlementRule__c> storeEntitlementRules)
        {
             SBUX_B2B_StoreEntitlementRule__c storeEntRule = new SBUX_B2B_StoreEntitlementRule__c();
             storeEntRule.SBUX_B2B_CatalogRule__c = calatogRuleId;
             storeEntRule.SBUX_B2B_Store__c = storeId;
             storeEntRule.SBUX_B2B_CatalogRuleExternalID__c = 'STORENTL' + calatogRuleId + storeId;
    
             storeEntitlementRules.add(storeEntRule);
        } 
    
    
    
    

        private static  Set <String> populateProdRuleRecords(String calatogRuleId,
                                                    List <SBUX_B2B_ProductEntitlementRule__c> prodEntitlementRules,
                                                    Map <String,Object> storeFilterValues,
                                                    Map<String, Object> prodCategoryData,
                                                    Map<String, Object> prodSkuMap)
        {
            Set<String> productSKUs =  new Set<String>();
    
            if(storeFilterValues.containsKey('SBUX_B2B_SkuList__c'))
            {
               String itemSkusWithCommas = (String)storeFilterValues.get('SBUX_B2B_SkuList__c') ;
               
                itemSkusWithCommas = itemSkusWithCommas.trim().replaceAll('(\\s+)', '');
    
                List<String> itemSkUs = itemSkusWithCommas.split(',');
    
                for (String sku :itemSkUs)
                {
                    if (prodSkuMap.containsKey(sku))
                    {
                        productSKUs.add(sku);
                    }
                }
            }  
    
            if (storeFilterValues.containsKey('SBUX_B2B_ProductCategory__c'))
            {
               Map<String, List<ccrz__E_Category__c>> categoryMap = (Map<String, List<ccrz__E_Category__c>>)prodCategoryData.get('CATEGORYMAP');
               Map<String, List<ccrz__E_ProductCategory__c>> prodCategoryByCatId = (Map<String, List<ccrz__E_ProductCategory__c>>)prodCategoryData.get('PROD_CATEGORY');
    
               String categoryIdWithCommas = (String)storeFilterValues.get('SBUX_B2B_ProductCategory__c') ;
    
                List<String> categoryIdList = categoryIdWithCommas.split(',');
         
                for (String categoryId :  categoryIdList)
                   {
                     if (categoryMap != null && !categoryMap.isEmpty() && ccrz.ccUtil.isKeyValued(categoryMap, categoryId))
                     {
                        List<ccrz__E_Category__c> categoryList = (List<ccrz__E_Category__c>)categoryMap.get(categoryId);

                        if (prodCategoryByCatId != null && !prodCategoryByCatId.isEmpty() 
                            && ccrz.ccUtil.isKeyValued(prodCategoryByCatId, categoryList[0].Id))
                        {
                            List<ccrz__E_ProductCategory__c> prodCategoryList =  (List<ccrz__E_ProductCategory__c>)prodCategoryByCatId.get(categoryList[0].Id);

                            if (prodCategoryList != null && !prodCategoryList.isEmpty())
                            {
                                for (ccrz__E_ProductCategory__c  prodCat : prodCategoryList)
                                {
                                    productSKUs.add(prodCat.ccrz__Product__r.ccrz__SKU__c);
                                }
                            } 
                        }
                     }  
                }
            } 
    
            if (!productSKUs.isEmpty())
            {
                for (String itemSku :productSKUs)
                {
                   SBUX_B2B_ProductEntitlementRule__c prodEntRule = new SBUX_B2B_ProductEntitlementRule__c(SBUX_B2B_ProductItem__r = new ccrz__E_Product__c(ccrz__SKU__c =itemSku));
                   prodEntRule.SBUX_B2B_CatalogRule__c = calatogRuleId;
                   prodEntRule.SBUX_B2B_ProductRuleExternalID__c = 'PRODENTL' + calatogRuleId + itemSku;
                   prodEntRule.SBUX_B2B_StartDate__c = validateInputDateObject(storeFilterValues.get('SBUX_B2B_StartDate__c')); 
                   prodEntRule.SBUX_B2B_EndDate__c = validateInputDateObject(storeFilterValues.get('SBUX_B2B_EndDate__c'));
    
                   prodEntitlementRules.add(prodEntRule);
                }
            } 
            return productSKUs;
        }
    
    
    
    
        private static Date validateInputDateObject(Object dateObject)
        {
            Date dateValue = null;
    
            if (dateObject != null)
            {
                dateValue = date.parse((String)dateObject);
            }
            return dateValue;
        }
    
    
    

        private static boolean matchRuleToStore(Map <String,Object> storeFilterValues, Store__c store, 
                                                Map <String,Object> localProductStoresMap,
                                                Map <String,Object> programStoresMap)
        {
            List <String> storeNumberMatchList = new List<String>();
            
            evaluateStoreMatchingCriteria(storeNumberMatchList,storeFilterValues,'Store_Number__c', store.Store_Number__c, true);
    
            List <String> otherCriteriaMatchList = new List<String>();
    
            evaluateStoreMatchingCriteria(otherCriteriaMatchList,storeFilterValues,'State__c', store.State__c,true);
            evaluateStoreMatchingCriteria(otherCriteriaMatchList,storeFilterValues,'City__c', store.City__c,true);
            evaluateStoreMatchingCriteria(otherCriteriaMatchList,storeFilterValues,'Country__c', store.Country__c,true);
            evaluateStoreMatchingCriteria(otherCriteriaMatchList,storeFilterValues,'Engine_Type__c', store.Engine_Type__c,false);
            evaluateStoreMatchingCriteria(otherCriteriaMatchList,storeFilterValues,'Licensee__c', store.Licensee__c,true);
            evaluateStoreMatchingCriteria(otherCriteriaMatchList,storeFilterValues,'SBUX_B2B_LocalProduct__c', getLocalProductForCurrentStore(localProductStoresMap,store),false);
            evaluateStoreMatchingCriteria(otherCriteriaMatchList,storeFilterValues,'SBUX_B2B_ProgramType__c', getProgramForCurrentStore(programStoresMap,store),false);
    
            boolean storeNumberMatch = false;
    
            if (!storeNumberMatchList.isEmpty() && storeNumberMatchList[0] == 'Y')
            {
                storeNumberMatch =  true;
            }
            boolean otherCriteriaMatch = false;
    
            if (otherCriteriaMatchList.isEmpty())
            {
                otherCriteriaMatch =  false;
            }
            else 
            {
                if (otherCriteriaMatchList.contains('N'))
                {
                    otherCriteriaMatch =  false;
                }
                else 
                {
                    otherCriteriaMatch =  true;
                 }
            }
            return storeNumberMatch || otherCriteriaMatch;
        }
        
        
    
        private static void evaluateStoreMatchingCriteria(List <String> criteriaMatchList, Map <String,Object> storeFilterValues,
                                                             String currentKey, String currentValue, boolean removeWhiteSpace)
        {
            if (storeFilterValues.containsKey(currentKey))
            {
                boolean foundValue = false;
    
                String valueFromRule = (String)storeFilterValues.get(currentKey);
    
                List<String> values = valueFromRule.split(',');
    
                for (String value :values)
                {
                    if (removeWhiteSpace)
                    {
                        value = value.trim().replaceAll('(\\s+)', '');
                    }
                    if (value.equalsIgnoreCase(currentValue))
                    {
                        foundValue = true;
    
                        break;
                    }
                }
                if (foundValue)
                {
                    criteriaMatchList.add('Y');
                }
                else 
                {
                    criteriaMatchList.add('N');
                }
            }
        }
    
    
    
    
    
        private static String getLocalProductForCurrentStore(Map <String,Object> localProductStoresMap, Store__c store)
        {
            String value = '';
    
            if (!localProductStoresMap.isEmpty())
            {
                Map<String, List<Store_Attribute__c>>  storeLocalProdMap = (Map<String, List<Store_Attribute__c>>)localProductStoresMap.get('STORE_LOCAL_PRODUCT');
    
                List<Store_Attribute__c> storeAttributeList = (List<Store_Attribute__c>)storeLocalProdMap.get(store.Id);
    
                if (storeAttributeList != null && !storeAttributeList.isEmpty())
                {
                     value = storeAttributeList[0].Local_Product__c;
                }  
            }
    
            return value;
        }
    
    


        private static String getProgramForCurrentStore(Map <String,Object> programStoresMap, Store__c store)
        {
            String value = '';
    
            if (!programStoresMap.isEmpty())
            {
                Map<String, List<Store_Program__c>>  storeProgramMap = (Map<String, List<Store_Program__c>>)programStoresMap.get('STORE_PROGRAM');
    
                List<Store_Program__c> storeProgramList = (List<Store_Program__c>)storeProgramMap.get(store.Store_Account__c);
    
                 if (storeProgramList != null && !storeProgramList.isEmpty())
                {
                    value = storeProgramList[0].Program_Type__c;
                }
            }
            return value;
        }
    
        
    
    
    
            private static void evaluateFilterForStoreSearch(SBUX_B2B_CatalogEntitlementRule__c catalogRule, 
                                                                Map<String, Object> catalogRuleFilterMap,
                                                                Map<String, Object> aggregatedFilterMap)
            {
                Map <String,Object> currentCatalogRuleData =  new Map<String,Object>();
    
                addValueToMap(currentCatalogRuleData,aggregatedFilterMap, 'City__c', catalogRule.SBUX_B2B_City__c);
                addValueToMap(currentCatalogRuleData,aggregatedFilterMap, 'Country__c', catalogRule.SBUX_B2B_Country__c);
                addValueToMap(currentCatalogRuleData,aggregatedFilterMap, 'Engine_Type__c', catalogRule.SBUX_B2B_EngineType__c);
                addValueToMap(currentCatalogRuleData,aggregatedFilterMap, 'Licensee__c', catalogRule.SBUX_B2B_LicenseeAccount__c);
                addValueToMap(currentCatalogRuleData,aggregatedFilterMap, 'SBUX_B2B_ProgramType__c', catalogRule.SBUX_B2B_ProgramType__c);
                addValueToMap(currentCatalogRuleData,aggregatedFilterMap, 'SBUX_B2B_LocalProduct__c', catalogRule.SBUX_B2B_LocalProduct__c);
                addValueToMap(currentCatalogRuleData,aggregatedFilterMap, 'Store_Number__c', catalogRule.SBUX_B2B_StoreNumber__c);
                addValueToMap(currentCatalogRuleData,aggregatedFilterMap, 'SBUX_B2B_SkuList__c', catalogRule.SBUX_B2B_SkuList__c);
                addValueToMap(currentCatalogRuleData,aggregatedFilterMap, 'SBUX_B2B_StartDate__c', validateInputDate(catalogRule.SBUX_B2B_StartDate__c));
                addValueToMap(currentCatalogRuleData,aggregatedFilterMap, 'SBUX_B2B_EndDate__c', validateInputDate(catalogRule.SBUX_B2B_EndDate__c));
    
                if (String.isNotBlank(catalogRule.SBUX_B2B_ProductCategory__c))
                {
                    list<String> categoryIdList =  catalogRule.SBUX_B2B_ProductCategory__c.split(';');
                    addValueToMap(currentCatalogRuleData,aggregatedFilterMap, 'SBUX_B2B_ProductCategory__c',   String.join(categoryIdList, ',')   );
                }
                if (String.isNotBlank(catalogRule.SBUX_B2B_State__c))
                {
                    list<String> stateList =  catalogRule.SBUX_B2B_State__c.split(';');
                    addValueToMap(currentCatalogRuleData,aggregatedFilterMap, 'State__c',   String.join(stateList, ',')   );
                }
                catalogRuleFilterMap.put(catalogRule.Id, currentCatalogRuleData);  
        }
    
          


            private static String validateInputDate(Date dateValue)
            {
                String dateString = null;
    
                if (dateValue != null)
                {
                    dateString = dateValue.format();
                }
                return dateString;
            }
    
    
    
    
        private static Map<String, Object>  queryForStores( Map<String, Object> catalogRuleFilterMap,
                                              Map<String, Object> aggregatedFilterMap,
                                              Map<String, Object> localProdStores,
                                              Map<String, Object> programTypeStores)
        {
            Map<String, Object> resultsMap = new Map<String, Object> ();
    
            List <String> filterCriteria = new List <String>();
    
             Map<String, String> filterMap = new Map<String, String> ();
    
            String STORE_SEARCH_QUERY = 'SELECT Id' +
                                        ',City__c' +
                                        ',State__c' +
                                        ',Country__c' +
                                        ',Engine_Type__c' +
                                        ',Store_Number__c' +
                                        ',Store_Account__c' +
                                        ',Licensee__c' +
                                        ' FROM Store__c ' +
                                        ' WHERE ( Status__c NOT IN (\'Dead\', \'Closed\') AND Store_Number__c != null ';
        
            if (aggregatedFilterMap.containsKey('City__c'))
            {
                String city = prepareValueForUseInQueryFilter('City__c',aggregatedFilterMap, true);
                filterMap.put('City__c', '  City__c IN  (' + city + ')');
            }
            if (aggregatedFilterMap.containsKey('State__c'))
            {
                String state = prepareValueForUseInQueryFilter('State__c',aggregatedFilterMap, true);
                filterMap.put('State__c', '  State__c IN  (' + state + ')');
            }
            if (aggregatedFilterMap.containsKey('Country__c'))
            {
                String country = prepareValueForUseInQueryFilter('Country__c',aggregatedFilterMap,true);
                filterMap.put('Country__c', '  Country__c IN  (' + country + ')');
            }
            if (aggregatedFilterMap.containsKey('Engine_Type__c'))
            {
                String engineType = prepareValueForUseInQueryFilter('Engine_Type__c',aggregatedFilterMap, false);
                filterMap.put('Engine_Type__c', '  Engine_Type__c IN  (' + engineType + ')');
            }
            if (aggregatedFilterMap.containsKey('Store_Number__c'))
            {
                String storeNumber = prepareValueForUseInQueryFilter('Store_Number__c',aggregatedFilterMap, true);
                filterMap.put('Store_Number__c', '  Store_Number__c IN  (' + storeNumber + ')');
            }
            if (aggregatedFilterMap.containsKey('Licensee__c'))
            {
                 String licensee = prepareValueForUseInQueryFilter('Licensee__c',aggregatedFilterMap, true);
                 filterMap.put('Licensee__c', '  Licensee__c IN  (' + licensee + ')');
            }
            if (programTypeStores.containsKey('STORE_ACCOUNT'))
            {
                String storeAccountList = getFormattedData(programTypeStores,'STORE_ACCOUNT', false);
    
                filterMap.put('PROG_STORE_ACCOUNT', ' Store_Account__c IN  (' + storeAccountList + ')');
            }
            if (localProdStores.containsKey('STORE_ID'))
            {
                String storeIDs = getFormattedData(localProdStores,'STORE_ID', false);
                filterMap.put('LOCAL_PROD_STORE_ID', '  ID IN  (' + storeIDs + ')');
            }
    
            if (!filterMap.isEmpty())
            {
              STORE_SEARCH_QUERY = buildQueryWithFilter(filterMap,STORE_SEARCH_QUERY);
            } 
            else
             {
                // fallback to allow for deletion of stale  store and prod rules data
                STORE_SEARCH_QUERY += ' ) LIMIT 1 ';
            }
    
            resultsMap.put('STORE_QUERY', STORE_SEARCH_QUERY);
            return resultsMap;
         }
    
    
         private static String buildQueryWithFilter(Map<String,String> filterMap, String storeQuery)
         {
            if (filterMap.size() == 1)
            {
                List <String> filterValues =  (List <String>)filterMap.values();
    
                storeQuery += ' AND ' + filterValues[0] + ' )';
            }
            else 
            {
                if (filterMap.containsKey('Store_Number__c'))
                {
                    String storeNumberFilter = (String)filterMap.remove('Store_Number__c');
    
                    for (String filterData :filterMap.values())
                    {
                        storeQuery += ' AND ' + filterData  ;
                    }
                     storeQuery += ' ) OR ' + storeNumberFilter;
                }
                else 
                {
                    for (String filterData :filterMap.values())
                    {
                        storeQuery += ' AND ' + filterData ;
                    }
                    storeQuery += ' )' ;
                }
            }
            return storeQuery;
         }
    
    
    
         private static  Map<String, Object> prepareProgramTypeData( Map<String, Object> aggregatedFilterMap)
         {
            Map<String, Object>  resultsMap = new Map<String, Object>();
    
            if (aggregatedFilterMap.containsKey('SBUX_B2B_ProgramType__c'))
            {
               String programType =  prepareValueForUseInQueryFilter('SBUX_B2B_ProgramType__c',aggregatedFilterMap ,false);
            
               String PROG_TYPE_QUERY =     'SELECT Id' +
                                            ',Program_Type__c' +
                                            ',End_Date__c' +
                                            ',Start_Date__c' +
                                            ',Store_Account__c' +
                                            ' FROM Store_Program__c ' +
                                            ' WHERE ' +
                                            '((Start_Date__c <= TODAY  OR  Start_Date__c = NULL) AND (End_Date__c >= TODAY  OR  End_Date__c = NULL) )' +
                                            ' AND Program_Type__c IN (' + programType + ') LIMIT 5000 ';
    
                List <Store_Program__c> programList = Database.query(PROG_TYPE_QUERY);
    
                if (!programList.isEmpty())
                {
                    Map<String, List<Store_Program__c>> storeProgramMap = Collection.of(programList).groupByStrings('Store_Account__c');
    
                    List<String> storeAccountList = Collection.of(programList).pluckStrings(Store_Program__c.Store_Account__c);
    
                    resultsMap.put('STORE_ACCOUNT', storeAccountList);
                    resultsMap.put('STORE_PROGRAM',storeProgramMap);
                }                             
            }
            return resultsMap;
         }
    
         
        
         private static Map<String, Object>  prepareLocalProductData( Map<String, Object> aggregatedFilterMap)
         {
            Map<String, Object>  resultsMap = new Map<String, Object>();
    
            if (aggregatedFilterMap.containsKey('SBUX_B2B_LocalProduct__c'))
            {
                 String localProduct =  prepareValueForUseInQueryFilter('SBUX_B2B_LocalProduct__c',aggregatedFilterMap, false);
    
                 String LOCAL_PROD_QUERY =  'SELECT Id' +
                                            ',Store__c' +
                                            ',Local_Product__c' +
                                            ' FROM Store_Attribute__c ' +
                                            ' WHERE  RecordType.DeveloperName = \'Autoship\' ' +
                                            ' AND Local_Product__c IN (' + localProduct + ') LIMIT 5000 ';
    
                List <Store_Attribute__c> storeAttributeList = Database.query(LOCAL_PROD_QUERY);
    
                if (!storeAttributeList.isEmpty())
                {
                    Map<String, List<Store_Attribute__c>> storeAttributeLocalProdMap = Collection.of(storeAttributeList).groupByStrings('Store__c');
    
                    List<String> storeIDs = Collection.of(storeAttributeList).pluckStrings(Store_Attribute__c.Store__c);
    
                    resultsMap.put('STORE_ID', storeIDs);
                    resultsMap.put('STORE_LOCAL_PRODUCT',storeAttributeLocalProdMap);
                }                             
            }
            return resultsMap;
         }
    
    
    
    
         private static String prepareValueForUseInQueryFilter(String currentKey, Map<String, Object> aggregatedFilterMap, 
                                                                boolean removeWhiteSpace)
         {
            String value = '';
    
            if (aggregatedFilterMap.containsKey(currentKey))
            {
               value =  getFormattedData(aggregatedFilterMap,currentKey,removeWhiteSpace);
            }
            return value;
         }
    
    


         private static String getFormattedData(Map<String,Object> inputMap, String currentKey, boolean removeWhiteSpace)
         {
            String valueIds = '';
    
            List<String> valueList = (List<String>)inputMap.get(currentKey);
    
            valueIds =  '\'' + String.join(valueList,',').replace(',', '\',' + '\'') + '\''; //add quote before and after each string
            
            if (removeWhiteSpace)
            {
                valueIds = valueIds.trim().replaceAll('(\\s+)', ''); // Remove any  whitespace
            }
          
            return valueIds;
        }
    
    


         private static Map<String, Object> findProdWithSKU(Map<String, Object> aggregatedFilterMap)
         {
            Map<String, Object> productSKuMap = new Map<String, Object> ();
    
            if (aggregatedFilterMap.containsKey('SBUX_B2B_SkuList__c'))
            {
                List<String> valueList = (List<String>)aggregatedFilterMap.get('SBUX_B2B_SkuList__c');
    
                String values = String.join(valueList,',');
                values = values.trim().replaceAll('(\\s+)', '');
    
                List<String> itemSkUs = values.split(',');

                List<ccrz__E_Product__c> productList = [ SELECT
                                                                ID,
                                                                ccrz__SKU__C,
                                                                SBUX_B2B_AutoShipLSCategory__c
                                                        FROM
                                                                ccrz__E_Product__c
                                                        WHERE
                                                                ccrz__SKU__C IN :(itemSkUs)
                                                            AND (ccrz__StartDate__c <= TODAY  OR  ccrz__StartDate__c = NULL) 
                                                            AND (ccrz__EndDate__c >= TODAY  OR  ccrz__EndDate__c = NULL) 
                                                            AND (ccrz__ProductStatus__c = 'Released' OR ccrz__ProductStatus__c = 'Not Orderable') ];
        
                if (productList != null && !productList.isEmpty()) 
                {
                    for (ccrz__E_Product__c product : productList) 
                    {
                        productSKUMap.put(product.ccrz__SKU__C, product);
                    }
                 }
            }

            return productSKuMap;
         }
    
    
    
        private static Map<String, Object> findProdViaCategory(Map<String, Object> aggregatedFilterMap)
        {
            Map<String, Object>  resultsMap = new Map<String, Object>();
    
            if (aggregatedFilterMap.containsKey('SBUX_B2B_ProductCategory__c'))
            {
                String prodCategoryName = prepareValueForUseInQueryFilter('SBUX_B2B_ProductCategory__c',aggregatedFilterMap, true);
    
                String CATEGORY_QUERY =     'SELECT ID' +
                                            ',Name' +
                                            ',ccrz__CategoryID__c' +
                                            ',ccrz__EndDate__c' +
                                            ',ccrz__StartDate__c' +
                                            ' FROM ccrz__E_Category__c ' +
                                            ' WHERE ' +
                                            ' ((ccrz__StartDate__c <= TODAY  OR  ccrz__StartDate__c = NULL) AND (ccrz__EndDate__c >= TODAY  OR  ccrz__EndDate__c = NULL) )' +
                                            ' AND ccrz__CategoryID__c IN (' + prodCategoryName + ') LIMIT 5000 ';
    
                 List <ccrz__E_Category__c> categoryList = Database.query(CATEGORY_QUERY);
    
                 if (!categoryList.isEmpty())
                 {
                     List<String> catIDList = Collection.of(categoryList).pluckStrings(ccrz__E_Category__c.ID);
    
                     String catIDs = '\'' + String.join(catIDList,',').replace(',', '\',' + '\'') + '\'';
    
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
                                                    ' AND ccrz__Category__c IN (' + catIDs + ') LIMIT 5000 ';
    
                     List<ccrz__E_ProductCategory__c> prodCatList = Database.query(PROD_CATEGORY_QUERY);
    
                     Map<String, List<ccrz__E_ProductCategory__c>> prodCategoryByCatId = Collection.of(prodCatList).groupByStrings('ccrz__Category__c');
                     Map<String, List<ccrz__E_Category__c>> categoryMap = Collection.of(categoryList).groupByStrings('ccrz__CategoryID__c');
    
                    resultsMap.put('CATEGORYMAP', categoryMap );
                    resultsMap.put('PROD_CATEGORY', prodCategoryByCatId);
                 }
           }
           return resultsMap;
        }
    
    

         private static void addValueToMap(Map <String,Object> currentCatalogRuleData,
                                          Map<String, Object> aggregatedFilterMap, 
                                          String currentKey, String currentValue)
         {
            if (String.isNotBlank(currentValue))
             {
                currentCatalogRuleData.put(currentKey,currentValue);
    
                List<String> valueList = new List<String> ();
    
                if (aggregatedFilterMap.containsKey(currentKey))
                {
                    valueList = (List <String>)aggregatedFilterMap.get(currentKey);
    
                    valueList.add(currentValue);
                }
                else 
                {
                    valueList.add(currentValue);
    
                    aggregatedFilterMap.put(currentKey, valueList);
                }
             }
         }
    
    }