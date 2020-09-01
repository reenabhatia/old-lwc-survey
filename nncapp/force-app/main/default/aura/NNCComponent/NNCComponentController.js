({
	doInit : function(component, event, helper) {
		
	},
    navigate : function(component, event, helper) {
        var navigateLightning = component.find('navigate');
        var pageReference = {
            type: 'standard__app',
            attributes: {
                 //componentName: 'c__NNCComponentIssues',
                 appTarget: "c__NNC",
            },
            state:{
        		c__storeId: component.get("v.recordId"),
    		}
        };
        //var appEvent = $A.get("e.c:NNCCompRecord"); 
        var comp = component.get("v.recordId");
        //window.postMessage(comp,'*');
        //console.log('comp--> '+comp);
        //appEvent.setParams({"message" : comp}); 
        //appEvent.fire(); 
        var defaultUrl = "#";
        var recordType;
        console.log('comp--> '+event.getSource().get("v.label"));
        if(event.getSource().get("v.label")=="Standard NNC"){
            recordType="NNC";
        }else if(event.getSource().get("v.label")=="Default NNC"){
            recordType="Default";
        }else if(event.getSource().get("v.label")=="Critical NNC"){
            recordType="Critical NNC";
        }
        /*navigateLightning.generateUrl(pageReference)
            .then($A.getCallback(function(url) {
                component.set("v.url", url? url : defaultUrl);
                //console.log('urlll--> '+url);
                window.open(url);
            }), $A.getCallback(function(error) {
                component.set("v.url", defaultUrl);
            }));*/
        //var urll=component.get("v.url");
        //console.log('URL--> '+urll);
        //var str="https://starbucksls--nxibmdev.lightning.force.com/lightning/n/NNC_App_Page"+"?c__storeId="+comp;
        var date=$A.localizationService.formatDate(new Date(), "MM/DD/YYYY");
        var str=$A.get("$Label.c.NNC")+"?c__storeId="+comp+"&c__mode=Edit"+"&c__type="+recordType+"&c__date="+date;
        //var str1="c__storeId="+comp+"&c__mode=Edit"+"&c__type="+recordType;
        //var str2=$A.get("$Label.c.NNC")+"?"+encodeURIComponent(str1);
        //var uri = "https://www.google.com?"+encodeURIComponent("name=a0045&c_type=NNC");
        window.open(str);
        //alert($A.localizationService.formatDate(new Date(), "MM/DD/YYYY"));
        //nagigateLightning.navigate(pageReference);
        //window.open(str,"null","width=900,height=750,toolbar=no,scrollbars=no,location=no,resizable =yes");
//window.moveTo(0,0);
//window.resizeTo(screen.width,screen.height-100);
        //self.close();
        /*var hide = ['c__type'];
	for(var h in hide) {
		if(helper.getURLParameter(h)) {
			history.replaceState(null, document.getElementsByTagName("title")[0].innerHTML, window.location.pathname);
		}
	}
        window.onload = hideURLParams;*/
    }
})