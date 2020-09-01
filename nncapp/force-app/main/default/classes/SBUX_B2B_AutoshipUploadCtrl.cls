public with sharing class SBUX_B2B_AutoshipUploadCtrl 
{
    public static final String STORE_ATTRIBUTE_RECORDTYPE = 'SBUX_B2B_Store_Attribute';
    public static final String ASSORTMENT_SIZE_RECORDTYPE = 'SBUX_B2B_Assortment_Size';
    public static final String base64Chars = '' + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +'abcdefghijklmnopqrstuvwxyz' +'0123456789+/';
    private static final Decimal MAX_ALLOWED_THRESHOLD =  9998;


    //TODO - Do not let duplicate entries result in errors.
    @AuraEnabled
    public static Map<String, Object>  upsertAutoshipLines (Id contentVersionId, Id autoshipHeaderId)
    { 
        Map<String, Object> autoshipLineData = new  Map<String, Object>();

        Map <String, Integer > fieldNameAndPositionMap = new Map < String, Integer > ();

        list<SBUX_B2B_AutoShipLine__c> autoshipLineList = new list<SBUX_B2B_AutoShipLine__c>();

        if(contentVersionId != null) 
        {
            ContentVersion contentVersion = [SELECT 
                                                    Id, 
                                                    VersionData,
                                                    ContentDocumentId 
                                            FROM 
                                                ContentVersion 
                                             WHERE 
                                                ContentDocumentId =:contentVersionId];
         
            list<String> csvLineList = contentVersion.VersionData.toString().split('\n');
            
            list<String> csvFieldNames = csvLineList[0].split(',');

             for (Integer i = 0; i < csvFieldNames.size(); i++) 
             {
                fieldNameAndPositionMap.put(csvFieldNames[i].replace(' ', ''), i);
             }
          
            processAutoshipLineListData(csvLineList,fieldNameAndPositionMap,autoshipLineList,
                                        autoshipHeaderId,csvFieldNames,autoshipLineData);

            Savepoint savePoint = Database.setSavepoint();

            try
            {    
                if(!autoshipLineList.isEmpty()) 
                {
                    if (autoshipLineList.size() > MAX_ALLOWED_THRESHOLD)
                    {
                        SBUX_B2B_SObjectJobProcessor sobjecBatchProcessor =  new SBUX_B2B_SObjectJobProcessor(autoshipLineList);
                        Database.executeBatch(sobjecBatchProcessor,2000);
                    }
                    else
                    {
                        upsert autoshipLineList sbux_b2b_externalid__c;
                    }
                  
                }
            }
            catch (Exception ex) 
            {
                Database.rollBack(savePoint);

                delete new ContentDocument( ID = contentVersion.ContentDocumentId);
               
                throw new AuraHandledException(ex.getMessage());
            } 
            finally
            {
                delete new ContentDocument( ID = contentVersion.ContentDocumentId);
            }
        }

        return autoshipLineData;    
    }
   








   public static void processAutoshipLineListData(List<String> csvLineList, 
                                                  Map <String, Integer > fieldNameAndPositionMap,
                                                  List<SBUX_B2B_AutoShipLine__c> autoshipLineList,
                                                  Id autoshipHeaderId,
                                                  List<String> csvFieldNames,
                                                  Map<String, Object> autoshipLineData)
   {
        Integer fieldPositionForItemSku = fieldNameAndPositionMap.get('sbux_b2b_itemsku__c');

        List<String> productSKUs = new List <String>();
        
        Map<String,List<String>> picklistDependencyMap =  getDependentPicklistValues(SBUX_B2B_AutoShipLine__c.SBUX_B2B_AssortmentSize__c, 
                                                                                     SBUX_B2B_AutoShipLine__c.SBUX_B2B_LSCategory__c);
  
        for (Integer i = 1; i < csvLineList.size(); i++) 
        {
            List<String> csvRecordData = csvLineList[i].split(',');

            productSKUs.add(csvRecordData[fieldPositionForItemSku]);
        }

        Map <String, ccrz__E_Product__c> productSKUMap =  SBUX_B2B_StorefrontUtil.createProductSKUMap(productSKUs);

        for (Integer i = 1; i < csvLineList.size(); i++) 
        {
            List<String> csvRecordData = csvLineList[i].split(',');

            SBUX_B2B_AutoShipLine__c autoshipLine = new SBUX_B2B_AutoShipLine__c();

            for (String fieldName : csvFieldNames) 
            {
                Integer fieldNumber = fieldNameAndPositionMap.get(fieldName);
                
                String fieldValue = csvRecordData[fieldNumber];

                if (fieldName.trim().equalsIgnoreCase('sbux_b2b_lineqty__c'))
                {
                    Decimal qtyValue = Integer.valueOf(fieldValue);

                    autoshipLine.put(fieldName.trim(), qtyValue);
                }
                else 
                {
                    autoshipLine.put(fieldName.trim(), fieldValue.trim());
                }
            }
            autoshipLine.put('sbux_b2b_autoshipheader__c',autoshipHeaderId);

            processAutoShipLine(autoshipLine, productSKUMap,autoshipLineList,picklistDependencyMap,autoshipLineData);           
        }
        autoshipLineData.put('autoshipLineList',autoshipLineList);  
        applyDefaultsToInvalidEntryData(autoshipLineData);
   }






  public static void processAutoShipLine(SBUX_B2B_AutoShipLine__c autoshipLine, Map <String, ccrz__E_Product__c> productSKUMap,
                                         List<SBUX_B2B_AutoShipLine__c> autoshipLineList, 
                                         Map<String,List<String>> picklistDependencyMap,
                                         Map<String, Object> autoshipLineData )
  {
      String sku = autoshipLine.sbux_b2b_itemsku__c;

      ccrz__E_Product__c product = productSKUMap.get(sku);
     
      if ( product != null )
      {
        validateAssortmentSizeLine( autoshipLine,product, autoshipLineList, picklistDependencyMap, autoshipLineData);
        validateStoreAttributeLine( autoshipLine, autoshipLineList, product);
        noAssortmentSizeOrStoreAttribute( autoshipLine,autoshipLineData);
      } 
      else 
      {
        processInvalidEntryData(autoshipLineData, 'autoshipLineInvalidSku');
      }
   }    


    private static void applyDefaultsToInvalidEntryData(Map<String, Object> autoshipLineData)
    {
        if (autoshipLineData != null && !autoshipLineData.isEmpty())
        {
            if (!autoshipLineData.containskey('autoshipLineInvalidSku'))
            {
                autoshipLineData.put('autoshipLineInvalidSku',0);
            }
            if (!autoshipLineData.containskey('autoshipLineInvalidAssortments'))
            {
                autoshipLineData.put('autoshipLineInvalidAssortments',0);
            }
        }
    }



     private static void validateAssortmentSizeLine(SBUX_B2B_AutoShipLine__c autoshipLine,
                                                    ccrz__E_Product__c product,List<SBUX_B2B_AutoShipLine__c> autoshipLineList,
                                                    Map<String,List<String>> picklistDependencyMap,
                                                    Map<String, Object> autoshipLineData)
     {
        if( autoshipLine.sbux_b2b_assortmentsize__c != null 
            && String.isNotBlank(autoshipLine.sbux_b2b_assortmentsize__c)  )
        {
            if (isAssortmentSizeValid(autoshipLine.sbux_b2b_assortmentsize__c,
                                        product.SBUX_B2B_AutoShipLSCategory__c,
                                        picklistDependencyMap) )
            {
                autoshipLine.put('sbux_b2b_lscategory__c',product.SBUX_B2B_AutoShipLSCategory__c);
                autoshipLine.put('recordTypeId',getRecordTypeId(ASSORTMENT_SIZE_RECORDTYPE)) ;
                autoshipLine.put('sbux_b2b_externalid__c', autoshipLine.sbux_b2b_itemsku__c+product.SBUX_B2B_AutoShipLSCategory__c+autoshipLine.sbux_b2b_assortmentsize__c+ autoshipLine.sbux_b2b_autoshipheader__c) ;
                autoshipLine.sbux_b2b_itemsku__c = product.ID;
    
                autoshipLineList.add(autoshipLine);
            }
            else 
            {
                processInvalidEntryData(autoshipLineData, 'autoshipLineInvalidAssortments');
            }
        }
     }


     private static void noAssortmentSizeOrStoreAttribute(SBUX_B2B_AutoShipLine__c autoshipLine,
                                                         Map<String, Object> autoshipLineData)
     {
        if( autoshipLine.sbux_b2b_assortmentsize__c == null 
            || String.isBlank(autoshipLine.sbux_b2b_assortmentsize__c) 
            &&  (autoshipLine.sbux_b2b_storeattribute__c == null 
                || String.isBlank(autoshipLine.sbux_b2b_storeattribute__c)
                || String.isBlank(autoshipLine.sbux_b2b_storeattributevalue__c)) )
            {
                // Marking this condition as that with an invalid assortment for now.
                processInvalidEntryData(autoshipLineData, 'autoshipLineInvalidAssortments');
            }

     }

     private static void processInvalidEntryData(Map<String, Object> autoshipLineData, String currentKey)
     {
        if (autoshipLineData.containsKey(currentKey))
        {
            Decimal invalidEntrySize = (Decimal)autoshipLineData.get(currentKey);
            autoshipLineData.put(currentKey,++invalidEntrySize);
        }
        else 
        {
            autoshipLineData.put(currentKey,1);
        }
     }




     private static void validateStoreAttributeLine(SBUX_B2B_AutoShipLine__c autoshipLine,
                                                    List<SBUX_B2B_AutoShipLine__c> autoshipLineList,
                                                    ccrz__E_Product__c product)
     {
        if (autoshipLine.sbux_b2b_storeattribute__c != null 
            && String.isNotBlank(autoshipLine.sbux_b2b_storeattribute__c)
            && String.isNotBlank(autoshipLine.sbux_b2b_storeattributevalue__c))
        {
            autoshipLine.put('recordTypeId',getRecordTypeId(STORE_ATTRIBUTE_RECORDTYPE)) ;
            autoshipLine.put('sbux_b2b_externalid__c', autoshipLine.sbux_b2b_itemsku__c+autoshipLine.sbux_b2b_storeattribute__c+autoshipLine.sbux_b2b_storeattributevalue__c+autoshipLine.sbux_b2b_autoshipheader__c) ;
            autoshipLine.sbux_b2b_itemsku__c = product.ID;

            autoshipLineList.add(autoshipLine);
        }
     }
 


    private static boolean isAssortmentSizeValid(String assortmentSize, String autoshipCategory,
                                        Map<String,List<String>> picklistDependencyMap)
    {
        boolean isValid = false;

        if (picklistDependencyMap != null && !picklistDependencyMap.isEmpty())
        {   
            List<String> dependentPickList =  picklistDependencyMap.get(autoshipCategory);

            if (dependentPickList != null && !dependentPickList.isEmpty())
            {
                //TODO - evaluate if looping through the list might be a more accurate alternative
                isValid = dependentPickList.contains(assortmentSize);
            }
        }
        return isValid;
    }




    // Create a map of Category and assortment size association
    // based on sample code found here - https://gist.github.com/boxfoot/4166342
    // dependentField is the assortment size and ctrlField is the category field
    public static Map<String,List<String>> getDependentPicklistValues( Schema.SObjectField dependentField, Schema.SObjectField contrlField )
    {
       List<Schema.PicklistEntry> contrlFieldEntries = contrlField.getDescribe().getPicklistValues();

       List<PicklistEntryWrapper> depFieldEntries = wrapPicklistEntries(dependentField.getDescribe().getPicklistValues());

       Map<String, List<String>> objResults = new Map<String, List<String>>();

       List<String> controllingValues = new List<String>();
       
       for (Schema.PicklistEntry cntrlPicklistEntry : contrlFieldEntries) 
       {
            String label = cntrlPicklistEntry.getLabel();

            objResults.put(label, new List<String>());
            
            controllingValues.add(label);
       }

        for (PicklistEntryWrapper depPickListEntry : depFieldEntries) 
        {
            String label = depPickListEntry.label;

            String validForBits = base64ToBits(depPickListEntry.validFor);

            for (Integer i = 0; i < validForBits.length(); i++) 
            {
                // For each bit, in order: if it's a 1, add this label to the dependent list for the corresponding controlling value
                String bit = validForBits.mid(i, 1);

                if (bit == '1')
                 {
                    objResults.get(controllingValues.get(i)).add(label);
                 }
        }
    }
     return objResults;
  }




  private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) 
  {
    return (List<PicklistEntryWrapper>)JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
  }



  //TODO - Change to Map<String, Object>
  public class PicklistEntryWrapper 
  {
    public String active {get; set;}
    public String defaultValue {get; set;}
    public String label {get; set;}
    public String value {get; set;}
    public String validFor {get; set;}
  }


    // Convert a base64 token into a binary/bits representation
	// e.g. 'gAAA' => '100000000000000000000'
    public static String base64ToBits(String validFor) 
    {
        if (String.isEmpty(validFor)) 
        {
          return '';
        }

		String validForBits = '';

        for (Integer i = 0; i < validFor.length(); i++) 
        {
            String thisChar = validFor.mid(i, 1);
            
            Integer val = base64Chars.indexOf(thisChar);
            
            String bits = decimalToBinary(val).leftPad(6, '0');
            
			validForBits += bits;
		}

		return validForBits;
    }
    



    // Convert decimal to binary representation (alas, Apex has no native method :-(
	//    eg. 4 => '100', 19 => '10011', etc.
	// Method: Divide by 2 repeatedly until 0. At each step note the remainder (0 or 1).
	// These, in reverse order, are the binary.
    public static String decimalToBinary(Integer val)
    
    {
        String bits = '';
        
        while (val > 0) 
        {
            Integer remainder = Math.mod(val, 2);
            
            val = Integer.valueOf(Math.floor(val / 2));
            
			bits = String.valueOf(remainder) + bits;
        }
		return bits;
	}


    public static Id getRecordTypeId(String recordTypeDeveloperName)
    {
       return Schema.SObjectType.SBUX_B2B_AutoShipLine__c.getRecordTypeInfosByDeveloperName()
                      .get(recordTypeDeveloperName).getRecordTypeId();
    }

}