({
	doInit : function(component, event, helper) {
		var action = component.get('c.getNNCDetails'); 
        action.setParams({
            "nonComplianceId" : component.get('v.recordId') 
        });
        action.setCallback(this, function(a){
            var state = a.getState();
            if(state == 'SUCCESS') {
                component.set('v.url', a.getReturnValue());
            }
        });
        $A.enqueueAction(action);
	},
    navigate : function(component, event, helper) {
        //var urlStr=component.get('v.url')+"&c__mode=View"
        var urlStr=component.get('v.url');
        //var str=$A.get("$Label.c.NNC")+"?c__storeId="+comp+"&c__mode=Edit"+"&c__type="+recordType;
        //var str1="&c__mode=View";
        //var str2=component.get('v.url')+encodeURIComponent(str1);
        //var uri = "https://www.google.com?"+encodeURIComponent("name=a0045&c_type=NNC");
        window.open(urlStr);
        //window.open(urlStr,"","location=0");
    }
})