var rp_els = {};

function rp_ensureSkeleton() {
	if (rp_els.table && rp_els.table.parentNode) return;

	rp_els.header = makeSectionHeader("readyplayers", "Готовые игроки", st_sections);
	rp_els.summary = el("div", "readyplayers-summary");
	rp_els.header.appendChild(rp_els.summary);
	rp_els.header._toggle = function() {
		rp_els.wrap.style.display = st_sections.readyplayers ? "" : "none";
	};
	st_skeleton.appendChild(rp_els.header);

	rp_els.wrap = el("div");
	rp_els.table = el("table", "data-table readyplayers-table");
	var thead = el("thead");
	var headRow = el("tr");
	headRow.appendChild(el("th", "readyplayers-col-num", "#"));
	headRow.appendChild(el("th", null, "Персонаж"));
	thead.appendChild(headRow);
	rp_els.table.appendChild(thead);
	rp_els.tbody = el("tbody");
	rp_els.table.appendChild(rp_els.tbody);
	rp_els.wrap.appendChild(rp_els.table);

	rp_els.empty = el("div", "readyplayers-empty", "Никто ещё не готов.");
	rp_els.empty.style.display = "none";
	rp_els.wrap.appendChild(rp_els.empty);

	st_skeleton.appendChild(rp_els.wrap);
}

function draw_readyplayers() {
	rp_ensureSkeleton();

	var visible = State.readyPlayersVisible;
	rp_els.header.style.display = visible ? "" : "none";
	rp_els.wrap.style.display = visible && st_sections.readyplayers ? "" : "none";

	var players = State.readyPlayers || [];
	setText(rp_els.summary, players.length > 0 ? " (" + players.length + ")" : "");
	rp_els.empty.style.display = players.length > 0 ? "none" : "";
	rp_els.table.style.display = players.length > 0 ? "" : "none";

	var hash = JSON.stringify(players);
	if (rp_els.tbody._lastHash === hash) return;
	rp_els.tbody._lastHash = hash;
	rp_els.tbody.textContent = "";

	for (var i = 0; i < players.length; i++) {
		var tr = el("tr");
		tr.appendChild(el("td", "readyplayers-col-num", "" + (i + 1)));
		tr.appendChild(el("td", "readyplayers-name", players[i]));
		rp_els.tbody.appendChild(tr);
	}
}
