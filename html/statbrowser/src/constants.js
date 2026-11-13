// Subsystem row layout from generate_mc_data() in code/controllers/subsystem/statpanel.dm.
var SS_NAME = 0, SS_STATE = 1, SS_COST = 2, SS_TICK = 3, SS_OVERRUN = 4,
	SS_TICKS = 5, SS_FIRED = 6, SS_CAN_FIRE = 7, SS_IS_BG = 8, SS_REF = 9, SS_EXTRA = 10,
	SS_LOAD = 11, SS_WAIT = 12, SS_PRIORITY = 13, SS_FLAGS = 14, SS_NEXT_FIRE = 15,
	SS_LAST_FIRE = 16, SS_POSTPONED = 17, SS_PAUSED_TICKS = 18, SS_INIT_ORDER = 19, SS_INITIALIZED = 20;
var STATE_LETTERS = ["  ", "Q", "R", "P", "S", "P"];
var STATE_NAMES = ["Ждёт", "В очереди", "Работает", "На паузе", "Спит в fire()", "Уходит на паузу"];
// Subsystem flags, code/__DEFINES/MC.dm
var SS_FLAG_NAMES = [
	[1, "NO_INIT"], [2, "NO_FIRE"], [4, "BACKGROUND"], [8, "NO_TICK_CHECK"],
	[16, "TICKER"], [32, "KEEP_TIMING"], [64, "POST_FIRE_TIMING"]
];
var MC_KEY_SUBSYSTEMS = ["Atmospherics", "Garbage", "Machines", "Lighting", "Clients", "Mobs", "Timer", "Objects"];
var SEARCH_ICON_SVG = '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2"><circle cx="6.5" cy="6.5" r="5"/><line x1="10" y1="10" x2="15" y2="15"/></svg>';
// Bridge protocol: must match STATBROWSER_PROTOCOL_VERSION in code/controllers/subsystem/statpanel.dm.
// Bumped when the DM->JS payload shape changes incompatibly. Mismatch logs a warning and asks DM to reload.
var EXPECTED_PROTOCOL_VERSION = 4;
