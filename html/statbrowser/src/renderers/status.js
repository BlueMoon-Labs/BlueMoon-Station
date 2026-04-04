var st_sections = { round: true, time: true, character: true };
var st_skeleton = null;
var st_els = {};
var st_fixSent = false;

var SHUTTLE_MODES = {
	"call":       { label: "Вызван",             cls: "shuttle-warn",   icon: "\u25B2" },
	"recall":     { label: "Отозван",            cls: "shuttle-safe",   icon: "\u25BC" },
	"docked":     { label: "На станции",         cls: "shuttle-danger", icon: "\u2193" },
	"escape":     { label: "Эвакуация",          cls: "shuttle-danger", icon: "\u2191" },
	"igniting":   { label: "Запуск двигателей",  cls: "shuttle-danger", icon: "\u2022" },
	"stranded":   { label: "Ошибка",             cls: "shuttle-danger shuttle-pulse", icon: "\u26A0" },
	"recharging": { label: "Перезарядка",        cls: "shuttle-warn",   icon: "\u21BB" },
	"landing":    { label: "Посадка",            cls: "shuttle-warn",   icon: "\u2193" }
};

function parseTimerSeconds(timerStr) {
	if (!timerStr || timerStr === "--:--") return -1;
	var parts = timerStr.split(":");
	if (parts.length !== 2) return -1;
	return (parseInt(parts[0], 10) || 0) * 60 + (parseInt(parts[1], 10) || 0);
}

function st_ensureSkeleton() {
	if (st_skeleton && st_skeleton.parentNode) return;
	statcontent.textContent = "";
	st_skeleton = el("div");

	st_els.shuttle = el("div", "shuttle-bar");
	st_els.shuttleIcon = el("span", "shuttle-icon");
	st_els.shuttle.appendChild(st_els.shuttleIcon);
	st_els.shuttleText = el("span", "shuttle-text");
	st_els.shuttle.appendChild(st_els.shuttleText);
	st_els.shuttleTimer = el("span", "shuttle-timer");
	st_els.shuttle.appendChild(st_els.shuttleTimer);
	st_els.shuttleProgress = el("div", "shuttle-progress");
	st_els.shuttleProgressFill = el("div", "shuttle-progress-fill");
	st_els.shuttleProgress.appendChild(st_els.shuttleProgressFill);
	st_els.shuttle.appendChild(st_els.shuttleProgress);
	st_skeleton.appendChild(st_els.shuttle);

	var roundHeader = makeSectionHeader("round", "Раунд", st_sections);
	st_els.roundGrid = el("div", "metric-grid");
	roundHeader._toggle = function() {
		st_els.roundGrid.style.display = st_sections.round ? "" : "none";
	};
	st_skeleton.appendChild(roundHeader);
	st_skeleton.appendChild(st_els.roundGrid);

	var timeHeader = makeSectionHeader("time", "Время", st_sections);
	st_els.timeGrid = el("div", "metric-grid");
	timeHeader._toggle = function() {
		st_els.timeGrid.style.display = st_sections.time ? "" : "none";
	};
	st_skeleton.appendChild(timeHeader);
	st_skeleton.appendChild(st_els.timeGrid);

	st_els.charHeader = makeSectionHeader("character", "Персонаж", st_sections);
	st_els.charTable = el("table", "data-table");
	st_els.charHeader._toggle = function() {
		st_els.charTable.style.display = st_sections.character ? "" : "none";
	};
	st_skeleton.appendChild(st_els.charHeader);
	st_skeleton.appendChild(st_els.charTable);

	st_els.voteSection = el("div", "vote-section");
	st_els.voteSection.style.display = "none";
	st_skeleton.appendChild(st_els.voteSection);

	statcontent.appendChild(st_skeleton);
}

function st_parseMobItem(str) {
	var idx = str.indexOf(": ");
	if (idx > 0 && idx < 30) return [str.substring(0, idx), str.substring(idx + 2)];
	return null;
}

