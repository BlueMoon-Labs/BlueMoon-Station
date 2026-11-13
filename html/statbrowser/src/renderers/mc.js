// MC tab: server health, tick budget, controller state, key subsystems and the subsystem table.
// Every section is built once and refreshed only when Master.iteration of the payload changes.

var MC_PREFS_KEY = "statbrowser_mc_prefs";
var MC_COLS = 8;

var mc = {
	root: null,
	els: {},
	rows: {},
	drawnIter: {},
	prefsLoaded: false
};

// ---------- Preferences ----------

function mc_loadPrefs() {
	if (mc.prefsLoaded) return;
	mc.prefsLoaded = true;
	var raw = null;
	try { raw = localStorage.getItem(MC_PREFS_KEY); } catch (e) {}
	if (!raw) return;
	try {
		var p = JSON.parse(raw);
		if (p.sections) {
			for (var k in State.mcSections) {
				if (typeof p.sections[k] === "boolean") State.mcSections[k] = p.sections[k];
			}
		}
		if (p.pinned && typeof p.pinned === "object") State.mcPinned = p.pinned;
		if (typeof p.sortCol === "number") State.mcSortCol = p.sortCol;
		if (typeof p.sortAsc === "boolean") State.mcSortAsc = p.sortAsc;
		State.mcHideIdle = !!p.hideIdle;
		State.mcHotOnly = !!p.hotOnly;
	} catch (e) {}
}

function mc_savePrefs() {
	var p = {
		sections: State.mcSections,
		pinned: State.mcPinned,
		sortCol: State.mcSortCol,
		sortAsc: State.mcSortAsc,
		hideIdle: State.mcHideIdle,
		hotOnly: State.mcHotOnly
	};
	try { localStorage.setItem(MC_PREFS_KEY, JSON.stringify(p)); } catch (e) {}
}

// ---------- Small helpers ----------

function mc_num(v, digits) {
	var n = parseFloat(v);
	if (isNaN(n)) return "-";
	return digits === undefined ? "" + n : n.toFixed(digits);
}

function mc_loadClass(pct) {
	if (pct >= 5) return "health-bad";
	if (pct >= 2) return "health-warn";
	return "health-good";
}

function mc_mapTickClass(pct) {
	if (pct >= 30) return "val-bad";
	if (pct >= 15) return "val-warn";
	return "val-good";
}

function mc_mcLoadClass(load, limit) {
	var share = load / Math.max(limit || 70, 1);
	if (share >= 0.9) return "val-bad";
	if (share >= 0.6) return "val-warn";
	return "val-good";
}

function mc_memClass(vsz, ceiling) {
	if (!ceiling) return "";
	var share = vsz / ceiling;
	if (share >= 0.9) return "val-bad";
	if (share >= 0.8) return "val-warn";
	return "val-good";
}

function mc_defconClass(defcon) {
	if (defcon === undefined || defcon === null) return "val-bad";
	if (defcon >= 5) return "val-good";
	if (defcon >= 3) return "val-warn";
	return "val-bad";
}

function mc_isHot(row) {
	return row[SS_CAN_FIRE] && ((row[SS_LOAD] || 0) >= 2 || (row[SS_COST] || 0) >= 3 || (row[SS_OVERRUN] || 0) >= 1);
}

function mc_link(text, ref, cls) {
	var a = el("a", cls, text);
	a.href = "#";
	a.onclick = function(e) {
		e.preventDefault();
		e.stopPropagation();
		if (ref) byond_topic(mcMakeVvLink(ref));
		return false;
	};
	return a;
}

function mc_button(text, title, onclick, cls) {
	var b = el("button", "mc-btn" + (cls ? " " + cls : ""), text);
	b.type = "button";
	if (title) b.title = title;
	b.onclick = function(e) {
		e.stopPropagation();
		onclick();
	};
	return b;
}

function mc_formatDs(ds) {
	if (ds === null || ds === undefined) return "-";
	var n = parseFloat(ds);
	if (isNaN(n)) return "-";
	var neg = n < 0;
	n = Math.abs(n);
	var out;
	if (n < 10) out = n.toFixed(1) + " дс";
	else if (n < 600) out = (n / 10).toFixed(n < 100 ? 1 : 0) + " с";
	else out = Math.floor(n / 600) + " мин " + Math.round((n % 600) / 10) + " с";
	return neg ? "-" + out : out;
}

function mc_flagNames(flags) {
	var out = [];
	for (var i = 0; i < SS_FLAG_NAMES.length; i++) {
		if (flags & SS_FLAG_NAMES[i][0]) out.push(SS_FLAG_NAMES[i][1]);
	}
	return out;
}

function mc_rowByName(name) {
	for (var i = 0; i < State.mcSSData.length; i++) {
		if (State.mcSSData[i][SS_NAME] === name) return State.mcSSData[i];
	}
	return null;
}

