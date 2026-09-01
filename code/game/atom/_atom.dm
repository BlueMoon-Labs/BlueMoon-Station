/atom/proc/process_recipes(mob/living/user, obj/item/processed_object, list/processing_recipes)
	//Only one recipe? use the first
	if(processing_recipes.len == 1)
		StartProcessingAtom(user, processed_object, processing_recipes[1])
		return
	//Otherwise, select one with a radial
	ShowProcessingGui(user, processed_object, processing_recipes)

///Creates the radial and processes the selected option
/atom/proc/ShowProcessingGui(mob/living/user, obj/item/processed_object, list/possible_options)
	var/list/choices_to_options = list() //Dict of object name | dict of object processing settings
	var/list/choices = list()

	for(var/list/current_option as anything in possible_options)
		var/atom/current_option_type = current_option[TOOL_PROCESSING_RESULT]
		choices_to_options[initial(current_option_type.name)] = current_option
		var/image/option_image = image(icon = initial(current_option_type.icon), icon_state = initial(current_option_type.icon_state))
		choices += list("[initial(current_option_type.name)]" = option_image)

	var/pick = show_radial_menu(user, src, choices, radius = 36, require_near = TRUE)
	if(!pick)
		return

	StartProcessingAtom(user, processed_object, choices_to_options[pick])


/atom/proc/StartProcessingAtom(mob/living/user, obj/item/process_item, list/chosen_option)
	var/processing_time = chosen_option[TOOL_PROCESSING_TIME]
	var/sound_to_play = chosen_option[TOOL_PROCESSING_SOUND]
	to_chat(user, span_notice("You start working on [src]."))
	if(sound_to_play)
		playsound(src, sound_to_play, 50, TRUE)
	if(!process_item.use_tool(src, user, processing_time, volume=50))
		return
	var/atom/atom_to_create = chosen_option[TOOL_PROCESSING_RESULT]
	var/list/atom/created_atoms = list()
	var/amount_to_create = chosen_option[TOOL_PROCESSING_AMOUNT]
	for(var/i = 1 to amount_to_create)
		var/atom/created_atom = new atom_to_create(drop_location())
		created_atom.OnCreatedFromProcessing(user, process_item, chosen_option, src)
		created_atom.pixel_x = pixel_x
		created_atom.pixel_y = pixel_y
		if(i > 1)
			created_atom.pixel_x += rand(-8,8)
			created_atom.pixel_y += rand(-8,8)
		created_atoms.Add(created_atom)
	to_chat(user, span_notice("You manage to create [amount_to_create] [initial(atom_to_create.gender) == PLURAL ? "[initial(atom_to_create.name)]" : "[initial(atom_to_create.name)][plural_s(initial(atom_to_create.name))]"] from [src]."))
	SEND_SIGNAL(src, COMSIG_ATOM_PROCESSED, user, process_item, created_atoms)
	UsedforProcessing(user, process_item, chosen_option, created_atoms)

/atom/proc/UsedforProcessing(mob/living/user, obj/item/used_item, list/chosen_option, list/created_atoms)
	qdel(src)
	return

/atom/proc/OnCreatedFromProcessing(mob/living/user, obj/item/work_tool, list/chosen_option, atom/original_atom)
	SHOULD_CALL_PARENT(TRUE)

	SEND_SIGNAL(src, COMSIG_ATOM_CREATEDBY_PROCESSING, original_atom, chosen_option)
	if(user.mind)
		ADD_TRAIT(src, TRAIT_FOOD_CHEF_MADE, REF(user.mind))
