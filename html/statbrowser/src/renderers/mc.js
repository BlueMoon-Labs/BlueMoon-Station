var mc_skeleton = null;
var mc_els = {};
var mc_ss_rows = {};

function mc_ensureSkeleton() {
	if (mc_skeleton && mc_skeleton.parentNode) return;
	statcontent.textContent = "";
	mc_ss_rows = {};
	mc_skeleton = el("div", "mc-container");

	var serverHeader = makeSectionHeader("server", "Сервер", State.mcSections);
	mc_els.serverGrid = el("div", "metric-grid");
	serverHeader._toggle = function() {
		mc_els.serverGrid.style.display = State.mcSections.server ? "" : "none";
	};
	mc_skeleton.appendChild(serverHeader);
	mc_skeleton.appendChild(mc_els.serverGrid);

	var pingHeader = makeSectionHeader("ping", "Пинг и Сеть", State.mcSections);
	mc_els.pingTable = el("table", "data-table");
	mc_els.pingTable.style.display = State.mcSections.ping ? "" : "none";
	pingHeader._toggle = function() {
		mc_els.pingTable.style.display = State.mcSections.ping ? "" : "none";
		if (!State.mcSections.ping) mc_els.pingTable._lastHash = null;
	};
	mc_skeleton.appendChild(pingHeader);
	mc_skeleton.appendChild(mc_els.pingTable);

	var keyHeader = makeSectionHeader("key", "Ключевые", State.mcSections);
	mc_els.keySection = el("div", "mc-key-section");
	keyHeader._toggle = function() {
		mc_els.keySection.style.display = State.mcSections.key ? "" : "none";
		if (!State.mcSections.key) mc_els.keySection._lastHash = null;
	};
	mc_skeleton.appendChild(keyHeader);
	mc_skeleton.appendChild(mc_els.keySection);

	mc_els.ssHeader = makeSectionHeader("subsystems", "Подсистемы (" + State.mcSSData.length + ")", State.mcSections);
	mc_els.filterInput = el("input", "mc-filter");
	mc_els.filterInput.type = "text";
	mc_els.filterInput.placeholder = "Фильтр...";
	mc_els.filterInput.value = State.mcFilterText;
	mc_els.filterInput.oninput = function() {
		State.mcFilterText = this.value.toLowerCase();
		mc_applyFilter();
	};
	mc_els.ssHeader._toggle = function() {
		mc_els.ssTable.style.display = State.mcSections.subsystems ? "" : "none";
		mc_els.filterInput.style.display = State.mcSections.subsystems ? "" : "none";
	};
	mc_skeleton.appendChild(mc_els.ssHeader);
	mc_skeleton.appendChild(mc_els.filterInput);

	mc_els.ssTable = el("table", "mc-ss-table");
	var thead = el("thead");
	var hrow = el("tr");
	var cols = [
		{ label: "", col: SS_STATE, title: "Статус" },
		{ label: "Имя", col: SS_NAME, title: "Имя" },
		{ label: "ms", col: SS_COST, title: "Стоимость (ms)" },
		{ label: "Тик%", col: SS_TICK, title: "% тика" },
		{ label: "Лим%", col: SS_OVERRUN, title: "Перерасход" },
		{ label: "Тики", col: SS_TICKS, title: "Тики за цикл" },
		{ label: "#", col: SS_FIRED, title: "Запусков" }
	];
	for (var c = 0; c < cols.length; c++) {
		var th = el("th", "mc-th-sort", cols[c].label);
		th.title = cols[c].title;
		th.setAttribute("data-col", cols[c].col);
		th.onclick = function() {
			var col = parseInt(this.getAttribute("data-col"));
			if (State.mcSortCol === col) {
				State.mcSortAsc = !State.mcSortAsc;
			} else {
				State.mcSortCol = col;
				State.mcSortAsc = (col === SS_NAME);
			}
			mc_updateSortIndicators();
			mc_sortAndReorder();
		};
		hrow.appendChild(th);
	}
	thead.appendChild(hrow);
	mc_els.ssTable.appendChild(thead);
	mc_els.ssTbody = el("tbody");
	mc_els.ssTable.appendChild(mc_els.ssTbody);
	mc_skeleton.appendChild(mc_els.ssTable);

	statcontent.appendChild(mc_skeleton);
	mc_updateSortIndicators();
}