function mc_togglePin(name) {
	if (State.mcPinned[name]) delete State.mcPinned[name];
	else State.mcPinned[name] = true;
	mc_savePrefs();
	mc.drawnIter.key = null;
	mc_updateKeySection();
	var r = mc.rows[name];
	if (r) {
		mc_updatePinMark(r, name);
		if (r.detail) mc_fillDetail(r);
	}
}

function mc_updatePinMark(r, name) {
	var pinned = !!State.mcPinned[name];
	r.pin.textContent = pinned ? "★" : "☆";
	r.pin.className = "mc-pin" + (pinned ? " mc-pin-on" : "");
	r.pin.title = pinned ? "Открепить из «Ключевых»" : "Закрепить в «Ключевых»";
}

// Sections are a header plus a body; collapsing forgets the drawn iteration so reopening redraws.
function mc_section(key, label) {
	var header = makeSectionHeader(key, label, State.mcSections);
	var body = el("div", "mc-section-body mc-section-" + key);
	body.style.display = State.mcSections[key] ? "" : "none";
	header._toggle = function() {
		body.style.display = State.mcSections[key] ? "" : "none";
		mc.drawnIter[key] = null;
		mc_savePrefs();
		if (State.mcSections[key]) draw_mc();
	};
	mc.root.appendChild(header);
	mc.root.appendChild(body);
	return { header: header, body: body };
}

function mc_sparkline(series, minVal, maxVal, cls) {
	if (!series || series.length < 2) return null;
	var svg = buildSparkline(series, minVal, maxVal, cls);
	svg.setAttribute("preserveAspectRatio", "none");
	svg.setAttribute("class", "sparkline mc-kpi-spark");
	var line = svg.firstChild;
	if (line) line.setAttribute("vector-effect", "non-scaling-stroke");
	return svg;
}

// ---------- Skeleton ----------

function mc_ensureSkeleton() {
	if (mc.root && mc.root.parentNode === statcontent) return;
	mc_loadPrefs();
	statcontent.textContent = "";
	mc.rows = {};
	mc.drawnIter = {};
	mc.els = {};
	mc.root = el("div", "mc-container");

	var s = mc_section("summary", "Сводка");
	mc.els.kpi = el("div", "mc-kpi-grid");
	s.body.appendChild(mc.els.kpi);
	mc.els.kpiTiles = {};

	s = mc_section("budget", "Бюджет тика");
	mc.els.budget = s.body;

	s = mc_section("controller", "Контроллер");
	mc.els.controllerGrid = el("div", "metric-grid mc-controller-grid");
	mc.els.controllerActions = el("div", "mc-actions");
	s.body.appendChild(mc.els.controllerGrid);
	s.body.appendChild(mc.els.controllerActions);
	mc_buildControllerActions();

	s = mc_section("net", "Пинг и сеть");
	mc.els.net = el("table", "data-table mc-net-table");
	s.body.appendChild(mc.els.net);

	s = mc_section("key", "Ключевые и закреплённые");
	mc.els.key = el("div", "mc-key-section");
	s.body.appendChild(mc.els.key);

	s = mc_section("subsystems", "Подсистемы");
	mc.els.ssHeader = s.header;
	mc_buildSubsystemTable(s.body);

	statcontent.appendChild(mc.root);
}

function mc_buildControllerActions() {
	var box = mc.els.controllerActions;
	box.appendChild(mc_button("Master", "Открыть переменные Master", function() {
		byond_topic(mcMakeVvLink(State.mcServerData.ref_master));
	}));
	box.appendChild(mc_button("Failsafe", "Открыть переменные Failsafe", function() {
		if (State.mcServerData.ref_failsafe) byond_topic(mcMakeVvLink(State.mcServerData.ref_failsafe));
	}));
	box.appendChild(mc_button("GLOB", "Открыть глобальные переменные", function() {
		byond_topic(mcMakeVvLink(State.mcServerData.ref_glob));
	}));
	box.appendChild(mc_button("Config", "Открыть конфиг", function() {
		byond_topic(mcMakeVvLink(State.mcServerData.ref_config));
	}));
	box.appendChild(mc_button("Камеры", "Открыть переменные камерасети", function() {
		byond_topic(mcMakeVvLink(State.mcServerData.ref_cameranet));
	}));
	box.appendChild(mc_button("Debug Controller", "Выбрать контроллер и открыть его переменные", function() {
		send_byond_command("Debug-Controller");
	}));
	box.appendChild(mc_button("Restart Controller", "Перезапустить Master или Failsafe (спросит, какой)", function() {
		send_byond_command("Restart-Controller");
	}, "mc-btn-danger"));
}

