function draw_sdql2() {
	statcontent.textContent = "";
	for (var i = 0; i < State.sdql2.length; i++) {
		var part = State.sdql2[i];
		var card = el("div", "sdql-card");

		if (part[0]) {
			var badge = el("span", "sdql-badge");
			var statusText = ("" + part[0]).toUpperCase();
			if (statusText.indexOf("DONE") !== -1 || statusText.indexOf("ГОТ") !== -1) {
				badge.classList.add("sdql-done");
			} else {
				badge.classList.add("sdql-run");
			}
			badge.textContent = statusText;
			card.appendChild(badge);
		}

		if (part[2]) {
			var a = el("a");
			a.href = "?src=_statpanel_;statpanel_item_target=" + part[2] + ";statpanel_item_click=left";
			a.textContent = part[1];
			card.appendChild(a);
		} else {
			var text = el("span", "sdql-query", part[1]);
			card.appendChild(text);
		}

		statcontent.appendChild(card);
	}
}
