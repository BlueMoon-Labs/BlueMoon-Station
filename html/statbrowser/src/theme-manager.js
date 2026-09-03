var GEAR_ICON_SVG = '<svg viewBox="0 0 16 16" fill="currentColor" width="14" height="14"><path d="M7.07 0l-.59 2.25a5.55 5.55 0 00-1.3.54L3.11 1.68 1.68 3.11l1.11 2.07c-.23.41-.4.85-.54 1.3L0 7.07v2.02l2.25.59c.14.45.31.89.54 1.3L1.68 13.05l1.43 1.43 2.07-1.11c.41.23.85.4 1.3.54L7.07 16.16h2.02l.59-2.25c.45-.14.89-.31 1.3-.54l2.07 1.11 1.43-1.43-1.11-2.07c.23-.41.4-.85.54-1.3l2.25-.59V7.07l-2.25-.59a5.55 5.55 0 00-.54-1.3l1.11-2.07-1.43-1.43-2.07 1.11c-.41-.23-.85-.4-1.3-.54L9.09 0H7.07zm1.01 4.5a3.58 3.58 0 110 7.16 3.58 3.58 0 010-7.16z"/></svg>';

var THEME_STORAGE_KEY = "statbrowser_theme";
var THEME_LOCAL_CACHE_KEY = "statbrowser_theme_cache";

