// AHELP_* enum constants must match code/__DEFINES/admin.dm
var AHELP_ACTIVE = 1, AHELP_CLOSED = 2, AHELP_RESOLVED = 3;

function ticketAgeText(seconds) {
	if (seconds == null || seconds < 0) return "";
	if (seconds < 60) return seconds + "с";
	var m = Math.floor(seconds / 60);
	var s = seconds % 60;
	if (m < 60) return m + "м " + s + "с";
	var h = Math.floor(m / 60);
	m = m % 60;
	return h + "ч " + m + "м";
}

function ticketAgeClass(seconds) {
	if (seconds == null) return "";
	if (seconds >= 600) return "val-bad";   // 10+ min — really stale
	if (seconds >= 180) return "val-warn";  // 3+ min — getting stale
	return "val-good";
}

function ticketStateInfo(meta) {
	var state = meta && meta.state;
	if (state === AHELP_ACTIVE) return { text: meta && meta.handler ? "В работе" : "Открыт", color: meta && meta.handler ? "var(--health-warn)" : "var(--health-good)", isClosed: false };
	if (state === AHELP_CLOSED) return { text: "Закрыт", color: "var(--text-muted)", isClosed: true };
	if (state === AHELP_RESOLVED) return { text: "Решён", color: "var(--text-muted)", isClosed: true };
	return { text: "", color: "var(--text-muted)", isClosed: false };
}

// Inline action descriptors mirror /datum/admin_help/proc/ClosureLinks in adminhelp.dm.
// Server-side hrefs accept the standard ahelp_action protocol; surfacing them here saves
// admins a round-trip into the chat window for the most common triage actions.
var TICKET_ACTIONS = [
	{ key: "reply",        label: "OTBET",  title: "Reply",   className: "" },
	{ key: "handle_issue", label: "HANDLE", title: "Handle",  className: "" },
	{ key: "close",        label: "CLOSE",  title: "Close",   className: "ticket-act-warn" },
	{ key: "resolve",      label: "RSLVE",  title: "Resolve", className: "ticket-act-good" },
	{ key: "reject",       label: "REJT",   title: "Reject",  className: "ticket-act-bad" }
];

// Render closed/resolved tickets behind a single collapsible row to keep the active list scannable.
var _ticketClosedExpanded = false;

// Per-ticket expand state, keyed by stable identifier (id/ref). Survives redraws so admins
// don't lose their place when DM pushes a tickets update. Stale keys are pruned on each draw.
var _ticketExpanded = {};

function _ticketKey(part) {
	var meta = part[3];
	if (meta && meta.id != null) return "id:" + meta.id;
	if (part[2]) return "ref:" + part[2];
	return null;
}

function _isTicketExpanded(part, isClosed) {
	var key = _ticketKey(part);
	if (key != null && Object.prototype.hasOwnProperty.call(_ticketExpanded, key)) {
		return _ticketExpanded[key];
	}
	// Default: active tickets are expanded (admins need to act on them), closed ones are collapsed.
	return !isClosed;
}

function _pruneExpandedState(seenKeys) {
	for (var k in _ticketExpanded) {
		if (Object.prototype.hasOwnProperty.call(_ticketExpanded, k) && !seenKeys[k]) {
			delete _ticketExpanded[k];
		}
	}
}

function draw_tickets() {
	// Preserve scroll position across redraws (toggle clicks, DM pushes).
	// Scroll happens on body/documentElement in this iframe, not on #statcontent.
	var scroller = document.scrollingElement || document.documentElement || document.body;
	var savedScroll = scroller ? scroller.scrollTop : 0;
	statcontent.textContent = "";
	if (!State.tickets || !State.tickets.length) {
		if (scroller) scroller.scrollTop = savedScroll;
		return;
	}

	var open = 0, inProgress = 0, closed = 0;
	var activeRows = [];
	var closedRows = [];
	var headerRows = [];
	var seenKeys = {};
	for (var i = 0; i < State.tickets.length; i++) {
		var t = State.tickets[i];
		var meta = t[3];
		var key = _ticketKey(t);
		if (key) seenKeys[key] = true;
		if (meta && meta.state != null) {
			if (meta.state === AHELP_ACTIVE) {
				if (meta.handler) inProgress++; else open++;
				activeRows.push(t);
			} else {
				closed++;
				closedRows.push(t);
			}
			continue;
		}
		// Header rows or legacy entries without metadata — preserve original behavior.
		var labelText = ("" + (t[0] || "")).toLowerCase();
		if (labelText.indexOf("ticket") !== -1 || labelText.indexOf("communications") !== -1 || labelText.indexOf("disconnected") !== -1) {
			headerRows.push(t);
		} else if (labelText.indexOf("close") !== -1 || labelText.indexOf("resolve") !== -1 || labelText.indexOf("закр") !== -1) {
			closed++;
			closedRows.push(t);
		} else {
			activeRows.push(t);
		}
	}
	_pruneExpandedState(seenKeys);

	var summary = el("div", "ticket-summary");
	summary.appendChild(el("span", "ticket-summary-item val-good", "Открыто: " + open));
	summary.appendChild(el("span", "ticket-summary-item val-warn", "В работе: " + inProgress));
	summary.appendChild(el("span", "ticket-summary-item", "Закрыто: " + closed));
	statcontent.appendChild(summary);

	for (var hi = 0; hi < headerRows.length; hi++) {
		statcontent.appendChild(_makeTicketHeaderRow(headerRows[hi]));
	}
	for (var ai = 0; ai < activeRows.length; ai++) {
		statcontent.appendChild(_makeTicketCard(activeRows[ai], false));
	}
	if (closedRows.length) {
		var toggle = el("div", "ticket-closed-toggle");
		toggle.textContent = (_ticketClosedExpanded ? "▼ Скрыть" : "▶ Показать") + " закрытые (" + closedRows.length + ")";
		toggle.onclick = function() {
			_ticketClosedExpanded = !_ticketClosedExpanded;
			draw_tickets();
		};
		statcontent.appendChild(toggle);
		if (_ticketClosedExpanded) {
			for (var ci = 0; ci < closedRows.length; ci++) {
				statcontent.appendChild(_makeTicketCard(closedRows[ci], true));
			}
		}
	}

	if (State.interviewManager && State.interviewManager.interviews && State.interviewManager.interviews.length > 0) {
		draw_interviews();
	}

	if (scroller) scroller.scrollTop = savedScroll;
}

