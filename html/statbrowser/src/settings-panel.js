var _settingsActive = false;
var _fontApplyTimer = null;

function draw_settings() {
	_settingsActive = true;
	clearTimeout(_fontApplyTimer);
	statcontent.textContent = "";
	var themeState = loadTheme();
	var panel = el("div", "settings-panel");

	var presetSection = el("div", "settings-section");
	presetSection.appendChild(el("div", "settings-section-title", "Тема"));
	var presetGrid = el("div", "settings-preset-grid");
	for (var key in THEME_PRESETS) {
		(function(k) {
			var isActive = themeState.preset === k;
			var btn = el("button", "settings-preset-btn" + (isActive ? " active" : ""));
			btn.textContent = THEME_PRESETS[k].name;
			btn.onclick = function() {
				themeState.preset = k;
				themeState.basePreset = k;
				themeState.overrides = {};
				var defaults = getDefaultThemeState();
				for (var li = 0; li < _SETTINGS_KEYS.length; li++) {
					themeState[_SETTINGS_KEYS[li]] = defaults[_SETTINGS_KEYS[li]];
				}
				var presetSettings = THEME_PRESETS[k].settings;
				if (presetSettings) {
					for (var sk in presetSettings) {
						themeState[sk] = presetSettings[sk];
					}
				}
				saveTheme(themeState);
				applyTheme(themeState);
				draw_settings();
			};
			presetGrid.appendChild(btn);
		})(key);
	}
	if (themeState.preset === "custom") {
		var customLabel = el("button", "settings-preset-btn custom-indicator");
		customLabel.textContent = "\u2728 \u041A\u0430\u0441\u0442\u043E\u043C\u043D\u0430\u044F";
		customLabel.onclick = function() {};
		presetGrid.appendChild(customLabel);
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
				var wasPre = themeState.preset;
				markCustomIfModified(themeState);
				saveTheme(themeState);
				applyTheme(themeState);
				if (themeState.preset !== wasPre) draw_settings();
			};
			row.appendChild(input);
			colorSection.appendChild(row);
		})(colorVars[i][0], colorVars[i][1]);
	}
	panel.appendChild(colorSection);

	var typoSection = el("div", "settings-section");
	typoSection.appendChild(el("div", "settings-section-title", "Типографика"));

	var FONT_OPTIONS = [
		["", "По умолчанию"],
		["Segoe UI", "Segoe UI"],
		["Arial", "Arial"],
		["Verdana", "Verdana"],
		["Tahoma", "Tahoma"],
		["Trebuchet MS", "Trebuchet MS"],
		["Georgia", "Georgia"],
		["Times New Roman", "Times New Roman"],
		["Consolas", "Consolas"],
		["Courier New", "Courier New"],
		["Lucida Console", "Lucida Console"],
		["Comic Sans MS", "Comic Sans MS"],
		["Impact", "Impact"]
	];
	var currentFont = themeState.fontFamily || "";
	var isCustomFont = currentFont && !FONT_OPTIONS.some(function(f) { return f[0] === currentFont; });

	var fontRow = el("div", "settings-row");
	fontRow.appendChild(el("span", "settings-label", "Шрифт"));
	var fontControls = el("div", "settings-font-controls");
	var fontSelect = document.createElement("select");
	fontSelect.className = "settings-select";
	for (var fi = 0; fi < FONT_OPTIONS.length; fi++) {
		var opt = document.createElement("option");
		opt.value = FONT_OPTIONS[fi][0];
		opt.textContent = FONT_OPTIONS[fi][1];
		if (opt.value) opt.style.fontFamily = opt.value;
		fontSelect.appendChild(opt);
	}
	var customOpt = document.createElement("option");
	customOpt.value = "__custom__";
	customOpt.textContent = "Свой...";
	fontSelect.appendChild(customOpt);
	fontSelect.value = isCustomFont ? "__custom__" : currentFont;

	var customFontInput = document.createElement("input");
	customFontInput.type = "text";
	customFontInput.className = "settings-input settings-font-custom";
	customFontInput.placeholder = "Название шрифта";
	customFontInput.value = isCustomFont ? currentFont : "";
	customFontInput.style.display = isCustomFont ? "" : "none";

	fontSelect.onchange = function() {
		if (fontSelect.value === "__custom__") {
			customFontInput.style.display = "";
			customFontInput.focus();
		} else {
			customFontInput.style.display = "none";
			themeState.fontFamily = fontSelect.value;
			var wasPre = themeState.preset;
			markCustomIfModified(themeState);
			saveTheme(themeState);
			applyTheme(themeState);
			if (themeState.preset !== wasPre) draw_settings();
		}
	};
	customFontInput.oninput = function() {
		clearTimeout(_fontApplyTimer);
		_fontApplyTimer = setTimeout(function() {
			themeState.fontFamily = customFontInput.value;
			var wasPre = themeState.preset;
			markCustomIfModified(themeState);
			saveTheme(themeState);
			applyTheme(themeState);
			if (themeState.preset !== wasPre) draw_settings();
		}, 500);
	};

	fontControls.appendChild(fontSelect);
	fontControls.appendChild(customFontInput);
	fontRow.appendChild(fontControls);
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
		var wasPre = themeState.preset;
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		if (themeState.preset !== wasPre) draw_settings();
	};
	sizeRow.appendChild(sizeInput);
	typoSection.appendChild(sizeRow);
	panel.appendChild(typoSection);

	// ===== Layout section =====
	var layoutSection = el("div", "settings-section");
	layoutSection.appendChild(el("div", "settings-section-title", "Расположение"));

	var verbLayoutRow = el("div", "settings-row");
	verbLayoutRow.appendChild(el("span", "settings-label", "Вид команд"));
	var verbLayoutGroup = el("div", "settings-btn-group");
	var pillsBtn = el("button", "settings-toggle-btn" + (themeState.verbLayout !== "grid" ? " active" : ""));
	pillsBtn.textContent = "Кнопки";
	pillsBtn.onclick = function() {
		themeState.verbLayout = "pills";
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		draw_settings();
	};
	verbLayoutGroup.appendChild(pillsBtn);
	var gridBtn = el("button", "settings-toggle-btn" + (themeState.verbLayout === "grid" ? " active" : ""));
	gridBtn.textContent = "Сетка";
	gridBtn.onclick = function() {
		themeState.verbLayout = "grid";
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		draw_settings();
	};
	verbLayoutGroup.appendChild(gridBtn);
	verbLayoutRow.appendChild(verbLayoutGroup);
	layoutSection.appendChild(verbLayoutRow);

	var verbStyleRow = el("div", "settings-row");
	verbStyleRow.appendChild(el("span", "settings-label", "Стиль команд"));
	var verbStyleGroup = el("div", "settings-btn-group");
	var stylePillsBtn = el("button", "settings-toggle-btn" + (themeState.verbStyle !== "links" ? " active" : ""));
	stylePillsBtn.textContent = "Кнопки";
	stylePillsBtn.onclick = function() {
		themeState.verbStyle = "pills";
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		draw_settings();
	};
	verbStyleGroup.appendChild(stylePillsBtn);
	var styleLinksBtn = el("button", "settings-toggle-btn" + (themeState.verbStyle === "links" ? " active" : ""));
	styleLinksBtn.textContent = "Ссылки";
	styleLinksBtn.onclick = function() {
		themeState.verbStyle = "links";
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		draw_settings();
	};
	verbStyleGroup.appendChild(styleLinksBtn);
	verbStyleRow.appendChild(verbStyleGroup);
	layoutSection.appendChild(verbStyleRow);

	var hideSearchRow = el("div", "settings-row");
	hideSearchRow.appendChild(el("span", "settings-label", "Скрыть поиск команд"));
	var hideSearchCheck = document.createElement("input");
	hideSearchCheck.type = "checkbox";
	hideSearchCheck.className = "settings-checkbox";
	hideSearchCheck.checked = !!themeState.hideVerbSearch;
	hideSearchCheck.onchange = function() {
		themeState.hideVerbSearch = hideSearchCheck.checked;
		var wasPre = themeState.preset;
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		if (themeState.preset !== wasPre) draw_settings();
	};
	hideSearchRow.appendChild(hideSearchCheck);
	layoutSection.appendChild(hideSearchRow);

	var verbPadRow = el("div", "settings-row");
	verbPadRow.appendChild(el("span", "settings-label", "Отступы кнопок"));
	var verbPadSlider = document.createElement("input");
	verbPadSlider.type = "range";
	verbPadSlider.className = "settings-slider";
	verbPadSlider.min = "1";
	verbPadSlider.max = "12";
	verbPadSlider.step = "1";
	verbPadSlider.value = themeState.verbPadding != null ? themeState.verbPadding : 5;
	var verbPadValue = el("span", "settings-slider-value", verbPadSlider.value + "px");
	verbPadSlider.oninput = function() {
		themeState.verbPadding = parseInt(verbPadSlider.value);
		verbPadValue.textContent = verbPadSlider.value + "px";
		var wasPre = themeState.preset;
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		if (themeState.preset !== wasPre) draw_settings();
	};
	verbPadRow.appendChild(verbPadSlider);
	verbPadRow.appendChild(verbPadValue);
	layoutSection.appendChild(verbPadRow);

	var tabPadRow = el("div", "settings-row");
	tabPadRow.appendChild(el("span", "settings-label", "Отступы вкладок"));
	var tabPadSlider = document.createElement("input");
	tabPadSlider.type = "range";
	tabPadSlider.className = "settings-slider";
	tabPadSlider.min = "0";
	tabPadSlider.max = "12";
	tabPadSlider.step = "1";
	tabPadSlider.value = themeState.tabPadding != null ? themeState.tabPadding : 6;
	var tabPadValue = el("span", "settings-slider-value", tabPadSlider.value + "px");
	tabPadSlider.oninput = function() {
		themeState.tabPadding = parseInt(tabPadSlider.value);
		tabPadValue.textContent = tabPadSlider.value + "px";
		var wasPre = themeState.preset;
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		if (themeState.preset !== wasPre) draw_settings();
	};
	tabPadRow.appendChild(tabPadSlider);
	tabPadRow.appendChild(tabPadValue);
	layoutSection.appendChild(tabPadRow);

	var compactRow = el("div", "settings-row");
	compactRow.appendChild(el("span", "settings-label", "Компактный режим"));
	var compactCheck = document.createElement("input");
	compactCheck.type = "checkbox";
	compactCheck.className = "settings-checkbox";
	compactCheck.checked = !!themeState.compactMode;
	compactCheck.onchange = function() {
		themeState.compactMode = compactCheck.checked;
		var wasPre = themeState.preset;
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		if (themeState.preset !== wasPre) draw_settings();
	};
	compactRow.appendChild(compactCheck);
	layoutSection.appendChild(compactRow);

	panel.appendChild(layoutSection);

	// ===== Turf (floor) section =====
	var turfSection = el("div", "settings-section");
	turfSection.appendChild(el("div", "settings-section-title", "Осмотр пола"));

	var turfLayoutRow = el("div", "settings-row");
	turfLayoutRow.appendChild(el("span", "settings-label", "Стиль"));
	var turfLayoutGroup = el("div", "settings-btn-group");
	var turfLayouts = [
		["list", "Список"],
		["grid", "Сетка"],
		["compact", "Компактный"]
	];
	for (var ti = 0; ti < turfLayouts.length; ti++) {
		(function(key, label) {
			var tBtn = el("button", "settings-toggle-btn" + ((themeState.turfLayout || "list") === key ? " active" : ""));
			tBtn.textContent = label;
			tBtn.onclick = function() {
				themeState.turfLayout = key;
				markCustomIfModified(themeState);
				saveTheme(themeState);
				applyTheme(themeState);
				draw_settings();
			};
			turfLayoutGroup.appendChild(tBtn);
		})(turfLayouts[ti][0], turfLayouts[ti][1]);
	}
	turfLayoutRow.appendChild(turfLayoutGroup);
	turfSection.appendChild(turfLayoutRow);

	var turfIconRow = el("div", "settings-row");
	turfIconRow.appendChild(el("span", "settings-label", "Размер иконок"));
	var turfIconSlider = document.createElement("input");
	turfIconSlider.type = "range";
	turfIconSlider.className = "settings-slider";
	turfIconSlider.min = "16";
	turfIconSlider.max = "48";
	turfIconSlider.step = "2";
	turfIconSlider.value = themeState.turfIconSize != null ? themeState.turfIconSize : 32;
	var turfIconValue = el("span", "settings-slider-value", turfIconSlider.value + "px");
	turfIconSlider.oninput = function() {
		themeState.turfIconSize = parseInt(turfIconSlider.value);
		turfIconValue.textContent = turfIconSlider.value + "px";
		var wasPre = themeState.preset;
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		if (themeState.preset !== wasPre) draw_settings();
	};
	turfIconRow.appendChild(turfIconSlider);
	turfIconRow.appendChild(turfIconValue);
	turfSection.appendChild(turfIconRow);

	var turfHideRow = el("div", "settings-row");
	turfHideRow.appendChild(el("span", "settings-label", "Скрыть иконки"));
	var turfHideCheck = document.createElement("input");
	turfHideCheck.type = "checkbox";
	turfHideCheck.className = "settings-checkbox";
	turfHideCheck.checked = !!themeState.turfHideIcons;
	turfHideCheck.onchange = function() {
		themeState.turfHideIcons = turfHideCheck.checked;
		var wasPre = themeState.preset;
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		if (themeState.preset !== wasPre) draw_settings();
	};
	turfHideRow.appendChild(turfHideCheck);
	turfSection.appendChild(turfHideRow);

	var turfFontRow = el("div", "settings-row");
	turfFontRow.appendChild(el("span", "settings-label", "Размер текста"));
	var turfFontSlider = document.createElement("input");
	turfFontSlider.type = "range";
	turfFontSlider.className = "settings-slider";
	turfFontSlider.min = "8";
	turfFontSlider.max = "18";
	turfFontSlider.step = "1";
	turfFontSlider.value = themeState.turfFontSize != null ? themeState.turfFontSize : 12;
	var turfFontValue = el("span", "settings-slider-value", turfFontSlider.value + "px");
	turfFontSlider.oninput = function() {
		themeState.turfFontSize = parseInt(turfFontSlider.value);
		turfFontValue.textContent = turfFontSlider.value + "px";
		var wasPre = themeState.preset;
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		if (themeState.preset !== wasPre) draw_settings();
	};
	turfFontRow.appendChild(turfFontSlider);
	turfFontRow.appendChild(turfFontValue);
	turfSection.appendChild(turfFontRow);

	panel.appendChild(turfSection);

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
		var wasPre = themeState.preset;
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		if (themeState.preset !== wasPre) draw_settings();
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
		var wasPre = themeState.preset;
		markCustomIfModified(themeState);
		saveTheme(themeState);
		applyTheme(themeState);
		if (themeState.preset !== wasPre) draw_settings();
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