var THEME_PRESETS = {
	"chat": {
		name: "Как в чате",
		vars: {
			"--bg-primary": "#202020",
			"--bg-secondary": "#1a1a1a",
			"--bg-tertiary": "#2a2a2a",
			"--bg-hover": "#333333",
			"--text-primary": "#abc6ec",
			"--text-secondary": "#8a9bb5",
			"--text-muted": "#556070",
			"--accent": "#dc143c",
			"--accent-hover": "#e8354f",
			"--health-good": "#4ec94e",
			"--health-warn": "#cca700",
			"--health-bad": "#f44747",
			"--border": "rgba(255, 255, 255, 0.08)"
		}
	},
	"vscode": {
		name: "VS Code Dark",
		vars: {
			"--bg-primary": "#1e1e1e",
			"--bg-secondary": "#252526",
			"--bg-tertiary": "#2d2d30",
			"--bg-hover": "#333337",
			"--text-primary": "#cccccc",
			"--text-secondary": "#969696",
			"--text-muted": "#5a5a5a",
			"--accent": "#0078d4",
			"--accent-hover": "#1a8ceb",
			"--health-good": "#4ec94e",
			"--health-warn": "#cca700",
			"--health-bad": "#f44747",
			"--border": "#3e3e42"
		}
	},
	"terminal": {
		name: "Terminal",
		vars: {
			"--bg-primary": "#0a0a0a",
			"--bg-secondary": "#111111",
			"--bg-tertiary": "#1a1a1a",
			"--bg-hover": "#222222",
			"--text-primary": "#33ff33",
			"--text-secondary": "#22aa22",
			"--text-muted": "#116611",
			"--accent": "#00ff00",
			"--accent-hover": "#44ff44",
			"--health-good": "#33ff33",
			"--health-warn": "#ffff33",
			"--health-bad": "#ff3333",
			"--border": "#1a3a1a",
			"--font-sans": "Consolas, 'Courier New', monospace"
		}
	},
	"cyberpunk": {
		name: "Cyberpunk",
		vars: {
			"--bg-primary": "#0d0221",
			"--bg-secondary": "#150535",
			"--bg-tertiary": "#1a0a3e",
			"--bg-hover": "#2a1050",
			"--text-primary": "#00f0ff",
			"--text-secondary": "#ff2a6d",
			"--text-muted": "#4a2060",
			"--accent": "#ff2a6d",
			"--accent-hover": "#ff5a8d",
			"--health-good": "#00ff9f",
			"--health-warn": "#f0e000",
			"--health-bad": "#ff0055",
			"--border": "rgba(0, 240, 255, 0.15)"
		}
	},
	"neon": {
		name: "Neon",
		vars: {
			"--bg-primary": "#0a0a12",
			"--bg-secondary": "#12121e",
			"--bg-tertiary": "#1a1a2e",
			"--bg-hover": "#24243a",
			"--text-primary": "#e0e0ff",
			"--text-secondary": "#a0a0cc",
			"--text-muted": "#505070",
			"--accent": "#7b2ff7",
			"--accent-hover": "#9b5fff",
			"--health-good": "#00ff88",
			"--health-warn": "#ffaa00",
			"--health-bad": "#ff2244",
			"--border": "rgba(123, 47, 247, 0.2)"
		}
	},
	"sakura": {
		name: "Sakura",
		vars: {
			"--bg-primary": "#1e1520",
			"--bg-secondary": "#2a1a2e",
			"--bg-tertiary": "#352238",
			"--bg-hover": "#402a44",
			"--text-primary": "#f0d0e0",
			"--text-secondary": "#c09ab0",
			"--text-muted": "#6a4a5a",
			"--accent": "#ff69b4",
			"--accent-hover": "#ff88cc",
			"--health-good": "#66cc88",
			"--health-warn": "#ddaa44",
			"--health-bad": "#ee5566",
			"--border": "rgba(255, 105, 180, 0.15)"
		}
	},
	"light": {
		name: "Светлая",
		vars: {
			"--bg-primary": "#ffffff",
			"--bg-secondary": "#f3f3f3",
			"--bg-tertiary": "#e8e8e8",
			"--bg-hover": "#e0e0e0",
			"--text-primary": "#1e1e1e",
			"--text-secondary": "#555555",
			"--text-muted": "#999999",
			"--accent": "#0078d4",
			"--accent-hover": "#1a8ceb",
			"--health-good": "#2ea043",
			"--health-warn": "#bf8700",
			"--health-bad": "#d32f2f",
			"--border": "#d4d4d4"
		}
	},
	"retro": {
		name: "Классика",
		vars: {
			"--bg-primary": "#1b1b1b",
			"--bg-secondary": "#161616",
			"--bg-tertiary": "#252525",
			"--bg-hover": "#2e2e2e",
			"--text-primary": "#c8c8c8",
			"--text-secondary": "#8a8a8a",
			"--text-muted": "#555555",
			"--accent": "#5f87af",
			"--accent-hover": "#7ea3c7",
			"--health-good": "#5faf5f",
			"--health-warn": "#d7af5f",
			"--health-bad": "#d75f5f",
			"--border": "rgba(255, 255, 255, 0.06)"
		},
		settings: {
			verbLayout: "grid",
			turfLayout: "list"
		}
	},
	"monokai": {
		name: "Monokai",
		vars: {
			"--bg-primary": "#272822",
			"--bg-secondary": "#1e1f1c",
			"--bg-tertiary": "#3e3d32",
			"--bg-hover": "#49483e",
			"--text-primary": "#f8f8f2",
			"--text-secondary": "#a6a28c",
			"--text-muted": "#75715e",
			"--accent": "#f92672",
			"--accent-hover": "#ff4f8e",
			"--health-good": "#a6e22e",
			"--health-warn": "#e6db74",
			"--health-bad": "#f92672",
			"--border": "rgba(255, 255, 255, 0.08)"
		}
	},
	"dracula": {
		name: "Dracula",
		vars: {
			"--bg-primary": "#282a36",
			"--bg-secondary": "#21222c",
			"--bg-tertiary": "#343746",
			"--bg-hover": "#3e4154",
			"--text-primary": "#f8f8f2",
			"--text-secondary": "#6272a4",
			"--text-muted": "#44475a",
			"--accent": "#ff79c6",
			"--accent-hover": "#ff92d0",
			"--health-good": "#50fa7b",
			"--health-warn": "#f1fa8c",
			"--health-bad": "#ff5555",
			"--border": "rgba(98, 114, 164, 0.3)"
		}
	},
	"nord": {
		name: "Nord",
		vars: {
			"--bg-primary": "#2e3440",
			"--bg-secondary": "#272c36",
			"--bg-tertiary": "#3b4252",
			"--bg-hover": "#434c5e",
			"--text-primary": "#eceff4",
			"--text-secondary": "#a3b1c7",
			"--text-muted": "#4c566a",
			"--accent": "#88c0d0",
			"--accent-hover": "#8fbcbb",
			"--health-good": "#a3be8c",
			"--health-warn": "#ebcb8b",
			"--health-bad": "#bf616a",
			"--border": "rgba(76, 86, 106, 0.5)"
		}
	}
};

var _customStyleEl = null;

function getDefaultThemeState() {
	return {
		preset: "chat",
		basePreset: "chat",
		overrides: {},
		fontFamily: "",
		fontSize: 12,
		borderRadius: 4,
		customCSS: "",
		verbLayout: "pills",
		verbStyle: "pills",
		hideVerbSearch: false,
		verbPadding: 5,
		tabPadding: 6,
		compactMode: false,
		turfIconSize: 32,
		turfLayout: "list",
		turfHideIcons: false,
		turfFontSize: 12,
		verbGridColumns: "auto",
		verbGridMinWidth: 135,
		turfGridColumns: "auto",
		mcGridColumns: "auto",
		mcGridMinWidth: 200
	};
}

