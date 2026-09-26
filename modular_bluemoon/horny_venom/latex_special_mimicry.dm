/datum/action/cooldown/latexmob/mimicry
	var/list/list_of_shapes = list()

/mob/living/simple_animal/latexmob/proc/check_type_for_mimicry(object_type, list/avaible_types)
	for(var/avaible_object in avaible_types)
		to_chat(src, "[avaible_object] + [object_type]")
		if(object_type == avaible_object)
			return TRUE

	src.balloon_alert(src, "Цель недоступна для копирования в текущий момент!")
	return FALSE

/mob/living/simple_animal/latexmob/proc/do_mimicry(appearance_to_copy, type_of_copied, list/list_of_shapes, mimicry_datum_type)
	var/turf/current_location
	if(isturf(src.loc))
		current_location = src.loc
		var/obj/mimicry_object =  new type_of_copied(current_location)
		var/datum/component/latex_mimicry/latex_component = mimicry_object.LoadComponent(mimicry_datum_type)
		latex_component.setup(src)
		//enter_in_object_animation()
		forceMove(mimicry_object)

	if(!current_location)
		return

/mob/living/simple_animal/latexmob/proc/go_back()
	if(!isturf(src.loc))
		var/obj/mimic_object = src.loc
		var/datum/component/latex_mimicry/component = locate(/datum/component/latex_mimicry) in mimic_object.datum_components
		if(component)
			//exiting_from_object_animation()
			forceMove(mimic_object.loc)
			qdel(mimic_object)
		else
			//что-то опять пошло не так
			return
	else
		//что-то пошло не так
		return
