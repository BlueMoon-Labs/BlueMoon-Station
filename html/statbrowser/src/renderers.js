var skeletons = {};

function invalidateRenderers() {
	skeletons = {};
}

function renderCurrentTab() {
	if (_settingsActive) return;
	var tab = State.currentTab;
	if (!tab) return;
	var isSpell = State.spellTabs.includes(tab);
	var isVerb = State.verbTabs.includes(tab);

	if (tab === "Status") {
		draw_status();
	} else if (tab === "MC") {
		draw_mc();
	} else if (tab === "Избранное") {
		draw_favorites();
	} else if (isSpell) {
		draw_spells(tab);
	} else if (tab === "Tickets") {
		draw_tickets();
	} else if (tab === "SDQL2") {
		draw_sdql2();
	} else if (tab === "Debug Stat Panel") {
		draw_debug();
	} else if (tab === State.turfName) {
		draw_listedturf();
	} else if (isVerb) {
		draw_verbs(tab);
	} else {
		statcontent.textContent = "Загрузка...";
	}
}

function pingClass(ms) {
	if (ms >= 200) return "val-bad";
	if (ms >= 100) return "val-warn";
	return "val-good";
}
function pingColor(ms) {
	if (ms >= 200) return "var(--health-bad)";
	if (ms >= 100) return "var(--health-warn)";
	return "var(--health-good)";
}
function jitterClass(ms) {
	if (ms >= 50) return "val-bad";
	if (ms >= 20) return "val-warn";
	return "val-good";
}
function tidiClass(val) {
	if (val >= 20) return "val-bad";
	if (val >= 5) return "val-warn";
	return "val-good";
}
function mcHealthCost(ms) {
	if (ms >= 10) return "health-bad";
	if (ms >= 3) return "health-warn";
	return "health-good";
}
function mcHealthTick(pct) {
	if (pct >= 20) return "health-bad";
	if (pct >= 8) return "health-warn";
	return "health-good";
}
function mcHealthOverrun(pct) {
	if (pct >= 5) return "health-bad";
	if (pct >= 1) return "health-warn";
	return "";
}
function mcCpuClass(cpu) {
	if (cpu >= 100) return "val-bad";
	if (cpu >= 80) return "val-warn";
	return "val-good";
}
function mcTidiClass(tidi) {
	if (tidi >= 20) return "val-bad";
	if (tidi >= 5) return "val-warn";
	return "val-good";
}

function mcMakeVvLink(ref) {
	return "?_src_=vars;admin_token=" + State.hrefToken + ";Vars=" + ref;
}

function makeGridItem(label, value, wide, cls, href) {
	var item = el("div", "metric-item" + (wide ? " metric-wide" : ""));
	item.appendChild(el("div", "metric-label", label));
	var val = el("div", "metric-value");
	if (href) {
		var a = el("a");
		a.href = "#";
		a.onclick = (function(h) {
			return function(e) { e.preventDefault(); byond_topic(h); return false; };
		})(href);
		a.textContent = value;
		if (cls) a.className = cls;
		val.appendChild(a);
	} else {
		val.textContent = "" + value;
		if (cls) val.className = "metric-value " + cls;
	}
	item.appendChild(val);
	return item;
}

function fillGrid(container, rows) {
	var hash = "";
	for (var j = 0; j < rows.length; j++) hash += rows[j][0] + "\t" + rows[j][1] + "\n";
	if (container._lastHash === hash) return;
	container._lastHash = hash;
	container.textContent = "";
	for (var i = 0; i < rows.length; i++) {
		var wide = ("" + rows[i][1]).length > 32;
		container.appendChild(makeGridItem(rows[i][0], rows[i][1], wide));
	}
}

function makeSectionHeader(key, label, sections) {
	var div = el("div", "section-header");
	var arrow = el("span", "section-arrow", sections[key] ? "▼" : "▶");
	div.appendChild(arrow);
	// Keep the label in a TextNode reference so renderers can mutate it cheaply (e.g. update counts).
	var labelText = document.createTextNode(" " + label);
	div.appendChild(labelText);
	div.onclick = function() {
		sections[key] = !sections[key];
		arrow.textContent = sections[key] ? "▼" : "▶";
		div._toggle(key);
	};
	div._arrow = arrow;
	div._countText = labelText;
	div._toggle = function() {};
	return div;
}