function mc_buildSubsystemTable(body) {
	var bar = el("div", "mc-toolbar");
	mc.els.filterInput = el("input", "mc-filter");
	mc.els.filterInput.type = "text";
	mc.els.filterInput.placeholder = "Фильтр по имени...";
	mc.els.filterInput.value = State.mcFilterText;
	mc.els.filterInput.oninput = function() {
		State.mcFilterText = this.value.toLowerCase();
		mc_applyFilter();
	};
	bar.appendChild(mc.els.filterInput);

	mc.els.chipIdle = mc_button("Скрыть выключенные", "Не показывать подсистемы, которые не запускаются", function() {
		State.mcHideIdle = !State.mcHideIdle;
		mc_savePrefs();
		mc_syncChips();
		mc_applyFilter();
	}, "mc-chip");
	mc.els.chipHot = mc_button("Только нагруженные", "Нагрузка от 2% тика, проход от 3 мс или перерасход", function() {
		State.mcHotOnly = !State.mcHotOnly;
		mc_savePrefs();
		mc_syncChips();
		mc_applyFilter();
	}, "mc-chip");
	bar.appendChild(mc.els.chipIdle);
	bar.appendChild(mc.els.chipHot);
	body.appendChild(bar);
	mc_syncChips();

	var table = el("table", "mc-ss-table");
	var thead = el("thead");
	var hrow = el("tr");
	var cols = [
		{ label: "", col: SS_STATE, title: "Состояние: R работает, Q в очереди, P пауза, S спит в fire()" },
		{ label: "Имя", col: SS_NAME, title: "Имя подсистемы. Клик по строке - подробности" },
		{ label: "Нагр%", col: SS_LOAD, title: "Средняя доля каждого тика: цена прохода, размазанная по интервалу" },
		{ label: "мс", col: SS_COST, title: "Средняя цена прохода, мс" },
		{ label: "Тик%", col: SS_TICK, title: "Средняя цена прохода в % тика" },
		{ label: "Пер%", col: SS_OVERRUN, title: "Перерасход: % тика сверх выделенного без паузы" },
		{ label: "Инт.", col: SS_WAIT, title: "Интервал между запусками" },
		{ label: "#", col: SS_FIRED, title: "Сколько проходов завершено" }
	];
	for (var c = 0; c < cols.length; c++) {
		var th = el("th", "mc-th-sort", cols[c].label);
		th.title = cols[c].title;
		th.setAttribute("data-col", cols[c].col);
		th.onclick = function() {
			var col = parseInt(this.getAttribute("data-col"), 10);
			if (State.mcSortCol === col) {
				State.mcSortAsc = !State.mcSortAsc;
			} else {
				State.mcSortCol = col;
				State.mcSortAsc = (col === SS_NAME);
			}
			mc_savePrefs();
			mc_updateSortIndicators();
			mc_sortAndReorder();
		};
		hrow.appendChild(th);
	}
	thead.appendChild(hrow);
	table.appendChild(thead);
	mc.els.ssTable = table;
	mc.els.ssTbody = el("tbody");
	table.appendChild(mc.els.ssTbody);
	body.appendChild(table);
	mc_updateSortIndicators();
}

function mc_syncChips() {
	if (!mc.els.chipIdle) return;
	mc.els.chipIdle.className = "mc-btn mc-chip" + (State.mcHideIdle ? " mc-chip-on" : "");
	mc.els.chipHot.className = "mc-btn mc-chip" + (State.mcHotOnly ? " mc-chip-on" : "");
}

// ---------- Summary ----------

function mc_kpiTile(key, label) {
	var t = mc.els.kpiTiles[key];
	if (t) return t;
	t = {};
	t.root = el("div", "mc-kpi");
	t.label = el("div", "mc-kpi-label", label);
	t.value = el("div", "mc-kpi-value");
	t.sub = el("div", "mc-kpi-sub");
	t.spark = el("div", "mc-kpi-spark-box");
	t.root.appendChild(t.label);
	t.root.appendChild(t.value);
	t.root.appendChild(t.sub);
	t.root.appendChild(t.spark);
	mc.els.kpi.appendChild(t.root);
	mc.els.kpiTiles[key] = t;
	return t;
}

function mc_setKpi(key, label, value, cls, sub, series, lo, hi, title) {
	var t = mc_kpiTile(key, label);
	setText(t.value, value);
	t.value.className = "mc-kpi-value " + (cls || "");
	setText(t.sub, sub || "");
	t.root.title = title || "";
	t.spark.textContent = "";
	var svg = mc_sparkline(series, lo, hi, cls);
	if (svg) t.spark.appendChild(svg);
}

