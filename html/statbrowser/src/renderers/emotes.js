var collapsedEmoteGroups = Object.create(null);
var emoteDrag = null;

function update_emotes(payload) {
	var panel = safeParse(payload);
	if (!panel || !Array.isArray(panel.emotes) || !Array.isArray(panel.groups)) return;
	if (State.currentTab !== STATPANEL_EMOTES_TAB) return;
	var scrollPosition = State.emotePanel && State.emotePanel.slot === panel.slot ? window.scrollY : 0;
	State.emotePanel = panel;
	if (_settingsActive) return;
	draw_emotes();
	window.scrollTo(0, scrollPosition);
}

function sendEmoteAction(action, fields) {
	var panel = State.emotePanel;
	if (!panel) return;
	run_after_focus(function() {
		if (_settingsActive || State.emotePanel !== panel) return;
		byond_bridge_call("", Object.assign({
			statpanel_emotes: "emotes/" + action,
			slot: panel.slot
		}, fields));
	});
}

function emoteButton(label, cls, action) {
	var button = el("button", cls, label);
	button.type = "button";
	button.onclick = action;
	return button;
}

function draw_emotes() {
	finishEmoteDrag();
	statcontent.textContent = "";
	var panel = State.emotePanel;
	if (!panel) {
		statcontent.appendChild(el("div", "fav-empty-msg", "Загрузка эмоций…"));
		return;
	}

	var root = el("div", "emote-panel");
	root.addEventListener("pointerdown", startEmoteDrag);
	root.addEventListener("pointermove", updateEmoteDrag);
	root.addEventListener("pointerup", dropEmote);
	root.addEventListener("pointercancel", cancelEmotePointer);
	root.addEventListener("lostpointercapture", cancelEmotePointer);
	var toolbar = el("div", "emote-toolbar");
	toolbar.appendChild(emoteButton("+ Эмоция", "emote-control", function() {
		sendEmoteAction("create");
	}));
	toolbar.appendChild(emoteButton("+ Группа", "emote-control", function() {
		sendEmoteAction("createGroup");
	}));
	root.appendChild(toolbar);

	var groups = [{ id: "", name: "Без группы", color: panel.ungroupedColor }].concat(panel.groups);
	var emotesByGroup = Object.create(null);
	for (var i = 0; i < groups.length; i++) emotesByGroup[groups[i].id] = [];
	for (var j = 0; j < panel.emotes.length; j++) {
		var emote = panel.emotes[j];
		var group = emote.entry && emote.entry.group;
		(emotesByGroup[group] || emotesByGroup[""]).push(emote);
	}

	var collapsed = collapsedEmoteGroups[panel.slot];
	if (!collapsed) collapsed = collapsedEmoteGroups[panel.slot] = Object.create(null);
	for (var id in collapsed) {
		if (!emotesByGroup[id]) delete collapsed[id];
	}
	for (var k = 0; k < groups.length; k++) {
		var currentGroup = groups[k];
		root.appendChild(drawEmoteGroup(currentGroup, emotesByGroup[currentGroup.id], collapsed));
	}
	statcontent.appendChild(root);
}

function drawEmoteGroup(group, emotes, collapsed) {
	var section = el("section", "emote-group");
	var header = el("div", "emote-group-header");
	header.dataset.group = group.id;
	var list = el("div", "emote-group-list");
	list.id = "emote-group-" + group.id;
	list.dataset.group = group.id;
	var label = group.name + " (" + emotes.length + ")";
	var toggle = emoteButton("", "emote-group-toggle", function() {
		collapsed[group.id] = !collapsed[group.id];
		updateGroupVisibility();
	});
	toggle.setAttribute("aria-controls", list.id);
	if (/^#[0-9a-f]{6}$/i.test(group.color)) {
		toggle.style.setProperty("--emote-group-color", group.color);
		toggle.style.setProperty("--emote-group-text", contrastRatio("#000000", group.color) >= 4.5 ? "#000000" : "#FFFFFF");
	}
	header.appendChild(toggle);
	updateGroupVisibility();
	var colorButton = emoteButton("Цвет", "emote-control", function() {
		sendEmoteAction("colorGroup", {
			group: group.id,
			defaultColor: normalizeToHex(getComputedStyle(toggle).backgroundColor)
		});
	});
	var colorLabel = "Изменить цвет группы «" + group.name + "»";
	colorButton.setAttribute("aria-label", colorLabel);
	colorButton.title = colorLabel;
	if (group.color) {
		colorButton.title += " · ПКМ — вернуть цвет темы";
		colorButton.oncontextmenu = function(event) {
			event.preventDefault();
			sendEmoteAction("colorGroup", { group: group.id, reset: 1 });
		};
	}
	header.appendChild(colorButton);
	if (group.id) {
		var edit = emoteButton("⋯", "emote-control", function() {
			sendEmoteAction("editGroup", { group: group.id });
		});
		edit.title = "Действия с группой «" + group.name + "»";
		edit.setAttribute("aria-label", edit.title);
		header.appendChild(edit);
	}
	if (!emotes.length) {
		list.appendChild(el("div", "emote-group-empty", "Перетащите сюда эмоцию"));
	}
	for (var i = 0; i < emotes.length; i++) list.appendChild(drawEmoteItem(emotes[i], group.id));
	section.appendChild(header);
	section.appendChild(list);
	return section;

	function updateGroupVisibility() {
		list.hidden = !!collapsed[group.id];
		toggle.setAttribute("aria-expanded", String(!list.hidden));
		toggle.textContent = (list.hidden ? "▸ " : "▾ ") + label;
	}
}

