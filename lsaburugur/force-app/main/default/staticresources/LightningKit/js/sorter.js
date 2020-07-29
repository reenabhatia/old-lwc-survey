window.kit = (function Sort(kit) {

	var byString = function(collection, key) {
		return collection.sort(function(a, b) {
			return a[key] > b[key];
		});
	};

	kit.sorter = {
		byString: byString
	};

	return kit;
})(window.kit || {});