function mc_updateSummary() {
	if (!State.mcSections.summary || mc.drawnIter.summary === State.mcIteration) return;
	mc.drawnIter.summary = State.mcIteration;
	var d = State.mcServerData;
	var h = d.history || {};

	mc_setKpi("tidi", "TimeDilation", mc_num(d.tidi_current, 1) + "%", mcTidiClass(d.tidi_current),
		mc_num(d.tidi_avg_fast, 1) + " / " + mc_num(d.tidi_avg, 1) + " / " + mc_num(d.tidi_avg_slow, 1),
		h.tidi, 0, 20, "Замедление времени сейчас; под ним средние: быстрое / обычное / медленное");
	mc_setKpi("cpu", "CPU", mc_num(d.cpu, 0) + "%", mcCpuClass(d.cpu), "world.cpu",
		h.cpu, 0, 100, "Занятость тика по мнению BYOND");
	mc_setKpi("maptick", "SendMaps", mc_num(d.maptick, 1) + "%", mc_mapTickClass(d.maptick), "отправка карты клиентам",
		h.maptick, 0, 30, "world.map_cpu: доля тика, которую BYOND тратит на рассылку карты. Её вычитают из лимита МК");
	mc_setKpi("mc", "Нагрузка МК", mc_num(d.mc_load, 1) + "%", mc_mcLoadClass(d.mc_load, d.tick_limit_running),
		"из " + mc_num(d.tick_limit_running, 0) + "% лимита",
		h.mc, 0, 50, "Сумма средней доли тика по всем активным подсистемам (оценка по их средним)");
	mc_setKpi("ping", "Пинг (медиана)", mc_num(d.ping_rtt_median, 0) + " мс", pingClass(d.ping_rtt_median),
		"ср. " + mc_num(d.ping_rtt_avg, 0) + " / макс " + mc_num(d.ping_rtt_max, 0),
		h.ping, 0, 150, "Медиана RTT по всем клиентам; среднее тянет вверх один клиент с плохим каналом");
	mc_setKpi("players", "Игроки", "" + (d.players || 0), "",
		d.round_time ? "раунд " + d.round_time : "раунд не начат", null, 0, 0, "");
	if (d.mem_vsz) {
		var memSub = d.mem_ceiling ? "из " + d.mem_ceiling + " МБ" : "потолок неизвестен";
		memSub += ", " + (d.mem_growth >= 0 ? "+" : "") + mc_num(d.mem_growth, 1) + " МБ/мин";
		mc_setKpi("mem", "Память", d.mem_vsz + " МБ", mc_memClass(d.mem_vsz, d.mem_ceiling), memSub, null, 0, 0,
			"Адресное пространство процесса (VmSize) и скорость роста");
	}
	mc_setKpi("coords", "Камера", d.coords || "-", "", d.instances + " объектов в мире", null, 0, 0, "Координаты взгляда (X, Y, Z)");
}

// ---------- Tick budget ----------

function mc_updateBudget() {
	if (!State.mcSections.budget || mc.drawnIter.budget === State.mcIteration) return;
	mc.drawnIter.budget = State.mcIteration;
	var d = State.mcServerData;
	var body = mc.els.budget;
	body.textContent = "";

	var maptick = Math.max(0, parseFloat(d.maptick) || 0);
	var mcLoad = Math.max(0, parseFloat(d.mc_load) || 0);
	var reserve = Math.max(0, parseFloat(d.tick_byond_reserve) || 0);
	var segs = [
		{ cls: "mc-seg-map", label: "SendMaps", value: maptick },
		{ cls: "mc-seg-mc", label: "МК", value: mcLoad },
		{ cls: "mc-seg-reserve", label: "Резерв BYOND", value: reserve }
	];
	var used = 0;
	for (var i = 0; i < segs.length; i++) used += segs[i].value;
	segs.push({ cls: "mc-seg-free", label: "Свободно", value: Math.max(0, 100 - used) });

	var bar = el("div", "mc-budget-bar");
	var scale = Math.max(100, used);
	var legend = el("div", "mc-budget-legend");
	for (var j = 0; j < segs.length; j++) {
		var w = segs[j].value / scale * 100;
		if (w > 0) {
			var seg = el("div", "mc-seg " + segs[j].cls);
			seg.style.width = w + "%";
			seg.title = segs[j].label + ": " + segs[j].value.toFixed(1) + "% тика";
			bar.appendChild(seg);
		}
		var li = el("span", "mc-legend-item");
		li.appendChild(el("span", "mc-legend-dot " + segs[j].cls));
		li.appendChild(document.createTextNode(segs[j].label + " " + segs[j].value.toFixed(1) + "%"));
		legend.appendChild(li);
	}
	var limit = parseFloat(d.tick_limit_running);
	if (limit > 0) {
		var mark = el("div", "mc-budget-limit");
		mark.style.left = Math.min(100, (maptick + limit) / scale * 100) + "%";
		mark.title = "Лимит МК: " + limit.toFixed(0) + "% тика после SendMaps";
		bar.appendChild(mark);
	}
	body.appendChild(bar);
	body.appendChild(legend);

	var info = el("div", "mc-budget-info");
	var parts = [
		"Лимит МК " + mc_num(d.mc_tick_limit, 1) + "%",
		"вне МК " + (d.outside_tick_limit ? d.outside_tick_limit + "%" : "без бюджета"),
		"фон " + (d.background_tick_budget ? d.background_tick_budget + "%" : "без потолка"),
		"растягивание " + (d.pace_passes ? "вкл" : "выкл")
	];
	info.textContent = parts.join(" · ");
	body.appendChild(info);

	// Top consumers by per-tick load
	var top = [];
	for (var k = 0; k < State.mcSSData.length; k++) {
		var row = State.mcSSData[k];
		if (row[SS_CAN_FIRE] && row[SS_LOAD] > 0) top.push(row);
	}
	top.sort(function(a, b) { return b[SS_LOAD] - a[SS_LOAD]; });
	top = top.slice(0, 6);
	if (!top.length) return;
	var maxLoad = top[0][SS_LOAD] || 1;
	var list = el("div", "mc-top-list");
	for (var t = 0; t < top.length; t++) {
		var r = top[t];
		var item = el("div", "mc-top-item");
		item.appendChild(mc_link(r[SS_NAME], r[SS_REF], "mc-top-name"));
		var track = el("div", "mc-top-track");
		var fill = el("div", "mc-top-fill " + mc_loadClass(r[SS_LOAD]));
		fill.style.width = Math.max(2, r[SS_LOAD] / maxLoad * 100) + "%";
		track.appendChild(fill);
		item.appendChild(track);
		item.appendChild(el("span", "mc-top-val " + mc_loadClass(r[SS_LOAD]),
			mc_num(r[SS_LOAD], 2) + "% · " + mc_num(r[SS_COST], 1) + " мс"));
		list.appendChild(item);
	}
	body.appendChild(list);
}

