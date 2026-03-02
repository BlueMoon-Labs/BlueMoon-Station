// Автоскролл
(function () {
	'use strict';

	var KEY = 'bm_prefs_scroll';
	var RESTORE_TIMEOUT_MS = 2000;

	function store(y) {
		var s = String(y | 0);
		try { localStorage.setItem(KEY, s); } catch (_) {}
		try { sessionStorage.setItem(KEY, s); } catch (_) {}
	}

	function recall() {
		var v;
		try { v = localStorage.getItem(KEY); } catch (_) { v = null; }
		if (v == null) {
			try { v = sessionStorage.getItem(KEY); } catch (_) { v = null; }
		}
		if (v == null) {
			try {
				var m = (window.name || '').match(/bm_prefs_scroll=(\d+)/);
				if (m) v = m[1];
			} catch (_) {}
		}
		var n = parseInt(v, 10);
		return (n > 0) ? n : 0;
	}

	function getScroll() {
		return window.pageYOffset
			|| (document.documentElement && document.documentElement.scrollTop)
			|| (document.body && document.body.scrollTop)
			|| 0;
	}

	function setScroll(y) {
		window.scrollTo(0, y);
		if (document.documentElement) document.documentElement.scrollTop = y;
		if (document.body) document.body.scrollTop = y;
	}

	var rafPending = false;

	function saveImmediate() {
		rafPending = false;
		store(getScroll());
	}

	function saveOnScroll() {
		if (!rafPending) {
			rafPending = true;
			(window.requestAnimationFrame || setTimeout)(saveImmediate);
		}
	}

	function restore() {
		var target = recall();
		if (target <= 0) return;

		var deadline = Date.now() + RESTORE_TIMEOUT_MS;
		var raf = window.requestAnimationFrame
			|| function (fn) { setTimeout(fn, 16); };

		(function attempt() {
			setScroll(target);

			var actual = getScroll();
			if (actual >= target - 1 || Date.now() >= deadline) {
				return;
			}

			raf(attempt);
		})();
	}

	document.addEventListener('scroll', saveOnScroll, { passive: true });

	document.addEventListener('mousedown', saveImmediate);
	document.addEventListener('touchstart', saveImmediate, { passive: true });

	document.addEventListener('keydown', function (e) {
		var k = e.keyCode || e.which;
		if (k === 13 /* Enter */ || k === 32 /* Space */) saveImmediate();
	});

	window.addEventListener('beforeunload', saveImmediate);
	window.addEventListener('pagehide', saveImmediate);
	window.addEventListener('visibilitychange', function () {
		if (document.hidden) saveImmediate();
	});

	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', restore);
	} else {
		restore();
	}
})();
