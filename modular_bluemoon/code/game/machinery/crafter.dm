#define MANUFACTURING_TURF_LAG_LIMIT 10

GLOBAL_LIST_EMPTY(attackby_recipes)

/datum/crafting_recipe/attackby

/proc/init_attackby_recipes()
	GLOB.attackby_recipes += new /datum/crafting_recipe/attackby/cable_restraints

/datum/crafting_recipe/attackby/cable_restraints
	name = "Cable Restraints"
	reqs = list(/obj/item/stack/cable_coil = 15)
	result = /obj/item/restraints/handcuffs/cable
	time = 0

/// Wrapper for stack recipes so crafter can use them
/datum/crafting_recipe/stack_wrap
	var/datum/stack_recipe/stack_ref
	var/stack_type
	name = "stack recipe"

/proc/is_craftable_item(datum/crafting_recipe/R)
	if(isnull(R?.result))
		return FALSE
	var/obj/result_type = R.result
	if(!ispath(result_type, /obj/item))
		return FALSE
	if(initial(result_type.anchored))
		return FALSE
	return TRUE

/proc/is_food_recipe(datum/crafting_recipe/R)
	return R.category == CAT_FOOD

/// Check if stack recipe result is an item (not a structure)
/proc/is_craftable_stack(datum/stack_recipe/R)
	if(isnull(R?.result_type))
		return FALSE
	if(!ispath(R.result_type, /obj/item))
		return FALSE
	var/obj/check_type = R.result_type
	if(initial(check_type.anchored))
		return FALSE
	return TRUE

/datum/component/personal_crafting/machine

/datum/component/personal_crafting/machine/proc/is_recipe_available(datum/crafting_recipe/potential_recipe, mob/user)
	if(!potential_recipe.always_availible && !(potential_recipe.type in user?.mind?.learned_recipes))
		return FALSE
	return TRUE

/datum/component/personal_crafting/machine/get_environment(atom/crafter, list/blacklist = null, radius_range = 1)
	. = list()
	var/turf/crafter_loc = get_turf(crafter)
	for(var/atom/movable/content as anything in crafter_loc.contents)
		if((content.flags_1 & HOLOGRAM_1) || (blacklist && (content.type in blacklist)))
			continue
		if(isitem(content))
			var/obj/item/item = content
			if(item.item_flags & ABSTRACT)
				continue
		. += content

/datum/component/personal_crafting/machine/check_tools(atom/source, datum/crafting_recipe/recipe, list/surroundings, final_check = FALSE)
	return TRUE

/obj/machinery/power/manufacturing
	icon = 'modular_bluemoon/icons/obj/machines/crafter.dmi'
	name = "base manufacture receiving type"
	desc = "this shouldnt exist"
	density = TRUE
	var/may_be_moved = TRUE

/obj/machinery/power/manufacturing/Initialize(mapload)
	. = ..()
	if(may_be_moved)
		AddComponent(/datum/component/simple_rotation, ROTATION_ALTCLICK)
	if(anchored)
		connect_to_network()

/obj/machinery/power/manufacturing/examine(mob/user)
	. = ..()
	if(may_be_moved)
		. += span_notice("It receives power via cable.")
	. += length(contents - circuit) ? span_notice("It contains:") : span_notice("It contains no items.")
	for(var/atom/movable/thing as anything in contents - circuit)
		var/text = thing.name
		var/obj/item/stack/possible_stack = thing
		if(istype(possible_stack))
			text = "[possible_stack.amount] [text]"
		. += text

/obj/machinery/power/manufacturing/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(!may_be_moved)
		return
	default_unfasten_wrench(user, tool)
	if(anchored)
		connect_to_network()
	else
		disconnect_from_network()
	return TRUE

/obj/machinery/power/manufacturing/crafter/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	update_printing_overlay()

/obj/machinery/power/manufacturing/screwdriver_act(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, tool)

/obj/machinery/power/manufacturing/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/power/manufacturing/proc/receive_resource(atom/movable/receiving, atom/from, receive_dir)
	CRASH("Unimplemented!")

