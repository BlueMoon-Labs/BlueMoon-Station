function sortVerbs() {
	State.verbs.sort(function(a, b) {
		var sel = a[0] === b[0] ? 1 : 0;
		var av = a[sel].toUpperCase();
		var bv = b[sel].toUpperCase();
		if (av < bv) return 1;
		if (av > bv) return -1;
		return 0;
	});
}

function findVerbIndex(name, verblist) {
	for (var i = 0; i < verblist.length; i++) {
		if (verblist[i][1] === name) return i;
	}
	return -1;
}

function remove_verb(v) {
	for (var i = State.verbs.length - 1; i >= 0; i--) {
		if (State.verbs[i][1] === v[1]) State.verbs.splice(i, 1);
	}
}

function check_verbs() {
	for (var v = State.verbTabs.length - 1; v >= 0; v--) {
		verbs_cat_check(State.verbTabs[v]);
	}
}

function verbs_cat_check(cat) {
	var tabCat = resolveTabDisplayName(cat);
	if (!State.verbTabs.includes(tabCat)) {
		removeStatusTab(tabCat);
		return;
	}
	var found = false;
	for (var v = 0; v < State.verbs.length; v++) {
		var verbcat = resolveTabDisplayName(State.verbs[v][0]);
		if (verbcat === tabCat && verbcat.trim() !== "") {
			found = true;
			break;
		}
	}
	if (!found) {
		removeStatusTab(tabCat);
		if (State.currentTab === tabCat) tab_change("Status");
	}
}

function wipe_verbs() {
	State.verbs = [];
	State.verbTabs = [];
	checkStatusTab();
}

function update_verbs() {
	wipe_verbs();
	send_byond_command("Update-Verbs");
}

function loadFavorites() {
	try {
		var stored = serverStorage.getItem("statbrowser_favorites");
		if (stored) State.favorites = JSON.parse(stored);
	} catch (e) {}
	updateFavoritesTab();
}

function saveFavorites() {
	try {
		serverStorage.setItem("statbrowser_favorites", JSON.stringify(State.favorites));
	} catch (e) {}
}

function toggleFavorite(category, verbName) {
	var key = category + ":" + verbName;
	if (State.favorites[key]) {
		delete State.favorites[key];
	} else {
		State.favorites[key] = { cat: category, verb: verbName };
	}
	saveFavorites();
	updateFavoritesTab();
	if (State.currentTab === "Избранное" || State.verbTabs.includes(State.currentTab)) {
		renderCurrentTab();
	}
}

function isFavorite(category, verbName) {
	return !!State.favorites[category + ":" + verbName];
}

function hasFavorites() {
	for (var k in State.favorites) {
		if (State.favorites.hasOwnProperty(k)) return true;
	}
	return false;
}

function updateFavoritesTab() {
	if (hasFavorites()) {
		if (!State.permanentTabs.includes("Избранное")) {
			addPermanentTab("Избранное");
		}
	} else {
		if (State.permanentTabs.includes("Избранное")) {
			removePermanentTab("Избранное");
			if (State.currentTab === "Избранное") tab_change("Status");
		}
	}
}
