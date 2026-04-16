var verbSearchTimers = {};
// Per-tab last query, so re-render after data change can repopulate without losing user's filter.
var verbLastQuery = {};

function draw_verbs(cat) {
	statcontent.textContent = "";

	var searchInput = el("input", "verb-search");
	searchInput.type = "text";
	searchInput.placeholder = "Поиск команд...";
	searchInput.autocomplete = "off";
	if (verbLastQuery[cat]) searchInput.value = verbLastQuery[cat];
	statcontent.appendChild(searchInput);

	var container = el("div");
	statcontent.appendChild(container);
	sortVerbs();

	// Map of pill -> the query strings it matches. Built once per draw, then filtered by toggling
	// display:none. This avoids thrashing the entire DOM on every keystroke for admins with 200+
	// verbs, and preserves focus/selection in the search input.
	var pillIndex = [];

	function buildVerbDOM() {
		container.textContent = "";
		pillIndex = [];
		var grid = el("div", "verb-grid");
		var additions = {};
		var subHeaders = {};

		var resolvedCat = cat;
		if (State.splitAdminTabs && cat.lastIndexOf(".") !== -1) {
			var sp = cat.split(".");
			if (sp[0] === "Admin") resolvedCat = sp[1];
		}

		var reversed = State.verbs.slice().reverse();
		for (var i = 0; i < reversed.length; i++) {
			var part = reversed[i];
			var verbCat = part[0];
			if (State.splitAdminTabs && verbCat.lastIndexOf(".") !== -1) {
				var sp2 = verbCat.split(".");
				if (sp2[0] === "Admin") verbCat = sp2[1];
			}
			var command = part[1];
			if (!command) continue;
			if (verbCat.lastIndexOf(resolvedCat, 0) !== 0) continue;
			if (verbCat.length !== resolvedCat.length && verbCat.charAt(resolvedCat.length) !== ".") continue;

			var subCat = verbCat.lastIndexOf(".") !== -1 ? verbCat.split(".")[1] : null;
			if (subCat && !additions[subCat]) {
				additions[subCat] = el("div", "verb-grid");
			}

			var pill = el("a", "verb-pill");
			pill.href = "#";
			if (isFavorite(part[0], command)) pill.classList.add("favorited");
			pill.textContent = command;
			pill.onclick = makeVerbOnclick(command);
			pill.oncontextmenu = (function(verbCatOrig, cmd) {
				return function(e) {
					e.preventDefault();
					toggleFavorite(verbCatOrig, cmd);
				};
			})(part[0], command);

			pillIndex.push({ el: pill, sub: subCat, search: command.toLowerCase() });
			(subCat ? additions[subCat] : grid).appendChild(pill);
		}

		container.appendChild(grid);

		for (var subKey in additions) {
			if (additions.hasOwnProperty(subKey)) {
				var hdr = el("div", "verb-sub-header", subKey);
				container.appendChild(hdr);
				container.appendChild(additions[subKey]);
				subHeaders[subKey] = { hdr: hdr, grid: additions[subKey] };
			}
		}
		return subHeaders;
	}

	var subHeaders = buildVerbDOM();

	function applyFilter(query) {
		// Toggle visibility instead of re-rendering. Hide whole sub-header sections when empty.
		var subVisibleCount = {};
		for (var i = 0; i < pillIndex.length; i++) {
			var entry = pillIndex[i];
			var matches = !query || entry.search.indexOf(query) !== -1;
			entry.el.style.display = matches ? "" : "none";
			if (entry.sub && matches) {
				subVisibleCount[entry.sub] = (subVisibleCount[entry.sub] | 0) + 1;
			}
		}
		for (var subKey in subHeaders) {
			if (!subHeaders.hasOwnProperty(subKey)) continue;
			var visible = subVisibleCount[subKey] || 0;
			subHeaders[subKey].hdr.style.display = visible ? "" : "none";
			subHeaders[subKey].grid.style.display = visible ? "" : "none";
		}
	}

	if (verbLastQuery[cat]) applyFilter(verbLastQuery[cat]);

	searchInput.oninput = function() {
		var val = this.value.toLowerCase();
		verbLastQuery[cat] = val;
		clearTimeout(verbSearchTimers[cat]);
		verbSearchTimers[cat] = setTimeout(function() { applyFilter(val); }, 60);
	};
}

function makeVerbOnclick(command) {
	return function(e) {
		e.preventDefault();
		run_after_focus(function() {
			send_byond_command(command.replace(/\s/g, "-"));
		});
	};
}