var _SETTINGS_KEYS = ["verbLayout", "verbStyle", "hideVerbSearch", "verbPadding", "tabPadding", "compactMode",
	"turfLayout", "turfIconSize", "turfHideIcons", "turfFontSize",
	"verbGridColumns", "verbGridMinWidth", "turfGridColumns", "mcGridColumns", "mcGridMinWidth",
	"fontFamily", "fontSize", "borderRadius", "customCSS"];

function getPresetDefaults(presetKey) {
	var defaults = getDefaultThemeState();
	var preset = THEME_PRESETS[presetKey];
	if (preset && preset.settings) {
		for (var k in preset.settings) {
			defaults[k] = preset.settings[k];
		}
	}
	return defaults;
}

function checkPresetModified(themeState) {
	if (themeState.preset === "custom") return true;
	if (themeState.overrides && Object.keys(themeState.overrides).length > 0) return true;
	var presetDefaults = getPresetDefaults(themeState.preset);
	for (var i = 0; i < _SETTINGS_KEYS.length; i++) {
		var k = _SETTINGS_KEYS[i];
		if (themeState[k] !== presetDefaults[k]) return true;
	}
	return false;
}

function markCustomIfModified(themeState) {
	if (themeState.preset !== "custom" && checkPresetModified(themeState)) {
		themeState.basePreset = themeState.preset;
		themeState.preset = "custom";
	}
}

function loadTheme() {
	var defaults = getDefaultThemeState();
	var stored = null;
	try {
		stored = serverStorage.getItem(THEME_STORAGE_KEY);
	} catch (e) {}
	if (!stored) {
		try {
			stored = localStorage.getItem(THEME_LOCAL_CACHE_KEY);
		} catch (e) {}
	}
	if (stored) {
		try {
			var parsed = JSON.parse(stored);
			for (var k in defaults) {
				if (!(k in parsed)) parsed[k] = defaults[k];
			}
			return parsed;
		} catch (e) {}
	}
	return defaults;
}

function saveTheme(themeState) {
	var json = JSON.stringify(themeState);
	try { serverStorage.setItem(THEME_STORAGE_KEY, json); } catch (e) {}
	try { localStorage.setItem(THEME_LOCAL_CACHE_KEY, json); } catch (e) {}
}

function _resolvePreset(themeState) {
	var key = themeState.preset === "custom" ? (themeState.basePreset || "chat") : themeState.preset;
	return THEME_PRESETS[key] || THEME_PRESETS["chat"];
}

// Applies one grid surface's density settings: a fixed column count (body class + --<prefix>-grid-cols)
// or, when "auto", a responsive minimum cell width (--<prefix>-grid-min). Pass minDefault === null to
// skip the min-width var entirely (the turf grid uses its icon-size slider instead).
function applyGridLayout(prefix, columnsVal, minVal, minDefault) {
	var root = document.documentElement;
	var fixed = columnsVal && columnsVal !== "auto";
	document.body.classList.toggle(prefix + "-grid-fixed", !!fixed);
	if (fixed) {
		root.style.setProperty("--" + prefix + "-grid-cols", parseInt(columnsVal) || 2); // fallback: 2 cols on garbage input
	} else {
		root.style.removeProperty("--" + prefix + "-grid-cols");
	}
	if (minDefault != null) {
		root.style.setProperty("--" + prefix + "-grid-min", (minVal != null ? minVal : minDefault) + "px");
	}
}

function applyTheme(themeState) {
	var root = document.documentElement;
	var preset = _resolvePreset(themeState);
	root.style.removeProperty("--font-sans");
	if (preset) {
		for (var key in preset.vars) {
			root.style.setProperty(key, preset.vars[key]);
		}
	}
	for (var key in themeState.overrides) {
		root.style.setProperty(key, themeState.overrides[key]);
	}
	if (themeState.fontFamily) {
		root.style.setProperty("--font-sans", themeState.fontFamily);
	}
	root.style.setProperty("--font-size", themeState.fontSize + "px");
	root.style.setProperty("--border-radius", themeState.borderRadius + "px");
	var vp = themeState.verbPadding != null ? themeState.verbPadding : 5;
	root.style.setProperty("--verb-padding-v", vp + "px");
	root.style.setProperty("--verb-padding-h", (vp * 2) + "px");
	var tp = themeState.tabPadding != null ? themeState.tabPadding : 6;
	root.style.setProperty("--tab-padding-v", tp + "px");
	root.style.setProperty("--tab-padding-h", (tp * 2) + "px");
	var tis = themeState.turfIconSize != null ? themeState.turfIconSize : 32;
	root.style.setProperty("--turf-icon-size", tis + "px");
	var tfs = themeState.turfFontSize != null ? themeState.turfFontSize : 12;
	root.style.setProperty("--turf-font-size", tfs + "px");
	document.body.classList.toggle("verb-layout-grid", themeState.verbLayout === "grid");
	document.body.classList.toggle("verb-style-links", themeState.verbStyle === "links");
	document.body.classList.toggle("hide-verb-search", !!themeState.hideVerbSearch);
	document.body.classList.toggle("compact-mode", !!themeState.compactMode);
	document.body.classList.toggle("turf-layout-grid", themeState.turfLayout === "grid");
	document.body.classList.toggle("turf-layout-compact", themeState.turfLayout === "compact");
	document.body.classList.toggle("turf-hide-icons", !!themeState.turfHideIcons);
	applyGridLayout("verb", themeState.verbGridColumns, themeState.verbGridMinWidth, 135);
	applyGridLayout("turf", themeState.turfGridColumns, null, null); // no min-width var for turf — icon-size slider controls density
	applyGridLayout("mc", themeState.mcGridColumns, themeState.mcGridMinWidth, 200);
	if (!_customStyleEl) {
		_customStyleEl = document.createElement("style");
		_customStyleEl.id = "custom-theme-css";
		document.head.appendChild(_customStyleEl);
	}
	_customStyleEl.textContent = themeState.customCSS || "";
}

