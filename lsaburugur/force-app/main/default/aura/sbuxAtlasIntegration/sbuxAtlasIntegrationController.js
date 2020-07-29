({
	init : function(component, event, helper) {
		var recordId = component.get("v.recordId");	
        var componentAction = component.get("v.action");
        if(componentAction==='createSite') {
            var action = component.get("c.callSitePreRequisites");
            action.setParams({ oppId : recordId });
            
            // Create a callback that is executed after 
            // the server-side action returns
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //If complete, then execute the callout to Atlas
                    var responseObject = response.getReturnValue();
                    var message;
                    if(responseObject.isSuccess) {
                        helper.createSite(component, event, helper);	    
                    }
                    else {
                        message = 'Error creating Site please contact an administrator: ' + responseObject.errorMessage;
                        component.set('v.message', message);
                		component.set('v.loaded', true);
                    }
                }
                else if (state === "INCOMPLETE") {
                    // do something
                }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    var message;
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            message = ("Error creating site: " + errors[0].message);
                        }
                    } else {
                        message = ("Unknown error please contact an administrator");
                    }
                    component.set('v.message', message);
                	component.set('v.loaded', true);
                }
            });
    
            $A.enqueueAction(action);
        }
        if(componentAction==='deactivateSite') {
            var action = component.get("c.callAtlasDeactivateSite");
            action.setParams({ oppId : recordId });
            
            // Create a callback that is executed after 
            // the server-side action returns
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var message;
                    var responseObject = response.getReturnValue();
                	if(responseObject.isSuccess) {
                        message = 'Site deactivated successfully in Atlas';	    
                    }
                    else {
                        message = 'Error deactivating site: ' + responseObject.errorMessage;
                    }
                    component.set('v.message', message);
                	component.set('v.loaded', true);
                }
                else if (state === "INCOMPLETE") {
                    // do something
                }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    var message;
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            message = ("Error deactivating site please contact an administrator: " + errors[0].message);
                        }
                    } else {
                        message = ("Unknown error please contact an administrator");
                    }
                    component.set('v.message', message);
                	component.set('v.loaded', true);
                }
            });
    
            $A.enqueueAction(action);
        }
	}
})