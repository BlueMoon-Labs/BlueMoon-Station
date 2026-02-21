/**
 * ## Item interaction
 *
 * Handles non-combat interactions of a tool on this atom,
 * such as using a tool on a wall to deconstruct it,
 * or scanning someone with a health analyzer
 */
/atom/proc/base_item_interaction(mob/living/user, obj/item/tool, params)
	SHOULD_CALL_PARENT(TRUE)
	PROTECTED_PROC(TRUE)

	if(tool.tool_behaviour && !SEND_SIGNAL(usr, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE))
		var/tool_return = tool_act(user, tool, tool.tool_behaviour)
		if(tool_return)
			return tool_return

	/*
	 * This is intentionally using `||` instead of `|` to short-circuit the signal calls
	 * This is because we want to return early if ANY of these signals return a value
	 *
	 * This puts priority on the atom's signals, then the tool's signals, then the user's signals,
	 * so we can avoid doing two interactions at once
	 */
	var/early_sig_return = SEND_SIGNAL(src, COMSIG_ATOM_ITEM_INTERACTION, user, tool, params) \
		|| SEND_SIGNAL(tool, COMSIG_ITEM_INTERACTING_WITH_ATOM, user, src, params) \
		|| SEND_SIGNAL(user, COMSIG_USER_ITEM_INTERACTION, src, tool, params)
	if(early_sig_return)
		return early_sig_return

	return NONE


// Tool behavior procedure. Redirects to tool-specific procs by default.
// You can override it to catch all tool interactions, for use in complex deconstruction procs.
// Just don't forget to return ..() in the end.
/atom/proc/tool_act(mob/living/user, obj/item/tool, params)
	var/tool_type = tool.tool_behaviour
	if(!tool_type)
		return NONE

	var/list/processing_recipes = list()
	var/signal_result = SEND_SIGNAL(src, COMSIG_ATOM_TOOL_ACT(tool_type), user, tool, processing_recipes)
	if(signal_result)
		return signal_result
	if(length(processing_recipes))
		process_recipes(user, tool, processing_recipes)
		return TOOL_ACT_TOOLTYPE_SUCCESS
	if(QDELETED(tool))
		return TOOL_ACT_TOOLTYPE_SUCCESS // Safe-ish to assume that if we deleted our item something succeeded

	switch(tool_type)
		if(TOOL_CROWBAR)
			return crowbar_act(user, tool)
		if(TOOL_MULTITOOL)
			. = multitool_act(user, tool)
			tool.update_icon()
			return
		if(TOOL_SCREWDRIVER)
			return screwdriver_act(user, tool)
		if(TOOL_WRENCH)
			return wrench_act(user, tool)
		if(TOOL_WIRECUTTER)
			return wirecutter_act(user, tool)
		if(TOOL_WELDER)
			return welder_act(user, tool)
		if(TOOL_ANALYZER)
			return analyzer_act(user, tool)

/// Called on an object when a tool with crowbar capabilities is used to left click an object
/atom/proc/crowbar_act(mob/living/user, obj/item/tool)
	return

/// Called on an object when a tool with multitool capabilities is used to left click an object
/atom/proc/multitool_act(mob/living/user, obj/item/tool)
	return

/// Called on an object when a tool with screwdriver capabilities is used to left click an object
/atom/proc/screwdriver_act(mob/living/user, obj/item/tool)
	return

/// Called on an object when a tool with wrench capabilities is used to left click an object
/atom/proc/wrench_act(mob/living/user, obj/item/tool)
	return

/// Called on an object when a tool with wirecutter capabilities is used to left click an object
/atom/proc/wirecutter_act(mob/living/user, obj/item/tool)
	return

/// Called on an object when a tool with welder capabilities is used to left click an object
/atom/proc/welder_act(mob/living/user, obj/item/tool)
	return

/// Called on an object when a tool with analyzer capabilities is used to left click an object
/atom/proc/analyzer_act(mob/living/user, obj/item/tool)
	return
