var tabBarSpacer = document.createElement("div");
tabBarSpacer.id = "tab-bar-spacer";
tabBar.appendChild(tabBarSpacer);

var searchBtn = document.createElement("button");
searchBtn.id = "tab-search-btn";
searchBtn.innerHTML = SEARCH_ICON_SVG;
searchBtn.title = "Поиск команд (Ctrl+F или /)";
searchBtn.onclick = function() {
	if (globalSearchOverlay.classList.contains("visible")) {
		closeGlobalSearch();
	} else {
		openGlobalSearch();
	}
};
tabBar.appendChild(searchBtn);

var gearBtn = document.createElement("button");
gearBtn.id = "settings-gear-btn";
gearBtn.innerHTML = GEAR_ICON_SVG;
gearBtn.title = "Настройки темы";
gearBtn.onclick = function() {
	if (_settingsActive) {
		_settingsActive = false;
		renderCurrentTab();
	} else {
		draw_settings();
	}
};
tabBar.appendChild(gearBtn);

applyTheme(loadTheme());

function restoreFocus() {
	var tag = document.activeElement && document.activeElement.tagName;
	if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return;
	run_after_focus(function() {
		byond_winset({ "map.focus": "true" });
	});
}
document.addEventListener("mouseup", restoreFocus);
document.addEventListener("keyup", restoreFocus);

loadFavorites();

if (!State.currentTab) {
	addPermanentTab("Status");
	tab_change("Status");
}

window.onload = function() {
	NotifyByondOnload();
};

function NotifyByondOnload() {
	byond_winset({ command: "Panel-Ready" });
}

setTimeout(NotifyByondOnload, 500);
setTimeout(NotifyByondOnload, 1500);

function getCookie(cname) {
	var name = cname + "=";
	var ca = document.cookie.split(";");
	for (var i = 0; i < ca.length; i++) {
		var c = ca[i];
		while (c.charAt(0) === " ") c = c.substring(1);
		if (c.indexOf(name) === 0) return decodeURIComponent(c.substring(name.length, c.length));
	}
	return "";
}
