function getTabOrder(name) {
	if (name === "Status") return 1;
	if (name === "MC") return 2;
	if (name === "Избранное") return 3;
	return 100 + name.charCodeAt(0);
}

function resolveTabDisplayName(name) {
	if (name.indexOf(".") !== -1) {
		var parts = name.split(".");
		if (State.splitAdminTabs && parts[0] === "Admin") return parts[1];
		return parts[0];
	}
	return name;
}

function createStatusTab(name) {
	var display = resolveTabDisplayName(name);
	if (display.trim() === "") return;
	if (document.getElementById("tab-" + display)) return;
	if (!State.verbTabs.includes(display) && !State.permanentTabs.includes(display)) return;

	var btn = el("button", "tab-btn");
	btn.id = "tab-" + display;
	btn.textContent = display;
	btn.style.order = getTabOrder(display);
	if (display === "Избранное") btn.classList.add("tab-fav");
	btn.onclick = function() {
		tab_change(display);
		this.blur();
	};

	var spacerEl = document.getElementById("tab-bar-spacer");
	if (spacerEl) {
		tabBar.insertBefore(btn, spacerEl);
	} else {
		tabBar.appendChild(btn);
	}
	SendTabToByond(display);
	spacer.style.height = tabBar.offsetHeight + "px";
}

function removeStatusTab(name) {
	var btn = document.getElementById("tab-" + name);
	if (!btn || State.permanentTabs.includes(name)) return;
	for (var i = State.verbTabs.length - 1; i >= 0; --i) {
		if (State.verbTabs[i] === name) State.verbTabs.splice(i, 1);
	}
	btn.parentNode.removeChild(btn);
	TakeTabFromByond(name);
	spacer.style.height = tabBar.offsetHeight + "px";
}

function addPermanentTab(name) {
	if (!State.permanentTabs.includes(name)) State.permanentTabs.push(name);
	createStatusTab(name);
}

function removePermanentTab(name) {
	for (var i = State.permanentTabs.length - 1; i >= 0; --i) {
		if (State.permanentTabs[i] === name) State.permanentTabs.splice(i, 1);
	}
	removeStatusTab(name);
}

function checkStatusTab() {
	var children = tabBar.children;
	for (var i = children.length - 1; i >= 0; i--) {
		var child = children[i];
		if (child.id === "tab-search-btn" || child.id === "tab-bar-spacer" || child.id === "settings-gear-btn") continue;
		var tabName = child.id.replace("tab-", "");
		if (!State.verbTabs.includes(tabName) && !State.permanentTabs.includes(tabName)) {
			tabBar.removeChild(child);
		}
	}
}

function tab_change(tab) {
	_settingsActive = false;
	if (tab === State.currentTab) return;
	var oldBtn = document.getElementById("tab-" + State.currentTab);
	if (oldBtn) oldBtn.classList.remove("active");
	State.currentTab = tab;
	set_byond_tab(tab);
	var newBtn = document.getElementById("tab-" + tab);
	if (newBtn) newBtn.classList.add("active");
	closeGlobalSearch();
	invalidateRenderers();
	renderCurrentTab();
	byond_winset({ "statbrowser.is-visible": "true" });
}

function set_byond_tab(tab) {
	send_byond_command("Set-Tab " + tab);
}

function SendTabsToByond() {
	var tabs = [].concat(State.permanentTabs, State.verbTabs);
	for (var i = 0; i < tabs.length; i++) SendTabToByond(tabs[i]);
}

function SendTabToByond(tab) {
	send_byond_command("Send-Tabs " + tab);
}

function TakeTabFromByond(tab) {
	send_byond_command("Remove-Tabs " + tab);
}

window.onresize = function() {
	spacer.style.height = tabBar.offsetHeight + "px";
};

if (window.ResizeObserver) {
	new ResizeObserver(function() {
		spacer.style.height = tabBar.offsetHeight + "px";
	}).observe(tabBar);
}
