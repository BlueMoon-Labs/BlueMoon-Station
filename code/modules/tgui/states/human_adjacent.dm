/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/**
 * tgui state: human_adjacent_state
 *
 * In addition to default checks, only allows interaction for a
 * human adjacent user.
 */

GLOBAL_DATUM_INIT(human_adjacent_state, /datum/ui_state/human_adjacent_state, new)

/datum/ui_state/human_adjacent_state
	var/viewcheck = TRUE

/datum/ui_state/human_adjacent_state/can_use_topic(src_object, mob/user)
	. = user.default_can_use_topic(src_object, viewcheck)
	if(!viewcheck && isatom(src_object))
		var/atom/A = src_object
		if(!isturf(A.loc) && !user.contains(A))
			return UI_CLOSE

	var/dist = get_dist(src_object, user)
	if((dist > 1) || (!ishuman(user)))
		// Can't be used unless adjacent and human, even with TK
		. = min(., UI_UPDATE)

/datum/ui_state/human_adjacent_state/no_view
	viewcheck = FALSE

GLOBAL_DATUM_INIT(human_adjacent_state_no_view, /datum/ui_state/human_adjacent_state/no_view, new)
