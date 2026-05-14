function safeParse(str, fallback) {
	try { return JSON.parse(str); }
	catch (e) { return fallback !== undefined ? fallback : null; }
}

// DM sends this once per session to assert which payload shape it speaks.
// On mismatch we log a single warning to the console and ask BYOND to reload the cached HTML.
// (The cached HTML is the most common cause of mismatch — WebView2 holds an old build.)
function set_protocol_version(ver_str) {
	var ver = parseInt(ver_str, 10);
	if (!ver) return;
	State.protocolVersion = ver;
	if (ver === EXPECTED_PROTOCOL_VERSION) return;
	if (State.protocolMismatchReported) return;
	State.protocolMismatchReported = true;
	try {
		console.warn("[statbrowser] Protocol mismatch: client expects " + EXPECTED_PROTOCOL_VERSION + ", server speaks " + ver + ". Asking BYOND to reload the panel.");
	} catch (e) {}
	// Best-effort: ask DM to re-browse the file. Hosts that don't expose this href harmlessly drop it.
	byond_topic("?reload_statbrowser=1");
}

function update_ping(ping_str, tidi_str) {
	var pingData = safeParse(ping_str);
	if (!Array.isArray(pingData)) return;
	State.pingData = pingData;
	// Tidi is now sent on a slower cadence; preserve last value when omitted instead of clearing.
	if (tidi_str && tidi_str !== "") {
		var tidiData = safeParse(tidi_str);
		if (tidiData) State.tidiData = tidiData;
	}

	pingBarGlobal.style.display = "";
	var ping = State.pingData[0];
	var avg = State.pingData[1];
	var jitter = State.pingData[2];
	g_ping.dot.style.backgroundColor = pingColor(ping);
	setText(g_ping.text, "Пинг: " + ping + "ms");
	g_ping.text.className = pingClass(ping);
	setText(g_ping.avg, " (сред: " + avg + "ms)");
	if (jitter != null && jitter > 0) {
		setText(g_ping.max, " ±" + jitter + "ms");
		g_ping.max.className = jitterClass(jitter);
	} else {
		setText(g_ping.max, "");
	}

	if (State.tidiData) {
		var cur = State.tidiData[0];
		g_ping.tidiText.className = tidiClass(cur);
		setText(g_ping.tidiText, "Откл: " + cur + "%");
		setText(g_ping.tidiAvg, " (ср: " + State.tidiData[2] + "%)");
		g_ping.spacer.style.display = "";
		g_ping.tidiText.style.display = "";
		g_ping.tidiAvg.style.display = "";
	}
}

function update(global_fast_str, global_slow_str, other_str) {
	var parsedFast = safeParse(global_fast_str);
	if (!parsedFast) return;
	State.globalFast = parsedFast;

	if (global_slow_str && global_slow_str !== "") {
		State.globalSlow = safeParse(global_slow_str) || State.globalSlow;
	}

	if (parsedFast.tidi) {
		State.tidiData = parsedFast.tidi;
	}

	// DM omits other_str when its content hash didn't change since last send.
	// Preserve the previous mobItems instead of clearing — saves redundant DOM rewrites.
	if (other_str && other_str !== "") {
		var parsedMob = safeParse(other_str);
		var newItems = [];
		if (parsedMob) {
			for (var i = 0; i < parsedMob.length; i++) {
				if (parsedMob[i] != null) newItems.push(parsedMob[i]);
			}
		}
		State.mobItems = newItems;
	}

	if (!_settingsActive) {
		if (State.currentTab === "Status") {
			draw_status();
		} else if (State.currentTab === "Debug Stat Panel") {
			draw_debug();
		}
	}
}

function update_voting(vote_data) {
	var parsed = safeParse(vote_data);
	if (!parsed) return;
	State.voteParts = parsed;
	if (!_settingsActive && State.currentTab === "Status") draw_status();
}

