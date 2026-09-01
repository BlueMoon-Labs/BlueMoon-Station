var pixelRatio = window.devicePixelRatio || 1;
var statbrowserBaseZoom = pixelRatio !== 1 ? (100 / pixelRatio) : 100;
var statbrowserUserZoom = 1;
var zoomHideTimer = null;
var zoomPersistTimer = null;

function clampZoom(value) {
	return Math.min(2.0, Math.max(0.5, value));
}

function applyZoom() {
	document.body.style.zoom = (statbrowserBaseZoom * statbrowserUserZoom) + "%";
}

function showZoomIndicator() {
	zoomIndicator.textContent = "Scale: " + Math.round(statbrowserUserZoom * 100) + "%";
	zoomIndicator.style.opacity = "1";
	clearTimeout(zoomHideTimer);
	zoomHideTimer = setTimeout(function() {
		zoomIndicator.style.opacity = "0";
	}, 1200);
}

function scheduleZoomPersist() {
	clearTimeout(zoomPersistTimer);
	zoomPersistTimer = setTimeout(function() {
		byond_topic(
			"?src=_statpanel_;statbrowser_zoom_save=1;zoom_value="
			+ encodeURIComponent(String(statbrowserUserZoom))
		);
	}, 200);
}

function set_zoom_pref(value) {
	var parsed = Number(value);
	if (!isFinite(parsed) || parsed <= 0) return;
	statbrowserUserZoom = clampZoom(parsed);
	applyZoom();
}

function updateZoom(delta) {
	statbrowserUserZoom = clampZoom(Math.round((statbrowserUserZoom + delta) * 100) / 100);
	applyZoom();
	scheduleZoomPersist();
	showZoomIndicator();
}

window.addEventListener("wheel", function(event) {
	if (!event.ctrlKey) return;
	var direction = Math.sign(event.deltaY);
	if (!direction) return;
	event.preventDefault();
	updateZoom(direction < 0 ? 0.1 : -0.1);
}, { passive: false });

applyZoom();

