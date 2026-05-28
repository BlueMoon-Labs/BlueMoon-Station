var globalSearchTimer = null;

function openGlobalSearch() {
	globalSearchOverlay.classList.add("visible");
	globalSearchBox.value = "";
	globalSearchBox.focus();
	renderGlobalSearchResults("");
}

function closeGlobalSearch() {
	globalSearchOverlay.classList.remove("visible");
	globalSearchBox.value = "";
	globalSearchResults.textContent = "";
}

function renderGlobalSearchResults(query) {
	globalSearchResults.textContent = "";
	query = query.toLowerCase().trim();
	if (!query) return;

	var byCategory = {};
	for (var i = 0; i < State.verbs.length; i++) {
		var part = State.verbs[i];
		var command = part[1];
		if (!command) continue;
		if (command.toLowerCase().indexOf(query) === -1) continue;
		var cat = resolveTabDisplayName(part[0]);
		if (!byCategory[cat]) byCategory[cat] = [];
		byCategory[cat].push(part);
	}

	for (var cat in byCategory) {
		if (!byCategory.hasOwnProperty(cat)) continue;
		globalSearchResults.appendChild(el("div", "search-cat-header", cat));
		var items = byCategory[cat];
		for (var j = 0; j < items.length; j++) {
			var item = el("a", "search-result-item", items[j][1]);
			item.href = "#";
			item.onclick = (function(cmd) {
				return function(e) {
					e.preventDefault();
					closeGlobalSearch();
					run_after_focus(function() {
						send_byond_command(cmd.replace(/\s/g, "-"));
					});
				};
			})(items[j][1]);
			globalSearchResults.appendChild(item);
		}
	}
}

globalSearchBox.oninput = function() {
	clearTimeout(globalSearchTimer);
	var val = this.value;
	globalSearchTimer = setTimeout(function() {
		renderGlobalSearchResults(val);
	}, 150);
};

globalSearchOverlay.onclick = function(e) {
	if (e.target === globalSearchOverlay) closeGlobalSearch();
};

// Returns true if the user is currently typing into something (we should NOT hijack their key).
function _shortcutInTextInput() {
	var ae = document.activeElement;
	if (!ae) return false;
	var tag = ae.tagName;
	if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return true;
	if (ae.isContentEditable) return true;
	return false;
}

// Tab list excluding chrome (search button, settings gear) — index by visible order.
function _orderedTabButtons() {
	var btns = [];
	var children = tabBar.children;
	for (var i = 0; i < children.length; i++) {
		var c = children[i];
		if (!c.classList || !c.classList.contains("tab-btn")) continue;
		btns.push(c);
	}
	btns.sort(function(a, b) {
		return (parseInt(a.style.order, 10) || 0) - (parseInt(b.style.order, 10) || 0);
	});
	return btns;
}

document.addEventListener("keydown", function(e) {
	if (e.key === "Escape") {
		if (globalSearchOverlay.classList.contains("visible")) {
			closeGlobalSearch();
			e.preventDefault();
			return;
		}
		if (_settingsActive) {
			_settingsActive = false;
			renderCurrentTab();
			e.preventDefault();
			return;
		}
	}
	// "/" or Ctrl+F opens global search — only when not typing into an input.
	if ((e.key === "/" || (e.key.toLowerCase() === "f" && (e.ctrlKey || e.metaKey))) && !_shortcutInTextInput()) {
		e.preventDefault();
		if (!globalSearchOverlay.classList.contains("visible")) openGlobalSearch();
		return;
	}
	// Ctrl+1..9 jumps to the Nth tab in display order.
	if ((e.ctrlKey || e.metaKey) && !e.shiftKey && !e.altKey && /^[1-9]$/.test(e.key) && !_shortcutInTextInput()) {
		var idx = parseInt(e.key, 10) - 1;
		var btns = _orderedTabButtons();
		if (idx < btns.length) {
			e.preventDefault();
			var label = btns[idx].id.replace(/^tab-/, "");
			tab_change(label);
		}
		return;
	}
});

// Ctrl+Click on any link copies its DM ref/href to the clipboard. Useful for admin workflows
// (paste into chat, share with another admin, feed into a SDQL2 query) without round-tripping
// through the BYOND verb panel.
document.addEventListener("click", function(e) {
	if (!(e.ctrlKey || e.metaKey)) return;
	var a = e.target;
	while (a && a !== document.body) {
		if (a.tagName === "A" && a.href) break;
		a = a.parentNode;
	}
	if (!a || !a.href) return;
	// Extract a meaningful identifier — REF or full href
	var match = /\[?(0x[0-9a-fA-F]+)\]?|(\?[^"'\s]+)/.exec(a.href);
	var payload = match ? (match[1] || match[2] || a.href) : a.href;
	try {
		if (navigator.clipboard && navigator.clipboard.writeText) {
			navigator.clipboard.writeText(payload);
		} else {
			// Fallback for environments without async clipboard
			var ta = document.createElement("textarea");
			ta.value = payload;
			document.body.appendChild(ta);
			ta.select();
			try { document.execCommand("copy"); } catch (err) {}
			document.body.removeChild(ta);
		}
		e.preventDefault();
		// Visual flash on the link to confirm the copy
		var prev = a.style.backgroundColor;
		a.style.backgroundColor = "var(--accent, #4a9eff)";
		setTimeout(function() { a.style.backgroundColor = prev; }, 200);
	} catch (err) {}
}, true);