function update_mc(server_data_encoded, ss_data_encoded, coords_entry, iteration_str) {
	// DM ships an iteration counter (Master.iteration) so JS can dedupe identical full payloads
	// without JSON.stringify-hashing every update. When iteration is unchanged, DM omits the heavy
	// payload and only ships fresh coords. We update only what changed and skip the redraw call
	// in the coords-only case unless the eye position string actually moved.
	var iter = iteration_str != null && iteration_str !== "" ? parseInt(iteration_str, 10) : NaN;
	var hasFullPayload = !!(server_data_encoded && ss_data_encoded);
	if (hasFullPayload) {
		var serverData = safeParse(server_data_encoded);
		var ssData = safeParse(ss_data_encoded);
		if (!serverData || !ssData) return;
		State.mcServerData = serverData;
		State.mcSSData = ssData;
		// Track iteration if DM provided it; else bump locally so renderer dirty checks still trigger
		// (covers older DM payloads or any path that doesn't include the counter).
		if (!isNaN(iter)) State.mcIteration = iter;
		else State.mcIteration = (State.mcIteration | 0) + 1;
	}
	var prevCoords = State.mcServerData.coords;
	if (coords_entry != null && coords_entry !== "") {
		State.mcServerData.coords = coords_entry;
	}
	addPermanentTab("MC");
	if (_settingsActive || State.currentTab !== "MC") return;
	// Skip the full draw call in the coords-only case unless coords actually changed.
	// All other sections are dirty-checked via mcIteration so they'd be no-ops anyway.
	if (!hasFullPayload && coords_entry === prevCoords) return;
	draw_mc();
}

function remove_mc() {
	removePermanentTab("MC");
	if (State.currentTab === "MC") tab_change("Status");
}

function update_spells(t, s) {
	var oldTabs = State.spellTabs || [];
	var parsed = safeParse(t, []);
	if (!Array.isArray(parsed)) return;
	State.spellTabs = parsed;
	var doUpdate = State.spellTabs.includes(State.currentTab);
	init_spells();
	// Remove tabs that were in the old list but not in the new one
	for (var i = 0; i < oldTabs.length; i++) {
		if (!State.spellTabs.includes(oldTabs[i])) {
			removePermanentTab(oldTabs[i]);
		}
	}
	if (s) {
		State.spells = safeParse(s, []);
		if (!_settingsActive && doUpdate) draw_spells(State.currentTab);
	} else {
		remove_spells();
	}
}

function remove_spells() {
	for (var s = 0; s < State.spellTabs.length; s++) {
		removePermanentTab(State.spellTabs[s]);
	}
}

function init_spells() {
	for (var i = 0; i < State.spellTabs.length; i++) {
		var cat = State.spellTabs[i];
		if (cat.length > 0) {
			addPermanentTab(cat);
		}
	}
}

function check_spells() {
	for (var v = 0; v < State.spellTabs.length; v++) {
		spell_cat_check(State.spellTabs[v]);
	}
}

function spell_cat_check(cat) {
	var count = 0;
	for (var s = 0; s < State.spells.length; s++) {
		if (State.spells[s][0] === cat) count++;
	}
	if (count < 1) removePermanentTab(cat);
}

function update_tickets(T) {
	var parsed = safeParse(T, []);
	if (!Array.isArray(parsed)) return;
	State.tickets = parsed;
	addPermanentTab("Tickets");
	if (!_settingsActive && State.currentTab === "Tickets") draw_tickets();
}

function update_interviews(I) {
	var parsed = safeParse(I);
	if (!parsed) return;
	State.interviewManager = parsed;
	if (!_settingsActive && State.currentTab === "Tickets") draw_interviews();
}

function draw_interviews() {
	var old = document.getElementById("interviews-panel");
	if (old && old.parentNode) old.parentNode.removeChild(old);
	var body = el("div");
	body.id = "interviews-panel";
	var header = el("h3", null, "Interviews");
	body.appendChild(header);
	var manLink = el("a", null, "Open Interview Manager Panel");
	manLink.href = "?_src_=holder;admin_token=" + State.hrefToken + ";interview_man=1;statpanel_item_click=left";
	body.appendChild(manLink);

	var statsTable = el("table", "data-table");
	for (var key in State.interviewManager.status) {
		var tr = el("tr");
		tr.appendChild(el("td", "data-label", key));
		tr.appendChild(el("td", "data-value", State.interviewManager.status[key]));
		statsTable.appendChild(tr);
	}
	body.appendChild(statsTable);

	if (State.interviewManager.interviews) {
		for (var i = 0; i < State.interviewManager.interviews.length; i++) {
			var part = State.interviewManager.interviews[i];
			var card = el("div", "ticket-card");
			var a = el("a", null, part["status"]);
			a.href = "?_src_=holder;admin_token=" + State.hrefToken + ";interview=" + part["ref"] + ";statpanel_item_click=left";
			card.appendChild(a);
			body.appendChild(card);
		}
	}
	statcontent.appendChild(body);
}

function update_sdql2(S) {
	var parsed = safeParse(S, []);
	if (!Array.isArray(parsed)) return;
	State.sdql2 = parsed;
	if (State.sdql2.length > 0) {
		addPermanentTab("SDQL2");
	}
	if (!_settingsActive && State.currentTab === "SDQL2") draw_sdql2();
}