/obj/machinery/power/manufacturing/proc/send_resource(atom/movable/sending, atom/what_or_dir)
	if(isobj(what_or_dir))
		var/obj/machinery/power/manufacturing/target = what_or_dir
		return target.receive_resource(sending, src, get_step(src, what_or_dir))
	var/turf/next_turf = isturf(what_or_dir) ? what_or_dir : get_step(src, what_or_dir)
	var/obj/machinery/power/manufacturing/manufactury = locate(/obj/machinery/power/manufacturing) in next_turf
	if(!isnull(manufactury))
		if(!manufactury.anchored)
			return FALSE
		return manufactury.receive_resource(sending, src, isturf(what_or_dir) ? get_dir(src, what_or_dir) : what_or_dir)
	if(next_turf.is_blocked_turf(exclude_mobs = TRUE, source_atom = sending) && !ischasm(next_turf))
		return FALSE
	if(length(get_overfloor_objects(next_turf)) >= MANUFACTURING_TURF_LAG_LIMIT)
		return FALSE
	if(isnull(sending))
		return TRUE
	if(isnull(sending.loc) || !sending.Move(next_turf, get_dir(src, next_turf)))
		sending.forceMove(next_turf)
	return TRUE

/obj/machinery/power/manufacturing/proc/get_overfloor_objects(turf/target)
	. = list()
	if(isnull(target))
		target = get_turf(src)
	for(var/atom/movable/thing as anything in target.contents)
		if(thing == src || isliving(thing) || iseffect(thing) || thing.invisibility >= INVISIBILITY_ABSTRACT)
			continue
		. += thing

// ==================== CRAFTER (craft + attackby + stack) ====================

/obj/machinery/power/manufacturing/crafter
	name = "factorio crafter"
	desc = "Assembles (crafts) the set recipe until it runs out of resources. Only resources on it will be used."
	icon_state = "crafter"
	density = FALSE
	circuit = /obj/item/circuitboard/machine/manucrafter
	active_power_usage = 5 KILO WATTS
	var/list/datum/weakref/withheld = list()
	var/datum/crafting_recipe/recipe
	var/datum/crafting_recipe/attackby/attackby_recipe
	var/datum/crafting_recipe/stack_wrap/stack_wrap_recipe
	var/datum/component/personal_crafting/machine/craftsman
	var/craft_timer
	var/mutable_appearance/printing_overlay

/obj/machinery/power/manufacturing/crafter/Initialize(mapload)
	. = ..()
	craftsman = AddComponent(/datum/component/personal_crafting/machine)
	if(ispath(recipe))
		recipe = locate(recipe) in GLOB.crafting_recipes
	START_PROCESSING(SSobj, src)

/obj/machinery/power/manufacturing/crafter/proc/update_printing_overlay()
	cut_overlays()
	if(anchored && (!isnull(attackby_recipe) || !isnull(stack_wrap_recipe) || !isnull(recipe)))
		printing_overlay = mutable_appearance(icon, "crafter_printing")
		add_overlay(printing_overlay)

/obj/machinery/power/manufacturing/crafter/examine(mob/user)
	. = ..()
	if(!isnull(attackby_recipe))
		. += span_notice("It is currently manufacturing <b>[attackby_recipe.name]</b>.")
		. += span_notice("It needs:")
		for(var/valid_type in attackby_recipe.reqs)
			var/atom/ingredient = valid_type
			var/amount = attackby_recipe.reqs[ingredient]
			. += "[amount > 1 ? ("[amount]" + " of") : "a"] [initial(ingredient.name)]"
		return
	if(!isnull(stack_wrap_recipe))
		var/datum/stack_recipe/SR = stack_wrap_recipe.stack_ref
		. += span_notice("It is currently manufacturing <b>[SR.title]</b>.")
		. += span_notice("It needs:")
		var/obj/item/stack/source = stack_wrap_recipe.stack_type
		. += "[SR.req_amount > 1 ? "[SR.req_amount]x" : "a"] [initial(source.name)]"
		return
	. += span_notice("It is currently manufacturing <b>[isnull(recipe) ? "nothing. Use a multitool to set it" : recipe.name]</b>.")
	if(isnull(recipe))
		return
	. += span_notice("It needs:")
	for(var/valid_type in recipe.reqs)
		var/datum/reagent/reagent_ingredient = valid_type
		if(istype(reagent_ingredient))
			var/amount = recipe.reqs[reagent_ingredient]
			. += "[amount] unit[amount > 1 ? "s" : ""] of [initial(reagent_ingredient.name)]"
			continue
		var/atom/ingredient = valid_type
		var/amount = recipe.reqs[ingredient]
		. += "[amount > 1 ? ("[amount]" + " of") : "a"] [initial(ingredient.name)]"