function mc_updateServerSection() {
	if (!mc_els.serverGrid) return;
	mc_els.serverGrid.textContent = "";
	if (!State.mcSections.server) return;
	var d = State.mcServerData;
	var hist = d.history || {};

	mc_els.serverGrid.appendChild(makeGridItem("XYZ", d.coords, false));
	var cpuItem = makeGridItem("CPU", d.cpu + "%", false, mcCpuClass(d.cpu));
	if (hist.cpu && hist.cpu.length > 1) {
		cpuItem.querySelector(".metric-value").appendChild(buildSparkline(hist.cpu, 0, 200, mcCpuClass(d.cpu)));
	}
	mc_els.serverGrid.appendChild(cpuItem);
	mc_els.serverGrid.appendChild(makeGridItem("Узлы", d.instances, false));

	var tidiItem = makeGridItem("TimeDilation",
		d.tidi_current + "% (" + d.tidi_avg_fast + "%, " + d.tidi_avg + "%, " + d.tidi_avg_slow + "%)",
		true, mcTidiClass(d.tidi_current));
	if (hist.tidi && hist.tidi.length > 1) {
		tidiItem.querySelector(".metric-value").appendChild(buildSparkline(hist.tidi, 0, 50, mcTidiClass(d.tidi_current)));
	}
	mc_els.serverGrid.appendChild(tidiItem);

	mc_els.serverGrid.appendChild(makeGridItem("BYOND",
		"FPS:" + d.fps + " | Тики:" + d.tick_count +
		" | Дрифт:" + d.tick_drift + "(" + d.tick_drift_pct + "%)" +
		" | Внутр.тик:" + d.internal_tick_usage + "%",
		true));
	mc_els.serverGrid.appendChild(makeGridItem("MC",
		"Rate:" + d.mc_tick_rate + " | Iter:" + d.mc_iteration + " | Лимит:" + d.mc_tick_limit,
		true, null, mcMakeVvLink(d.ref_master)));
	mc_els.serverGrid.appendChild(makeGridItem("Failsafe", d.failsafe_stat,
		true, null, d.ref_failsafe ? mcMakeVvLink(d.ref_failsafe) : null));
	mc_els.serverGrid.appendChild(makeGridItem("Камеры",
		d.camera_count + " | Чанки:" + d.camera_chunks,
		true, null, d.ref_cameranet ? mcMakeVvLink(d.ref_cameranet) : null));
	mc_els.serverGrid.appendChild(makeGridItem("Очистка",
		d.cleanup_last + "ms | Avg:" + d.cleanup_avg + "ms | Target:" + d.cleanup_target,
		true));

	var hist_ping = hist.ping || [];
	var pingLabel = "Пинг средний";
	var lastPing = hist_ping.length > 0 ? hist_ping[hist_ping.length - 1] : 0;
	var pingItem = makeGridItem(pingLabel, lastPing + "ms", false, pingClass(lastPing));
	if (hist_ping.length > 1) {
		pingItem.querySelector(".metric-value").appendChild(buildSparkline(hist_ping, 0, 300, pingClass(lastPing)));
	}
	mc_els.serverGrid.appendChild(pingItem);

	mc_els.serverGrid.appendChild(makeGridItem("GLOB", "VV",
		false, null, mcMakeVvLink(d.ref_glob)));
	mc_els.serverGrid.appendChild(makeGridItem("Config", "VV",
		false, null, mcMakeVvLink(d.ref_config)));
}

function mc_updatePingSection() {
	if (!mc_els.pingTable) return;
	if (!State.mcSections.ping) { mc_els.pingTable.textContent = ""; return; }
	var d = State.mcServerData;
	// MC iteration advances once per Master tick; same iteration means identical ping data.
	if (mc_els.pingTable._lastIter === State.mcIteration) return;
	mc_els.pingTable._lastIter = State.mcIteration;
	mc_els.pingTable.textContent = "";
	mc_els.pingTable.appendChild(mc_makeRow("RTT",
		"Сэмпл:" + d.ping_samples +
		" | Avg:" + d.ping_rtt_avg + "ms" +
		" | Max:" + d.ping_rtt_max + "ms" +
		" | AvgСр:" + d.ping_rtt_avg_avg + "ms"));
	mc_els.pingTable.appendChild(mc_makeRow("Тик/Сервер",
		"Тик Avg:" + d.ping_tick_avg + "ms" +
		" | Тик Max:" + d.ping_tick_max + "ms" +
		" | Серв Avg:" + d.ping_server_avg + "ms" +
		" | Серв Max:" + d.ping_server_max + "ms"));
	mc_els.pingTable.appendChild(mc_makeRow("Джиттер",
		"Raw:" + d.raw_mult +
		" | Last:" + d.jitter_last + "%" +
		" | Avg:" + d.jitter_avg + "%" +
		" | MaxОкно:" + d.jitter_max_wnd + "%" +
		" | Glide:" + d.glide_mult));
}

