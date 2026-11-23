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

	var groups = [{ id: "", name: "Без группы" }].concat(panel.groups);
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
	var list = el("div", "verb-grid emote-group-list");
	list.id = "emote-group-" + group.id;
	list.dataset.group = group.id;
	var label = group.name + " (" + emotes.length + ")";
	var toggle = emoteButton("", "emote-group-toggle", function() {
		collapsed[group.id] = !collapsed[group.id];
		updateGroupVisibility();
	});
	toggle.setAttribute("aria-controls", list.id);
	header.appendChild(toggle);
	updateGroupVisibility();
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
	var item = el("div", entry ? "emote-item emote-sortable" : "emote-item");
	item.dataset.group = group;
	item.dataset.emote = emote.name;
	var button = emoteButton(emote.name, "emote-button", function() {
		sendEmoteAction("execute", { name: emote.name });
	});
	if (entry && entry.type === 1) {
		button.title = "*" + entry.key;
	} else if (entry && entry.type === 2) {
		button.classList.add("emote-custom");
		button.title = "*" + entry.key + " | " + entry.message_override;
	} else if (entry && entry.type === 3) {
		button.classList.add("emote-custom");
		button.title = entry.message;
	}
	item.oncontextmenu = function(event) {
		event.preventDefault();
		if (!emoteDrag) sendEmoteAction("contextAction", { name: emote.name });
	};
	item.appendChild(button);
	if (entry) {
		var handle = el("span", "emote-drag-handle", "⠿");
		handle.title = "Перетащить эмоцию";
		handle.setAttribute("aria-hidden", "true");
		item.appendChild(handle);
	}
	return item;
}

function startEmoteDrag(event) {
	var handle = event.target;
	if (event.button !== 0 || emoteDrag || !handle.classList.contains("emote-drag-handle")) return;
	if (!handle.setPointerCapture) return;
	handle.setPointerCapture(event.pointerId);
	emoteDrag = {
		handle: handle,
		item: handle.parentNode,
		root: event.currentTarget,
		pointerId: event.pointerId,
		x: event.clientX,
		y: event.clientY,
		target: null,
		marker: "",
		frame: null
	};
	emoteDrag.item.classList.add("emote-dragging");
	event.preventDefault();
}

function updateEmoteDrag(event) {
	if (!emoteDrag || emoteDrag.pointerId !== event.pointerId) return;
	emoteDrag.x = event.clientX;
	emoteDrag.y = event.clientY;
	updateEmoteDropTarget();
	queueEmoteDragScroll();
}

function updateEmoteDropTarget() {
	var drag = emoteDrag;
	// Обе координаты и прямоугольники уже учитывают масштаб статпанели.
	var hit = document.elementFromPoint(drag.x, drag.y);
	var target = hit && hit.closest(".emote-item, .emote-group-header, .emote-group-list");
	if (target === drag.item || !drag.root.contains(target)) target = null;
	var marker = "emote-drop-group";
	if (target && target.classList.contains("emote-item")) {
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
	drag.x = event.clientX;
	drag.y = event.clientY;
	updateEmoteDropTarget();
	finishEmoteDrag();
	if (!drag.target) return;
	sendEmoteAction("move", {
		name: drag.item.dataset.emote,
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
	drag.item.classList.remove("emote-dragging");
	if (drag.handle.hasPointerCapture(drag.pointerId)) drag.handle.releasePointerCapture(drag.pointerId);
}

window.addEventListener("blur", finishEmoteDrag);
