/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/client/var/datum/tgui_panel/tgui_panel
/// When TRUE, the tgui panel will not auto-switch to new UI on load.
/// Set when the user explicitly chooses "switch to old ui" via Fix Chat.
/client/var/use_legacy_chat = FALSE

/**
 * tgui panel / chat troubleshooting verb
 */
/client/verb/fix_tgui_panel()
	set name = "Fix chat"
	set category = "OOC"
	var/action
	log_tgui(src, "Started fixing.", context = "verb/fix_tgui_panel")

	nuke_chat()

	// Failed to fix, using tgalert as fallback
	action = tgalert(src, "Did that work?", "", "Yes", "No, switch to old ui")
	if (action == "No, switch to old ui")
		use_legacy_chat = TRUE
		winset(src, "legacy_output_selector", "left=output_legacy")
		log_tgui(src, "Failed to fix.", context = "verb/fix_tgui_panel")

/client/proc/nuke_chat()
	// Reset legacy chat flag — user is attempting to use new UI
	use_legacy_chat = FALSE
	// Catch all solution (kick the whole thing in the pants)
	winset(src, "legacy_output_selector", "left=output_legacy")
	if(!tgui_panel || !istype(tgui_panel))
		log_tgui(src, "tgui_panel datum is missing",
			context = "verb/fix_tgui_panel")
		tgui_panel = new(src)
	tgui_panel.initialize(force = TRUE)
	// The on_message("ready") handler will switch to output_browser
	// when the panel is actually loaded, respecting use_legacy_chat.

/mob/verb/fix_overlays()
	set name = "Fix Overlays"
	set category = "OOC"

	cut_overlays()
	regenerate_icons()
