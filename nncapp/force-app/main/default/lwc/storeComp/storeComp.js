import { LightningElement,api,wire,track} from 'lwc';
/*import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { publish,subscribe,unsubscribe,createMessageContext,releaseMessageContext } from 'lightning/messageService';
import storeChannel from "@salesforce/messageChannel/StoreChannel__c";*/
import { NavigationMixin } from 'lightning/navigation';
import getIssuesNew from '@salesforce/apex/GetComplianceIssues.getIssuesNew';


export default class StoreComp extends NavigationMixin(LightningElement) {
    @track data;
    @track error;
    @wire(getIssuesNew) wiredComplainceIssues(result) {
        this.data = result;
        if(result.data){
            localStorage.setItem('name','Chris');
            console.log(localStorage.getItem('name'));
        for(var key in result.data.storeRelatedIds){
            console.log('Key --> '+key);
            console.log(result.data.storeRelatedIds[key].split(";"));
        }
    }else if(result.error){
        console.log(JSON.stringify(result.error));
    }
    } 
}