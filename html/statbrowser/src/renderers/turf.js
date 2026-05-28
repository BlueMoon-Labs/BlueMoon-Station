var turfTable = null;
var turfItemNodes = {};

function iconError() {
	var that = this;
	setTimeout(function() {
		var current_attempts = that.getAttribute("data-retry") || 0;
		current_attempts = parseInt(current_attempts);
		if (current_attempts > State.imageRetryLimit) return;
		var src = that.src.split("#")[0];
		that.src = "";
		that.src = src + "#" + current_attempts;
		that.setAttribute("data-retry", current_attempts + 1);
	}, State.imageRetryDelay);
}

function draw_listedturf() {
	if (!turfTable || !turfTable.parentNode) {
		statcontent.textContent = "";
		turfTable = el("div", "turf-grid-wrap");
		turfItemNodes = {};
		statcontent.appendChild(turfTable);
	}

	var newData = {};
	for (var i = 0; i < State.turfContents.length; i++) {
		newData[State.turfContents[i][1]] = State.turfContents[i];
	}

	for (var ref in turfItemNodes) {
		if (!(ref in newData)) {
			turfTable.removeChild(turfItemNodes[ref]);
			delete turfItemNodes[ref];
		}
	}

	var nextSibling = turfTable.firstChild;
	for (var i = 0; i < State.turfContents.length; i++) {
		var part = State.turfContents[i];
		var ref = part[1];

		if (ref in turfItemNodes) {
			var container = turfItemNodes[ref];
			var nameEl = container.querySelector(".turf-item-name");
			if (nameEl && nameEl.textContent !== part[0]) {
				nameEl.textContent = part[0];
				container.title = part[0];
			}
			if (container !== nextSibling) {
				turfTable.insertBefore(container, nextSibling);
			} else {
				nextSibling = nextSibling ? nextSibling.nextSibling : null;
			}
		} else {
			var container = el("div", "turf-item");
			container.title = part[0];
			var img = el("img");
			if (State.storedImages[ref]) {
				img.src = State.storedImages[ref];
			} else if (part[2]) {
				img.src = part[2];
				State.storedImages[ref] = part[2];
			} else {
				img.className = "icon-pending";
			}
			img.onerror = iconError;
			container.appendChild(img);
			var nameSpan = el("span", "turf-item-name", part[0]);
			container.appendChild(nameSpan);
			container.onmousedown = (function(p) {
				return function(e) {
					e.preventDefault();
					var clickcatcher = "?src=_statpanel_;statpanel_item_target=" + p[1];
					switch (e.button) {
						case 1: clickcatcher += ";statpanel_item_click=middle"; break;
						case 2: clickcatcher += ";statpanel_item_click=right"; break;
						default: clickcatcher += ";statpanel_item_click=left";
					}
					if (e.shiftKey) clickcatcher += ";statpanel_item_shiftclick=1";
					if (e.ctrlKey) clickcatcher += ";statpanel_item_ctrlclick=1";
					if (e.altKey) clickcatcher += ";statpanel_item_altclick=1";
					byond_topic(clickcatcher);
				};
			})(part);
			turfItemNodes[ref] = container;
			turfTable.insertBefore(container, nextSibling);
		}
	}
}
