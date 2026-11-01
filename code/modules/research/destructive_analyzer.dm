

/*
Destructive Analyzer

It is used to destroy hand-held objects and advance technological research. Controls are in the linked R&D console.

Note: Must be placed within 3 tiles of the R&D Console
*/
/obj/machinery/rnd/destructive_analyzer
	name = "destructive analyzer"
	desc = "Learn science by destroying things!"
	icon_state = "d_analyzer"
	circuit = /obj/item/circuitboard/machine/destructive_analyzer
	var/decon_mod = 0

/obj/machinery/rnd/destructive_analyzer/RefreshParts()
	var/T = 0
	for(var/obj/item/stock_parts/S in component_parts)
		T += S.rating
	decon_mod = T


/obj/machinery/rnd/destructive_analyzer/proc/ConvertReqString2List(list/source_list)
	var/list/temp_list = params2list(source_list)
	for(var/O in temp_list)
		temp_list[O] = text2num(temp_list[O])
	return temp_list

/obj/machinery/rnd/destructive_analyzer/disconnect_console()
	linked_console.linked_destroy = null
	..()

/obj/machinery/rnd/destructive_analyzer/default_deconstruction_screwdriver(mob/user, icon_state_open, icon_state_closed, obj/item/I)
	if(user.a_intent == INTENT_DISARM || HAS_TRAIT(I, TRAIT_NODROP))
		return ..()

/obj/machinery/rnd/destructive_analyzer/Insert_Item(obj/item/O, mob/user)
	if(user.a_intent != INTENT_HARM)
		. = 1
		if(!is_insertion_ready(user))
			return
		if(!user.transferItemToLoc(O, src))
			to_chat(user, "<span class='warning'>\The [O] is stuck to your hand, you cannot put it in the [src.name]!</span>")
			return
		busy = TRUE
		loaded_item = O
		to_chat(user, "<span class='notice'>You add the [O.name] to the [src.name]!</span>")
		flick("d_analyzer_la", src)
		addtimer(CALLBACK(src, PROC_REF(finish_loading)), 10)
		if (linked_console)
			linked_console.updateUsrDialog()

/obj/machinery/rnd/destructive_analyzer/proc/finish_loading()
	update_icon()
	reset_busy()

/obj/machinery/rnd/destructive_analyzer/update_icon_state()
	if(loaded_item)
		icon_state = "d_analyzer_l"
	else
		icon_state = initial(icon_state)

/obj/machinery/rnd/destructive_analyzer/proc/reclaim_materials_from(obj/item/thing)
	. = 0
	var/datum/component/material_container/storage = linked_console?.linked_lathe?.materials.mat_container
	if(storage) //Also sends salvaged materials to a linked protolathe, if any.
		for(var/material in thing.custom_materials)
			var/can_insert = min((storage.max_amount - storage.total_amount), (min(thing.custom_materials[material]*(decon_mod/10), thing.custom_materials[material])))
			storage.insert_amount_mat(can_insert, material)
			. += can_insert
		if (.)
			linked_console.linked_lathe.materials.silo_log(src, "reclaimed", 1, "[thing.name]", thing.custom_materials)

/obj/machinery/rnd/destructive_analyzer/proc/destroy_item(obj/item/thing, innermode = FALSE)
	if(QDELETED(thing) || QDELETED(src) || QDELETED(linked_console))
		return FALSE
	if(!innermode)
		flick("d_analyzer_process", src)
		busy = TRUE
		addtimer(CALLBACK(src, PROC_REF(reset_busy)), 24)
		use_power(250)
		if(thing == loaded_item)
			loaded_item = null
		var/list/food = thing.GetDeconstructableContents()
		for(var/obj/item/innerthing in food)
			destroy_item(innerthing, TRUE)
	reclaim_materials_from(thing)
	for(var/mob/M in thing)
		M.death()
	qdel(thing)
	if (!innermode)
		update_icon()
	return TRUE

