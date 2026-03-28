var globalSearchTimer = null;

function openGlobalSearch() {
	globalSearchOverlay.classList.add("visible");
	globalSearchBox.value = "";
	globalSearchBox.focus();
	renderGlobalSearchResults("");
}

function closeGlobalSearch() {
	globalSearchOverlay.classList.remove("visible");
	globalSearchBox.value = "";
	globalSearchResults.textContent = "";
}

function renderGlobalSearchResults(query) {
	globalSearchResults.textContent = "";
	query = query.toLowerCase().trim();
	if (!query) return;

	var byCategory = {};
	for (var i = 0; i < State.verbs.length; i++) {
		var part = State.verbs[i];
		var command = part[1];
		if (!command) continue;
		if (command.toLowerCase().indexOf(query) === -1) continue;
		var cat = resolveTabDisplayName(part[0]);
		if (!byCategory[cat]) byCategory[cat] = [];
		byCategory[cat].push(part);
	}

	for (var cat in byCategory) {
		if (!byCategory.hasOwnProperty(cat)) continue;
		globalSearchResults.appendChild(el("div", "search-cat-header", cat));
		var items = byCategory[cat];
		for (var j = 0; j < items.length; j++) {
			var item = el("a", "search-result-item", items[j][1]);
			item.href = "#";
			item.onclick = (function(cmd) {
				return function(e) {
					e.preventDefault();
					closeGlobalSearch();
					run_after_focus(function() {
						send_byond_command(cmd.replace(/\s/g, "-"));
					});
				};
			})(items[j][1]);
			globalSearchResults.appendChild(item);
		}
	}
}

globalSearchBox.oninput = function() {
	clearTimeout(globalSearchTimer);
	var val = this.value;
	globalSearchTimer = setTimeout(function() {
		renderGlobalSearchResults(val);
	}, 150);
};

globalSearchOverlay.onclick = function(e) {
	if (e.target === globalSearchOverlay) closeGlobalSearch();
};

document.addEventListener("keydown", function(e) {
	if (e.key === "Escape" && globalSearchOverlay.classList.contains("visible")) {
		closeGlobalSearch();
	}
});
