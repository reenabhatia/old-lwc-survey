window.kit = (function Notifier(kit, $c) {

	var url = window.location.protocol+'//'+window.location.hostname+'/cometd/40.0/';
	var cometd;
	var subscriptions = [];

	var createConnection = function(sessionId, subscriptionOptions) {
		cometd.configure({
			url: url,
			requestHeaders: { Authorization: 'OAuth '+ sessionId},
			appendMessageTypeToURL : false
		});
		cometd.websocketEnabled = false;

		cometd.handshake(function(res) {
			if(res.successful) {
				createSubscriptions(subscriptionOptions);

			} else {
				console.error("Failed to connect to CometD");
			}
		});
	};

	var createSubscriptions = function(subscriptionOptions) {
		subscriptions = subscriptionOptions.map(function(sub) {
			return cometd.subscribe(sub.path, $A.getCallback(sub.callback));
		});
	};

	var disconnectCometD = function() {
		subscriptions.forEach(function(sub) {
			cometd.unsubscribe(sub);
		});
	};

	kit.notifier = {
		createConnection: createConnection,
	};

	var init = function() {
		cometd = cometd || new $c.CometD();

		window.addEventListener('unload', function(event) {
			disconnectCometD();
		});
	};

	init();

	return kit;
})(window.kit || {}, window.org.cometd);
