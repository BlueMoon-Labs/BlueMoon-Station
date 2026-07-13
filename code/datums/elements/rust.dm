/**
 * Adds a rust overlay to atoms and allows removing it with a welder, wirebrush, or space cola.
 */
/datum/element/rust
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH
	id_arg_index = 2
	var/image/rust_overlay

/datum/element/rust/Attach(atom/target, rust_icon = 'icons/effects/rust_overlay.dmi', rust_icon_state = "rust_default")
	. = ..()
	if(!isatom(target))
		return ELEMENT_INCOMPATIBLE
	if(!rust_overlay)
		rust_overlay = image(rust_icon, rust_icon_state)
	ADD_TRAIT(target, TRAIT_RUSTY, ELEMENT_TRAIT(type))
	RegisterSignal(target, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(apply_rust_overlay))
	RegisterSignal(target, COMSIG_PARENT_EXAMINE, PROC_REF(handle_examine))
	RegisterSignal(target, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(on_interaction))
	RegisterSignal(target, list(COMSIG_ATOM_TOOL_ACT(TOOL_WELDER), COMSIG_ATOM_TOOL_ACT(TOOL_RUSTSCRAPER)), PROC_REF(tool_act))
	RegisterSignal(target, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_reagent_expose))
	target.update_appearance()

/datum/element/rust/Detach(atom/source)
	. = ..()
	UnregisterSignal(source, list(
		COMSIG_ATOM_UPDATE_OVERLAYS,
		COMSIG_PARENT_EXAMINE,
		COMSIG_ATOM_ITEM_INTERACTION,
		COMSIG_ATOM_TOOL_ACT(TOOL_WELDER),
		COMSIG_ATOM_TOOL_ACT(TOOL_RUSTSCRAPER),
		COMSIG_ATOM_EXPOSE_REAGENTS,
	))
	REMOVE_TRAIT(source, TRAIT_RUSTY, ELEMENT_TRAIT(type))
	source.update_appearance()

/datum/element/rust/proc/handle_examine(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("[source] is very rusty. You could <b>burn</b> or <b>scrape</b> it off, or pour some <b>space cola</b> on it.")

/datum/element/rust/proc/apply_rust_overlay(atom/parent_atom, list/overlays)
	SIGNAL_HANDLER
	if(rust_overlay)
		overlays += rust_overlay

/datum/element/rust/proc/tool_act(atom/source, mob/user, obj/item/item, list/processing_recipes)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(handle_tool_use), source, user, item)
	return TOOL_ACT_SIGNAL_BLOCKING

/datum/element/rust/proc/handle_tool_use(atom/source, mob/user, obj/item/item)
	switch(item.tool_behaviour)
		if(TOOL_WELDER)
			if(!item.tool_start_check(user, amount = 1))
				return
			user.balloon_alert(user, "burning off rust...")
			if(!item.use_tool(source, user, 5 SECONDS))
				return
			user.balloon_alert(user, "burned off rust")
			Detach(source)
		if(TOOL_RUSTSCRAPER)
			if(!item.tool_start_check(user))
				return
			user.balloon_alert(user, "scraping off rust...")
			if(!item.use_tool(source, user, 2 SECONDS))
				return
			user.balloon_alert(user, "scraped off rust")
			Detach(source)

/datum/element/rust/proc/on_reagent_expose(atom/source, list/reagents, datum/reagents/source_reagents, methods, volume_modifier, show_message, from_gas)
	SIGNAL_HANDLER
	if(from_gas)
		return
	for(var/datum/reagent/R in reagents)
		if(istype(R, /datum/reagent/consumable/space_cola))
			Detach(source)
			return

/datum/element/rust/proc/on_interaction(atom/source, mob/user, obj/item/tool, params)
	SIGNAL_HANDLER
	if(istype(tool, /obj/item/stack/tile) || istype(tool, /obj/item/stack/rods))
		user.balloon_alert(user, "floor too rusted!")
		return TOOL_ACT_SIGNAL_BLOCKING
