var SS_NAME = 0, SS_STATE = 1, SS_COST = 2, SS_TICK = 3, SS_OVERRUN = 4,
	SS_TICKS = 5, SS_FIRED = 6, SS_CAN_FIRE = 7, SS_IS_BG = 8, SS_REF = 9, SS_EXTRA = 10;
var STATE_LETTERS = ["  ", "Q", "R", "P", "S", "P"];
var MC_KEY_SUBSYSTEMS = ["Atmospherics", "Garbage", "Machines", "Lighting", "Clients", "Mobs", "Timer", "Objects"];
var SEARCH_ICON_SVG = '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2"><circle cx="6.5" cy="6.5" r="5"/><line x1="10" y1="10" x2="15" y2="15"/></svg>';
// Bridge protocol: must match STATBROWSER_PROTOCOL_VERSION in code/controllers/subsystem/statpanel.dm.
// Bumped when the DM->JS payload shape changes incompatibly. Mismatch logs a warning and asks DM to reload.
var EXPECTED_PROTOCOL_VERSION = 2;
