// Preserves scroll position in BYOND browser windows across content refreshes.
// Loaded only for the character preferences browser.
(function () {
	'use strict';

	var KEY = 'bm_prefs_scroll';

	function getScrollTop() {
		return (document.documentElement && document.documentElement.scrollTop) || document.body.scrollTop || 0;
	}

	function setScrollTop(y) {
		try {
			if (document.documentElement) document.documentElement.scrollTop = y;
			if (document.body) document.body.scrollTop = y;
			window.scrollTo(0, y);
		} catch (e) {
			// ignore
		}
	}

	function save() {
		var y = getScrollTop();
		try {
			if (window.sessionStorage) {
				window.sessionStorage.setItem(KEY, String(y));
				return;
			}
		} catch (e) {
			// fallback
		}
		try {
			window.name = KEY + '=' + String(y);
		} catch (e2) {
			// ignore
		}
	}

	function load() {
		var stored = null;
		try {
			if (window.sessionStorage) stored = window.sessionStorage.getItem(KEY);
		} catch (e) {
			stored = null;
		}

		if (stored == null) {
			try {
				var m = (window.name || '').match(new RegExp(KEY + '=(\\d+)'));
				if (m) stored = m[1];
			} catch (e2) {
				stored = null;
			}
		}

		var y = parseInt(stored, 10);
		if (!isNaN(y) && y > 0) {
			// Delay until layout has settled.
			setTimeout(function () { setScrollTop(y); }, 0);
		}
	}

	try {
		load();
		window.onscroll = save;
		window.onbeforeunload = save;
		window.onunload = save;
	} catch (e) {
		// ignore
	}
})();
