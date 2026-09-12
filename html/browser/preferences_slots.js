(function () {
	'use strict';

	function showCurrentSlot() {
		var list = document.getElementById('csetup-slot-list');
		if (!list) return;
		var current = list.querySelector('[aria-current="true"]');
		if (!current) return;
		// Прокручиваем только список, не сдвигая страницу редактора.
		if (current.offsetTop + current.offsetHeight > list.clientHeight) {
			list.scrollTop = current.offsetTop - (list.clientHeight - current.offsetHeight) / 2;
		}
	}

	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', showCurrentSlot);
	} else {
		showCurrentSlot();
	}
})();
