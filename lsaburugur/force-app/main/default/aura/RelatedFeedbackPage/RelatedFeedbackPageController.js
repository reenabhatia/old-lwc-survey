({
  doInit: function(component, event, helper) {
    var verifyLinkCreatibilty = component.get("c.isLinkCreatable");
    verifyLinkCreatibilty.setCallback(this, function(response) {
      var state = response.getState();
      //console.log("RK>>Resonse State for Link Creation : " + state);
      if (state == "SUCCESS") {
        //console.log("RK>>Resonse rcvd (Link): " + response.getReturnValue());
        component.set("v.userCanLink", response.getReturnValue());
      } else {
        console.log("failed with state (Link): " + state);
      }
    });

    var action = component.get("c.getLinkedFeedbacksId");
    action.setParams({ id: component.get("v.recordId") });
    action.setCallback(this, function(response) {
      var state = response.getState();
      console.log("RK>>Resonse State: " + state);
      if (state == "SUCCESS") {
        console.log("RK>>Resonse rcvd: " + response.getReturnValue());
        component.set("v.linkedFeedbacks", response.getReturnValue());
      } else {
        console.log("failed with state: " + state);
      }
    });
    $A.enqueueAction(verifyLinkCreatibilty);
    $A.enqueueAction(action);
  },

  handleClick: function(comp, event, helper) {
    //console.log("RK>>Generating URL...");
    var recordId = event.target.dataset.fbid;
    //console.log("RK>>" + recordId);
    var pageReference = {
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        objectApiName: "Feedback__c",
        actionName: "view"
      }
    };
    var navService = comp.find("navService");
    //console.log("RK>> navService " + navService);
    event.preventDefault();
    navService.navigate(pageReference);
  },

  createNewLink: function(cmp, event, helter) {
    var createLinkedEvent = $A.get("e.force:createRecord");
    createLinkedEvent.setParams({
      entityApiName: "Related_Feedback__c",
      defaultFieldValues: {
        Source_Feedback__c: cmp.get("v.recordId")
      },
      navigationLocation: "RELATED_LIST" //LOOKUP
    });
    createLinkedEvent.fire();
  }
});