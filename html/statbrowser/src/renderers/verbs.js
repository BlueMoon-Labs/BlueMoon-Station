var verbSearchTimers = {};

function draw_verbs(cat) {
	statcontent.textContent = "";

	var searchInput = el("input", "verb-search");
	searchInput.type = "text";
	searchInput.placeholder = "Поиск команд...";
	searchInput.autocomplete = "off";
	statcontent.appendChild(searchInput);

	var container = el("div");
	statcontent.appendChild(container);

	function renderVerbsFiltered(query) {
		container.textContent = "";
		var grid = el("div", "verb-grid");
		var additions = {};
		sortVerbs();

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

			if (query && command.toLowerCase().indexOf(query) === -1) continue;

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

			(subCat ? additions[subCat] : grid).appendChild(pill);
		}

		container.appendChild(grid);

		for (var subKey in additions) {
			if (additions.hasOwnProperty(subKey)) {
				container.appendChild(el("div", "verb-sub-header", subKey));
				container.appendChild(additions[subKey]);
			}
		}

	}

	renderVerbsFiltered("");

	searchInput.oninput = function() {
		var val = this.value.toLowerCase();
		clearTimeout(verbSearchTimers[cat]);
		verbSearchTimers[cat] = setTimeout(function() {
			renderVerbsFiltered(val);
		}, 150);
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