/obj/machinery/power/manufacturing/crafter/receive_resource(obj/receiving, atom/from, receive_dir)
	var/turf/machine_turf = get_turf(src)
	if(length(machine_turf.contents) >= MANUFACTURING_TURF_LAG_LIMIT)
		return FALSE
	receiving.forceMove(machine_turf)
	return TRUE

/obj/machinery/power/manufacturing/crafter/multitool_act(mob/living/user, obj/item/tool)
	. = NONE

	var/list/available_recipes = list()

	// Normal crafting recipes (no food)
	for(var/datum/crafting_recipe/potential_recipe as anything in GLOB.crafting_recipes)
		if(is_food_recipe(potential_recipe))
			continue
		if(!is_craftable_item(potential_recipe))
			continue
		if(!craftsman.is_recipe_available(potential_recipe, user))
			continue
		available_recipes += potential_recipe

	// Attackby recipes
	for(var/datum/crafting_recipe/attackby/potential_recipe as anything in GLOB.attackby_recipes)
		if(!is_craftable_item(potential_recipe))
			continue
		available_recipes += potential_recipe

	// Stack recipes (items only)
	for(var/list/stack_list in list(GLOB.metal_recipes, GLOB.rod_recipes, GLOB.glass_recipes, GLOB.cloth_recipes, GLOB.wood_recipes, GLOB.cardboard_recipes, GLOB.plastic_recipes, GLOB.plasteel_recipes, GLOB.bone_recipes, GLOB.durathread_recipes))
		for(var/datum/stack_recipe/SR in stack_list)
			if(!is_craftable_stack(SR))
				continue
			var/datum/crafting_recipe/stack_wrap/sw = new
			sw.name = SR.title
			sw.result = SR.result_type
			sw.stack_ref = SR
			// Find the stack type from the list reference
			if(stack_list == GLOB.metal_recipes)
				sw.stack_type = /obj/item/stack/sheet/metal
			else if(stack_list == GLOB.rod_recipes)
				sw.stack_type = /obj/item/stack/rods
			else if(stack_list == GLOB.glass_recipes)
				sw.stack_type = /obj/item/stack/sheet/glass
			else if(stack_list == GLOB.cloth_recipes)
				sw.stack_type = /obj/item/stack/sheet/cloth
			else if(stack_list == GLOB.wood_recipes)
				sw.stack_type = /obj/item/stack/sheet/mineral/wood
			else if(stack_list == GLOB.cardboard_recipes)
				sw.stack_type = /obj/item/stack/sheet/cardboard
			else if(stack_list == GLOB.plastic_recipes)
				sw.stack_type = /obj/item/stack/sheet/plastic
			else if(stack_list == GLOB.plasteel_recipes)
				sw.stack_type = /obj/item/stack/sheet/plasteel
			else if(stack_list == GLOB.bone_recipes)
				sw.stack_type = /obj/item/stack/sheet/bone
			else if(stack_list == GLOB.durathread_recipes)
				sw.stack_type = /obj/item/stack/sheet/durathread
			sw.time = SR.time
			available_recipes += sw

	if(!length(available_recipes))
		balloon_alert(user, "no recipes available")
		return TRUE

	var/result = tgui_input_list(user, "Recipe", "Select Recipe", available_recipes)
	if(isnull(result) || !user.canUseTopic(src, BE_CLOSE))
		return TRUE

	recipe = null
	attackby_recipe = null
	stack_wrap_recipe = null

	if(istype(result, /datum/crafting_recipe/attackby))
		attackby_recipe = result
	else if(istype(result, /datum/crafting_recipe/stack_wrap))
		stack_wrap_recipe = result
	else
		recipe = result

	balloon_alert(user, "set")
	update_printing_overlay()
	return TRUE

/obj/machinery/power/manufacturing/crafter/Destroy()
	. = ..()
	recipe = null
	attackby_recipe = null
	stack_wrap_recipe = null
	craftsman = null
	withheld.Cut()

