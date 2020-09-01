import { LightningElement, track, wire, api } from 'lwc';
//import getIssues from '@salesforce/apex/GetComplianceIssues.getIssues';
import getIssuesNew from '@salesforce/apex/GetComplianceIssues.getIssuesNew';
import saveRecords from '@salesforce/apex/GetComplianceIssues.saveRecords';
import sendForApproval from '@salesforce/apex/GetComplianceIssues.sendForApproval';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';

// Set the row columns and URL
const url = '/sfc/servlet.shepherd/document/download/';
const actions = [
    { label: 'View', name: 'view' },
    { label: 'Edit', name: 'edit' },
    { label: 'Refresh', name: 'refresh' },
];
const columns = [
    { label: 'Name', fieldName: 'Name' },
    //{ label: 'Status', fieldName: 'Status__c' },
    { label: 'Comments', fieldName: 'Comments' },
    { label: 'Number of Attachments', fieldName: 'Number_of_attachments__c' },
    {
        label: '', cellAttributes: { alignment: 'center' },
        type: 'button', typeAttributes: {
            label: 'Attach Photos',
            name: 'Attach Photos',
            title: 'Attach Photos',
            disabled: false,
            value: 'attachphotos',
            iconPosition: 'right',

        }
    }, {
        type: 'action',
        typeAttributes: { rowActions: actions },
    }
];
export default class IssuesDetails extends NavigationMixin(LightningElement) {
    // Variables declarations
    @track multiple = true;
    @track compliance = [];
    @track link = 'https://starbucksnncapp.lightning.force.com/';
    @track data;
    @track error;
    @track uploadedFiles;
    //@track dataTb = [];
    @track isEdited = false;
    @api issueDetails;
    @track files = [];
    @track columns = columns;
    @track uploadPhotos = false;
    @track recId;
    @track isPreview = false;
    @track currentRecId;
    @track recordPageUrl;
    @track editRecId;
    @track mapValues = [];
    @track tempSelectedMap = [];
    @track selectedMapVar = [];
    @api storeId;
    @track disableApprove = false;
    @track disableSave = false;
    @track selectedRows = [];
    timeout;
    @track openSections = [];
    @track counter = 0;
    @track childLoaded = false;
    @track approveClicked = false;
    // Get the current page reference
    @wire(CurrentPageReference) pageRef;
    // Connected call backs
    connectedCallback() {
        registerListener('actionitemspage', this.handleActionMessage, this);
        registerListener('actionitemsloaded', this.handleActionLoaded, this);
    }
    // Load the selected data once the child is loaded to ensure the linking of datas
    handleActionLoaded(data) {
        this.childLoaded = true;
        if (this.viewStatusFromState == 'View') {
            console.log('childcalled');

            this.compliance.forEach(compVal => {
                this.selectedRows.forEach(selectId => {
                    if (compVal.Issues.filter(e => e.Id == selectId).length > 0) {
                        this.openSections.push(compVal.Name);
                        this.tempSelectedMap.push({ "Id": selectId, "Name": compVal.Issues.filter(e => e.Id == selectId)[0].Name })
                    }
                })
            })
            if (this.tempSelectedMap.length > 0) {
                console.log('valuesss--> ' + this.tempSelectedMap);
                console.log('openSections--> ' + this.openSections);
                fireEvent(this.pageRef, 'detailPageMessage', this.tempSelectedMap);
            }
        }
    }
    // Get the store id from URl
    get recordIdFromState() {

        let cURL = window.location.href;
        let newURL = new URL(cURL).searchParams;
        //console.log('id ===> ' + JSON.stringify(newURL));
        return newURL.get('c__storeId');

    }
    // Get the state from URl
    get viewStatusFromState() {

        let url = window.location.href;
        let nURL = new URL(url).searchParams;
        //console.log('id ===> ' + JSON.stringify(newURL));
        return nURL.get('c__mode');

    }
    // Get the type of NNC from URl
    get typeOfNnc() {
        let url = window.location.href;
        let nURL = new URL(url).searchParams;
        //console.log('id ===> ' + JSON.stringify(newURL));
        return nURL.get('c__type');
    }
    // Store the selected actions from child
    handleActionMessage(data) {
        //console.log('Parent data--> '+JSON.stringify(data));
        if (this.selectedMapVar.findIndex(v => { if (v.actionitems) { return 1; } }) == -1) {
            this.selectedMapVar.push({ "actionitems": data });
        }
        //console.log('Parent data final--> '+JSON.stringify(this.selectedMapVar).replace(/__c/g,""));
    }
    // Decode the URl
    get decodeUrl() {
        return decodeURIComponent(window.location.href);
    }
    // Call server to get the datas
    @wire(getIssuesNew, { storeIdVal: '$recordIdFromState', viewUrl: '$decodeUrl', recordType: '$typeOfNnc' }) wiredComplainceIssues(result) {

        this.data = result;
        //this.compliance=[];
        if (result.data) {
            this.compliance = [];
            console.log('result.data--- ' + JSON.stringify(result.data));
            result.data.issuesList.forEach(val => {
                if (this.compliance.length == 0) {
                    if (val.hasOwnProperty('Non_Compliance_Items__r')) {
                        val.Non_Compliance_Items__r.forEach(compId => {
                            if (val.Long_Description__c != null) {
                                this.compliance.push({ Name: val.Category__c, Issues: [{ "Id": compId.Id, "Name": val.Long_Description__c, "Comments": compId.Action_Plan_Comments__c, "Number_of_attachments__c": compId.Number_of_attachments__c }] });
                                //console.log('Action_Plan_Comments__c--> ' + JSON.stringify(compId));
                            }
                        })
                    }
                }
                this.compliance.forEach(compVal => {
                    //console.log(compVal.Name+'-----'+val.Category__c);
                    if (compVal.Name == val.Category__c) {
                        //console.log('ifff--> ' + compVal.Name + '---' + val.Category__c);
                        if (val.hasOwnProperty('Non_Compliance_Items__r')) {
                            val.Non_Compliance_Items__r.forEach(compId => {
                                if (compVal.Issues.filter(e => e.Id == compId.Id).length == 0) {
                                    if (val.Long_Description__c != null) {
                                        compVal.Issues.push({ "Id": compId.Id, "Name": val.Long_Description__c, "Comments": compId.Action_Plan_Comments__c, "Number_of_attachments__c": compId.Number_of_attachments__c });
                                    }
                                }
                            })
                        }
                    } else if (this.compliance.filter(e => e.Name == val.Category__c).length == 0) {
                        if (val.hasOwnProperty('Non_Compliance_Items__r')) {
                            //console.log('Action_Plan_Comments__c--> ' + val.Category__c);
                            val.Non_Compliance_Items__r.forEach(compId => {
                                if (val.Long_Description__c != null) {
                                    this.compliance.push({ Name: val.Category__c, Comments: compId.Action_Plan_Comments__c, Issues: [{ "Id": compId.Id, "Name": val.Long_Description__c, "Comments": compId.Action_Plan_Comments__c, "Number_of_attachments__c": compId.Number_of_attachments__c }] });
                                    //this.compliance.push({Name : val.Category__c,Comments:"",Issues : [{"Id":compId.Id,"Name":val.Long_Description__c}]});
                                    //console.log('Action_Plan_Comments__c--> '+JSON.stringify(compId));
                                }
                            })
                        }
                    }
                })


            })
            // If status is 'View' then fetch the previous selected rows
            if (this.viewStatusFromState == 'View') {
                for (var key in result.data.storeRelatedIds) {
                    //console.log('Key --> '+key);
                    if (key == this.recordIdFromState) {
                        console.log(result.data.storeRelatedIds[key].split(","));
                        this.selectedRows = result.data.storeRelatedIds[key].split(",");
                    }
                }
                if (this.tempSelectedMap.length == 0 && this.viewStatusFromState == 'View') {
                    this.compliance.forEach(compVal => {
                        this.selectedRows.forEach(selectId => {
                            if (compVal.Issues.filter(e => e.Id == selectId).length > 0) {
                                this.openSections.push(compVal.Name);
                                this.tempSelectedMap.push({ "Id": selectId, "Name": compVal.Issues.filter(e => e.Id == selectId)[0].Name })
                            }
                        })
                    })
                    if (this.tempSelectedMap.length > 0) {
                        console.log('valuesss--> ' + this.tempSelectedMap);
                        console.log('openSections--> ' + this.openSections);
                        fireEvent(this.pageRef, 'detailPageMessage', this.tempSelectedMap);
                    }
                }
                // If status is 'View' then fetch the previous selected rows and if the status is in Active then make the page uneditable
                for (var key in result.data.storeStatus) {
                    //console.log('Key --> '+key);
                    if (key == this.recordIdFromState) {
                        console.log(result.data.storeStatus[key]);
                        if (result.data.storeStatus[key] == 'Active' || result.data.storeStatus[key] == 'Sent for Approval') {
                            this.disableApprove = true;
                            this.disableSave = true;
                            this.columns = [
                                { label: 'Name', fieldName: 'Name' },
                                { label: 'Comments', fieldName: 'Comments' },
                                {
                                    label: '', cellAttributes: { alignment: 'center' },
                                    type: 'button', typeAttributes: {
                                        label: 'Attach Photos',
                                        name: 'Attach Photos',
                                        title: 'Attach Photos',
                                        disabled: true,
                                        value: 'attachphotos',
                                        iconPosition: 'right',

                                    }
                                }, {
                                    type: 'action',
                                    typeAttributes: { rowActions: actions },
                                }
                            ];
                        } else {
                            this.disableApprove = false;
                            this.disableSave = false;
                        }
                    }
                }
            }
        } else if (result.error) {
            this.error = result.error;
        }

    }
    // Rendered call back to make the page uneditbale after the data loads
    renderedCallback() {
        //console.log('rendered');
        if (this.disableApprove == true && this.viewStatusFromState == 'View') {
            console.log('rendered');

            var disableAllRows = this.template.querySelectorAll('.disableCheckBox');
            //console.log('disableAllRows.length--> ' + disableAllRows.length);
            for (let i = 0; i < disableAllRows.length; i++) {
                disableAllRows[i].classList.add('dynamicDisableCheckBox');

            }
            // Fire the event to pre-select the actions upon render
            fireEvent(this.pageRef, 'approveDetail', true);
        }
    }
    // Approve functionality to store the records in the Non-Compliance object
    handleClickApprove(event) {
        refreshApex(this.data);
        this.approveClicked = false;
        console.log('APPROVE-- > ' + JSON.stringify(this.recordIdFromState) + ' ' + this.viewStatusFromState);
        sendForApproval({ json: JSON.stringify(this.selectedMapVar).replace(/__c/g, ""), storeId: this.recordIdFromState, approvalRecordType: this.typeOfNnc, approveUrl: this.decodeUrl }).then(res => {
            console.log('callout approve --> ' + JSON.stringify(res));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Compliance items sent for approval',
                    variant: 'success',
                }),
            );
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: res,
                    objectApiName: 'Non_Compliance__c',
                    actionName: 'view'
                },
            });
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error while sending for approval',
                    variant: 'error',
                }),
            );
            console.log('callout error approve --> ' + JSON.stringify(error));
        });
        this.disableApprove = true;
        this.disableSave = true;
        this.columns = [
            { label: 'Name', fieldName: 'Name' },
            { label: 'Comments', fieldName: 'Comments' },
            {
                label: '', cellAttributes: { alignment: 'center' },
                type: 'button', typeAttributes: {
                    label: 'Attach Photos',
                    name: 'Attach Photos',
                    title: 'Attach Photos',
                    disabled: true,
                    value: 'attachphotos',
                    iconPosition: 'right',

                }
            }, {
                type: 'action',
                typeAttributes: { rowActions: actions },
            }
        ];
        var disableAllRows = this.template.querySelectorAll('.disableCheckBox');
        for (let i = 0; i < disableAllRows.length; i++) {
            disableAllRows[i].classList.add('dynamicDisableCheckBox');

        }
        // Fire event to child once the approve button is clicked to make the page uneditable
        fireEvent(this.pageRef, 'approveDetail', true);
    }
    // Open and close modal pop-up based on the condition of photos being uploaded
    openModal() {
        this.uploadPhotos = true;
    }
    closeModal() {
        this.uploadPhotos = false;
        this.isPreview = false;
    }
    submitDetails() {
        this.uploadPhotos = false;
        this.files = [];
    }
    approveClickHandle() {
        this.approveClicked = true;
    }
    closeModalApprove() {
        this.approveClicked = false;
        this.disableApprove = false;
        this.disableSave = false;
    }
    // Row actions functionality
    handleRowAction(event) {

        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'view':
                /*this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        objectApiName: 'Non_Compliance_Item__c',
                        actionName: 'view'
                    }
                });*/
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        objectApiName: 'Non_Compliance_Item__c',
                        actionName: 'view'
                    },
                }).then(url => {
                    window.open(url);
                });
                break;
            case 'edit':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        objectApiName: 'Non_Compliance_Item__c',
                        actionName: 'edit'
                    }
                })
                //this.dispatchEvent(new CustomEvent('edit'));
                this.isEdited = true;
                //refreshApex(this.data);
                //eval("$A.get('e.force:refreshView').fire();");
                break;
            case 'refresh':
                refreshApex(this.data);

                break;
            case 'Attach Photos':
                //alert('Attach Photos-->'+row.Id);
                this.uploadPhotos = true;
                this.recId = row.Id;
                this.uploadedFiles = undefined;
                break;
            case 'Edit':
                this.editRecId = row.Id;
                break;
            default:
        }

    }
    // Accepted file formats
    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }
    // Preview mode for the file uploaded
    handleFilePreview(event) {
        let previewId = event.target.getAttribute('data-id');
        this.currentRecId = previewId;
        this.isPreview = true;
    }
    // Delete functionality for the files
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
    // Confirmation on the file being uploaded
    handleSubmit(event) {
        event.preventDefault();
        //this.template.querySelector("[data-field='Edit']").submit(event.detail.fields);
        this.template.querySelector('lightning-record-edit-form').submit(event.detail.fields);
        this.isPreview = false;

        this.dispatchEvent(new ShowToastEvent({
            title: 'Success!',
            message: ' File content updated.',
            variant: 'success'
        }));
    }
    // Logic for successful uploading of the fiels
    handleSuccess(event) {
        var description = event.detail.fields.Description;

        for (let i = 0; i < this.files.length; i++) {
            if (this.files[i].Id === this.currentRecId) {
                this.files[i].Description = description.value;
            }
        }
    }
    // Logic for the Save button and display the child on the row selections
    handleRowSelection(event) {

        var ela = this.template.querySelectorAll('lightning-datatable');
        this.selectedMapVar = [];
        for (let i = 0; i < ela.length; i++) {
            if (ela[i].getSelectedRows().length > 0) {
                ela[i].data.forEach(val => {
                    //console.log('this.val--> '+JSON.stringify(val));
                    if (ela[i].getSelectedRows().find(val1 => { return val1.Name == val.Name }) != undefined) {
                        if (this.selectedMapVar.find(val2 => { return val2.Name == val.Name }) == undefined) {
                            this.selectedMapVar.push(val);
                        }
                    }
                })
            }
        }
        console.log('this.tempSelectedMap--> ' + JSON.stringify(this.selectedMapVar));
        fireEvent(this.pageRef, 'detailPageMessage', this.selectedMapVar);
        //console.log('FINAL--> '+JSON.stringify(this.mapValues));
    }

    handleClickSave() {
        console.log('Store record id --> ' + this.recordIdFromState);
        var urlDecoded = decodeURIComponent(window.location.href);
        console.log('URL decoded --> ' + urlDecoded);
        //console.log('calloutinput --> '+JSON.stringify(this.selectedMapVar).replace(/__c/g,""));
        saveRecords({ json: JSON.stringify(this.selectedMapVar).replace(/__c/g, ""), saveStoreId: this.recordIdFromState, recordType: this.typeOfNnc, sUrl: urlDecoded }).then(res => {
            console.log('callout --> ' + JSON.stringify(res));
            refreshApex(this.data);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Compliance items successfully saved',
                    variant: 'success',
                }),
            );
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: res,
                    objectApiName: 'Non_Compliance__c',
                    actionName: 'view'
                },
            });
        })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error while saving the compliance items',
                        variant: 'error',
                    }),
                );
                console.log('callout error --> ' + JSON.stringify(error));
            });

    }
    handleUploadFinished(event) {
        // Get the list of uploaded files
        this.uploadedFiles = event.detail.files;
        //const uploadedFiles = event.detail.files;
        let uploadedFileNames = '';
        for (let i = 0; i < this.uploadedFiles.length; i++) {
            if (uploadedFileNames == '') {
                uploadedFileNames = this.uploadedFiles[i].name;
            } else {
                uploadedFileNames = uploadedFileNames + ',' + this.uploadedFiles[i].name;
            }
        }
        for (let index = 0; index < this.uploadedFiles.length; index++) {
            if ({}.hasOwnProperty.call(this.uploadedFiles, index)) {
                this.files = [...this.files, {
                    Id: this.uploadedFiles[index].documentId,
                    name: this.uploadedFiles[index].name,
                    src: url + this.uploadedFiles[index].documentId,
                    description: ''
                }];
            }
        }
        console.log(" Files-- > ", JSON.stringify(this.files));
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: this.uploadedFiles.length + ' File(s) uploaded Successfully: ' + uploadedFileNames,
                variant: 'success',
            }),
        );
    }
}