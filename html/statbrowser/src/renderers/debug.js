function draw_debug() {
	statcontent.textContent = "";

	var actionBar = el("div", "debug-action-bar");
	var wipeBtn = el("button", "debug-btn debug-btn-danger", "Wipe All Verbs");
	wipeBtn.onclick = function() { wipe_verbs(); };
	actionBar.appendChild(wipeBtn);
	var updateBtn = el("button", "debug-btn debug-btn-warn", "Wipe & Update All Verbs");
	updateBtn.onclick = function() { update_verbs(); };
	actionBar.appendChild(updateBtn);
	statcontent.appendChild(actionBar);

	var vtHeader = makeSectionHeader("vt", "Verb Tabs", { vt: true });
	vtHeader._toggle = function() {};
	statcontent.appendChild(vtHeader);
	var vtSection = el("div", "debug-section");
	for (var i = 0; i < State.verbTabs.length; i++) {
		var tabName = State.verbTabs[i];
		if (tabName.lastIndexOf(".") !== -1) {
			var sp = tabName.split(".");
			if (State.splitAdminTabs && sp[0] === "Admin") tabName = sp[1];
			else continue;
		}
		var item = el("div", "debug-item");
		item.appendChild(el("span", null, tabName));
		var del = el("span", "debug-delete", "Удалить");
		del.onclick = (function(n) {
			return function() { removeStatusTab(n); draw_debug(); };
		})(tabName);
		item.appendChild(del);
		vtSection.appendChild(item);
	}
	statcontent.appendChild(vtSection);

	var verbHeader = makeSectionHeader("vb", "Verbs (" + State.verbs.length + ")", { vb: true });
	verbHeader._toggle = function() {};
	statcontent.appendChild(verbHeader);
	var vSection = el("div", "debug-section");
	for (var v = 0; v < State.verbs.length; v++) {
		var part = State.verbs[v];
		var item2 = el("div", "debug-item");
		item2.appendChild(el("span", null, part[0]));
		item2.appendChild(el("span", "data-value", part[1]));
		vSection.appendChild(item2);
	}
	statcontent.appendChild(vSection);

	var ptHeader = makeSectionHeader("pt", "Permanent Tabs", { pt: true });
	ptHeader._toggle = function() {};
	statcontent.appendChild(ptHeader);
	var ptSection = el("div", "debug-section");
	for (var p = 0; p < State.permanentTabs.length; p++) {
		ptSection.appendChild(el("div", "debug-item", State.permanentTabs[p]));
	}
	statcontent.appendChild(ptSection);
}
