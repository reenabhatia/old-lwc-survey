import { LightningElement, track,wire,api } from 'lwc';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import PARSHEET_OBJECT from '@salesforce/schema/SBUX_B2B_PARSheet__c';
import CATEGORY_FIELD from '@salesforce/schema/SBUX_B2B_PARSheet__c.SBUX_B2B_Category__c';
import getParItems from '@salesforce/apex/SBUX_B2B_ParSheetCtrl.getParItems';
import generateParItems from '@salesforce/apex/SBUX_B2B_ParSheetCtrl.generateParItems';
import updateParSheetItems from '@salesforce/apex/SBUX_B2B_ParSheetCtrl.updateParSheetItems';
import getStoreId from '@salesforce/apex/SBUX_B2B_ParSheetCtrl.getCurrentStoreID';
import getParSheetCategory from '@salesforce/apex/SBUX_B2B_ParSheetCtrl.getParSheetCategory';
import resetParValues from '@salesforce/apex/SBUX_B2B_ParSheetCtrl.resetParValues';
import resetOnHandValues from '@salesforce/apex/SBUX_B2B_ParSheetCtrl.resetOnHandValues';
import deleteParItems from '@salesforce/apex/SBUX_B2B_ParSheetCtrl.deleteParItems';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import LANG from '@salesforce/i18n/lang';
import CURRENCY from '@salesforce/i18n/currency';


const initCtx = (obj) => 
{
    let ctx = {};
    
    if (null != obj && "object" === typeof obj)
    {
        ctx = obj.constructor();
        
        for (var attr in obj) 
        {
            if (obj.hasOwnProperty(attr))
            {
				ctx[attr] = obj[attr];
			}
		}
	}
	ctx['userIsoCode'] = CURRENCY;
	ctx['userLocale'] = getLanguage();

	return JSON.stringify(ctx);
};


const getLanguage = () => 
{
	return LANG.replace(/-/g, '_');
};

// TODO - Make this number configurable
const QUERYLIMIT = Number(50);


export default class SBUX_B2B_ParSheet extends LightningElement 
{
    //common reusable data
    @wire(getStoreId, {ctx: initCtx()}) storeId;

    //titles and labels
	@api generatePARLabel;
	@api resetPARLabel;
	@api resetOnHandLabel;
    @api deleteProductsLabel;
    
    //dual list box fields/values and logic
    @track options;
    defaultOptions;
    @track selectedOptionsList = [];

   
    handleListBoxChange(event) 
    {
        this.selectedOptionsList = event.detail.value;
    }