/obj/machinery/power/manufacturing/crafter/process(seconds_per_tick)
	send_withheld()

	if(!isnull(craft_timer))
		return

	if(!isnull(attackby_recipe))
		if(!check_attackby_contents())
			return
		flick_overlay_view(mutable_appearance(icon, "crafter_printing"), attackby_recipe.time)
		craft_timer = addtimer(CALLBACK(src, PROC_REF(craft_attackby), attackby_recipe), attackby_recipe.time, TIMER_STOPPABLE)
		return

	if(!isnull(stack_wrap_recipe))
		if(!check_stack_contents())
			return
		flick_overlay_view(mutable_appearance(icon, "crafter_printing"), stack_wrap_recipe.time)
		craft_timer = addtimer(CALLBACK(src, PROC_REF(craft_stack), stack_wrap_recipe), stack_wrap_recipe.time, TIMER_STOPPABLE)
		return

	if(!isnull(recipe) && craftsman.check_contents(src, recipe, craftsman.get_surroundings(src)))
		flick_overlay_view(mutable_appearance(icon, "crafter_printing"), recipe.time)
		craft_timer = addtimer(CALLBACK(src, PROC_REF(craft), recipe), recipe.time, TIMER_STOPPABLE)

// ==================== Attackby support ====================

/obj/machinery/power/manufacturing/crafter/proc/check_attackby_contents()
	var/turf/my_turf = get_turf(src)
	for(var/req_type in attackby_recipe.reqs)
		var/needed = attackby_recipe.reqs[req_type]
		if(ispath(req_type, /obj/item/stack))
			for(var/obj/item/stack/S in my_turf)
				if(ispath(S.type, req_type))
					needed -= S.amount
					if(needed <= 0)
						break
		else
			for(var/obj/item/I in my_turf)
				if(ispath(I.type, req_type))
					needed--
					if(needed <= 0)
						break
		if(needed > 0)
			return FALSE
	return TRUE

/obj/machinery/power/manufacturing/crafter/proc/del_attackby_reqs()
	var/turf/my_turf = get_turf(src)
	for(var/req_type in attackby_recipe.reqs)
		var/needed = attackby_recipe.reqs[req_type]
		if(ispath(req_type, /obj/item/stack))
			for(var/obj/item/stack/S in my_turf)
				if(!ispath(S.type, req_type))
					continue
				if(S.amount >= needed)
					S.amount -= needed
					if(S.amount <= 0)
						qdel(S)
					needed = 0
					break
				else
					needed -= S.amount
					qdel(S)
		else
			for(var/obj/item/I in my_turf)
				if(!ispath(I.type, req_type))
					continue
				qdel(I)
				needed--
				if(needed <= 0)
					break

/obj/machinery/power/manufacturing/crafter/proc/craft_attackby(datum/crafting_recipe/attackby/R)
	if(QDELETED(src))
		return
	craft_timer = null
	var/list/prediff = get_overfloor_objects()
	del_attackby_reqs()
	var/atom/movable/result = new R.result(get_turf(src))
	if(isstack(result))
		var/obj/item/stack/S = result
		for(var/obj/item/stack/other in get_turf(src))
			if(other != S && S.can_merge(other))
				S.merge(other)
				break
	SSblackbox.record_feedback("tally", "object_crafted", 1, result.type)
	var/list/diff = get_overfloor_objects() - prediff
	for(var/atom/movable/diff_result as anything in diff)
		if(iseffect(diff_result) || ismob(diff_result))
			continue
		if(isitem(diff_result))
			diff_result.pixel_x += rand(-4, 4)
			diff_result.pixel_y += rand(-4, 4)
		withheld += WEAKREF(diff_result)
	send_withheld()

// ==================== Stack recipe support ====================

/obj/machinery/power/manufacturing/crafter/proc/check_stack_contents()
	var/datum/stack_recipe/SR = stack_wrap_recipe.stack_ref
	var/turf/my_turf = get_turf(src)
	var/obj/item/stack/source = stack_wrap_recipe.stack_type
	var/needed = SR.req_amount
	for(var/obj/item/stack/S in my_turf)
		if(ispath(S.type, source))
			needed -= S.amount
			if(needed <= 0)
				break
	return needed <= 0

