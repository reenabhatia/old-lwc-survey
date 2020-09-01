import { LightningElement , api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import upsertAutoshipLines from '@salesforce/apex/SBUX_B2B_AutoshipUploadCtrl.upsertAutoshipLines';

export default class SBUX_B2B_AutoshiplineUpload extends LightningElement 
{
    @api recordId;

   
    get acceptedFormats() 
    {
        return ['.csv'];
    }

    handleUploadFinished(event) 
    {
       const uploadedFiles = event.detail.files;

       if  (uploadedFiles)
       {
        upsertAutoshipLines({contentVersionId : uploadedFiles[0].documentId, autoshipHeaderId: this.recordId})
        .then(result => 
        {
            if (result && result.autoshipLineList)
            {
                this.data = result.autoshipLineList;

                const noOfInsertedLines =  this.data.length.toString();
                const invalidSku = result.autoshipLineInvalidSku.toString();
                const invalidAssortmentSize = result.autoshipLineInvalidAssortments.toString();

                let event;

                if (this.data.length > 10000)
                {
                     event = new ShowToastEvent({
                        "title": "Success!",
                        "message": "{0} Autoship lines were successfully uploaded! {1} entries had invalid sku numbers and {2} had invalid assortment sizes. Due to the size of the data the information will take a while so please refresh your browser in a few minutes",
                        "messageData": [noOfInsertedLines,invalidSku,invalidAssortmentSize],
                        "mode": "sticky",
                        "variant": "success"});
                }
                else
                {
                   event = new ShowToastEvent({
                        "title": "Success!",
                        "message": "{0} Autoship lines were successfully uploaded! {1} entries had invalid sku numbers and {2} had invalid assortment sizes",
                        "messageData": [noOfInsertedLines,invalidSku,invalidAssortmentSize],
                        "mode": "sticky",
                        "variant": "success"});
                }
               
                this.dispatchEvent(event);
            }
           
             // TODO - consider wrapping this LWC in an aura container and triggering a custom event
            eval("$A.get('e.force:refreshView').fire();"); //eslint-disable-line no-eval
        })
        .catch(error => 
        {
            this.error = error;

            this.dispatchEvent( new ShowToastEvent({title: 'File upload Error!',
                                message: JSON.stringify(error),
                                variant: 'error',
                            }),
            );     
        })
       }
    }

}