function draw_status() {
	if (!document.getElementById("tab-Status")) {
		createStatusTab("Status");
		State.currentTab = "Status";
	}

	var d = {};
	if (State.globalFast) {
		for (var k in State.globalFast) d[k] = State.globalFast[k];
	}
	if (State.globalSlow) {
		d.server = State.globalSlow;
	}
	if (State.tidiData) {
		d.tidi = State.tidiData;
	}

	if (!State.globalFast && !State.pingData) {
		statcontent.textContent = "Загрузка...";
		return;
	}

	st_ensureSkeleton();

	if (d.shuttle) {
		st_els.shuttle.style.display = "flex";
		var modeKey = d.shuttle[2] || "";
		var timerStr = d.shuttle[1] || "00:00";
		var totalSec = d.shuttle[3] || 0;
		var cfg = SHUTTLE_MODES[modeKey] || { label: d.shuttle[0], cls: "shuttle-warn", icon: "\u25B2" };

		setText(st_els.shuttleIcon, cfg.icon);
		setText(st_els.shuttleText, cfg.label);
		setText(st_els.shuttleTimer, timerStr);
		st_els.shuttle.className = "shuttle-bar " + cfg.cls;

		var remainSec = parseTimerSeconds(timerStr);
		if (totalSec > 0 && remainSec >= 0) {
			var pct = Math.max(0, Math.min(100, ((totalSec - remainSec) / totalSec) * 100));
			st_els.shuttleProgressFill.style.width = pct + "%";
			st_els.shuttleProgress.style.display = "";
		} else {
			st_els.shuttleProgress.style.display = "none";
		}
	} else {
		st_els.shuttle.style.display = "none";
	}

	if (st_sections.round && d.server) {
		fillGrid(st_els.roundGrid, d.server);
		st_els.roundGrid.style.display = "";
	} else if (!st_sections.round) {
		st_els.roundGrid.style.display = "none";
	}

	if (st_sections.time && d.time) {
		fillGrid(st_els.timeGrid, d.time);
		st_els.timeGrid.style.display = "";
	} else if (!st_sections.time) {
		st_els.timeGrid.style.display = "none";
	}

	if (st_sections.character) {
		var charHash = State.mobItems.join("\n");
		if (st_els.charTable._lastHash !== charHash) {
			st_els.charTable._lastHash = charHash;
			st_els.charTable.textContent = "";
			for (var i = 0; i < State.mobItems.length; i++) {
				var item = State.mobItems[i];
				if (typeof item !== "string" || item.trim() === "") continue;
				var parsed = st_parseMobItem(item);
				if (parsed) {
					var tr = el("tr");
					var td1 = el("td", "data-label", parsed[0]);
					var td2 = el("td", "data-value", parsed[1]);
					tr.appendChild(td1);
					tr.appendChild(td2);
					st_els.charTable.appendChild(tr);
				} else {
					var tr2 = el("tr");
					var td = el("td", "data-value", item);
					td.colSpan = 2;
					tr2.appendChild(td);
					st_els.charTable.appendChild(tr2);
				}
			}
		}
		var hasItems = State.mobItems.length > 0;
		st_els.charTable.style.display = hasItems ? "" : "none";
		st_els.charHeader.style.display = hasItems ? "" : "none";
	} else {
		st_els.charTable.style.display = "none";
	}

	var vp = State.voteParts;
	if (vp && vp[0] && vp[0][0]) {
		st_els.voteSection.style.display = "";
		st_els.voteSection.textContent = "";
		var table = el("table", "vote-table");
		for (var i = 0; i < vp.length; i++) {
			var part = vp[i];
			var tr = el("tr");
			var td1 = el("td", null, part[0]);
			var td2 = el("td");
			if (part[2]) {
				var a = el("a");
				a.href = "#";
				a.style.cursor = "pointer";
				if (part[2] === "disabled") {
					a.onclick = function(e) {
						if (e && e.preventDefault) e.preventDefault();
						byond_winset({ command: "Vote" });
						return false;
					};
				} else {
					a.onclick = (function(ref) {
						return function(e) {
							if (e && e.preventDefault) e.preventDefault();
							byond_topic("?src=" + ref);
							return false;
						};
					})(part[2]);
				}
				a.textContent = part[1];
				td2.appendChild(a);
			} else {
				td2.textContent = part[1];
			}
			tr.appendChild(td1);
			tr.appendChild(td2);
			table.appendChild(tr);
		}
		st_els.voteSection.appendChild(table);
	} else {
		st_els.voteSection.style.display = "none";
	}

	if (!st_fixSent && (State.verbTabs.length === 0 || State.verbs.length === 0)) {
		st_fixSent = true;
		send_byond_command("Fix-Stat-Panel");
	}
}