// ---------- Controller ----------

function mc_updateController() {
	if (!State.mcSections.controller || mc.drawnIter.controller === State.mcIteration) return;
	mc.drawnIter.controller = State.mcIteration;
	var d = State.mcServerData;
	var g = mc.els.controllerGrid;
	g.textContent = "";
	var processing = d.mc_processing;
	g.appendChild(makeGridItem("Итерация МК", "" + d.mc_iteration, false, processing > 0 ? "val-good" : "val-bad",
		mcMakeVvLink(d.ref_master)));
	g.appendChild(makeGridItem("Стадия", d.mc_runlevel + (d.mc_map_loading ? " (грузит карту)" : ""), false));
	g.appendChild(makeGridItem("Ход МК", processing > 0 ? "раз в " + processing + " тик" : "остановлен", false,
		processing > 0 ? "" : "val-bad"));
	g.appendChild(makeGridItem("Лимит тика", mc_num(d.mc_tick_limit, 1) + "%", false));
	g.appendChild(makeGridItem("Сон между прогонами", "×" + mc_num(d.mc_sleep_delta, 2), false,
		d.mc_sleep_delta >= 2 ? "val-warn" : ""));
	g.appendChild(makeGridItem("Очередь", d.mc_queue + (d.mc_skip_ticks ? " · пропуск " + d.mc_skip_ticks : ""), false));
	g.appendChild(makeGridItem("Дрифт тиков", mc_num(d.tick_drift, 1) + " (" + mc_num(d.tick_drift_pct, 1) + "%)", false,
		d.tick_drift_pct >= 5 ? "val-warn" : ""));
	g.appendChild(makeGridItem("Тики мира", d.tick_count + " · " + d.fps + " fps", false));
	g.appendChild(makeGridItem("Failsafe", d.failsafe_defcon !== null && d.failsafe_defcon !== undefined ? "DEFCON " + d.failsafe_defcon : "нет",
		false, mc_defconClass(d.failsafe_defcon), d.ref_failsafe ? mcMakeVvLink(d.ref_failsafe) : null));
	g.appendChild(makeGridItem("Перезапуски МК", "" + d.mc_restarts, false, d.mc_restarts ? "val-warn" : ""));
	g.appendChild(makeGridItem("Камеры", d.camera_count + " · чанков " + d.camera_chunks, false, null,
		d.ref_cameranet ? mcMakeVvLink(d.ref_cameranet) : null));
	g.appendChild(makeGridItem("Очистка клиентов", mc_num(d.cleanup_last, 2) + " мс · ср. " + mc_num(d.cleanup_avg, 2) + " · цель " + d.cleanup_target, true));
	if (d.mc_last_ss) g.appendChild(makeGridItem("Последняя запущенная", d.mc_last_ss, true));
	if (d.failsafe_stat) g.appendChild(makeGridItem("Failsafe подробно", d.failsafe_stat, true));
}

// ---------- Network ----------

function mc_updateNet() {
	if (!State.mcSections.net || mc.drawnIter.net === State.mcIteration) return;
	mc.drawnIter.net = State.mcIteration;
	var d = State.mcServerData;
	var t = mc.els.net;
	t.textContent = "";
	function row(label, value, title) {
		var tr = el("tr");
		var td = el("td", "data-label", label);
		if (title) td.title = title;
		tr.appendChild(td);
		tr.appendChild(el("td", "data-value", value));
		t.appendChild(tr);
	}
	row("RTT", "медиана " + d.ping_rtt_median + " · ср. " + d.ping_rtt_avg + " · макс " + d.ping_rtt_max +
		" · ср.ср. " + d.ping_rtt_avg_avg + " мс", "Полный круг до клиента и обратно");
	row("Ожидание тика", "ср. " + d.ping_tick_avg + " · макс " + d.ping_tick_max + " мс",
		"Сколько ответ ждёт следующего тика");
	row("Сервер", "ср. " + d.ping_server_avg + " · макс " + d.ping_server_max + " · ср.ср. " + d.ping_server_avg_avg + " мс",
		"Доля пинга, которую добавляет сам сервер");
	row("Сэмплов", "" + d.ping_samples);
	row("Джиттер", "сейчас " + d.jitter_last + "% · ср. " + d.jitter_avg + "% · макс в окне " + d.jitter_max_wnd + "%",
		"Неровность хода игрового времени относительно реального");
	row("Множители", "raw ×" + d.raw_mult + " · glide ×" + d.glide_mult);
}

