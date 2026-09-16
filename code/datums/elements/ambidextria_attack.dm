
/datum/element/ambidextria_attack
	element_flags = ELEMENT_DETACH
	// С предметами какого типа, будет производиться двойная атака
	var/list/attack_with_type

/datum/element/ambidextria_attack/Attach(obj/item/target, list/_attack_with_type)
	if(!isitem(target))
		return ELEMENT_INCOMPATIBLE
	. = ..()
	if(_attack_with_type)
		if(islist(_attack_with_type) && _attack_with_type.len)
			attack_with_type = _attack_with_type.Copy()
		else
			attack_with_type = list(_attack_with_type)
	if(!attack_with_type)
		attack_with_type = list(target.type)
	RegisterSignal(target, COMSIG_ITEM_ATTACK, PROC_REF(attack))
	RegisterSignal(target, COMSIG_ITEM_ATTACK_OBJ, PROC_REF(attack_obj))

/datum/element/ambidextria_attack/Detach(obj/item/source)
	. = ..()
	UnregisterSignal(source, list(COMSIG_ITEM_ATTACK, COMSIG_ITEM_ATTACK_OBJ))

/datum/element/ambidextria_attack/proc/get_second_blade(obj/item/blade, mob/living/user)
	var/obj/item/second_blade = user.get_inactive_held_item()
	// Если это сигнал от предмета во второй руке или не подходит по типу = игнорируем
	if(blade == second_blade || !is_type_in_list(second_blade, attack_with_type))
		return
	return second_blade

/datum/element/ambidextria_attack/proc/attack(obj/item/source, mob/living/M, mob/living/user, damage_multiplier)
	SIGNAL_HANDLER
	var/obj/item/second_blade = get_second_blade(source, user)
	if(!second_blade)
		return
	addtimer(CALLBACK(second_blade, TYPE_PROC_REF(/obj/item, attack), M, user, NONE, damage_multiplier), 0.2 SECONDS)
	//second_blade.attack(M, user, damage_multiplier = damage_multiplier)

/datum/element/ambidextria_attack/proc/attack_obj(obj/item/source, obj/O, mob/living/user)
	SIGNAL_HANDLER
	var/obj/item/second_blade = get_second_blade(source, user)
	if(!second_blade)
		return
	addtimer(CALLBACK(second_blade, TYPE_PROC_REF(/obj/item, attack_obj), O, user), 0.2 SECONDS)
	//second_blade.attack_obj(O, user)

/*

/**
 * Adds a rust overlay to atoms and allows removing it with a welder, wirebrush, or space cola.
 */
/datum/element/rust
	element_flags = ELEMENT_DETACH
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
*/