    @wire(getObjectInfo, { objectApiName: PARSHEET_OBJECT })objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CATEGORY_FIELD })
    getPicklistValuesCallBack({ error, data })
     {
        if (data) 
        {
            this.options = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
        } 
        else if (error) 
        {
            // TODO - Handle error - display on the UI
            console.log(error);
        }
    }


    @wire(getParSheetCategory, { ctx: initCtx(), storeId: '$storeId.data'})
    getParSheetCategoryCallBack({data })
     {
        if (data) 
        {
            this.defaultOptions = [...data];
        } 
    }

    

   // lightning data table fields/logic
   //TODO - make column  labels configurable
  @api totalNumberOfRows;

  @track isInfiniteLoading = false;

  @api loadingCoffeeDiv = false;


  @track  columns =  [{ label: 'SKU', fieldName: 'SKU' , wrapText: true, columnWidthsMode: 'auto'},
      { label: 'Description', fieldName: 'ItemName' , wrapText: true, columnWidthsMode: 'auto'},
      { label: 'Case Ct Qty', fieldName: 'UOMCONV', wrapText: true , columnWidthsMode: 'auto'},
      { label: 'PAR', fieldName: 'SBUX_B2B_ParQty__c', editable: true, type: 'number', columnWidthsMode: 'auto',cellAttributes: { alignment: 'left'} },
      { label: 'On Hand', fieldName: 'SBUX_B2B_OnHandQty__c' , editable: true, type: 'number', columnWidthsMode: 'auto', cellAttributes: { alignment: 'left'}},
      { label: 'Order Qty', fieldName: 'SBUX_B2B_OrderQty__c' , type: 'number', columnWidthsMode: 'auto', cellAttributes: { alignment: 'left'}} ];

    
   @track parItems ;

   @track selectedParItemIds = [];

   @track draftValues = [];

   connectedCallback() 
   {
     this.isInfiniteLoading = true;
     this.loadingCoffeeDiv = true;
   }

   @wire(getParItems,{ctx: initCtx(), queryLimit:QUERYLIMIT, selectedCategories: '$defaultOptions', storeId: '$storeId.data'}) getParItemsCallBack({ error, data })
   {
        if (data && data.parItemList)
        {
            this.parItems = this.mapParSheetItems(data.parItemList);
            this.totalNumberOfRows = data.totalNumberOfRows;
            this.loadingCoffeeDiv = false;
        }
      else if (error) 
      {
          // TODO - Handle error - display on the UI
          // TODO - Display some messaging if no items in selected categories were added
          console.log( error);
      }
  }




    handleGenerateParItems(event)
    {
        if (this.selectedOptionsList && this.selectedOptionsList !== null && this.selectedOptionsList.length !== 0 )
        {
           this.loadingCoffeeDiv = true;

            generateParItems({ctx: initCtx(), selectedCategories: this.selectedOptionsList,  storeId: this.storeId.data, queryLimit : QUERYLIMIT})
            .then(result => 
            {
                this.dispatchEvent(new ShowToastEvent({title: 'Success!!',
                                                     message: 'The Items  were successfully created!',variant: 'success' }));

                this.data = this.mapParSheetItems(result.parItemList);

                this.parItems =  [...new Set(this.data)];
            
                this.totalNumberOfRows = result.totalNumberOfRows;

                this.isInfiniteLoading = true;

                this.loadingCoffeeDiv = false;

                let divElement = this.template.querySelector('.printTableHeight');

                if (divElement)
                {
                    // The infinite loading feature requires a table height 
                    // We are adding the necessary class here should this be no longer available 
                    // This could happen when a user reaches the end of the list and tries to print its content 
                    divElement.classList.remove('printTableHeight');
                    divElement.classList.add('tableHeight');
                }
                
                this.defaultOptions = [...this.selectedOptionsList];
            })
            .catch(error => 
            {
                console.log(error);
                this.dispatchEvent( new ShowToastEvent({title: 'Par Items creation error!',
                                    message: JSON.stringify(error),
                                    variant: 'error' }));     
            })
        }
        else
        {
            this.dispatchEvent( new ShowToastEvent({title: 'Please select your categories', variant: 'info' }) );     
        }
    }




    handleResetParValues(event)
    {
        if (this.selectedParItemIds && this.selectedParItemIds !== null && this.selectedParItemIds.length !== 0 )
        {
            this.loadingCoffeeDiv = true;

            resetParValues({ctx: initCtx(), selectedParItemIds: this.selectedParItemIds})
            .then(result => 
                {
                    this.dispatchEvent(new ShowToastEvent({title: 'Success!!',
                                                        message: 'The PAR Values  were successfully updated!!',
                                                        variant: 'success' }));
                   
                     //TODO - This code appears to be duplicated and hence ripe for reuse
                    this.data = this.mapParSheetItems(result);

                    let existingParItemList = this.parItems;

                    this.data.forEach(function (item) 
                    {
                       let indexOfUpdatedItem = existingParItemList.findIndex(parItem => parItem.Id === item.Id)
                    
                        existingParItemList.splice(indexOfUpdatedItem, 1, item);
                    });
                      this.loadingCoffeeDiv = false;
                    
                     this.parItems =  [...new Set(existingParItemList)];
                })  
            .catch(error => 
            {
                console.log(error);
                this.dispatchEvent( new ShowToastEvent({title: 'Par Values Reset error!',
                                    message: JSON.stringify(error),
                                    variant: 'error' })
                );     
            })
        }
        else
        {
            this.dispatchEvent( new ShowToastEvent({title: 'No items are selected, please select at least one item', variant: 'info' }) );     
        }
    }




    handleResetOnHandValues(event)
    {
        if (this.selectedParItemIds && this.selectedParItemIds !== null && this.selectedParItemIds.length !== 0 )
        {
            this.loadingCoffeeDiv = true;

            resetOnHandValues({ctx: initCtx(), selectedParItemIds: this.selectedParItemIds})
            .then(result => 
            {
                this.dispatchEvent(new ShowToastEvent({title: 'Success!!',
                                                    message: 'The On Hand Values  were successfully updated!',
                                                    variant: 'success' }));
               
                this.data = this.mapParSheetItems(result);

                let existingParItemList = this.parItems;

                this.data.forEach(function (item) 
                {
                   let indexOfUpdatedItem = existingParItemList.findIndex(parItem => parItem.Id === item.Id)
                
                    existingParItemList.splice(indexOfUpdatedItem, 1, item);
                });
    
                 this.parItems =  [...new Set(existingParItemList)];
                 
                 this.loadingCoffeeDiv = false;
            })
            .catch(error => 
            {
                console.log(error);
                this.dispatchEvent( new ShowToastEvent({title: 'On Hand Values Reset error!',
                                    message: JSON.stringify(error),
                                    variant: 'error' }));     
            })
        }
        else
        {
            this.dispatchEvent( new ShowToastEvent({title: 'No items are selected, please select at least one item', variant: 'info' }) );     
        }
    }


   
    handleInlineEdit(event) 
    {
        this.loadingCoffeeDiv = true;

        this.draftValues = event.detail.draftValues;

        let mapOfDraftValues = {};

        this.draftValues.map(item => {
                const parItem = {};
                parItem['Id'] = item.Id;
                parItem['SBUX_B2B_ParQty__c'] = item.SBUX_B2B_ParQty__c;
                parItem['SBUX_B2B_OnHandQty__c'] = item.SBUX_B2B_OnHandQty__c;
                
                mapOfDraftValues[item.Id] = parItem;

                return parItem;
          });
        
        updateParSheetItems({  itemsFromUI : JSON.stringify(mapOfDraftValues) })
        .then(result => 
        {
            this.dispatchEvent(new ShowToastEvent({title: 'Success!!',
                                                message: 'The Items  were successfully updated!',
                                                variant: 'success' }));
            this.draftValues = [];
      
            this.data = this.mapParSheetItems(result);

            let existingParItemList = this.parItems;

            this.data.forEach(function (item) 
            {
               let indexOfUpdatedItem = existingParItemList.findIndex(parItem => parItem.Id === item.Id)
            
                existingParItemList.splice(indexOfUpdatedItem, 1, item);
            });

             this.parItems =  [...new Set(existingParItemList)];

             this.loadingCoffeeDiv = false;
        })
        .catch(error => 
        {
            console.log(error);
            this.dispatchEvent( new ShowToastEvent({title: 'Items save error!',
                                message: JSON.stringify(error),
                                variant: 'error' }));     
        })
        
    }


    mapParSheetItems(result)
    {
       return  result.map(item => {

                        const parItem = {};
                        parItem['Id'] = item.Id;
                        parItem['SBUX_B2B_ParQty__c'] = item.SBUX_B2B_ParQty__c;
                        parItem['SBUX_B2B_OnHandQty__c'] = item.SBUX_B2B_OnHandQty__c;
                        parItem['SBUX_B2B_OrderQty__c'] = item.SBUX_B2B_OrderQty__c;
                        parItem['ItemName'] = item.SBUX_B2B_ProductItem__r.Name;
                        parItem['SKU'] = item.SBUX_B2B_ProductItem__r.ccrz__SKU__c;
                        parItem['UOMCONV'] = this.handleUOMConversion(item);

                        return parItem;
        });
    }


    handleUOMConversion(item)
    {
       if (item 
            && item.SBUX_B2B_ProductItem__r.SBUX_B2B_UOMConv__c 
            &&  item.SBUX_B2B_ProductItem__r.ccrz__UnitOfMeasure__c
            &&  item.SBUX_B2B_ProductItem__r.SBUX_B2B_PrimaryUOM__c)
       {
         let uomConversionData = JSON.parse(item.SBUX_B2B_ProductItem__r.SBUX_B2B_UOMConv__c);

         for (let uomconversionItem in uomConversionData) 
         {
            if (uomConversionData[uomconversionItem].fromCode && uomConversionData[uomconversionItem].convRt 
                && uomConversionData[uomconversionItem].fromCode === item.SBUX_B2B_ProductItem__r.ccrz__UnitOfMeasure__c
                && uomConversionData[uomconversionItem].toCode === item.SBUX_B2B_ProductItem__r.SBUX_B2B_PrimaryUOM__c) 
                {
                    let  qtyString =  item.SBUX_B2B_ProductItem__r.SBUX_B2B_PrimaryUOM__c + '  (' + uomConversionData[uomconversionItem].convRt + '/' + uomConversionData[uomconversionItem].fromCode + ')';

                    return qtyString;
            }
         }
       }
    }

    handleDeleteParItems(event)
    {
        if (this.selectedParItemIds && this.selectedParItemIds !== null && this.selectedParItemIds.length !== 0 )
        {
            this.loadingCoffeeDiv = true;

            deleteParItems({ctx: initCtx(), selectedParItemIds: this.selectedParItemIds})
            .then(result => 
            {
                this.dispatchEvent(new ShowToastEvent({title: 'Success!!', 
                                                      message: 'The items  were successfully deleted!', variant: 'success' }));
               
                let filteredList = this.parItems;
    
                this.selectedParItemIds.forEach(function (item) 
                {
                    filteredList = filteredList.filter(parItem => parItem.Id !== item);
                });

                this.parItems =  [...new Set(filteredList)];

                this.totalNumberOfRows = this.parItems.length;

                this.loadingCoffeeDiv = false;
            })
            .catch(error => 
            {
                console.log(error);
                this.dispatchEvent( new ShowToastEvent({title: 'Item deletion  error!',
                                    message: JSON.stringify(error),variant: 'error' }));     
            })
        }
        else
        {
            this.dispatchEvent( new ShowToastEvent({title: 'No items are selected, please select at least one item', variant: 'info' }) );     
        }
    }



    getSelectedItem(event) 
    { 
        const selectedRows = event.detail.selectedRows;

        if (selectedRows  &&  selectedRows.length > 0)
        {
            let parItemIds = new Set();

            selectedRows.forEach(function (item) 
            {
                parItemIds.add(item.Id)
            });
            this.selectedParItemIds = Array.from(parItemIds);
        }
    }


    handleLoadMoreData(event)
    {
        this.loadingCoffeeDiv = true;

        const currentParItemList = this.parItems;

        const lastRecId = currentParItemList[currentParItemList.length - 1].Id;

        getParItems({ctx: initCtx(), queryLimit:QUERYLIMIT, selectedCategories: this.defaultOptions, storeId: this.storeId.data, recId:lastRecId})
        .then(result => 
        {
            this.loadingCoffeeDiv = false;
            
            const fetchedData = this.mapParSheetItems(result.parItemList);
            const newItemList = [...currentParItemList, ...fetchedData];

            this.parItems = newItemList; 

            if (this.parItems.length >= this.totalNumberOfRows) 
            {
                this.isInfiniteLoading = false;

                let divElement = this.template.querySelector('.tableHeight');

                if (divElement)
                {
                   // removing the table height and setting it to none in order to allow the user to print the content of the screen
                    divElement.classList.add('printTableHeight');
                    divElement.classList.remove('tableHeight');
                }
            }
        })
        .catch(error => 
        {
            console.log(error);
            this.dispatchEvent( new ShowToastEvent({title: 'Item fetch  error!',
                                message: JSON.stringify(error),variant: 'error' }));   
        });
    }
    
}