// ---------- Key and pinned subsystems ----------

function mc_updateKeySection() {
	if (!State.mcSections.key || mc.drawnIter.key === State.mcIteration) return;
	mc.drawnIter.key = State.mcIteration;
	var box = mc.els.key;
	box.textContent = "";
	var keyData = State.mcServerData.key_ss || {};
	var names = [];
	var seen = {};
	for (var i = 0; i < MC_KEY_SUBSYSTEMS.length; i++) {
		names.push(MC_KEY_SUBSYSTEMS[i]);
		seen[MC_KEY_SUBSYSTEMS[i]] = true;
	}
	for (var p in State.mcPinned) {
		if (!seen[p]) { names.push(p); seen[p] = true; }
	}
	for (var n = 0; n < names.length; n++) {
		var name = names[n];
		var row = mc_rowByName(name);
		var details = keyData[name];
		if (!row && !details) continue;
		box.appendChild(mc_buildKeyCard(name, row, details));
	}
}

function mc_buildKeyCard(name, row, details) {
	var card = el("div", "mc-key-card" + (State.mcPinned[name] ? " mc-key-pinned" : ""));
	var header = el("div", "mc-key-header");
	var nameEl = el("span", "mc-key-name");
	if (row) nameEl.appendChild(mc_link(name, row[SS_REF]));
	else nameEl.textContent = name;
	header.appendChild(nameEl);
	var stats = el("span", "mc-key-stats");
	if (row && row[SS_CAN_FIRE]) {
		stats.appendChild(el("span", mc_loadClass(row[SS_LOAD]), mc_num(row[SS_LOAD], 2) + "%"));
		stats.appendChild(document.createTextNode(" · "));
		stats.appendChild(el("span", mcHealthCost(row[SS_COST]), mc_num(row[SS_COST], 1) + " мс"));
		stats.appendChild(document.createTextNode(" · " + (STATE_LETTERS[row[SS_STATE]] || "?")));
	} else if (row) {
		stats.textContent = "выключена";
		stats.className += " mc-offline";
	}
	header.appendChild(stats);
	if (row) {
		var pin = el("span", "mc-pin" + (State.mcPinned[name] ? " mc-pin-on" : ""), State.mcPinned[name] ? "★" : "☆");
		pin.title = State.mcPinned[name] ? "Открепить" : "Закрепить";
		pin.onclick = function(e) { e.stopPropagation(); mc_togglePin(name); };
		header.appendChild(pin);
	}
	card.appendChild(header);
	if (details && details.length) {
		var table = el("table", "mc-key-table");
		for (var d = 0; d < details.length; d++) {
			var tr = el("tr");
			tr.appendChild(el("td", "mc-key-dlabel", details[d][0]));
			tr.appendChild(el("td", "mc-key-dval", details[d][1]));
			table.appendChild(tr);
		}
		card.appendChild(table);
	} else if (row && row[SS_EXTRA]) {
		card.appendChild(el("div", "mc-key-extra", row[SS_EXTRA]));
	}
	return card;
}

// ---------- Subsystem table ----------

function mc_matchesFilter(row) {
	if (State.mcHideIdle && !row[SS_CAN_FIRE]) return false;
	if (State.mcHotOnly && !mc_isHot(row)) return false;
	if (!State.mcFilterText) return true;
	return row[SS_NAME].toLowerCase().indexOf(State.mcFilterText) !== -1;
}

function mc_applyFilter() {
	var shown = 0;
	for (var name in mc.rows) {
		var r = mc.rows[name];
		var visible = mc_matchesFilter(r.data);
		if (visible) shown++;
		r.tr.style.display = visible ? "" : "none";
		if (r.detail) r.detail.style.display = visible ? "" : "none";
	}
	mc_updateSSHeader(shown);
}

function mc_updateSSHeader(shown) {
	if (!mc.els.ssHeader) return;
	var total = State.mcSSData.length;
	var active = 0;
	for (var i = 0; i < total; i++) if (State.mcSSData[i][SS_CAN_FIRE]) active++;
	var label = " Подсистемы: " + active + " активных из " + total;
	if (shown !== undefined && shown !== total) label += ", показано " + shown;
	if (mc.els.ssHeader._countText.textContent !== label) mc.els.ssHeader._countText.textContent = label;
}

