({
	createSite : function(component, event, helper) {
		var recordId = component.get("v.recordId");	
        var action = component.get("c.callAtlasCreateSite");
        action.setParams({ oppId : recordId });

        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var responseObject = response.getReturnValue();
                //assemble the message
                var message = '';
                if(responseObject.isSuccess) {
                	message = responseObject.successMessage;	    
                }
                else {
                    message = 'Error creating Site: ' + responseObject.errorMessage;    
                }
                component.set('v.message', message);
                component.set('v.loaded', true);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	}})