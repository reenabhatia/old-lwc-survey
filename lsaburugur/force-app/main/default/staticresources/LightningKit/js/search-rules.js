window.acumen = (function SearchRules(acumen) {

	var searchRules = [
		{
			name: 'name',
			label: 'Name',
			type: 'text',
			pattern: '',
			errorMessage: ''
		},
		{
			name: 'phone',
			label: 'Phone',
			type: 'text',
			pattern: '',
			errorMessage: ''
		},
		{
			name: 'email',
			label: 'Email',
			type: 'text',
			pattern: '',
			errorMessage: ''
		}
	];

	acumen.searchRules = searchRules;

	return acumen;
})(window.acumen || {});
