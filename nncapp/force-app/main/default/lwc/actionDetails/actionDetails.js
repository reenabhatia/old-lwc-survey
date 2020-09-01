import { LightningElement, wire, track } from 'lwc';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getActionItems from '@salesforce/apex/GetComplianceIssues.getActionItems';

export default class ActionDetails extends LightningElement {
    // Variables declarations
    @wire(CurrentPageReference) pageRef;
    @track showComp = false;
    @track resultData = [];
    @track actionsData;
    @track error;
    @track actionsDataVal = [];
    @track values = [];
    @track finalActionItems = [];
    @track tempResultData;
    @track valuesArr = [];
    @track approvedClicked = false;
    @track refreshAct=false;
    connectedCallback() {
        registerListener('detailPageMessage', this.handleMessage, this);
        registerListener('approveDetail', this.handleApprove, this);
        
    }
    // Get the state from the URl
    get viewStatusFromState() {

        let url = window.location.href;
        let nURL = new URL(url).searchParams;
        //console.log('id ===> ' + JSON.stringify(newURL));
        return nURL.get('c__mode');

    }
    //Get the store id from the URl
    get recordIdFromState() {

        let cURL = window.location.href;
        let newURL = new URL(cURL).searchParams;
        //console.log('id ===> ' + JSON.stringify(newURL));
        return newURL.get('c__storeId');

    }
    // Listener for the approve message to make the page uneditable
    handleApprove(data) {
        var eleChckBoxes = this.template.querySelectorAll('[data-id="checkbox"]');
        for (let i = 0; i < eleChckBoxes.length; i++) {
            eleChckBoxes[i].classList.add('dynamicDisableCheckBox');

        }
        this.approvedClicked = true;
        //console.log('Disable child');
    }
    // Rendered callback to make the page uneditable
    renderedCallback() {
        console.log('child rendered');
        if (this.approvedClicked == true && this.viewStatusFromState == 'View') {
            var eleChckBoxes = this.template.querySelectorAll('[data-id="checkbox"]');
            for (let i = 0; i < eleChckBoxes.length; i++) {
                eleChckBoxes[i].classList.add('dynamicDisableCheckBox');

            }
        }
    }
    get decodeUrl() {
        return decodeURIComponent(window.location.href);
    }
    // Get all the recommended actions from server
    @wire(getActionItems,{storeId: '$recordIdFromState',viewUrl: '$decodeUrl'}) wiredActionItems(result) {

        this.actionsData = result;
        if (result.data) {
            //this.actionsDataVal = result.data;
            //result.data.forEach(val => {
                for (var key in result.data){
                //this.actionsDataVal.push({ Issue__c: val.Issue__r.Long_Description__c, Action_Items__c: val.Additional_Recommended_Actions__c });
                this.actionsDataVal.push({ Issue__c: key, Action_Items__c: result.data[key] });
                }
            //})
            console.log(JSON.stringify(this.actionsDataVal));
            //if (this.refreshAct == false) {
                fireEvent(this.pageRef, 'actionitemsloaded', true);
            //}
        } else if (result.error) {
            this.error = result.error;
        }
        //refreshApex(this.actionsData);
    }
    // Logic on the check-boxes selections
    handleChange(event) {
        console.log('handlechange-- >' + JSON.stringify(event.detail));
        //this.tempResultData =[{...this.resultData}];

        var eleChckBox = this.template.querySelectorAll('[data-id="checkbox"]');
        this.actionsDataVal.forEach(val => {
            this.valuesArr = [];
            val.Action_Items__c.split(";").forEach(val1 => {
                if (event.detail.value.includes(val1)) {
                    this.valuesArr.push(val1);
                }
            })
            if (this.valuesArr.length > 0 && this.resultData.findIndex(v => (v.name == val.Issue__c)) > -1) {
                if (this.finalActionItems.findIndex(v1 => v1.name == val.Issue__c) > -1) { this.finalActionItems.splice(this.finalActionItems.findIndex(v1 => v1.name == val.Issue__c), 1) };
                this.finalActionItems.push({ name: val.Issue__c, items: this.valuesArr.join(";") });
                //console.log('IF--- '+val.Issue__c);
            } else if (this.resultData.findIndex(v => (v.name == val.Issue__c)) > -1 && this.finalActionItems.findIndex(v => (v.name == val.Issue__c)) == -1) {
                this.finalActionItems.push({ name: val.Issue__c, items: val.Action_Items__c });
                //console.log('ELSE--- '+val.Issue__c);
                //console.log('ELSE refresh-- >'+JSON.stringify(this.finalActionItems));
            }

        });
        for (let i = 0; i < eleChckBox.length; i++) {
            if (eleChckBox[i].value.length == 0) {
                this.finalActionItems.filter(el => el.name == eleChckBox[i].name).forEach(fVar => {

                    fVar.items = "";
                    //console.log('fVar-->' +fVar.items);
                })
            }
        }

        console.log('After refresh-- >' + JSON.stringify(this.finalActionItems));
        fireEvent(this.pageRef, 'actionitemspage', this.finalActionItems);
    }
    // Logic for the pre-select the datas
    handleMessage(data) {
        //var data=[{"Compliance__c":"a003t00000imQ1KAAU","Id":"a023t00000bghbzAAA","Name":"Scheduling Issue","Status__c":"Open","Comments__c":" Issue refreshed "}];
        this.resultData = [];
        if (data.length > 0) {
            this.showComp = true;
        } else {
            this.showComp = false;
        }
        //console.log('Handle checkbox-- >');
        data.forEach(val => {
            let valArr = [];
            if (this.resultData.find(val1 => { return val1.name == val.Name }) == undefined) {
                //console.log('Handle val.Name-- >'+val.Name);
                this.actionsDataVal.forEach(valueParent => {
                    if (val.Name == valueParent.Issue__c) {
                        if (valueParent.Action_Items__c.includes(";")) {
                            valueParent.Action_Items__c.split(";").forEach(valA => {
                                valArr.push({ 'actionVal': valA });
                                this.values.push(valA);
                            })

                        }
                        else {
                            valArr.push({ 'actionVal': valueParent.Action_Items__c });
                            this.values.push(valueParent.Action_Items__c);
                        }
                        this.resultData.push({ name: val.Name, items: valArr.map(values => { return { 'value': values.actionVal, 'label': values.actionVal } }) });
                    }
                })
                //this.resultData.push({name:val.Name,items:valArr.map(values => { return { 'value': values.Name, 'label': values.Name }})});
            }
        });
        //this.result=JSON.stringify(data);
        console.log('actionData --> ' + JSON.stringify(this.resultData));
        if(this.resultData.length==0){
            this.showComp = false;
        }

    }
}