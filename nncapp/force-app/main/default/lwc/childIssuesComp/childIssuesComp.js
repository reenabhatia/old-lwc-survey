import { LightningElement, api, track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';

const url = '/sfc/servlet.shepherd/document/download/';
const actions = [
    { label: 'View', name: 'view' },
    { label: 'Edit', name: 'edit' },
];
const columns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Status', fieldName: 'Status__c' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
    { label:'',cellAttributes: { alignment: 'center' },
    type: 'button', typeAttributes: {
            label: 'Attach Photos',
            name: 'Attach Photos',
            title: 'Attach Photos',
            disabled: false,
            value: 'attachphotos',
            iconPosition: 'right',
            //class:'justify-content: center'
            //menuAlignment: 'center'
    }
    },
];
export default class ChildIssuesComp extends NavigationMixin(LightningElement) {
    @api issueDetails;
    //@api isEdited;
    //@track dataTb=[];
    @track files = [];
    @track columns = columns;
    @track uploadPhotos = false;
    @track recId;
    @track isPreview=false;
    @track currentRecId;
    @track recordPageUrl;
    //@track isModalOpen = false;
    //@wire(CurrentPageReference) pageRef;
    openModal() {
        this.uploadPhotos = true;
    }
    closeModal() {
        this.uploadPhotos = false;
        this.isPreview=false;
    }
    submitDetails() {
        this.uploadPhotos = false;
    }

    get dataTb() {
        var data = [];
        this.issueDetails.forEach((value) => {


            data.push(value);

            //this.dataTb.push(item.CompIssues__r);

        });
        console.log('child--> ' + JSON.stringify(data));
        return data;
    }

    /*get redirectRecord(){
        return 'https://starbucksnncapp.lightning.force.com/'+this.issueDetails.Id;
    }*/
    handleRowAction(event) {

        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'view':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        objectApiName: 'CompIssues__c',
                        actionName: 'view'
                    }
                });
                break;
            case 'edit':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        objectApiName: 'CompIssues__c',
                        actionName: 'edit'
                    }
                })                
                //this.dispatchEvent(new CustomEvent('edit'));
                //this.isEdited=true;
                break;
            case 'Attach Photos':
                //alert('Attach Photos-->'+row.Id);
                this.uploadPhotos = true;
                this.recId = row.Id;
                break;
            default:
        }

    }
    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }
    handleFilePreview(event) {
        let previewId = event.target.getAttribute('data-id');
        this.currentRecId = previewId;
        this.isPreview = true;
    }
    handleDelete(event) {
        deleteRecord(this.currentRecId)
            .then(() => {
                for (let i = 0; i < this.files.length; i++) {
                    if (this.files[i].Id === this.currentRecId) {
                        this.files.splice(i, 1);
                    }
                }

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record deleted',
                        variant: 'success'
                    })
                );
                this.isPreview = false;
            }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error deleting record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
    handleSubmit(event) {
        event.preventDefault();

        this.template.querySelector('lightning-record-edit-form').submit(event.detail.fields);
        this.isPreview = false;

        this.dispatchEvent(new ShowToastEvent({
            title: 'Success!',
            message: ' file content updated.',
            variant: 'success'
        }));
    }

    handleSuccess(event) {
        var description = event.detail.fields.Description;

        for (let i = 0; i < this.files.length; i++) {
            if (this.files[i].Id === this.currentRecId) {
                this.files[i].Description = description.value;
            }
        }
    }
    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        let uploadedFileNames = '';
        for (let i = 0; i < uploadedFiles.length; i++) {
            uploadedFileNames += uploadedFiles[i].name + ', ';
        }
        for (let index = 0; index < uploadedFiles.length; index++) {
            if ({}.hasOwnProperty.call(uploadedFiles, index)) {
                this.files = [...this.files, {
                    Id: uploadedFiles[index].documentId,
                    name: uploadedFiles[index].name,
                    src: url + uploadedFiles[index].documentId,
                    description: ''
                }];
            }
        }
        console.log(" Files-- > ", JSON.stringify(this.files));
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: uploadedFiles.length + ' Files uploaded Successfully: ' + uploadedFileNames,
                variant: 'success',
            }),
        );
    }
}