function mc_compare(a, b) {
	if (a[SS_CAN_FIRE] !== b[SS_CAN_FIRE]) return b[SS_CAN_FIRE] - a[SS_CAN_FIRE];
	var col = State.mcSortCol;
	var asc = State.mcSortAsc;
	if (col === SS_NAME) {
		var av = ("" + a[col]).toLowerCase();
		var bv = ("" + b[col]).toLowerCase();
		var cmp = av < bv ? -1 : av > bv ? 1 : 0;
		return asc ? cmp : -cmp;
	}
	var an = parseFloat(a[col]) || 0;
	var bn = parseFloat(b[col]) || 0;
	if (an === bn) return a[SS_NAME] < b[SS_NAME] ? -1 : 1;
	return asc ? an - bn : bn - an;
}

function mc_sortAndReorder() {
	var list = [];
	for (var name in mc.rows) list.push(mc.rows[name]);
	list.sort(function(x, y) { return mc_compare(x.data, y.data); });
	var tbody = mc.els.ssTbody;
	var idx = 0;
	for (var i = 0; i < list.length; i++) {
		var nodes = list[i].detail ? [list[i].tr, list[i].detail] : [list[i].tr];
		for (var j = 0; j < nodes.length; j++) {
			if (tbody.childNodes[idx] !== nodes[j]) tbody.insertBefore(nodes[j], tbody.childNodes[idx] || null);
			idx++;
		}
	}
}

function mc_updateSortIndicators() {
	if (!mc.els.ssTable) return;
	var ths = mc.els.ssTable.getElementsByTagName("th");
	for (var i = 0; i < ths.length; i++) {
		var col = parseInt(ths[i].getAttribute("data-col"), 10);
		ths[i].className = col === State.mcSortCol
			? "mc-th-sort mc-sorted" + (State.mcSortAsc ? "" : " desc")
			: "mc-th-sort";
	}
}

function mc_makeRow(name) {
	var r = { tr: el("tr", "mc-ss-row"), cells: [], detail: null, data: null };
	for (var c = 0; c < MC_COLS; c++) {
		var td = el("td");
		r.tr.appendChild(td);
		r.cells.push(td);
	}
	r.pin = el("span", "mc-pin");
	r.pin.onclick = function(e) { e.stopPropagation(); mc_togglePin(name); };
	r.link = mc_link(name, null);
	r.link.onclick = function(e) {
		e.preventDefault();
		e.stopPropagation();
		if (r.data) byond_topic(mcMakeVvLink(r.data[SS_REF]));
		return false;
	};
	r.link.title = "Открыть переменные";
	r.cells[1].appendChild(r.pin);
	r.cells[1].appendChild(r.link);
	r.tr.onclick = function() {
		if (State.mcExpanded[name]) delete State.mcExpanded[name];
		else State.mcExpanded[name] = true;
		mc_syncDetail(r, name);
		mc_sortAndReorder();
	};
	mc_updatePinMark(r, name);
	return r;
}

function mc_syncDetail(r, name) {
	if (State.mcExpanded[name]) {
		if (!r.detail) {
			r.detail = el("tr", "mc-detail-row");
			r.detailCell = el("td");
			r.detailCell.colSpan = MC_COLS;
			r.detail.appendChild(r.detailCell);
		}
		r.tr.className = "mc-ss-row mc-expanded";
		mc_fillDetail(r);
	} else {
		if (r.detail && r.detail.parentNode) r.detail.parentNode.removeChild(r.detail);
		r.detail = null;
		r.tr.className = "mc-ss-row";
	}
}

function mc_fillDetail(r) {
	var row = r.data;
	var cell = r.detailCell;
	cell.textContent = "";
	var grid = el("div", "mc-detail-grid");
	function item(label, value, cls) {
		var it = el("div", "mc-detail-item");
		it.appendChild(el("span", "mc-detail-label", label));
		it.appendChild(el("span", "mc-detail-value" + (cls ? " " + cls : ""), value));
		grid.appendChild(it);
	}
	item("Состояние", STATE_NAMES[row[SS_STATE]] || "?");
	item("Интервал", mc_formatDs(row[SS_WAIT]));
	item("Приоритет", "" + row[SS_PRIORITY]);
	item("Порядок init", "" + row[SS_INIT_ORDER] + (row[SS_INITIALIZED] ? "" : " (не готова)"));
	if (row[SS_CAN_FIRE]) {
		item("Тиков на проход", mc_num(row[SS_TICKS], 1));
		item("Следующий запуск", row[SS_NEXT_FIRE] > 0 ? "через " + mc_formatDs(row[SS_NEXT_FIRE]) : "в очереди");
	}
	item("Прошлый запуск", row[SS_LAST_FIRE] === null || row[SS_LAST_FIRE] === undefined ? "не было" : mc_formatDs(row[SS_LAST_FIRE]) + " назад");
	if (row[SS_POSTPONED]) item("Отложено", "" + row[SS_POSTPONED], "health-warn");
	if (row[SS_PAUSED_TICKS]) item("Пауз в проходе", "" + row[SS_PAUSED_TICKS], "health-warn");
	cell.appendChild(grid);

	var flags = mc_flagNames(row[SS_FLAGS] || 0);
	if (flags.length) {
		var fl = el("div", "mc-flags");
		for (var f = 0; f < flags.length; f++) fl.appendChild(el("span", "mc-flag", flags[f]));
		cell.appendChild(fl);
	}
	if (row[SS_EXTRA]) cell.appendChild(el("div", "mc-detail-extra", row[SS_EXTRA]));

	var actions = el("div", "mc-actions");
	actions.appendChild(mc_button("Переменные", "Открыть переменные подсистемы", function() {
		byond_topic(mcMakeVvLink(row[SS_REF]));
	}));
	var name = row[SS_NAME];
	actions.appendChild(mc_button(State.mcPinned[name] ? "Открепить" : "Закрепить",
		"Показывать карточку в «Ключевых»", function() { mc_togglePin(name); }));
	cell.appendChild(actions);
}