function mc_makeRow(label, value) {
	var tr = el("tr");
	tr.appendChild(el("td", "data-label", label));
	tr.appendChild(el("td", "data-value", value));
	return tr;
}

function mc_matchesFilter(name) {
	if (!State.mcFilterText) return true;
	return name.toLowerCase().indexOf(State.mcFilterText) !== -1;
}

function mc_applyFilter() {
	for (var name in mc_ss_rows) {
		mc_ss_rows[name].style.display = mc_matchesFilter(name) ? "" : "none";
	}
}

function mc_sortAndReorder() {
	var rows = [];
	for (var name in mc_ss_rows) rows.push(mc_ss_rows[name]);
	var col = State.mcSortCol;
	var asc = State.mcSortAsc;
	rows.sort(function(a, b) {
		var ad = a._ssData;
		var bd = b._ssData;
		if (ad[SS_CAN_FIRE] !== bd[SS_CAN_FIRE]) return bd[SS_CAN_FIRE] - ad[SS_CAN_FIRE];
		if (col === SS_NAME) {
			var av = ("" + ad[col]).toLowerCase();
			var bv = ("" + bd[col]).toLowerCase();
			return asc ? (av < bv ? -1 : av > bv ? 1 : 0)
					   : (bv < av ? -1 : bv > av ? 1 : 0);
		}
		var an = parseFloat(ad[col]) || 0;
		var bn = parseFloat(bd[col]) || 0;
		return asc ? (an - bn) : (bn - an);
	});
	for (var i = 0; i < rows.length; i++) {
		if (mc_els.ssTbody.childNodes[i] !== rows[i]) {
			mc_els.ssTbody.insertBefore(rows[i], mc_els.ssTbody.childNodes[i]);
		}
	}
}

function mc_updateSortIndicators() {
	if (!mc_els.ssTable) return;
	var ths = mc_els.ssTable.getElementsByTagName("th");
	for (var i = 0; i < ths.length; i++) {
		var col = parseInt(ths[i].getAttribute("data-col"));
		if (col === State.mcSortCol) {
			ths[i].className = "mc-th-sort mc-sorted" + (State.mcSortAsc ? "" : " desc");
		} else {
			ths[i].className = "mc-th-sort";
		}
	}
}

function mc_updateSSRows() {
	var seen = {};
	for (var i = 0; i < State.mcSSData.length; i++) {
		var row = State.mcSSData[i];
		var name = row[SS_NAME];
		seen[name] = true;
		var tr = mc_ss_rows[name];
		if (!tr) {
			tr = el("tr");
			for (var c = 0; c < 7; c++) tr.appendChild(el("td"));
			mc_ss_rows[name] = tr;
			mc_els.ssTbody.appendChild(tr);
		}
		var cells = tr.childNodes;
		var state_letter = STATE_LETTERS[row[SS_STATE]] || "?";
		var can_fire = row[SS_CAN_FIRE];

		setText(cells[0], state_letter);
		cells[0].className = "mc-state mc-state-" + row[SS_STATE];

		var link = tr._nameLink;
		if (!link) {
			cells[1].textContent = "";
			link = el("a");
			cells[1].appendChild(link);
			tr._nameLink = link;
		}
		var dname = row[SS_IS_BG] ? name + " [BG]" : name;
		if (link.textContent !== dname) link.textContent = dname;
		link.href = "#";
		link.onclick = (function(r) {
			return function(e) { e.preventDefault(); byond_topic(mcMakeVvLink(r)); return false; };
		})(row[SS_REF]);
		cells[1].className = !can_fire ? "mc-name mc-offline" : (row[SS_IS_BG] ? "mc-name mc-bg" : "mc-name");

		if (!can_fire) {
			setText(cells[2], "-"); cells[2].className = "mc-num";
			setText(cells[3], "-"); cells[3].className = "mc-num";
			setText(cells[4], "-"); cells[4].className = "mc-num";
			setText(cells[5], "-"); cells[5].className = "mc-num";
			setText(cells[6], row[SS_FIRED]); cells[6].className = "mc-num";
		} else {
			var cost = row[SS_COST];
			var tick = row[SS_TICK];
			var overrun = row[SS_OVERRUN];
			setText(cells[2], cost); cells[2].className = "mc-num " + mcHealthCost(cost);
			setText(cells[3], tick); cells[3].className = "mc-num " + mcHealthTick(tick);
			setText(cells[4], overrun); cells[4].className = "mc-num " + mcHealthOverrun(overrun);
			setText(cells[5], row[SS_TICKS]); cells[5].className = "mc-num";
			setText(cells[6], row[SS_FIRED]); cells[6].className = "mc-num";
		}

		tr._ssData = row;
		tr.style.display = mc_matchesFilter(name) ? "" : "none";
	}
	for (var n in mc_ss_rows) {
		if (!seen[n]) {
			if (mc_ss_rows[n].parentNode === mc_els.ssTbody) {
				mc_els.ssTbody.removeChild(mc_ss_rows[n]);
			}
			delete mc_ss_rows[n];
		}
	}
	mc_sortAndReorder();
}