/obj/machinery/rnd/destructive_analyzer/proc/user_try_decon_id(id, mob/user)
	if(!istype(loaded_item) || !istype(linked_console) || !linked_console.netrun_research_cache || !netrun_research_authorizes(linked_console, linked_console.stored_research))
		return FALSE

	if (id && id != RESEARCH_MATERIAL_RECLAMATION_ID)
		var/datum/techweb_node/TN = SSresearch.techweb_node_by_id(id)
		if(!istype(TN))
			return FALSE
		var/dpath = loaded_item.type
		var/list/worths = TN.boost_item_paths[dpath]
		var/list/differences = list()
		var/list/already_boosted = linked_console.netrun_research_cache.boosted_nodes[TN.id]
		for(var/i in worths)
			var/used = already_boosted? already_boosted[i] : 0
			var/value = min(worths[i], TN.research_costs[i]) - used
			if(value > 0)
				differences[i] = value
		if(length(worths) && !length(differences))
			return FALSE
		var/choice = input("Are you sure you want to destroy [loaded_item] to [!length(worths) ? "reveal [TN.display_name]" : "boost [TN.display_name] by [json_encode(differences)] point\s"]?") in list("Proceed", "Cancel")
		if(choice == "Cancel" || !choice)
			return FALSE
		if(QDELETED(loaded_item) || QDELETED(linked_console) || !user.Adjacent(linked_console) || QDELETED(src))
			return FALSE
		return linked_console.request_research_action("analyze", user, list("item" = REF(loaded_item), "node_id" = TN.id))

	else
		var/list/point_value = techweb_item_point_check(loaded_item)
		if(linked_console.netrun_research_cache.deconstructed_items[loaded_item.type] && !istype(loaded_item, /obj/item/heretic_veil_crystal))
			point_value = list()
		var/user_mode_string = ""
		if(length(point_value))
			user_mode_string = " for [json_encode(point_value)] points"
		else if(length(loaded_item.custom_materials))
			user_mode_string = " for material reclamation"
		var/choice = input("Are you sure you want to destroy [loaded_item][user_mode_string]?") in list("Proceed", "Cancel")
		if(choice != "Proceed")
			return FALSE
		if(QDELETED(loaded_item) || QDELETED(linked_console) || !user.Adjacent(linked_console) || QDELETED(src))
			return FALSE
		return linked_console.request_research_action("analyze", user, list("item" = REF(loaded_item)))

/// The item is destroyed and the research credited together only after a delivered request.
/obj/machinery/computer/rdconsole/proc/perform_research_analysis(list/data, mob/user, datum/techweb/authority)
	var/obj/machinery/rnd/destructive_analyzer/analyzer = linked_destroy
	if(!netrun_research_authorizes(src, authority) || QDELETED(analyzer) || QDELETED(user) || !user.Adjacent(src))
		return FALSE
	var/obj/item/item = analyzer.loaded_item
	if(QDELETED(item) || REF(item) != data["item"] || analyzer.busy || analyzer.linked_console != src)
		return FALSE
	var/item_type = item.type
	var/id = data["node_id"]
	if(id)
		var/datum/techweb_node/node = SSresearch.techweb_node_by_id(id)
		if(!istype(node))
			return FALSE
		SSblackbox.record_feedback("nested tally", "item_deconstructed", 1, list("[id]", "[item_type]"))
		if(!analyzer.destroy_item(item))
			return FALSE
		return authority.boost_with_path(node, item_type)
	var/list/points = techweb_item_point_check(item)
	if(authority.deconstructed_items[item_type] && !istype(item, /obj/item/heretic_veil_crystal))
		points = list()
	if(!analyzer.destroy_item(item))
		return FALSE
	authority.add_point_list(points)
	authority.deconstructed_items[item_type] = points
	authority.netrun_research_changed()
	return TRUE

/obj/machinery/rnd/destructive_analyzer/proc/unload_item()
	if(!loaded_item)
		return FALSE
	loaded_item.forceMove(get_turf(src))
	loaded_item = null
	update_icon()
	return TRUE
