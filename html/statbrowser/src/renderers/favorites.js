function draw_favorites() {
	statcontent.textContent = "";

	if (!hasFavorites()) {
		var msg = el("div", "fav-empty-msg", "ПКМ по любой команде чтобы добавить в избранное");
		statcontent.appendChild(msg);
		return;
	}

	var byCategory = {};

	for (var key in State.favorites) {
		if (!State.favorites.hasOwnProperty(key)) continue;
		var fav = State.favorites[key];
		if (!byCategory[fav.cat]) byCategory[fav.cat] = [];
		byCategory[fav.cat].push(fav);
	}

	for (var cat in byCategory) {
		if (!byCategory.hasOwnProperty(cat)) continue;
		var displayCat = resolveTabDisplayName(cat);
		var header = el("div", "verb-sub-header", displayCat);
		statcontent.appendChild(header);

		var catGrid = el("div", "verb-grid");
		var favs = byCategory[cat];
		for (var i = 0; i < favs.length; i++) {
			var fav = favs[i];
			var pill = el("a", "verb-pill favorited");
			pill.href = "#";
			pill.textContent = fav.verb;
			pill.onclick = makeVerbOnclick(fav.verb);
			pill.oncontextmenu = (function(c, v) {
				return function(e) {
					e.preventDefault();
					toggleFavorite(c, v);
				};
			})(fav.cat, fav.verb);
			catGrid.appendChild(pill);
		}
		statcontent.appendChild(catGrid);
	}
}