function drawEmoteItem(emote, group) {
	var entry = emote.entry;
	var button = emoteButton(emote.name, entry ? "emote-button emote-sortable" : "emote-button", function(event) {
		if (event.detail && button._skipEmoteClick) {
			button._skipEmoteClick = false;
			return;
		}
		sendEmoteAction("execute", { name: emote.name });
	});
	button.dataset.group = group;
	button.dataset.emote = emote.name;
	if (entry && /^#[0-9a-f]{6}$/i.test(entry.color)) {
		button.classList.add("emote-colored");
		button.style.setProperty("--emote-color", entry.color);
		button.style.setProperty("--emote-color-text", contrastRatio("#000000", entry.color) >= 4.5 ? "#000000" : "#FFFFFF");
	} else if (entry && (entry.type === 2 || entry.type === 3)) {
		button.classList.add("emote-custom");
	}
	if (entry && entry.type === 1) {
		button.title = "*" + entry.key;
	} else if (entry && entry.type === 2) {
		button.title = "*" + entry.key + " | " + entry.message_override;
	} else if (entry && entry.type === 3) {
		button.title = entry.message;
	}
	button.oncontextmenu = function(event) {
		event.preventDefault();
		if (!emoteDrag || !emoteDrag.active) {
			sendEmoteAction("contextAction", {
				name: emote.name,
				defaultColor: normalizeToHex(getComputedStyle(button).backgroundColor)
			});
		}
	};
	return button;
}

function startEmoteDrag(event) {
	var button = event.target;
	if (event.button !== 0 || emoteDrag || !button.classList.contains("emote-sortable")) return;
	if (!button.setPointerCapture) return;
	button._skipEmoteClick = false;
	button.setPointerCapture(event.pointerId);
	emoteDrag = {
		button: button,
		root: event.currentTarget,
		pointerId: event.pointerId,
		startX: event.clientX,
		startY: event.clientY,
		active: false,
		target: null,
		marker: "",
		frame: null
	};
}

function updateEmoteDrag(event) {
	var drag = emoteDrag;
	if (!drag || drag.pointerId !== event.pointerId) return;
	if (!drag.active) {
		var dx = event.clientX - drag.startX;
		var dy = event.clientY - drag.startY;
		if (dx * dx + dy * dy < 25) return;
		drag.active = true;
		drag.button.classList.add("emote-dragging");
	}
	drag.x = event.clientX;
	drag.y = event.clientY;
	updateEmoteDropTarget();
	if (event.type === "pointermove") queueEmoteDragScroll();
}

function updateEmoteDropTarget() {
	var drag = emoteDrag;
	// Обе координаты и прямоугольники уже учитывают масштаб статпанели.
	var hit = document.elementFromPoint(drag.x, drag.y);
	var target = hit && hit.closest(".emote-button, .emote-group-header, .emote-group-list");
	if (target === drag.button || !drag.root.contains(target)) target = null;
	var marker = "emote-drop-group";
	if (target && target.classList.contains("emote-button")) {
		var rect = target.getBoundingClientRect();
		marker = drag.x < (rect.left + rect.right) / 2 ? "emote-drop-before" : "emote-drop-after";
	}
	if (drag.target === target && drag.marker === marker) return;
	if (drag.target) drag.target.classList.remove(drag.marker);
	drag.target = target;
	drag.marker = marker;
	if (target) target.classList.add(marker);
}

function queueEmoteDragScroll() {
	var drag = emoteDrag;
	if (drag.frame !== null) return;
	var scroll = document.scrollingElement;
	if (!scroll) return;
	var top = tabBar.getBoundingClientRect().bottom;
	var bottom = window.innerHeight;
	if (drag.x < 0 || drag.x >= window.innerWidth || drag.y < top || drag.y >= bottom) return;
	var direction = 0;
	if (drag.y < top + 26 && scroll.scrollTop > 0) direction = -1;
	else if (drag.y > bottom - 26 && scroll.scrollTop + scroll.clientHeight < scroll.scrollHeight) direction = 1;
	if (!direction) return;
	drag.frame = requestAnimationFrame(function() {
		drag.frame = null;
		var previous = scroll.scrollTop;
		scroll.scrollTop += direction * 10;
		if (scroll.scrollTop === previous) return;
		updateEmoteDropTarget();
		queueEmoteDragScroll();
	});
}

function dropEmote(event) {
	var drag = emoteDrag;
	if (!drag || drag.pointerId !== event.pointerId) return;
	updateEmoteDrag(event);
	finishEmoteDrag();
	if (!drag.target) return;
	sendEmoteAction("move", {
		name: drag.button.dataset.emote,
		group: drag.target.dataset.group,
		anchor: drag.target.dataset.emote,
		after: drag.marker === "emote-drop-after" ? 1 : 0
	});
}

function cancelEmotePointer(event) {
	if (emoteDrag && emoteDrag.pointerId === event.pointerId) finishEmoteDrag();
}

function finishEmoteDrag() {
	var drag = emoteDrag;
	if (!drag) return;
	emoteDrag = null;
	if (drag.frame !== null) cancelAnimationFrame(drag.frame);
	if (drag.target) drag.target.classList.remove(drag.marker);
	if (drag.active) {
		// После отпускания браузер может прислать клик по захваченной кнопке.
		drag.button._skipEmoteClick = true;
		drag.button.classList.remove("emote-dragging");
	}
	if (drag.button.hasPointerCapture(drag.pointerId)) drag.button.releasePointerCapture(drag.pointerId);
}

window.addEventListener("blur", finishEmoteDrag);