/obj/machinery/power/manufacturing/crafter/proc/del_stack_reqs()
	var/datum/stack_recipe/SR = stack_wrap_recipe.stack_ref
	var/turf/my_turf = get_turf(src)
	var/obj/item/stack/source = stack_wrap_recipe.stack_type
	var/needed = SR.req_amount
	for(var/obj/item/stack/S in my_turf)
		if(!ispath(S.type, source))
			continue
		if(S.amount >= needed)
			S.amount -= needed
			if(S.amount <= 0)
				qdel(S)
			needed = 0
			break
		else
			needed -= S.amount
			qdel(S)

/obj/machinery/power/manufacturing/crafter/proc/craft_stack(datum/crafting_recipe/stack_wrap/SW)
	if(QDELETED(src))
		return
	craft_timer = null
	var/list/prediff = get_overfloor_objects()
	var/datum/stack_recipe/SR = SW.stack_ref
	del_stack_reqs()
	var/atom/movable/result = new SR.result_type(get_turf(src))
	if(isstack(result))
		var/obj/item/stack/S = result
		if(SR.res_amount > 1)
			S.amount = SR.res_amount
		for(var/obj/item/stack/other in get_turf(src))
			if(other != S && S.can_merge(other))
				S.merge(other)
				break
	SSblackbox.record_feedback("tally", "object_crafted", 1, result.type)
	var/list/diff = get_overfloor_objects() - prediff
	for(var/atom/movable/diff_result as anything in diff)
		if(iseffect(diff_result) || ismob(diff_result))
			continue
		if(isitem(diff_result))
			diff_result.pixel_x += rand(-4, 4)
			diff_result.pixel_y += rand(-4, 4)
		withheld += WEAKREF(diff_result)
	send_withheld()

// ==================== Common procs ====================

/obj/machinery/power/manufacturing/crafter/proc/send_withheld()
	if(!length(withheld))
		return FALSE
	for(var/datum/weakref/weakref as anything in withheld)
		var/atom/movable/resolved = weakref?.resolve()
		if(isnull(resolved))
			withheld -= weakref
			continue
		if(resolved.loc != loc || send_resource(resolved, dir))
			withheld -= weakref
	return length(withheld)

/obj/machinery/power/manufacturing/crafter/proc/craft(datum/crafting_recipe/recipe)
	if(QDELETED(src))
		return
	craft_timer = null
	var/list/prediff = get_overfloor_objects()
	var/result = craftsman.construct_item(src, recipe)
	if(istext(result))
		say("Crafting failed[result]")
		return
	var/list/diff = get_overfloor_objects() - prediff
	for(var/atom/movable/diff_result as anything in diff)
		if(iseffect(diff_result) || ismob(diff_result))
			continue
		if(isitem(diff_result))
			diff_result.pixel_x += rand(-4, 4)
			diff_result.pixel_y += rand(-4, 4)
		withheld += WEAKREF(diff_result)
	send_withheld()

// ==================== COOKER (food recipes only) ====================

/obj/machinery/power/manufacturing/crafter/cooker
	name = "cooking crafter"
	desc = "Cooks the set recipe until it runs out of resources. Only resources on it will be used. Use multitool to set the recipe."
	icon_state = "crafter"
	circuit = /obj/item/circuitboard/machine/manucrafter/cooker

/obj/machinery/power/manufacturing/crafter/cooker/multitool_act(mob/living/user, obj/item/tool)
	. = NONE

	var/list/available_recipes = list()

	for(var/datum/crafting_recipe/potential_recipe as anything in GLOB.crafting_recipes)
		if(!is_food_recipe(potential_recipe))
			continue
		if(!is_craftable_item(potential_recipe))
			continue
		if(!craftsman.is_recipe_available(potential_recipe, user))
			continue
		available_recipes += potential_recipe

	if(!length(available_recipes))
		balloon_alert(user, "no recipes available")
		return TRUE

	var/result = tgui_input_list(user, "Recipe", "Select Cooking Recipe", available_recipes)
	if(isnull(result) || !user.canUseTopic(src, BE_CLOSE))
		return TRUE

	recipe = result
	attackby_recipe = null
	stack_wrap_recipe = null

	balloon_alert(user, "set")
	update_printing_overlay()
	return TRUE
