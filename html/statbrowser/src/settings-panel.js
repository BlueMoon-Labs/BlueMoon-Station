var _settingsActive = false;

function draw_settings() {
	_settingsActive = true;
	statcontent.textContent = "";
	var themeState = loadTheme();
	var panel = el("div", "settings-panel");

	var presetSection = el("div", "settings-section");
	presetSection.appendChild(el("div", "settings-section-title", "Тема"));
	var presetGrid = el("div", "settings-preset-grid");
	for (var key in THEME_PRESETS) {
		(function(k) {
			var btn = el("button", "settings-preset-btn" + (themeState.preset === k ? " active" : ""));
			btn.textContent = THEME_PRESETS[k].name;
			btn.onclick = function() {
				themeState.preset = k;
				themeState.overrides = {};
				saveTheme(themeState);
				applyTheme(themeState);
				draw_settings();
			};
			presetGrid.appendChild(btn);
		})(key);
	}
	presetSection.appendChild(presetGrid);
	panel.appendChild(presetSection);

	var colorSection = el("div", "settings-section");
	colorSection.appendChild(el("div", "settings-section-title", "Цвета"));
	var colorVars = [
		["--bg-primary", "Фон"],
		["--bg-secondary", "Фон панели вкладок"],
		["--text-primary", "Текст"],
		["--text-secondary", "Второстепенный текст"],
		["--accent", "Акцент"],
		["--border", "Граница"],
		["--health-good", "Здоровье (норма)"],
		["--health-warn", "Здоровье (внимание)"],
		["--health-bad", "Здоровье (критическое)"]
	];
	var effective = getCurrentVarValues(themeState);
	for (var i = 0; i < colorVars.length; i++) {
		(function(varName, label) {
			var row = el("div", "settings-row");
			row.appendChild(el("span", "settings-label", label));
			var input = document.createElement("input");
			input.type = "color";
			input.className = "settings-color-input";
			input.value = normalizeToHex(effective[varName] || "#000000");
			input.oninput = function() {
				themeState.overrides[varName] = input.value;
				saveTheme(themeState);
				applyTheme(themeState);
			};
			row.appendChild(input);
			colorSection.appendChild(row);
		})(colorVars[i][0], colorVars[i][1]);
	}
	panel.appendChild(colorSection);

	var typoSection = el("div", "settings-section");
	typoSection.appendChild(el("div", "settings-section-title", "Типографика"));

	var fontRow = el("div", "settings-row");
	fontRow.appendChild(el("span", "settings-label", "Шрифт"));
	var fontInput = document.createElement("input");
	fontInput.type = "text";
	fontInput.className = "settings-input";
	fontInput.style.width = "180px";
	fontInput.placeholder = "По умолчанию";
	fontInput.value = themeState.fontFamily || "";
	fontInput.oninput = function() {
		themeState.fontFamily = fontInput.value;
		saveTheme(themeState);
		applyTheme(themeState);
	};
	fontRow.appendChild(fontInput);
	typoSection.appendChild(fontRow);

	var sizeRow = el("div", "settings-row");
	sizeRow.appendChild(el("span", "settings-label", "Размер шрифта"));
	var sizeInput = document.createElement("input");
	sizeInput.type = "number";
	sizeInput.className = "settings-input";
	sizeInput.style.width = "60px";
	sizeInput.min = "8";
	sizeInput.max = "24";
	sizeInput.value = themeState.fontSize || 12;
	sizeInput.oninput = function() {
		themeState.fontSize = parseInt(sizeInput.value) || 12;
		saveTheme(themeState);
		applyTheme(themeState);
	};
	sizeRow.appendChild(sizeInput);
	typoSection.appendChild(sizeRow);
	panel.appendChild(typoSection);

	var advSection = el("div", "settings-section");
	advSection.appendChild(el("div", "settings-section-title", "Дополнительно"));

	var radRow = el("div", "settings-row");
	radRow.appendChild(el("span", "settings-label", "Скругление углов"));
	var radSlider = document.createElement("input");
	radSlider.type = "range";
	radSlider.className = "settings-slider";
	radSlider.min = "0";
	radSlider.max = "12";
	radSlider.step = "1";
	radSlider.value = themeState.borderRadius != null ? themeState.borderRadius : 4;
	var radValue = el("span", "settings-slider-value", radSlider.value + "px");
	radSlider.oninput = function() {
		themeState.borderRadius = parseInt(radSlider.value);
		radValue.textContent = radSlider.value + "px";
		saveTheme(themeState);
		applyTheme(themeState);
	};
	radRow.appendChild(radSlider);
	radRow.appendChild(radValue);
	advSection.appendChild(radRow);

	var cssRow = el("div", "settings-row");
	cssRow.style.flexDirection = "column";
	cssRow.style.alignItems = "stretch";
	cssRow.appendChild(el("span", "settings-label", "Свой CSS"));
	var cssArea = document.createElement("textarea");
	cssArea.className = "settings-textarea";
	cssArea.placeholder = "/* Ваш CSS здесь */";
	cssArea.value = themeState.customCSS || "";
	cssArea.oninput = function() {
		themeState.customCSS = cssArea.value;
		saveTheme(themeState);
		applyTheme(themeState);
	};
	cssRow.appendChild(cssArea);
	advSection.appendChild(cssRow);
	panel.appendChild(advSection);

	var actions = el("div", "settings-actions");

	var resetBtn = el("button", "settings-action-btn", "Сброс");
	resetBtn.onclick = function() {
		var def = getDefaultThemeState();
		saveTheme(def);
		applyTheme(def);
		draw_settings();
	};
	actions.appendChild(resetBtn);

	var exportBtn = el("button", "settings-action-btn", "Экспорт");
	exportBtn.onclick = function() {
		var json = exportTheme(loadTheme());
		if (navigator.clipboard && navigator.clipboard.writeText) {
			navigator.clipboard.writeText(json).then(function() {
				exportBtn.textContent = "Скопировано!";
				setTimeout(function() { exportBtn.textContent = "Экспорт"; }, 1500);
			});
		} else {
			var ta = document.createElement("textarea");
			ta.value = json;
			document.body.appendChild(ta);
			ta.select();
			document.execCommand("copy");
			document.body.removeChild(ta);
			exportBtn.textContent = "Скопировано!";
			setTimeout(function() { exportBtn.textContent = "Экспорт"; }, 1500);
		}
	};
	actions.appendChild(exportBtn);

	var importBtn = el("button", "settings-action-btn", "Импорт");
	importBtn.onclick = function() {
		var json = prompt("Вставьте JSON темы:");
		if (json) {
			var imported = importTheme(json);
			if (imported) {
				saveTheme(imported);
				applyTheme(imported);
				draw_settings();
			} else {
				alert("Неверный формат JSON");
			}
		}
	};
	actions.appendChild(importBtn);
	panel.appendChild(actions);

	statcontent.appendChild(panel);
}
