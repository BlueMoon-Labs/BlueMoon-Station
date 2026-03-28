var GEAR_ICON_SVG = '<svg viewBox="0 0 16 16" fill="currentColor" width="14" height="14"><path d="M7.07 0l-.59 2.25a5.55 5.55 0 00-1.3.54L3.11 1.68 1.68 3.11l1.11 2.07c-.23.41-.4.85-.54 1.3L0 7.07v2.02l2.25.59c.14.45.31.89.54 1.3L1.68 13.05l1.43 1.43 2.07-1.11c.41.23.85.4 1.3.54L7.07 16.16h2.02l.59-2.25c.45-.14.89-.31 1.3-.54l2.07 1.11 1.43-1.43-1.11-2.07c.23-.41.4-.85.54-1.3l2.25-.59V7.07l-2.25-.59a5.55 5.55 0 00-.54-1.3l1.11-2.07-1.43-1.43-2.07 1.11c-.41-.23-.85-.4-1.3-.54L9.09 0H7.07zm1.01 4.5a3.58 3.58 0 110 7.16 3.58 3.58 0 010-7.16z"/></svg>';

var THEME_STORAGE_KEY = "statbrowser_theme";

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
	}
};

var _customStyleEl = null;

function getDefaultThemeState() {
	return {
		preset: "chat",
		overrides: {},
		fontFamily: "",
		fontSize: 12,
		borderRadius: 4,
		customCSS: ""
	};
}

function loadTheme() {
	try {
		var stored = serverStorage.getItem(THEME_STORAGE_KEY);
		if (stored) return JSON.parse(stored);
	} catch (e) {}
	return getDefaultThemeState();
}

function saveTheme(themeState) {
	try {
		serverStorage.setItem(THEME_STORAGE_KEY, JSON.stringify(themeState));
	} catch (e) {}
}

function applyTheme(themeState) {
	var root = document.documentElement;
	var preset = THEME_PRESETS[themeState.preset];
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
	if (!_customStyleEl) {
		_customStyleEl = document.createElement("style");
		_customStyleEl.id = "custom-theme-css";
		document.head.appendChild(_customStyleEl);
	}
	_customStyleEl.textContent = themeState.customCSS || "";
	document.body.classList.remove("light");
}

function getCurrentVarValues(themeState) {
	var result = {};
	var preset = THEME_PRESETS[themeState.preset];
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