function _makeTicketHeaderRow(part) {
	var card = el("div", "ticket-header-row");
	var labelText = "" + (part[0] || "");
	card.appendChild(el("span", "ticket-header-label", labelText));
	if (part[3] && typeof part[3] === "string") {
		var a = el("a", "ticket-header-link");
		a.href = "#";
		a.textContent = part[1];
		a.onclick = (function(ref) {
			return function(e) {
				e.preventDefault();
				byond_topic("?src=_statpanel_;statpanel_item_target=" + ref + ";statpanel_item_click=left");
			};
		})(part[3]);
		card.appendChild(a);
	} else {
		card.appendChild(el("span", "ticket-header-value", part[1] || ""));
	}
	return card;
}

function _makeTicketCard(part, isClosed) {
	var meta = part[3];
	var expanded = _isTicketExpanded(part, isClosed);
	var canToggle = _ticketKey(part) != null;

	var card = el("div", "ticket-card" + (expanded ? " ticket-card--expanded" : ""));
	if (isClosed) card.classList.add("ticket-closed");

	// Header row — always visible, click toggles expand.
	var header = el("div", "ticket-card-header");

	var caret = el("span", "ticket-caret", canToggle ? (expanded ? "▼" : "▶") : "·");
	header.appendChild(caret);

	var stateInfo = ticketStateInfo(meta);
	var indicator = el("span", "ticket-indicator");
	indicator.style.backgroundColor = stateInfo.color;
	indicator.title = stateInfo.text;
	header.appendChild(indicator);

	if (meta && meta.id != null) {
		header.appendChild(el("span", "ticket-id", "#" + meta.id));
	}

	var labelLink = el("a", "ticket-label");
	labelLink.href = "#";
	labelLink.textContent = part[0] || "";
	if (part[2]) {
		labelLink.title = "Открыть тикет в окне админки";
		labelLink.onclick = (function(ref) {
			return function(e) {
				e.preventDefault();
				e.stopPropagation();
				byond_topic("?_src_=holder;admin_token=" + State.hrefToken + ";ahelp=" + ref + ";ahelp_action=ticket");
			};
		})(part[2]);
	}
	header.appendChild(labelLink);

	var meta_box = el("div", "ticket-meta");
	if (meta && meta.handler) {
		var handler = el("span", "ticket-handler", meta.handler);
		handler.title = "Взял в работу: " + meta.handler;
		meta_box.appendChild(handler);
	}
	if (meta && meta.age != null) {
		var ageEl = el("span", "ticket-age " + ticketAgeClass(meta.age), ticketAgeText(meta.age));
		ageEl.title = meta.age + " секунд с момента открытия";
		meta_box.appendChild(ageEl);
	}
	header.appendChild(meta_box);

	if (canToggle) {
		header.classList.add("ticket-card-header--clickable");
		header.onclick = function(e) {
			// Don't toggle when the user actually clicked the label link, an action button,
			// or any nested interactive element — those handlers do their own thing.
			var node = e.target;
			while (node && node !== header) {
				var tag = node.tagName;
				if (tag === "A" || tag === "BUTTON") return;
				node = node.parentNode;
			}
			var key = _ticketKey(part);
			_ticketExpanded[key] = !_isTicketExpanded(part, isClosed);
			draw_tickets();
		};
	}

	card.appendChild(header);

	if (expanded) {
		// Body — full message text with proper wrapping.
		if (part[1]) {
			var body = el("div", "ticket-body");
			body.textContent = "" + part[1];
			card.appendChild(body);
		}
		// Action buttons only on active tickets, when DM gave us admin href + ticket REF.
		if (!isClosed && part[2] && State.hrefToken && meta && meta.state === AHELP_ACTIVE) {
			var actions = el("div", "ticket-actions");
			for (var aIdx = 0; aIdx < TICKET_ACTIONS.length; aIdx++) {
				var spec = TICKET_ACTIONS[aIdx];
				var btn = el("button", "ticket-action-btn " + spec.className, spec.label);
				btn.title = spec.title;
				btn.onclick = (function(ref, action) {
					return function(e) {
						e.preventDefault();
						e.stopPropagation();
						// ahelp_silent=1 tells DM not to pop the full ticket window after closure-type
						// actions — the whole point of these buttons is one-click triage from the
						// stat panel. Reply/handle_issue ignore the flag server-side.
						byond_topic("?_src_=holder;admin_token=" + State.hrefToken + ";ahelp=" + ref + ";ahelp_action=" + action + ";ahelp_silent=1");
					};
				})(part[2], spec.key);
				actions.appendChild(btn);
			}
			card.appendChild(actions);
		}
	} else if (part[1]) {
		// Compact one-line preview of the message, so collapsed cards aren't blank.
		var preview = el("div", "ticket-preview", "" + part[1]);
		card.appendChild(preview);
	}

	return card;
}