function mc_updateSSRows() {
	if (!State.mcSections.subsystems) { mc_updateSSHeader(); return; }
	if (mc.drawnIter.subsystems === State.mcIteration) return;
	mc.drawnIter.subsystems = State.mcIteration;
	var seen = {};
	var maxLoad = 0;
	for (var m = 0; m < State.mcSSData.length; m++) {
		if (State.mcSSData[m][SS_CAN_FIRE] && State.mcSSData[m][SS_LOAD] > maxLoad) maxLoad = State.mcSSData[m][SS_LOAD];
	}
	for (var i = 0; i < State.mcSSData.length; i++) {
		var row = State.mcSSData[i];
		var name = row[SS_NAME];
		seen[name] = true;
		var r = mc.rows[name];
		if (!r) {
			r = mc_makeRow(name);
			mc.rows[name] = r;
			mc.els.ssTbody.appendChild(r.tr);
		}
		r.data = row;
		var cells = r.cells;
		var active = row[SS_CAN_FIRE];

		setText(cells[0], STATE_LETTERS[row[SS_STATE]] || "?");
		cells[0].className = "mc-state mc-state-" + row[SS_STATE];
		cells[0].title = STATE_NAMES[row[SS_STATE]] || "";

		var dname = row[SS_IS_BG] ? name + " [BG]" : name;
		if (r.link.textContent !== dname) r.link.textContent = dname;
		cells[1].className = "mc-name" + (!active ? " mc-offline" : (row[SS_IS_BG] ? " mc-bg" : ""));
		cells[1].title = row[SS_EXTRA] || "";

		if (!active) {
			for (var c = 2; c < 6; c++) { setText(cells[c], "-"); cells[c].className = "mc-num"; }
			cells[2].style.background = "";
		} else {
			var load = row[SS_LOAD] || 0;
			setText(cells[2], mc_num(load, 2));
			cells[2].className = "mc-num mc-load " + mc_loadClass(load);
			var w = maxLoad > 0 ? Math.round(load / maxLoad * 100) : 0;
			cells[2].style.background = w > 0
				? "linear-gradient(to left, var(--mc-load-bar) " + w + "%, transparent " + w + "%)"
				: "";
			setText(cells[3], mc_num(row[SS_COST], 1));
			cells[3].className = "mc-num " + mcHealthCost(row[SS_COST]);
			setText(cells[4], mc_num(row[SS_TICK], 1));
			cells[4].className = "mc-num " + mcHealthTick(row[SS_TICK]);
			setText(cells[5], mc_num(row[SS_OVERRUN], 1));
			cells[5].className = "mc-num " + mcHealthOverrun(row[SS_OVERRUN]);
		}
		setText(cells[6], mc_formatDs(row[SS_WAIT]));
		cells[6].className = "mc-num mc-wait";
		setText(cells[7], row[SS_FIRED]);
		cells[7].className = "mc-num";

		if (State.mcExpanded[name]) mc_syncDetail(r, name);
	}
	for (var n in mc.rows) {
		if (seen[n]) continue;
		var dead = mc.rows[n];
		if (dead.tr.parentNode) dead.tr.parentNode.removeChild(dead.tr);
		if (dead.detail && dead.detail.parentNode) dead.detail.parentNode.removeChild(dead.detail);
		delete mc.rows[n];
	}
	mc_sortAndReorder();
	mc_applyFilter();
}

// ---------- Entry point ----------

function draw_mc() {
	mc_ensureSkeleton();
	// Coordinates arrive on their own between full payloads; the camera tile is cheap to refresh.
	if (State.mcSections.summary && mc.els.kpiTiles.coords) {
		setText(mc.els.kpiTiles.coords.value, State.mcServerData.coords || "-");
	}
	mc_updateSummary();
	mc_updateBudget();
	mc_updateController();
	mc_updateNet();
	mc_updateKeySection();
	mc_updateSSRows();
}