function mc_updateKeySection() {
	if (!mc_els.keySection) return;
	if (!State.mcSections.key) { mc_els.keySection.textContent = ""; return; }
	var key_data = State.mcServerData.key_ss || {};
	// Iteration-based dedup — DM bumps mcIteration once per Master tick. JSON.stringify on the
	// nested key_data structure was the heaviest per-update operation; this drops it entirely.
	if (mc_els.keySection._lastIter === State.mcIteration) return;
	mc_els.keySection._lastIter = State.mcIteration;
	mc_els.keySection.textContent = "";
	var rendered = {};

	for (var i = 0; i < State.mcSSData.length; i++) {
		var row = State.mcSSData[i];
		var name = row[SS_NAME];
		if (MC_KEY_SUBSYSTEMS.indexOf(name) === -1) continue;
		rendered[name] = true;
		var card = el("div", "mc-key-card");
		var header = el("div", "mc-key-header");
		var nameEl = el("span", "mc-key-name");
		var nameLink = el("a");
		nameLink.href = "#";
		nameLink.onclick = (function(r) {
			return function(e) { e.preventDefault(); byond_topic(mcMakeVvLink(r)); return false; };
		})(row[SS_REF]);
		nameLink.textContent = name;
		nameEl.appendChild(nameLink);
		header.appendChild(nameEl);
		var statsEl = el("span", "mc-key-stats");
		if (row[SS_CAN_FIRE]) {
			var costCls = mcHealthCost(row[SS_COST]);
			var tickCls = mcHealthTick(row[SS_TICK]);
			statsEl.textContent = "";
			var costSpan = el("span", costCls, row[SS_COST] + "ms");
			var tickSpan = el("span", tickCls, row[SS_TICK] + "%");
			statsEl.appendChild(costSpan);
			statsEl.appendChild(document.createTextNode(" | "));
			statsEl.appendChild(tickSpan);
			statsEl.appendChild(document.createTextNode(" | " + (STATE_LETTERS[row[SS_STATE]] || "?")));
		} else {
			statsEl.textContent = "OFFLINE";
			statsEl.style.opacity = "0.5";
		}
		header.appendChild(statsEl);
		card.appendChild(header);
		mc_appendKeyDetails(card, key_data[name]);
		mc_els.keySection.appendChild(card);
	}
	for (var k = 0; k < MC_KEY_SUBSYSTEMS.length; k++) {
		var kname = MC_KEY_SUBSYSTEMS[k];
		if (rendered[kname] || !key_data[kname]) continue;
		var card2 = el("div", "mc-key-card");
		var header2 = el("div", "mc-key-header");
		header2.appendChild(el("span", "mc-key-name", kname));
		card2.appendChild(header2);
		mc_appendKeyDetails(card2, key_data[kname]);
		mc_els.keySection.appendChild(card2);
	}
}

function mc_appendKeyDetails(card, details) {
	if (!details || !details.length) return;
	var dtable = el("table", "mc-key-table");
	for (var d = 0; d < details.length; d++) {
		var dtr = el("tr");
		dtr.appendChild(el("td", "mc-key-dlabel", details[d][0]));
		dtr.appendChild(el("td", "mc-key-dval", details[d][1]));
		dtable.appendChild(dtr);
	}
	card.appendChild(dtable);
}

function draw_mc() {
	mc_ensureSkeleton();

	// Cheap dirty-check on the header (arrow + count). Both states matter, so derive a single key.
	if (mc_els.ssHeader) {
		var arrow = State.mcSections.subsystems ? "▼" : "▶";
		var headerKey = arrow + ":" + State.mcSSData.length;
		if (mc_els.ssHeader._lastKey !== headerKey) {
			mc_els.ssHeader._lastKey = headerKey;
			if (mc_els.ssHeader._arrow) mc_els.ssHeader._arrow.textContent = arrow;
			if (mc_els.ssHeader._countText) {
				mc_els.ssHeader._countText.textContent = " Подсистемы (" + State.mcSSData.length + ")";
			}
		}
	}

	mc_updateServerSection();
	mc_updatePingSection();
	mc_updateKeySection();
	mc_updateSSRows();
}