function getCurrentVarValues(themeState) {
	var result = {};
	var preset = _resolvePreset(themeState);
	if (preset) {
		for (var key in preset.vars) {
			result[key] = preset.vars[key];
		}
	}
	for (var key in themeState.overrides) {
		result[key] = themeState.overrides[key];
	}
	return result;
}

function exportTheme(themeState) {
	return JSON.stringify(themeState, null, 2);
}

function importTheme(jsonStr) {
	try {
		var parsed = JSON.parse(jsonStr);
		if (parsed && typeof parsed === "object" && parsed.preset) {
			var defaults = getDefaultThemeState();
			for (var k in defaults) {
				if (!(k in parsed)) parsed[k] = defaults[k];
			}
			return parsed;
		}
	} catch (e) {}
	return null;
}

function normalizeToHex(color) {
	if (!color) return "#000000";
	if (color.charAt(0) === "#" && color.length === 7) return color;
	if (color.charAt(0) === "#" && color.length === 4) {
		return "#" + color[1]+color[1] + color[2]+color[2] + color[3]+color[3];
	}
	var tmp = document.createElement("div");
	tmp.style.color = color;
	document.body.appendChild(tmp);
	var computed = getComputedStyle(tmp).color;
	document.body.removeChild(tmp);
	var match = computed.match(/\d+/g);
	if (match && match.length >= 3) {
		return "#" + ((1 << 24) + (parseInt(match[0]) << 16) + (parseInt(match[1]) << 8) + parseInt(match[2]))
			.toString(16).slice(1);
	}
	return "#000000";
}

// WCAG 2.1 relative-luminance + contrast-ratio helpers. Used by the settings panel to flag
// custom color pairs that would render text invisibly against their background.
function _hexToRgb(hex) {
	if (!hex || hex.charAt(0) !== "#") return null;
	if (hex.length === 4) {
		hex = "#" + hex[1]+hex[1] + hex[2]+hex[2] + hex[3]+hex[3];
	}
	if (hex.length !== 7) return null;
	return [parseInt(hex.substr(1, 2), 16), parseInt(hex.substr(3, 2), 16), parseInt(hex.substr(5, 2), 16)];
}

function _luminance(rgb) {
	if (!rgb) return 0;
	var a = rgb.map(function(v) {
		v /= 255;
		return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
	});
	return a[0] * 0.2126 + a[1] * 0.7152 + a[2] * 0.0722;
}

function contrastRatio(hexFg, hexBg) {
	var fg = _hexToRgb(normalizeToHex(hexFg));
	var bg = _hexToRgb(normalizeToHex(hexBg));
	if (!fg || !bg) return 0;
	var l1 = _luminance(fg);
	var l2 = _luminance(bg);
	var lighter = Math.max(l1, l2);
	var darker = Math.min(l1, l2);
	return (lighter + 0.05) / (darker + 0.05);
}

// Returns an object describing the WCAG verdict at the given size.
// Thresholds: AA-large 3.0, AA 4.5, AAA 7.0.
function contrastVerdict(ratio) {
	if (ratio >= 7) return { level: "AAA", className: "val-good", text: "AAA" };
	if (ratio >= 4.5) return { level: "AA", className: "val-good", text: "AA" };
	if (ratio >= 3) return { level: "AA Large", className: "val-warn", text: "AA крупн." };
	return { level: "fail", className: "val-bad", text: "Низкий" };
}
