window.kit = (function AppContext(kit, window) {

	var hasLightning = function() {
		return window.$A
	};

	var isMobile = function() {
		var userAgent = window.navigator.userAgent.toLowerCase();
		return (-1 != userAgent.indexOf('mobile'));
	};

	var isSalesforce = function() {
		return !!window.Sfdc;
	};

	var isLightningForVisualForce = function() {
		return hasLightning() && isVisualforce();
	};

	var isSalesforceOne = function() {
		return hasLightning() && isMobile();
	};

	var isVisualforce = function() {
		return isSalesforce() && !window.Sfdc.canvas;
	};

	var isServiceConsole = function() {
		return window.sforce && window.sforce.console && window.sforce.console.isInConsole();
	};

	var isLightningExperience = function() {
		return hasLightning() && !isMobile() && !isVisualforce();
	};

	var guess = function() {
		var ctx;
		if(isServiceConsole()) {
			ctx = 'console';
		} else if(isLightningForVisualForce()) {
			ctx = 'lc4vf';
		} else if(isVisualforce()) {
			ctx = 'vf';
		} else if(isLightningExperience()) {
			ctx = 'lex';
		} else if(isSalesforceOne()) {
			ctx = 'sf1';
		}
		return ctx;
	};

	kit.context = {
		guess: guess,
		isMobile: isMobile,
		isSalesforce: isSalesforce,
		isLightningForVisualForce: isLightningForVisualForce,
		isSalesforceOne: isSalesforceOne,
		isLightningExperience: isLightningExperience,
		isVisualforce: isVisualforce,
		isServiceConsole: isServiceConsole
	};

	return kit;
})(window.kit || {}, window);