function remove_sdql2() {
	State.sdql2 = [];
	removePermanentTab("SDQL2");
	if (State.currentTab === "SDQL2") tab_change("Status");
	checkStatusTab();
}

function remove_tickets() {
	State.tickets = [];
	removePermanentTab("Tickets");
	if (State.currentTab === "Tickets") tab_change("Status");
	checkStatusTab();
}

function remove_interviews() {
	State.interviewManager = { status: "", interviews: [] };
	checkStatusTab();
}

function remove_admin_tabs() {
	State.hrefToken = null;
	remove_mc();
	remove_tickets();
	remove_sdql2();
}

function add_admin_tabs(ht) {
	State.hrefToken = ht;
	addPermanentTab("MC");
	addPermanentTab("Tickets");
}

function create_listedturf(TN) {
	remove_listedturf();
	State.turfContents = [];
	State.turfName = safeParse(TN, "");
	addPermanentTab(State.turfName);
	tab_change(State.turfName);
}

function update_listedturf(TC) {
	if (TC === State.turfContentsRaw) return;
	State.turfContentsRaw = TC;
	State.turfContents = safeParse(TC, []);
	if (!_settingsActive && State.currentTab === State.turfName) draw_listedturf();
}

function update_turf_icons(data) {
	var parsed = safeParse(data, []);
	if (!Array.isArray(parsed)) return;
	for (var i = 0; i < parsed.length; i++) {
		var ref = parsed[i][0];
		var iconUrl = parsed[i][1];
		if (!iconUrl) continue;
		State.storedImages[ref] = iconUrl;
		if (turfItemNodes[ref]) {
			var img = turfItemNodes[ref].querySelector("img");
			if (img) {
				img.src = iconUrl;
				img.className = "";
				img.setAttribute("data-retry", "0");
			}
		}
	}
}

function remove_listedturf() {
	removePermanentTab(State.turfName);
	State.turfContentsRaw = "";
	turfTable = null;
	turfItemNodes = {};
	checkStatusTab();
	if (State.currentTab === State.turfName) tab_change("Status");
}

function init_verbs(c, v) {
	connected_to_server();
	wipe_verbs();
	st_fixSent = false;
	checkStatusTab();
	State.verbTabs = safeParse(c, []);
	State.verbTabs.sort();
	var doUpdate = false;
	for (var i = 0; i < State.verbTabs.length; i++) {
		createStatusTab(State.verbTabs[i]);
	}
	if (State.verbTabs.includes(State.currentTab)) doUpdate = true;
	if (v) {
		add_verb_list(v);
		sortVerbs();
		if (!_settingsActive && doUpdate) draw_verbs(State.currentTab);
	}
	SendTabsToByond();
}

function add_verb_list(v) {
	var toAdd = safeParse(v, []);
	if (!Array.isArray(toAdd)) return;
	toAdd.sort();
	for (var i = 0; i < toAdd.length; i++) {
		var part = toAdd[i];
		if (!part[0]) continue;
		var category = resolveTabDisplayName(part[0]);
		if (findVerbIndex(part[0], part[1], State.verbs) !== -1) continue;
		if (State.verbTabs.includes(category)) {
			State.verbs.push(part);
			if (!_settingsActive && State.currentTab === category) draw_verbs(category);
		} else if (category) {
			State.verbTabs.push(category);
			State.verbs.push(part);
			createStatusTab(category);
		}
	}
}

function remove_verb_list(v) {
	var toRemove = safeParse(v, []);
	if (!Array.isArray(toRemove)) return;
	for (var i = 0; i < toRemove.length; i++) {
		remove_verb(toRemove[i]);
	}
	check_verbs();
	sortVerbs();
	if (!_settingsActive && State.verbTabs.includes(State.currentTab)) draw_verbs(State.currentTab);
}

function update_split_admin_tabs(status) {
	status = (status === true);
	if (State.splitAdminTabs !== status) {
		if (State.splitAdminTabs === true) {
			removeStatusTab("Events");
			removeStatusTab("Fun");
			removeStatusTab("Game");
			removeStatusTab("Player Interaction");
		}
		update_verbs();
	}
	State.splitAdminTabs = status;
}


function create_debug() {
	if (!document.getElementById("tab-Debug Stat Panel")) {
		addPermanentTab("Debug Stat Panel");
	} else {
		removePermanentTab("Debug Stat Panel");
		if (State.currentTab === "Debug Stat Panel") tab_change("Status");
	}
}

function reapply_storage() {
	var theme = loadTheme();
	saveTheme(theme);
	applyTheme(theme);
	loadFavorites();
}
