function draw_tickets() {
	statcontent.textContent = "";
	if (!State.tickets || !State.tickets.length) return;

	var open = 0, inProgress = 0, closed = 0;
	for (var i = 0; i < State.tickets.length; i++) {
		var t = State.tickets[i];
		var label = ("" + (t[0] || "")).toLowerCase();
		if (label.indexOf("open") !== -1 || label.indexOf("откр") !== -1) open++;
		else if (label.indexOf("progress") !== -1 || label.indexOf("в работе") !== -1) inProgress++;
		else if (label.indexOf("close") !== -1 || label.indexOf("resolve") !== -1 || label.indexOf("закр") !== -1) closed++;
	}

	var summary = el("div", "ticket-summary");
	summary.appendChild(el("span", "ticket-summary-item val-good", "Открыто: " + open));
	summary.appendChild(el("span", "ticket-summary-item val-warn", "В работе: " + inProgress));
	summary.appendChild(el("span", "ticket-summary-item", "Закрыто: " + closed));
	statcontent.appendChild(summary);

	for (var i = 0; i < State.tickets.length; i++) {
		var part = State.tickets[i];
		var card = el("div", "ticket-card");
		var labelText = "" + (part[0] || "");
		var isClosed = labelText.toLowerCase().indexOf("close") !== -1 || labelText.toLowerCase().indexOf("resolve") !== -1 || labelText.toLowerCase().indexOf("закр") !== -1;
		if (isClosed) card.classList.add("ticket-closed");

		var indicator = el("span", "ticket-indicator");
		if (labelText.toLowerCase().indexOf("open") !== -1 || labelText.toLowerCase().indexOf("откр") !== -1) {
			indicator.style.backgroundColor = "var(--health-good)";
		} else if (labelText.toLowerCase().indexOf("progress") !== -1) {
			indicator.style.backgroundColor = "var(--health-warn)";
		} else {
			indicator.style.backgroundColor = "var(--text-muted)";
		}
		card.appendChild(indicator);

		var statusSpan = el("span", null, labelText);
		card.appendChild(statusSpan);

		var td2 = el("span");
		td2.style.flex = "1";
		if (part[2]) {
			var a = el("a");
			a.href = "#";
			a.onclick = (function(ref) {
				return function(e) {
					e.preventDefault();
					byond_topic("?_src_=holder;admin_token=" + State.hrefToken + ";ahelp=" + ref + ";ahelp_action=ticket");
				};
			})(part[2]);
			a.textContent = part[1];
			td2.appendChild(a);
		} else if (part[3]) {
			var a2 = el("a");
			a2.href = "#";
			a2.onclick = (function(ref) {
				return function(e) {
					e.preventDefault();
					byond_topic("?src=_statpanel_;statpanel_item_target=" + ref + ";statpanel_item_click=left");
				};
			})(part[3]);
			a2.textContent = part[1];
			td2.appendChild(a2);
		} else {
			td2.textContent = part[1];
		}
		card.appendChild(td2);
		statcontent.appendChild(card);
	}
}
