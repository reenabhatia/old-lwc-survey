({
	gotoAllFeedbacks: function(component, event, helper) {
        var pageReference = {
			type: "standard__objectPage",
			attributes: {
				objectApiName: "Feedback__c",
				actionName: "list"
			},
            state:{
                "filterName":"All"
            }
		};
		var navService = component.find("navService");
		event.preventDefault();
		navService.navigate(pageReference);
	},
    createNew: function(component, event, helper) {
		var createLinkedEvent = $A.get("e.force:createRecord");
		createLinkedEvent.setParams({
			entityApiName: "Feedback__c",
		});
        createLinkedEvent.fire();
    }
});