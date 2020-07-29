window.kit = (function Collection(kit) {

	var addElement = function(collection, element, key) {
		var index = collection.findIndex(function(ele) {
			return ele[key] === element[key];
		});

		if(index !== -1) {
			collection[index] = element;
		} else {
			collection.push(element);
		}

		return collection;
	};

	var removeElement = function(collection, element, key) {
		var index = collection.findIndex(function(ele) {
			return ele[key] === element[key];
		});

		if(index !== -1) {
			collection.splice(index, 1);
		}

		return collection;
	}

	kit.collection = {
		addElement: addElement,
		removeElement: removeElement
	};

	return kit;
})(window.kit || {});
