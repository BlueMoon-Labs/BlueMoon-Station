/obj/machinery/ipc_constructor
	name = "synthetic constructor"
	desc = "A robotics assembly cradle for constructing IPC chassis around an active positronic intelligence."
	icon = 'icons/mecha/mech_fab.dmi'
	icon_state = "fabricator"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 15
	active_power_usage = 1500
	circuit = /obj/item/circuitboard/machine/ipc_constructor
	// pixel_x = 16

	var/busy = FALSE
	var/selected_body_size = RESIZE_DEFAULT_SIZE
	var/selected_screen
	var/stored_metal = 0
	var/stored_glass = 0
	var/stored_plastic = 0
	var/material_capacity = 100
	var/base_metal_cost = 70
	var/base_glass_cost = 30
	var/base_plastic_cost = 15
	var/base_assembly_time_seconds = 70
	var/assembly_part_tier = 1
	var/static/no_screen_option = "None"
	var/assembly_started_at = 0
	var/assembly_finish_at = 0
	var/list/loaded_implants = list()
	var/static/list/limb_style_icons = list(
		"standard" = 'icons/mob/augmentation/augments.dmi',
		"engineer" = 'icons/mob/augmentation/augments_engineer.dmi',
		"security" = 'icons/mob/augmentation/augments_security.dmi',
		"mining" = 'icons/mob/augmentation/augments_mining.dmi',
		"Talon" = 'icons/mob/augmentation/cosmetic_prosthetic/talon.dmi',
		"Nanotrasen" = 'icons/mob/augmentation/cosmetic_prosthetic/nanotrasen.dmi',
		"Veymed" = 'icons/mob/augmentation/cosmetic_prosthetic/veymed.dmi',
		"Grayson" = 'icons/mob/augmentation/cosmetic_prosthetic/grayson.dmi',
		"Cybersolutions" = 'icons/mob/augmentation/cosmetic_prosthetic/cybersolutions.dmi',
		"Morpheus" = 'icons/mob/augmentation/cosmetic_prosthetic/ipc/morpheus.dmi',
		"Bishop" = 'icons/mob/augmentation/cosmetic_prosthetic/ipc/bishop_ipc.dmi',
		"Bishop 2.0" = 'icons/mob/augmentation/cosmetic_prosthetic/ipc/bishop2_ipc.dmi',
		"Hephaestus" = 'icons/mob/augmentation/cosmetic_prosthetic/ipc/hephaestus_ipc.dmi',
		"Hephaestus 2.0" = 'icons/mob/augmentation/cosmetic_prosthetic/ipc/hephaestus2_ipc.dmi',
		"Shellguard" = 'icons/mob/augmentation/cosmetic_prosthetic/ipc/shellguard_ipc.dmi',
		"Ward" = 'icons/mob/augmentation/cosmetic_prosthetic/ipc/ward_ipc.dmi',
		"Xion" = 'icons/mob/augmentation/cosmetic_prosthetic/ipc/xion_ipc.dmi',
		"Xion 2.0" = 'icons/mob/augmentation/cosmetic_prosthetic/ipc/xion2_ipc.dmi',
		"Zeng-Hu" = 'icons/mob/augmentation/cosmetic_prosthetic/ipc/zenghu_ipc.dmi',
		"Mariinsky" = 'icons/mob/augmentation/cosmetic_prosthetic/ipc/mariinsky_ipc.dmi'
	)

	var/obj/item/bodypart/head/robot/head_part
	var/obj/item/bodypart/chest/robot/chest_part
	var/obj/item/bodypart/l_arm/robot/l_arm_part
	var/obj/item/bodypart/r_arm/robot/r_arm_part
	var/obj/item/bodypart/l_leg/robot/l_leg_part
	var/obj/item/bodypart/r_leg/robot/r_leg_part

	var/obj/item/organ/heart/ipc/heart_part
	var/obj/item/organ/lungs/ipc/lungs_part
	var/obj/item/organ/liver/ipc/liver_part
	var/obj/item/organ/stomach/ipc/stomach_part
	var/obj/item/organ/eyes/ipc/eyes_part
	var/obj/item/organ/ears/ipc/ears_part
	var/obj/item/organ/tongue/robot/ipc/tongue_part
	var/obj/item/mmi/cognitive_core_part
	var/add_genitals = FALSE
	var/genital_has_cock = FALSE
	var/genital_has_balls = FALSE
	var/genital_has_vag = FALSE
	var/genital_has_womb = FALSE
	var/genital_has_breasts = FALSE
	var/genital_has_butt = FALSE
	var/genital_has_belly = FALSE
	var/genital_has_anus = FALSE
	var/genital_cock_length = COCK_SIZE_DEF
	var/genital_balls_size = BALLS_SIZE_DEF
	var/genital_breasts_size = BREASTS_SIZE_DEF
	var/genital_butt_size = BUTT_SIZE_DEF
	var/genital_belly_size = BELLY_SIZE_DEF
	var/genital_cock_shape = DEF_COCK_SHAPE
	var/genital_balls_shape = DEF_BALLS_SHAPE
	var/genital_vag_shape = DEF_VAGINA_SHAPE
	var/genital_breasts_shape = DEF_BREASTS_SHAPE
	var/genital_butt_shape = "Pair"
	var/genital_belly_shape = "Pair"
	var/genital_anus_shape = DEF_ANUS_SHAPE
	var/genital_cock_color = "FFFFFF"
	var/genital_balls_color = "FFFFFF"
	var/genital_vag_color = "FFFFFF"
	var/genital_breasts_color = "FFFFFF"
	var/genital_butt_color = "FFFFFF"
	var/genital_belly_color = "FFFFFF"
	var/genital_anus_color = "FFFFFF"
	var/list/obj/structure/filler/ipc_constructor/fillers = list()

/obj/machinery/ipc_constructor/Initialize(mapload)
	selected_screen = get_default_screen()
	. = ..()
	create_fillers()
	update_icon()
	return .

/obj/machinery/ipc_constructor/Destroy()
	clear_fillers()
	return ..()

/obj/machinery/ipc_constructor/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IPCConstructor", src)
		ui.open()

/obj/machinery/ipc_constructor/update_icon_state()
	. = ..()
	if(busy)
		icon_state = "fabricator_ani"
		return
	if(panel_open)
		icon_state = "fabricator_load"
		return
	icon_state = "fabricator"

/obj/machinery/ipc_constructor/ui_static_data(mob/user)
	var/list/data = list()
	data["screens"] = get_available_screens()
	data["default_screen"] = get_default_screen()
	data["limb_styles"] = get_limb_style_names()
	data["size_min"] = CONFIG_GET(number/body_size_min)
	data["size_max"] = CONFIG_GET(number/body_size_max)
	data["size_default"] = RESIZE_DEFAULT_SIZE
	return data

/obj/machinery/ipc_constructor/ui_data(mob/user)
	var/list/data = list()
	var/list/required_materials = get_required_materials()
	data["busy"] = busy
	data["suggested_name"] = get_suggested_designation()
	data["selected_size"] = selected_body_size
	data["selected_screen"] = get_selected_screen()
	data["stored_metal"] = stored_metal
	data["stored_glass"] = stored_glass
	data["stored_plastic"] = stored_plastic
	data["material_capacity"] = material_capacity
	data["required_metal"] = required_materials["metal"]
	data["required_glass"] = required_materials["glass"]
	data["required_plastic"] = required_materials["plastic"]
	data["estimated_time_seconds"] = get_assembly_time_seconds()
	data["assembly_progress"] = get_assembly_progress()
	data["assembly_remaining_seconds"] = get_assembly_remaining_seconds()
	data["assembly_status_text"] = get_assembly_status_text()
	data["assembly_part_tier"] = assembly_part_tier
	data["preinstalled_software"] = has_preinstalled_software() ? "Да" : "Нет"
	data["preview_icon"] = get_preview_icon_base64()
	data["implants"] = get_implant_data()
	data["genitals_enabled"] = add_genitals
	data["genital_options"] = get_genital_data()
	data["genital_size_options"] = get_genital_size_data()
	data["genital_color_options"] = get_genital_color_data()
	data["missing_optional_parts"] = get_missing_optional_parts()
	data["bodyparts"] = list(
		get_slot_data("head", "Голова", head_part),
		get_slot_data("chest", "Торс", chest_part),
		get_slot_data("l_arm", "Левая рука", l_arm_part),
		get_slot_data("r_arm", "Правая рука", r_arm_part),
		get_slot_data("l_leg", "Левая нога", l_leg_part),
		get_slot_data("r_leg", "Правая нога", r_leg_part),
	)
	data["organs"] = list(
		get_slot_data("cognitive_core", "Когнитивное ядро (грудь)", cognitive_core_part, get_cognitive_core_type()),
		get_slot_data("heart", "Гидравлический насос", heart_part),
		get_slot_data("lungs", "Система охлаждения", lungs_part),
		get_slot_data("liver", "Реагентный процессор", liver_part),
		get_slot_data("stomach", "Энергоячейка", stomach_part),
		get_slot_data("eyes", "Оптический сенсорный блок", eyes_part),
		get_slot_data("ears", "Аудиосенсорный блок", ears_part),
		get_slot_data("tongue", "Голосовой синтезатор", tongue_part),
	)
	var/list/problems = get_required_assembly_problems()
	data["issues"] = problems
	data["can_assemble"] = !LAZYLEN(problems)
	return data

/obj/machinery/ipc_constructor/proc/get_slot_data(slot_id, label, obj/item/item, type_override)
	var/item_type = type_override
	if(!item_type && item)
		item_type = item.type
	var/style = null
	var/style_changeable = FALSE
	var/list/style_options = null
	if(istype(item, /obj/item/bodypart/head/robot/ipc) || istype(item, /obj/item/bodypart/chest/robot/ipc) || istype(item, /obj/item/bodypart/l_arm/robot) || istype(item, /obj/item/bodypart/r_arm/robot) || istype(item, /obj/item/bodypart/l_leg/robot) || istype(item, /obj/item/bodypart/r_leg/robot))
		style = get_bodypart_style(item)
		style_changeable = TRUE
		style_options = get_bodypart_style_options(slot_id)
	return list(
		id = slot_id,
		label = label,
		occupied = !!item,
		name = item ? item.name : "Отсутствует",
		type = item_type,
		style = style,
		style_changeable = style_changeable,
		styles = style_options,
	)

/obj/machinery/ipc_constructor/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Stored steel: [stored_metal]/[material_capacity]. Stored glass: [stored_glass]/[material_capacity]. Stored plastic: [stored_plastic]/[material_capacity].</span>"

/obj/machinery/ipc_constructor/proc/create_fillers()
	clear_fillers()
	var/turf/secondary_turf = get_step(src, EAST)
	if(!secondary_turf)
		return
	var/obj/structure/filler/ipc_constructor/filler = new(secondary_turf)
	filler.parent = src
	fillers += filler

/obj/machinery/ipc_constructor/proc/clear_fillers()
	for(var/obj/structure/filler/ipc_constructor/filler in fillers)
		filler.parent = null
		qdel(filler)
	fillers.Cut()

/obj/machinery/ipc_constructor/attackby(obj/item/user_item, mob/living/user, params)
	if(busy)
		to_chat(user, "<span class='warning'>[src] is already assembling a synthetic.</span>")
		return TRUE

	if(default_deconstruction_screwdriver(user, "fabricator_load", "fabricator", user_item))
		update_icon()
		ui_close(user)
		return TRUE

	if(user_item.tool_behaviour == TOOL_WRENCH && panel_open)
		return ..()

	if(panel_open && default_deconstruction_crowbar(user_item))
		return TRUE

	if(panel_open)
		to_chat(user, "<span class='warning'>Close the maintenance panel before loading parts.</span>")
		return TRUE

	if(load_material(user_item, user))
		return TRUE

	if(load_implant(user_item, user))
		return TRUE

	if(insert_part(user_item, user))
		return TRUE

	return ..()

/obj/machinery/ipc_constructor/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("eject")
			if(busy)
				to_chat(usr, "<span class='warning'>[src] is locked while assembling a synthetic.</span>")
				return TRUE
			var/slot_id = params["slot"]
			if(eject_slot(slot_id, usr))
				return TRUE

		if("eject_implant")
			if(busy)
				to_chat(usr, "<span class='warning'>[src] is locked while assembling a synthetic.</span>")
				return TRUE
			var/obj/item/implant_item = locate(params["implant"])
			if(eject_implant(implant_item, usr))
				return TRUE

		if("assemble")
			if(busy)
				to_chat(usr, "<span class='warning'>[src] is already assembling a synthetic.</span>")
				return TRUE
			if(panel_open)
				to_chat(usr, "<span class='warning'>Close the maintenance panel before starting assembly.</span>")
				return TRUE
			var/designation = reject_bad_name(params["designation"], TRUE)
			start_assembly(usr, designation, get_selected_screen())
			return TRUE

		if("set_size")
			var/new_size = text2num(params["size"])
			if(isnull(new_size))
				new_size = RESIZE_DEFAULT_SIZE
			selected_body_size = clamp(new_size, CONFIG_GET(number/body_size_min), CONFIG_GET(number/body_size_max))
			return TRUE

		if("set_screen")
			var/new_screen = params["screen"]
			if(new_screen in get_available_screens())
				selected_screen = new_screen
			else
				selected_screen = get_default_screen()
			return TRUE

		if("set_limb_style")
			if(busy)
				to_chat(usr, "<span class='warning'>[src] is locked while assembling a synthetic.</span>")
				return TRUE
			var/slot_id = params["slot"]
			var/style = params["style"]
			if(set_bodypart_style(slot_id, style, usr))
				return TRUE
			return TRUE

		if("toggle_genitals")
			if(busy)
				to_chat(usr, "<span class='warning'>[src] is locked while assembling a synthetic.</span>")
				return TRUE
			add_genitals = !!text2num(params["enabled"])
			return TRUE

		if("set_genital_option")
			if(busy)
				to_chat(usr, "<span class='warning'>[src] is locked while assembling a synthetic.</span>")
				return TRUE
			set_genital_option(params["option"], !!text2num(params["enabled"]))
			return TRUE

		if("set_genital_size")
			if(busy)
				to_chat(usr, "<span class='warning'>[src] is locked while assembling a synthetic.</span>")
				return TRUE
			set_genital_size(params["size_id"], params["value"])
			return TRUE

		if("set_genital_color")
			if(busy)
				to_chat(usr, "<span class='warning'>[src] is locked while assembling a synthetic.</span>")
				return TRUE
			prompt_genital_color(usr, params["color_id"])
			return TRUE

/obj/machinery/ipc_constructor/on_deconstruction()
	dump_parts()
	dump_implants()
	dump_materials()
	return ..()

/obj/machinery/ipc_constructor/RefreshParts()
	var/matter_bin_rating_total = 0
	var/matter_bin_parts = 0
	var/capacitor_rating_total = 0
	var/capacitor_parts = 0
	var/manip_rating_total = 0
	var/manip_parts = 0
	var/laser_rating_total = 0
	var/laser_parts = 0

	for(var/obj/item/stock_parts/matter_bin/matter_bin in component_parts)
		matter_bin_rating_total += matter_bin.rating
		matter_bin_parts++

	for(var/obj/item/stock_parts/capacitor/capacitor in component_parts)
		capacitor_rating_total += capacitor.rating
		capacitor_parts++

	for(var/obj/item/stock_parts/manipulator/manipulator in component_parts)
		manip_rating_total += manipulator.rating
		manip_parts++

	for(var/obj/item/stock_parts/micro_laser/laser in component_parts)
		laser_rating_total += laser.rating
		laser_parts++

	var/matter_bin_rating = matter_bin_parts ? (matter_bin_rating_total / matter_bin_parts) : 1
	var/capacitor_rating = capacitor_parts ? (capacitor_rating_total / capacitor_parts) : 1
	var/manip_rating = manip_parts ? (manip_rating_total / manip_parts) : 1
	var/laser_rating = laser_parts ? (laser_rating_total / laser_parts) : 1
	assembly_part_tier = clamp((matter_bin_rating + capacitor_rating + manip_rating + laser_rating) * 0.25, 1, 5)

/obj/machinery/ipc_constructor/proc/load_material(obj/item/user_item, mob/living/user)
	if(istype(user_item, /obj/item/stack/sheet/metal))
		var/obj/item/stack/sheet/metal/metal = user_item
		var/can_take = material_capacity - stored_metal
		if(can_take <= 0)
			to_chat(user, "<span class='warning'>[src] cannot store any more steel.</span>")
			return TRUE
		var/taken = min(metal.amount, can_take)
		if(!metal.use(taken))
			return TRUE
		stored_metal += taken
		to_chat(user, "<span class='notice'>You load [taken] sheets of steel into [src].</span>")
		return TRUE

	if(istype(user_item, /obj/item/stack/sheet/glass))
		var/obj/item/stack/sheet/glass/glass = user_item
		var/can_take = material_capacity - stored_glass
		if(can_take <= 0)
			to_chat(user, "<span class='warning'>[src] cannot store any more glass.</span>")
			return TRUE
		var/taken = min(glass.amount, can_take)
		if(!glass.use(taken))
			return TRUE
		stored_glass += taken
		to_chat(user, "<span class='notice'>You load [taken] sheets of glass into [src].</span>")
		return TRUE

	if(istype(user_item, /obj/item/stack/sheet/plastic))
		var/obj/item/stack/sheet/plastic/plastic = user_item
		var/can_take = material_capacity - stored_plastic
		if(can_take <= 0)
			to_chat(user, "<span class='warning'>[src] cannot store any more plastic.</span>")
			return TRUE
		var/taken = min(plastic.amount, can_take)
		if(!plastic.use(taken))
			return TRUE
		stored_plastic += taken
		to_chat(user, "<span class='notice'>You load [taken] sheets of plastic into [src].</span>")
		return TRUE

	return FALSE

/obj/machinery/ipc_constructor/proc/load_implant(obj/item/user_item, mob/living/user)
	var/obj/item/implant/implant_to_load
	var/obj/item/organ/cyberimp/cyberimp_to_load

	if(istype(user_item, /obj/item/implant))
		implant_to_load = user_item
		if(implant_to_load.imp_in)
			to_chat(user, "<span class='warning'>[implant_to_load] is already implanted in someone.</span>")
			return TRUE
		if(!user.transferItemToLoc(implant_to_load, src))
			return TRUE

	else if(istype(user_item, /obj/item/organ/cyberimp))
		cyberimp_to_load = user_item
		if(cyberimp_to_load.owner)
			to_chat(user, "<span class='warning'>[cyberimp_to_load] is already installed in someone.</span>")
			return TRUE
		if(!user.transferItemToLoc(cyberimp_to_load, src))
			return TRUE

	else if(istype(user_item, /obj/item/implanter))
		var/obj/item/implanter/implanter = user_item
		if(!implanter.imp)
			to_chat(user, "<span class='warning'>[implanter] is empty.</span>")
			return TRUE
		implant_to_load = implanter.imp
		implanter.imp = null
		implant_to_load.forceMove(src)
		implanter.update_icon()

	else if(istype(user_item, /obj/item/implantcase))
		var/obj/item/implantcase/implant_case = user_item
		if(!implant_case.imp)
			to_chat(user, "<span class='warning'>[implant_case] is empty.</span>")
			return TRUE
		implant_to_load = implant_case.imp
		implant_case.imp = null
		implant_case.reagents = null
		implant_to_load.forceMove(src)
		implant_case.update_icon()

	var/obj/item/item_to_load = implant_to_load || cyberimp_to_load
	if(!item_to_load)
		return FALSE

	LAZYADD(loaded_implants, item_to_load)
	to_chat(user, "<span class='notice'>You load [item_to_load] into [src]. It will be installed during assembly.</span>")
	return TRUE

/obj/machinery/ipc_constructor/proc/insert_part(obj/item/user_item, mob/living/user)
	var/slot_name

	if(istype(user_item, /obj/item/bodypart/head/robot/ipc))
		if(head_part)
			to_chat(user, "<span class='warning'>The head slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/bodypart/head/robot/ipc/head = user_item
			if(locate(/obj/item/organ) in head.contents)
				to_chat(user, "<span class='warning'>Remove any organs from [head] before loading it.</span>")
				return TRUE
			if(!user.transferItemToLoc(head, src))
				return TRUE
			head.icon_state = initial(head.icon_state)
			head.cut_overlays()
			head_part = head
			slot_name = "head"

	else if(istype(user_item, /obj/item/bodypart/chest/robot/ipc))
		if(chest_part)
			to_chat(user, "<span class='warning'>The torso slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/bodypart/chest/robot/ipc/chest = user_item
			if(locate(/obj/item/organ) in chest.contents)
				to_chat(user, "<span class='warning'>Remove any organs from [chest] before loading it.</span>")
				return TRUE
			if(!user.transferItemToLoc(chest, src))
				return TRUE
			chest.icon_state = initial(chest.icon_state)
			chest.cut_overlays()
			chest_part = chest
			slot_name = "torso"

	else if(is_valid_prosthetic_part(user_item, BODY_ZONE_L_ARM))
		if(l_arm_part)
			to_chat(user, "<span class='warning'>The left arm slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/bodypart/l_arm/robot/l_arm = user_item
			if(!user.transferItemToLoc(user_item, src))
				return TRUE
			user_item.icon_state = initial(user_item.icon_state)
			user_item.cut_overlays()
			l_arm_part = l_arm
			slot_name = "left arm"

	else if(is_valid_prosthetic_part(user_item, BODY_ZONE_R_ARM))
		if(r_arm_part)
			to_chat(user, "<span class='warning'>The right arm slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/bodypart/r_arm/robot/r_arm = user_item
			if(!user.transferItemToLoc(user_item, src))
				return TRUE
			user_item.icon_state = initial(user_item.icon_state)
			user_item.cut_overlays()
			r_arm_part = r_arm
			slot_name = "right arm"

	else if(is_valid_prosthetic_part(user_item, BODY_ZONE_L_LEG))
		if(l_leg_part)
			to_chat(user, "<span class='warning'>The left leg slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/bodypart/l_leg/robot/l_leg = user_item
			if(!user.transferItemToLoc(user_item, src))
				return TRUE
			user_item.icon_state = initial(user_item.icon_state)
			user_item.cut_overlays()
			l_leg_part = l_leg
			slot_name = "left leg"

	else if(is_valid_prosthetic_part(user_item, BODY_ZONE_R_LEG))
		if(r_leg_part)
			to_chat(user, "<span class='warning'>The right leg slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/bodypart/r_leg/robot/r_leg = user_item
			if(!user.transferItemToLoc(user_item, src))
				return TRUE
			user_item.icon_state = initial(user_item.icon_state)
			user_item.cut_overlays()
			r_leg_part = r_leg
			slot_name = "right leg"

	else if(istype(user_item, /obj/item/organ/heart/ipc))
		if(heart_part)
			to_chat(user, "<span class='warning'>The hydraulic pump slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/organ/heart/ipc/heart = user_item
			if(!user.transferItemToLoc(heart, src))
				return TRUE
			heart_part = heart
			slot_name = "hydraulic pump"

	else if(istype(user_item, /obj/item/organ/lungs/ipc))
		if(lungs_part)
			to_chat(user, "<span class='warning'>The cooling system slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/organ/lungs/ipc/lungs = user_item
			if(!user.transferItemToLoc(lungs, src))
				return TRUE
			lungs_part = lungs
			slot_name = "cooling system"

	else if(istype(user_item, /obj/item/organ/liver/ipc))
		if(liver_part)
			to_chat(user, "<span class='warning'>The reagent processor slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/organ/liver/ipc/liver = user_item
			if(!user.transferItemToLoc(liver, src))
				return TRUE
			liver_part = liver
			slot_name = "reagent processor"

	else if(istype(user_item, /obj/item/organ/stomach/ipc))
		if(stomach_part)
			to_chat(user, "<span class='warning'>The power cell slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/organ/stomach/ipc/stomach = user_item
			if(!user.transferItemToLoc(stomach, src))
				return TRUE
			stomach_part = stomach
			slot_name = "power cell"

	else if(istype(user_item, /obj/item/organ/eyes/ipc))
		if(eyes_part)
			to_chat(user, "<span class='warning'>The optics slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/organ/eyes/ipc/eyes = user_item
			if(!user.transferItemToLoc(eyes, src))
				return TRUE
			eyes_part = eyes
			slot_name = "optics"

	else if(istype(user_item, /obj/item/organ/ears/ipc))
		if(ears_part)
			to_chat(user, "<span class='warning'>The audio sensor slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/organ/ears/ipc/ears = user_item
			if(!user.transferItemToLoc(ears, src))
				return TRUE
			ears_part = ears
			slot_name = "audio sensors"

	else if(istype(user_item, /obj/item/organ/tongue/robot/ipc))
		if(tongue_part)
			to_chat(user, "<span class='warning'>The voice synthesizer slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/organ/tongue/robot/ipc/tongue = user_item
			if(!user.transferItemToLoc(tongue, src))
				return TRUE
			tongue_part = tongue
			slot_name = "voice synthesizer"

	else if(istype(user_item, /obj/item/mmi))
		if(cognitive_core_part)
			to_chat(user, "<span class='warning'>The chest cognitive core slot is already occupied.</span>")
			return TRUE
		else
			var/obj/item/mmi/core = user_item
			if(!cognitive_core_can_be_assembled(core))
				to_chat(user, "<span class='warning'>[core] cannot be used for IPC assembly in its current state.</span>")
				return TRUE
			if(!user.transferItemToLoc(core, src))
				return TRUE
			cognitive_core_part = core
			if(cognitive_core_spawns_ghost_role(core))
				to_chat(user, "<span class='notice'>[core] is vacant. The finished IPC will be released as a joinable ghost role.</span>")
			slot_name = "chest cognitive core"

	if(!slot_name)
		return FALSE

	to_chat(user, "<span class='notice'>You load [user_item] into [src].</span>")
	return TRUE

/obj/machinery/ipc_constructor/proc/eject_slot(slot_id, mob/user)
	var/obj/item/ejected
	switch(slot_id)
		if("head")
			ejected = head_part
			head_part = null
		if("chest")
			ejected = chest_part
			chest_part = null
		if("l_arm")
			ejected = l_arm_part
			l_arm_part = null
		if("r_arm")
			ejected = r_arm_part
			r_arm_part = null
		if("l_leg")
			ejected = l_leg_part
			l_leg_part = null
		if("r_leg")
			ejected = r_leg_part
			r_leg_part = null
		if("heart")
			ejected = heart_part
			heart_part = null
		if("lungs")
			ejected = lungs_part
			lungs_part = null
		if("liver")
			ejected = liver_part
			liver_part = null
		if("stomach")
			ejected = stomach_part
			stomach_part = null
		if("eyes")
			ejected = eyes_part
			eyes_part = null
		if("ears")
			ejected = ears_part
			ears_part = null
		if("tongue")
			ejected = tongue_part
			tongue_part = null
		if("cognitive_core")
			ejected = cognitive_core_part
			cognitive_core_part = null

	if(!ejected)
		return FALSE

	ejected.forceMove(drop_location())
	if(istype(ejected, /obj/item/bodypart))
		var/obj/item/bodypart/ejected_bodypart = ejected
		ejected_bodypart.update_icon_dropped()
		ejected_bodypart.update_dropped_size(user)
	if(user)
		to_chat(user, "<span class='notice'>You eject [ejected] from [src].</span>")
	return TRUE

/obj/machinery/ipc_constructor/proc/eject_implant(obj/item/implant_item, mob/user)
	if(!implant_item || !(implant_item in loaded_implants))
		return FALSE

	loaded_implants -= implant_item
	implant_item.forceMove(drop_location())
	if(user)
		to_chat(user, "<span class='notice'>You eject [implant_item] from [src].</span>")
	return TRUE

/obj/machinery/ipc_constructor/proc/dump_parts()
	eject_slot("head")
	eject_slot("chest")
	eject_slot("l_arm")
	eject_slot("r_arm")
	eject_slot("l_leg")
	eject_slot("r_leg")
	eject_slot("heart")
	eject_slot("lungs")
	eject_slot("liver")
	eject_slot("stomach")
	eject_slot("eyes")
	eject_slot("ears")
	eject_slot("tongue")
	eject_slot("cognitive_core")

/obj/machinery/ipc_constructor/proc/dump_implants()
	for(var/obj/item/implant_item as anything in loaded_implants.Copy())
		eject_implant(implant_item)

/obj/machinery/ipc_constructor/proc/get_implant_data()
	. = list()
	for(var/obj/item/implant_item as anything in loaded_implants)
		. += list(list(
			"id" = REF(implant_item),
			"name" = implant_item.name,
		))

/obj/machinery/ipc_constructor/proc/get_genital_data()
	return list(
		list(
			"id" = "has_cock",
			"label" = "Половой член",
			"enabled" = genital_has_cock,
			"disabled" = FALSE,
		),
		list(
			"id" = "has_balls",
			"label" = "Семенники",
			"enabled" = genital_has_balls,
			"disabled" = !genital_has_cock,
		),
		list(
			"id" = "has_vag",
			"label" = "Вагина",
			"enabled" = genital_has_vag,
			"disabled" = FALSE,
		),
		list(
			"id" = "has_womb",
			"label" = "Матка",
			"enabled" = genital_has_womb,
			"disabled" = !genital_has_vag,
		),
		list(
			"id" = "has_breasts",
			"label" = "Грудь",
			"enabled" = genital_has_breasts,
			"disabled" = FALSE,
		),
		list(
			"id" = "has_butt",
			"label" = "Ягодицы",
			"enabled" = genital_has_butt,
			"disabled" = FALSE,
		),
		list(
			"id" = "has_belly",
			"label" = "Живот",
			"enabled" = genital_has_belly,
			"disabled" = FALSE,
		),
		list(
			"id" = "has_anus",
			"label" = "Анус",
			"enabled" = genital_has_anus,
			"disabled" = !genital_has_butt,
		),
	)

/obj/machinery/ipc_constructor/proc/get_genital_size_data()
	return list(
		list(
			"id" = "cock_shape",
			"label" = "Тип члена",
			"type" = "list",
			"value" = genital_cock_shape,
			"options" = sort_list(assoc_to_keys(GLOB.cock_shapes_list)),
			"enabled" = genital_has_cock,
		),
		list(
			"id" = "cock_length",
			"label" = "Размер члена",
			"type" = "number",
			"value" = genital_cock_length,
			"min" = CONFIG_GET(number/penis_min_inches_prefs),
			"max" = CONFIG_GET(number/penis_max_inches_prefs),
			"enabled" = genital_has_cock,
		),
		list(
			"id" = "balls_shape",
			"label" = "Тип яиц",
			"type" = "list",
			"value" = genital_balls_shape,
			"options" = sort_list(assoc_to_keys(GLOB.balls_shapes_list)),
			"enabled" = genital_has_balls,
		),
		list(
			"id" = "balls_size",
			"label" = "Размер яиц",
			"type" = "number",
			"value" = genital_balls_size,
			"min" = BALLS_SIZE_MIN,
			"max" = BALLS_SIZE_MAX,
			"enabled" = genital_has_balls,
		),
		list(
			"id" = "vag_shape",
			"label" = "Тип вагины",
			"type" = "list",
			"value" = genital_vag_shape,
			"options" = sort_list(assoc_to_keys(GLOB.vagina_shapes_list)),
			"enabled" = genital_has_vag,
		),
		list(
			"id" = "breasts_shape",
			"label" = "Тип груди",
			"type" = "list",
			"value" = genital_breasts_shape,
			"options" = sort_list(assoc_to_keys(GLOB.breasts_shapes_list)),
			"enabled" = genital_has_breasts,
		),
		list(
			"id" = "breasts_size",
			"label" = "Размер груди",
			"type" = "list",
			"value" = genital_breasts_size,
			"options" = sort_list(assoc_to_keys(CONFIG_GET(keyed_list/breasts_cups_prefs))),
			"enabled" = genital_has_breasts,
		),
		list(
			"id" = "butt_shape",
			"label" = "Тип ягодиц",
			"type" = "list",
			"value" = genital_butt_shape,
			"options" = sort_list(assoc_to_keys(GLOB.butt_shapes_list)),
			"enabled" = genital_has_butt,
		),
		list(
			"id" = "butt_size",
			"label" = "Размер задницы",
			"type" = "number",
			"value" = genital_butt_size,
			"min" = CONFIG_GET(number/butt_min_size_prefs),
			"max" = CONFIG_GET(number/butt_max_size_prefs),
			"enabled" = genital_has_butt,
		),
		list(
			"id" = "belly_shape",
			"label" = "Тип живота",
			"type" = "list",
			"value" = genital_belly_shape,
			"options" = sort_list(assoc_to_keys(GLOB.belly_shapes_list)),
			"enabled" = genital_has_belly,
		),
		list(
			"id" = "belly_size",
			"label" = "Размер живота",
			"type" = "number",
			"value" = genital_belly_size,
			"min" = CONFIG_GET(number/belly_min_size_prefs),
			"max" = CONFIG_GET(number/belly_max_size_prefs),
			"enabled" = genital_has_belly,
		),
		list(
			"id" = "anus_shape",
			"label" = "Тип ануса",
			"type" = "list",
			"value" = genital_anus_shape,
			"options" = sort_list(assoc_to_keys(GLOB.anus_shapes_list)),
			"enabled" = genital_has_anus,
		),
	)

/obj/machinery/ipc_constructor/proc/get_genital_color_data()
	return list(
		list(
			"id" = "cock_color",
			"label" = "Цвет члена",
			"value" = genital_cock_color,
			"enabled" = genital_has_cock,
		),
		list(
			"id" = "balls_color",
			"label" = "Цвет яиц",
			"value" = genital_balls_color,
			"enabled" = genital_has_balls,
		),
		list(
			"id" = "vag_color",
			"label" = "Цвет вагины",
			"value" = genital_vag_color,
			"enabled" = genital_has_vag,
		),
		list(
			"id" = "breasts_color",
			"label" = "Цвет груди",
			"value" = genital_breasts_color,
			"enabled" = genital_has_breasts,
		),
		list(
			"id" = "butt_color",
			"label" = "Цвет ягодиц",
			"value" = genital_butt_color,
			"enabled" = genital_has_butt,
		),
		list(
			"id" = "belly_color",
			"label" = "Цвет живота",
			"value" = genital_belly_color,
			"enabled" = genital_has_belly,
		),
		list(
			"id" = "anus_color",
			"label" = "Цвет ануса",
			"value" = genital_anus_color,
			"enabled" = genital_has_anus,
		),
	)

/obj/machinery/ipc_constructor/proc/set_genital_option(option_id, enabled)
	switch(option_id)
		if("has_cock")
			genital_has_cock = enabled
			if(!enabled)
				genital_has_balls = FALSE
		if("has_balls")
			genital_has_balls = enabled
			if(enabled)
				genital_has_cock = TRUE
		if("has_vag")
			genital_has_vag = enabled
			if(!enabled)
				genital_has_womb = FALSE
		if("has_womb")
			genital_has_womb = enabled
			if(enabled)
				genital_has_vag = TRUE
		if("has_breasts")
			genital_has_breasts = enabled
		if("has_butt")
			genital_has_butt = enabled
			if(!enabled)
				genital_has_anus = FALSE
		if("has_belly")
			genital_has_belly = enabled
		if("has_anus")
			genital_has_anus = enabled
			if(enabled)
				genital_has_butt = TRUE

/obj/machinery/ipc_constructor/proc/set_genital_size(size_id, value)
	switch(size_id)
		if("cock_shape")
			genital_cock_shape = sanitize_inlist("[value]", GLOB.cock_shapes_list, DEF_COCK_SHAPE)
		if("cock_length")
			genital_cock_length = clamp(round(text2num(value)), CONFIG_GET(number/penis_min_inches_prefs), CONFIG_GET(number/penis_max_inches_prefs))
		if("balls_shape")
			genital_balls_shape = sanitize_inlist("[value]", GLOB.balls_shapes_list, DEF_BALLS_SHAPE)
		if("balls_size")
			genital_balls_size = clamp(round(text2num(value)), BALLS_SIZE_MIN, BALLS_SIZE_MAX)
		if("vag_shape")
			genital_vag_shape = sanitize_inlist("[value]", GLOB.vagina_shapes_list, DEF_VAGINA_SHAPE)
		if("breasts_shape")
			genital_breasts_shape = sanitize_inlist("[value]", GLOB.breasts_shapes_list, DEF_BREASTS_SHAPE)
		if("breasts_size")
			genital_breasts_size = sanitize_inlist("[value]", CONFIG_GET(keyed_list/breasts_cups_prefs), BREASTS_SIZE_DEF)
		if("butt_shape")
			genital_butt_shape = sanitize_inlist("[value]", GLOB.butt_shapes_list, "Pair")
		if("butt_size")
			genital_butt_size = clamp(round(text2num(value)), CONFIG_GET(number/butt_min_size_prefs), CONFIG_GET(number/butt_max_size_prefs))
		if("belly_shape")
			genital_belly_shape = sanitize_inlist("[value]", GLOB.belly_shapes_list, "Pair")
		if("belly_size")
			genital_belly_size = clamp(round(text2num(value)), CONFIG_GET(number/belly_min_size_prefs), CONFIG_GET(number/belly_max_size_prefs))
		if("anus_shape")
			genital_anus_shape = sanitize_inlist("[value]", GLOB.anus_shapes_list, DEF_ANUS_SHAPE)

/obj/machinery/ipc_constructor/proc/set_genital_color(color_id, value)
	var/hex_color = sanitize_hexcolor(value, 6, FALSE, "FFFFFF")
	switch(color_id)
		if("cock_color")
			genital_cock_color = hex_color
		if("balls_color")
			genital_balls_color = hex_color
		if("vag_color")
			genital_vag_color = hex_color
		if("breasts_color")
			genital_breasts_color = hex_color
		if("butt_color")
			genital_butt_color = hex_color
		if("belly_color")
			genital_belly_color = hex_color
		if("anus_color")
			genital_anus_color = hex_color

/obj/machinery/ipc_constructor/proc/get_genital_color_value(color_id)
	switch(color_id)
		if("cock_color")
			return genital_cock_color
		if("balls_color")
			return genital_balls_color
		if("vag_color")
			return genital_vag_color
		if("breasts_color")
			return genital_breasts_color
		if("butt_color")
			return genital_butt_color
		if("belly_color")
			return genital_belly_color
		if("anus_color")
			return genital_anus_color
	return "FFFFFF"

/obj/machinery/ipc_constructor/proc/get_genital_color_prompt(color_id)
	switch(color_id)
		if("cock_color")
			return "Выберите цвет члена"
		if("balls_color")
			return "Выберите цвет яиц"
		if("vag_color")
			return "Выберите цвет вагины"
		if("breasts_color")
			return "Выберите цвет груди"
		if("butt_color")
			return "Выберите цвет ягодиц"
		if("belly_color")
			return "Выберите цвет живота"
		if("anus_color")
			return "Выберите цвет ануса"
	return "Выберите цвет"

/obj/machinery/ipc_constructor/proc/prompt_genital_color(mob/user, color_id)
	if(!user || busy)
		return
	var/current_color = get_genital_color_value(color_id)
	var/chosen_color = input(user, get_genital_color_prompt(color_id), "Цвет половой системы", "#[current_color]") as color|null
	if(!chosen_color)
		return
	if(QDELETED(src) || QDELETED(user) || busy)
		return
	set_genital_color(color_id, chosen_color)

/obj/machinery/ipc_constructor/proc/is_valid_prosthetic_part(obj/item/bodypart/part, body_zone)
	if(!part)
		return FALSE
	switch(body_zone)
		if(BODY_ZONE_L_ARM)
			return istype(part, /obj/item/bodypart/l_arm/robot/surplus) || istype(part, /obj/item/bodypart/l_arm/robot/surplus_upgraded)
		if(BODY_ZONE_R_ARM)
			return istype(part, /obj/item/bodypart/r_arm/robot/surplus) || istype(part, /obj/item/bodypart/r_arm/robot/surplus_upgraded)
		if(BODY_ZONE_L_LEG)
			return istype(part, /obj/item/bodypart/l_leg/robot/surplus) || istype(part, /obj/item/bodypart/l_leg/robot/surplus_upgraded)
		if(BODY_ZONE_R_LEG)
			return istype(part, /obj/item/bodypart/r_leg/robot/surplus) || istype(part, /obj/item/bodypart/r_leg/robot/surplus_upgraded)
	return FALSE

/obj/machinery/ipc_constructor/proc/dump_materials()
	if(stored_metal > 0)
		new /obj/item/stack/sheet/metal(drop_location(), stored_metal)
		stored_metal = 0
	if(stored_glass > 0)
		new /obj/item/stack/sheet/glass(drop_location(), stored_glass)
		stored_glass = 0
	if(stored_plastic > 0)
		new /obj/item/stack/sheet/plastic(drop_location(), stored_plastic)
		stored_plastic = 0

/obj/machinery/ipc_constructor/proc/get_suggested_designation()
	if(core_has_resident_intelligence(cognitive_core_part) && cognitive_core_part?.brainmob?.real_name)
		return cognitive_core_part.brainmob.real_name
	return ""

/obj/machinery/ipc_constructor/proc/get_available_screens()
	. = list()
	for(var/screen_name in GLOB.ipc_screens_list)
		if(screen_name == "Blank")
			continue
		. += screen_name

/obj/machinery/ipc_constructor/proc/get_default_screen()
	return no_screen_option

/obj/machinery/ipc_constructor/proc/get_resolved_screen(screen_name = selected_screen)
	if(screen_name == "Blank")
		return no_screen_option
	if(screen_name == no_screen_option)
		return no_screen_option
	return screen_name

/obj/machinery/ipc_constructor/proc/get_applied_screen(screen_name = selected_screen)
	var/resolved_screen = get_resolved_screen(screen_name)
	if(resolved_screen)
		return resolved_screen
	return get_default_screen()

/obj/machinery/ipc_constructor/proc/get_selected_screen()
	var/list/available_screens = get_available_screens()
	selected_screen = get_resolved_screen(selected_screen)
	if(selected_screen in available_screens)
		return selected_screen
	selected_screen = get_default_screen()
	return selected_screen

/obj/machinery/ipc_constructor/proc/get_limb_style_names()
	. = list()
	for(var/style_name in limb_style_icons)
		. += style_name

/obj/machinery/ipc_constructor/proc/style_supports_slot(style_name, slot_id)
	var/icon_file = limb_style_icons[style_name]
	if(!icon_file)
		return FALSE
	if(slot_id == "head")
		var/list/head_states = icon_states(icon_file)
		return ("robotic_head" in head_states) || (("head_f" in head_states) && ("head_m" in head_states))
	if(slot_id == "chest")
		var/list/chest_states = icon_states(icon_file)
		return ("robotic_chest" in chest_states) || (("chest_f" in chest_states) && ("chest_m" in chest_states))
	return TRUE

/obj/machinery/ipc_constructor/proc/get_bodypart_style_options(slot_id)
	. = list()
	for(var/style_name in limb_style_icons)
		if(style_supports_slot(style_name, slot_id))
			. += style_name

/obj/machinery/ipc_constructor/proc/get_bodypart_style(obj/item/bodypart/robotic_part)
	if(!robotic_part)
		return null
	for(var/style_name in limb_style_icons)
		if(limb_style_icons[style_name] == robotic_part.icon)
			return style_name
	return "standard"

/obj/machinery/ipc_constructor/proc/get_styleable_bodypart(slot_id)
	switch(slot_id)
		if("head")
			return head_part
		if("chest")
			return chest_part
		if("l_arm")
			return l_arm_part
		if("r_arm")
			return r_arm_part
		if("l_leg")
			return l_leg_part
		if("r_leg")
			return r_leg_part
	return null

/obj/machinery/ipc_constructor/proc/set_bodypart_style(slot_id, style_name, mob/user)
	if(!(style_name in limb_style_icons))
		return FALSE
	if(!style_supports_slot(style_name, slot_id))
		if(user)
			to_chat(user, "<span class='warning'>Эта серия не поддерживает стандартный внешний вид для выбранного модуля.</span>")
		return FALSE
	var/obj/item/bodypart/robotic_part = get_styleable_bodypart(slot_id)
	if(!robotic_part)
		if(user)
			to_chat(user, "<span class='warning'>Сначала установите соответствующую конечность.</span>")
		return FALSE
	robotic_part.icon = limb_style_icons[style_name]
	robotic_part.update_icon_dropped()
	if(user)
		to_chat(user, "<span class='notice'>Вы меняете серию [robotic_part] на [style_name].</span>")
	return TRUE

/obj/machinery/ipc_constructor/proc/get_cognitive_core_type()
	if(istype(cognitive_core_part, /obj/item/mmi/posibrain))
		if(cognitive_core_spawns_ghost_role(cognitive_core_part))
			return "Vacant positronic brain"
		return "Positronic brain"
	if(cognitive_core_part)
		return "MMI"
	return null

/obj/machinery/ipc_constructor/proc/has_preinstalled_software()
	if(!cognitive_core_part)
		return FALSE
	if(istype(cognitive_core_part, /obj/item/mmi/posibrain))
		return FALSE
	return core_has_resident_intelligence(cognitive_core_part)

/obj/machinery/ipc_constructor/proc/core_has_resident_intelligence(obj/item/mmi/core)
	if(!core || !core.brainmob)
		return FALSE
	if(core.brainmob.suiciding)
		return FALSE
	if(!core.brainmob.mind && !core.brainmob.key)
		return FALSE
	return TRUE

/obj/machinery/ipc_constructor/proc/cognitive_core_spawns_ghost_role(obj/item/mmi/core)
	if(!istype(core, /obj/item/mmi/posibrain))
		return FALSE
	return !core_has_resident_intelligence(core)

/obj/machinery/ipc_constructor/proc/cognitive_core_can_be_assembled(obj/item/mmi/core)
	if(!core || !core.brainmob)
		return FALSE
	if(core_has_resident_intelligence(core))
		return TRUE
	if(cognitive_core_spawns_ghost_role(core))
		return TRUE
	return FALSE

/obj/machinery/ipc_constructor/proc/get_required_materials(body_size = selected_body_size)
	var/material_multiplier = get_material_efficiency_multiplier()
	return list(
		"metal" = max(1, round(base_metal_cost * body_size * material_multiplier)),
		"glass" = max(1, round(base_glass_cost * body_size * material_multiplier)),
		"plastic" = add_genitals ? max(1, round(base_plastic_cost * body_size * material_multiplier)) : 0,
	)

/obj/machinery/ipc_constructor/proc/get_material_efficiency_multiplier()
	return clamp(1 - ((assembly_part_tier - 1) * 0.1), 0.6, 1)

/obj/machinery/ipc_constructor/proc/get_assembly_time_seconds()
	var/size_extra = max(0, round((selected_body_size - RESIZE_DEFAULT_SIZE) * 40))
	var/implant_extra = LAZYLEN(loaded_implants) * 6
	var/workload_seconds = base_assembly_time_seconds + size_extra + implant_extra
	var/quality_multiplier = 1 + ((5 - assembly_part_tier) * 0.25)
	return max(base_assembly_time_seconds, round(workload_seconds * quality_multiplier))

/obj/machinery/ipc_constructor/proc/get_assembly_progress()
	if(!busy || assembly_finish_at <= assembly_started_at)
		return 0
	var/elapsed = world.time - assembly_started_at
	var/duration = assembly_finish_at - assembly_started_at
	return clamp(elapsed / duration, 0, 1)

/obj/machinery/ipc_constructor/proc/get_assembly_remaining_seconds()
	if(!busy)
		return 0
	return max(0, round((assembly_finish_at - world.time) / 10))

/obj/machinery/ipc_constructor/proc/get_assembly_status_text()
	if(!busy)
		return null

	var/progress = get_assembly_progress()
	if(progress < 0.15)
		return "Собираем вашего синтетика..."
	if(progress < 0.3)
		return "Проверяем проводку..."
	if(progress < 0.45)
		return "Фиксируем шасси и конечности..."
	if(progress < 0.6)
		return "Подключаем внутренние модули..."
	if(progress < 0.75)
		return "Калибруем сенсорные системы..."
	if(progress < 0.9)
		return "Синхронизируем когнитивное ядро..."
	return "Завершаем инициализацию синтетика..."

/obj/machinery/ipc_constructor/proc/build_preview_icon()
	var/mob/living/carbon/human/dummy/consistent/preview = new(get_turf(src))
	preview.set_species(/datum/species/ipc)
	if(preview.dna)
		var/old_size = preview.dna.features["body_size"]
		preview.dna.features["ipc_screen"] = get_applied_screen()
		preview.dna.features["body_size"] = selected_body_size
		preview.update_size(get_size(preview), old_size)

	install_preview_bodypart(preview, head_part, BODY_ZONE_HEAD, /obj/item/bodypart/head/robot/ipc)
	install_preview_bodypart(preview, chest_part, BODY_ZONE_CHEST, /obj/item/bodypart/chest/robot/ipc)
	install_preview_bodypart(preview, l_arm_part, BODY_ZONE_L_ARM)
	install_preview_bodypart(preview, r_arm_part, BODY_ZONE_R_ARM)
	install_preview_bodypart(preview, l_leg_part, BODY_ZONE_L_LEG)
	install_preview_bodypart(preview, r_leg_part, BODY_ZONE_R_LEG)

	apply_genital_configuration(preview)
	preview.update_body(TRUE)
	preview.update_hair()
	preview.update_body_parts()

	var/icon/result = getFlatIcon(preview, defdir = SOUTH, no_anim = TRUE)
	qdel(preview)
	return result

/obj/machinery/ipc_constructor/proc/get_preview_icon_base64()
	try
		var/icon/preview_icon = build_preview_icon()
		if(!preview_icon || !isicon(preview_icon))
			return null
		return icon2base64(preview_icon)
	catch(var/exception/e)
		stack_trace("ipc_constructor: preview icon generation failed ([e]).")
		return null

/obj/machinery/ipc_constructor/proc/install_preview_bodypart(mob/living/carbon/human/preview, obj/item/bodypart/source_part, body_zone, fallback_type)
	var/obj/item/bodypart/existing_part = preview.get_bodypart(body_zone)
	if(existing_part)
		existing_part.drop_limb(TRUE)
		qdel(existing_part)
	var/obj/item/bodypart/preview_part
	if(source_part)
		preview_part = new source_part.type
	else if(fallback_type)
		preview_part = new fallback_type
	else
		return

	if(source_part)
		preview_part.icon = source_part.icon
		preview_part.icon_state = source_part.icon_state
		preview_part.base_bp_icon = source_part.base_bp_icon
		preview_part.aux_icons = source_part.aux_icons?.Copy()
		preview_part.should_draw_gender = source_part.should_draw_gender
		preview_part.species_id = source_part.species_id
		preview_part.species_color = source_part.species_color
		preview_part.mutation_color = source_part.mutation_color
		preview_part.body_markings_list = source_part.body_markings_list?.Copy()
		preview_part.markings_color = source_part.markings_color?.Copy()
		preview_part.px_x = source_part.px_x
		preview_part.px_y = source_part.px_y
	install_bodypart(preview, preview_part)

/obj/machinery/ipc_constructor/proc/get_assembly_problems()
	. = list()
	var/list/required_materials = get_required_materials()
	if(!head_part)
		. += "Отсутствует головной модуль IPC."
	else
		if(locate(/obj/item/organ) in head_part.contents)
			. += "Головной модуль IPC должен быть пустым."

	if(!chest_part)
		. += "Отсутствует торсовый модуль IPC."
	else
		if(locate(/obj/item/organ) in chest_part.contents)
			. += "Торсовый модуль IPC должен быть пустым."

	if(!l_arm_part)
		. += "Отсутствует левая рука."
	if(!r_arm_part)
		. += "Отсутствует правая рука."
	if(!l_leg_part)
		. += "Отсутствует левая нога."
	if(!r_leg_part)
		. += "Отсутствует правая нога."
	if(!heart_part)
		. += "Отсутствует гидравлический насос."
	if(!lungs_part)
		. += "Отсутствует система охлаждения."
	if(!liver_part)
		. += "Отсутствует реагентный процессор."
	if(!stomach_part)
		. += "Отсутствует энергоячейка IPC."
	if(!eyes_part)
		. += "Отсутствует оптический сенсорный блок."
	if(!ears_part)
		. += "Отсутствует аудиосенсорный блок."
	if(!tongue_part)
		. += "Отсутствует голосовой синтезатор IPC."
	if(stored_metal < required_materials["metal"])
		. += "Недостаточно стали для выбранного размера шасси."
	if(stored_glass < required_materials["glass"])
		. += "Недостаточно стекла для выбранного размера шасси."
	if(stored_plastic < required_materials["plastic"])
		. += "Недостаточно пластика для модуля гениталий."
	if(!cognitive_core_part)
		. += "Отсутствует когнитивное ядро в груди. Установите позитронный мозг или ММИ."
	else if(!cognitive_core_can_be_assembled(cognitive_core_part))
		. += "Загруженное когнитивное ядро не может инициализировать IPC."
	else if(istype(cognitive_core_part, /obj/item/mmi) && !istype(cognitive_core_part, /obj/item/mmi/posibrain) && !core_has_resident_intelligence(cognitive_core_part))
		. += "В загруженном ММИ нет сознания."

/obj/machinery/ipc_constructor/proc/get_required_assembly_problems()
	. = list()
	var/list/required_materials = get_required_materials()
	if(!head_part)
		. += "Отсутствует головной модуль IPC."
	else if(locate(/obj/item/organ) in head_part.contents)
		. += "Головной модуль IPC должен быть пустым."
	if(!chest_part)
		. += "Отсутствует торсовый модуль IPC."
	else if(locate(/obj/item/organ) in chest_part.contents)
		. += "Торсовый модуль IPC должен быть пустым."
	if(!heart_part)
		. += "Отсутствует гидравлический насос."
	if(!lungs_part)
		. += "Отсутствует система охлаждения."
	if(!liver_part)
		. += "Отсутствует реагентный процессор."
	if(!stomach_part)
		. += "Отсутствует энергоячейка IPC."
	if(!eyes_part)
		. += "Отсутствует оптический сенсорный блок."
	if(!ears_part)
		. += "Отсутствует аудиосенсорный блок."
	if(!tongue_part)
		. += "Отсутствует голосовой синтезатор IPC."
	if(stored_metal < required_materials["metal"])
		. += "Недостаточно стали для выбранного размера шасси."
	if(stored_glass < required_materials["glass"])
		. += "Недостаточно стекла для выбранного размера шасси."
	if(stored_plastic < required_materials["plastic"])
		. += "Недостаточно пластика для модуля половых систем."
	if(!cognitive_core_part)
		. += "Отсутствует когнитивное ядро в груди. Установите позитронный мозг или ММИ."
	else if(!cognitive_core_can_be_assembled(cognitive_core_part))
		. += "Загруженное когнитивное ядро не может инициализировать IPC."
	else if(istype(cognitive_core_part, /obj/item/mmi) && !istype(cognitive_core_part, /obj/item/mmi/posibrain) && !core_has_resident_intelligence(cognitive_core_part))
		. += "В загруженном ММИ нет сознания."

/obj/machinery/ipc_constructor/proc/get_missing_optional_parts()
	. = list()
	if(!l_arm_part)
		. += "левая рука"
	if(!r_arm_part)
		. += "правая рука"
	if(!l_leg_part)
		. += "левая нога"
	if(!r_leg_part)
		. += "правая нога"

/obj/machinery/ipc_constructor/proc/get_optional_assembly_problem_text()
	return list(
		"Отсутствует левая рука.",
		"Отсутствует правая рука.",
		"Отсутствует левая нога.",
		"Отсутствует правая нога.",
	)

/obj/machinery/ipc_constructor/proc/start_assembly(mob/user, designation, selected_screen)
	var/list/problems = get_required_assembly_problems()
	if(LAZYLEN(problems))
		to_chat(user, "<span class='warning'>[problems[1]]</span>")
		return

	var/assembly_time = get_assembly_time_seconds()
	busy = TRUE
	assembly_started_at = world.time
	assembly_finish_at = world.time + (assembly_time * 10)
	use_power(active_power_usage)
	update_icon()
	visible_message("<span class='notice'>[src] locks down and begins synthetic assembly. Estimated completion time: [assembly_time] seconds.</span>")
	addtimer(CALLBACK(src, PROC_REF(finish_assembly), designation, selected_screen), assembly_time * 10)

/obj/machinery/ipc_constructor/proc/finish_assembly(designation, selected_screen)
	busy = FALSE
	assembly_started_at = 0
	assembly_finish_at = 0
	update_icon()

	var/list/problems = get_required_assembly_problems()
	if(LAZYLEN(problems))
		audible_message("<span class='warning'>[src] aborts assembly: [problems[1]]</span>")
		return
	var/list/required_materials = get_required_materials()
	stored_metal -= required_materials["metal"]
	stored_glass -= required_materials["glass"]

	stored_plastic -= required_materials["plastic"]
	var/turf/output_turf = drop_location()
	var/mob/living/carbon/human/assembled = new(output_turf)
	assembled.set_species(/datum/species/ipc)
	var/spawn_as_ghost_role = cognitive_core_spawns_ghost_role(cognitive_core_part)

	install_bodypart(assembled, head_part)
	install_bodypart(assembled, chest_part)
	install_bodypart(assembled, l_arm_part)
	install_bodypart(assembled, r_arm_part)
	install_bodypart(assembled, l_leg_part)
	install_bodypart(assembled, r_leg_part)
	apply_identification_tattoo(assembled, get_loaded_chassis_series())

	install_organ(assembled, heart_part)
	install_organ(assembled, lungs_part)
	install_organ(assembled, liver_part)
	install_organ(assembled, stomach_part)
	install_organ(assembled, eyes_part)
	install_organ(assembled, ears_part)
	install_organ(assembled, tongue_part)

	if(spawn_as_ghost_role)
		discard_cognitive_core()
	else
		var/obj/item/organ/brain/ipc/final_brain = consume_cognitive_core()
		if(final_brain)
			final_brain.Insert(assembled, TRUE, TRUE, FALSE)

	install_loaded_implants(assembled)

	head_part = null
	chest_part = null
	l_arm_part = null
	r_arm_part = null
	l_leg_part = null
	r_leg_part = null
	heart_part = null
	lungs_part = null
	liver_part = null
	stomach_part = null
	eyes_part = null
	ears_part = null
	tongue_part = null
	cognitive_core_part = null

	if(designation)
		assembled.fully_replace_character_name(null, designation)
		if(assembled.dna)
			assembled.dna.real_name = designation
	else
		assembled.fully_replace_character_name(null, "Uninitialized IPC")
		if(assembled.dna)
			assembled.dna.real_name = assembled.real_name
		assembled.ipc_name_pending = TRUE
		if(!spawn_as_ghost_role)
			addtimer(CALLBACK(assembled, TYPE_PROC_REF(/mob/living/carbon/human, ipc_prompt_designation)), 1 SECONDS)
	if(assembled.dna)
		assembled.dna.features["ipc_screen"] = get_applied_screen(selected_screen)
		var/old_size = assembled.dna.features["body_size"]
		assembled.dna.features["body_size"] = selected_body_size
		assembled.update_size(get_size(assembled), old_size)
	assembled.update_body()
	assembled.update_hair()
	assembled.update_body_parts()
	apply_genital_configuration(assembled)
	assembled.updatehealth()

	if(spawn_as_ghost_role)
		assembled.death()
		new /obj/effect/mob_spawn/human/ipc_shell(output_turf, assembled)

	visible_message("<span class='notice'>[src] finishes construction and releases [assembled].</span>")

/obj/machinery/ipc_constructor/proc/install_bodypart(mob/living/carbon/human/assembled, obj/item/bodypart/new_part)
	if(!new_part)
		return
	var/obj/item/bodypart/old_part = assembled.get_bodypart(new_part.body_zone)
	new_part.replace_limb(assembled, TRUE)
	if(old_part)
		qdel(old_part)

/obj/machinery/ipc_constructor/proc/install_organ(mob/living/carbon/human/assembled, obj/item/organ/new_organ)
	new_organ.Insert(assembled, TRUE, FALSE)

/obj/machinery/ipc_constructor/proc/apply_genital_configuration(mob/living/carbon/human/assembled)
	if(!assembled?.dna)
		return

	assembled.dna.features["has_cock"] = add_genitals && genital_has_cock
	assembled.dna.features["has_balls"] = add_genitals && genital_has_balls
	assembled.dna.features["has_vag"] = add_genitals && genital_has_vag
	assembled.dna.features["has_womb"] = add_genitals && genital_has_womb
	assembled.dna.features["has_breasts"] = add_genitals && genital_has_breasts
	assembled.dna.features["has_butt"] = add_genitals && genital_has_butt
	assembled.dna.features["has_belly"] = add_genitals && genital_has_belly
	assembled.dna.features["has_anus"] = add_genitals && genital_has_anus
	assembled.dna.features["cock_shape"] = genital_cock_shape
	assembled.dna.features["cock_length"] = genital_cock_length
	assembled.dna.features["balls_shape"] = genital_balls_shape
	assembled.dna.features["balls_size"] = genital_balls_size
	assembled.dna.features["vag_shape"] = genital_vag_shape
	assembled.dna.features["breasts_shape"] = genital_breasts_shape
	assembled.dna.features["breasts_size"] = genital_breasts_size
	assembled.dna.features["butt_shape"] = genital_butt_shape
	assembled.dna.features["butt_size"] = genital_butt_size
	assembled.dna.features["belly_shape"] = genital_belly_shape
	assembled.dna.features["belly_size"] = genital_belly_size
	assembled.dna.features["anus_shape"] = genital_anus_shape
	assembled.dna.features["cock_color"] = genital_cock_color
	assembled.dna.features["balls_color"] = genital_balls_color
	assembled.dna.features["vag_color"] = genital_vag_color
	assembled.dna.features["breasts_color"] = genital_breasts_color
	assembled.dna.features["butt_color"] = genital_butt_color
	assembled.dna.features["belly_color"] = genital_belly_color
	assembled.dna.features["anus_color"] = genital_anus_color
	assembled.dna.features["genitals_use_skintone"] = FALSE

	assembled.give_genitals(TRUE)
	assembled.update_genitals()

/obj/machinery/ipc_constructor/proc/get_loaded_chassis_series()
	var/list/style_counts = list()
	for(var/obj/item/bodypart/robotic_part as anything in list(l_arm_part, r_arm_part, l_leg_part, r_leg_part))
		if(!robotic_part)
			continue
		var/style_name = get_bodypart_style(robotic_part)
		if(!style_name)
			continue
		style_counts[style_name] = (style_counts[style_name] || 0) + 1

	if(!length(style_counts))
		return "standard"
	if(length(style_counts) > 1)
		return "Mixed"
	for(var/style_name in style_counts)
		return style_name
	return "standard"

/obj/machinery/ipc_constructor/proc/get_series_code(series_name)
	switch(series_name)
		if("standard")
			return "STD"
		if("engineer")
			return "ENG"
		if("security")
			return "SEC"
		if("mining")
			return "MIN"
		if("Talon")
			return "TLN"
		if("Nanotrasen")
			return "NTS"
		if("Morpheus")
			return "MOR"
		if("Veymed")
			return "VEY"
		if("Bishop")
			return "BSH"
		if("Bishop 2.0")
			return "BS2"
		if("Hephaestus")
			return "HEP"
		if("Hephaestus 2.0")
			return "HP2"
		if("Shellguard")
			return "SHL"
		if("Xion")
			return "XION"
		if("Xion 2.0")
			return "XI2"
		if("Grayson")
			return "GRY"
		if("Cybersolutions")
			return "CYS"
		if("Ward")
			return "WRD"
		if("Zeng-Hu")
			return "ZHU"
		if("Mariinsky")
			return "MAR"
		if("Mixed")
			return "MIX"
	return uppertext(copytext("[series_name]", 1, 5))

/obj/machinery/ipc_constructor/proc/apply_identification_tattoo(mob/living/carbon/human/assembled, series_name)
	var/obj/item/bodypart/head/assembled_head = assembled.get_bodypart(BODY_ZONE_HEAD)
	var/obj/item/bodypart/chest/assembled_chest = assembled.get_bodypart(BODY_ZONE_CHEST)
	if(!assembled_head)
		return
	var/serial_number = add_leading(num2text(rand(0, 999999)), 6, "0")
	var/series_code = get_series_code(series_name)
	var/identification_text = "<span style='color:#9aa4ac'>Серия [html_encode(series_code)] | ID [html_encode(serial_number)]</span>"
	if(length(assembled_head.tattoo_text))
		assembled_head.tattoo_text += "; [identification_text]"
	else
		assembled_head.tattoo_text = identification_text
	if(add_genitals && assembled_chest)
		var/groin_identification_text = "<span style='color:#9aa4ac'>ID [html_encode(series_code)]-[html_encode(serial_number)]</span>"
		set_tattoo_text_for_zone(assembled_chest, TATTOO_ZONE_GROIN, groin_identification_text)

/obj/machinery/ipc_constructor/proc/install_loaded_implants(mob/living/carbon/human/assembled)
	for(var/obj/item/implant_item as anything in loaded_implants.Copy())
		loaded_implants -= implant_item
		if(!install_loaded_implant(assembled, implant_item))
			LAZYADD(loaded_implants, implant_item)

/obj/machinery/ipc_constructor/proc/install_loaded_implant(mob/living/carbon/human/assembled, obj/item/implant_item)
	if(istype(implant_item, /obj/item/implant))
		var/obj/item/implant/implant = implant_item
		return implant.implant(assembled, null, TRUE)

	if(istype(implant_item, /obj/item/organ/cyberimp))
		var/obj/item/organ/cyberimp/cyberimp = implant_item
		return cyberimp.Insert(assembled, TRUE, FALSE)

	return FALSE

/obj/machinery/ipc_constructor/proc/consume_cognitive_core()
	var/obj/item/organ/brain/ipc/final_brain
	if(!cognitive_core_part)
		return null

	var/obj/item/mmi/loaded_core = cognitive_core_part
	cognitive_core_part = null

	final_brain = new /obj/item/organ/brain/ipc(src)
	final_brain.brainmob = loaded_core.brainmob
	if(final_brain.brainmob)
		final_brain.brainmob.forceMove(final_brain)
		final_brain.brainmob.container = null
	loaded_core.brainmob = null
	QDEL_NULL(loaded_core.brain)
	qdel(loaded_core)
	return final_brain

/obj/machinery/ipc_constructor/proc/discard_cognitive_core()
	if(!cognitive_core_part)
		return
	var/obj/item/mmi/loaded_core = cognitive_core_part
	cognitive_core_part = null
	QDEL_NULL(loaded_core.brainmob)
	QDEL_NULL(loaded_core.brain)
	qdel(loaded_core)

/obj/structure/filler/ipc_constructor
	name = "synthetic constructor frame"
	icon = 'icons/effects/effects.dmi'
	icon_state = "nothing"
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_OPAQUE

/obj/structure/filler/ipc_constructor/attack_hand(mob/user, act_intent = user?.a_intent, attackchain_flags)
	if(parent)
		return parent.attack_hand(user, act_intent, attackchain_flags)
	return ..()

/obj/structure/filler/ipc_constructor/attackby(obj/item/user_item, mob/living/user, params)
	if(parent)
		return parent.attackby(user_item, user, params)
	return ..()

/obj/structure/filler/ipc_constructor/examine(mob/user)
	if(parent)
		return parent.examine(user)
	return ..()

/obj/effect/mob_spawn/human/ipc_shell
	name = "inactive IPC shell"
	job_description = "IPC Shell"
	mob_name = "an inactive IPC shell"
	icon = null
	icon_state = null
	density = FALSE
	anchored = TRUE
	roundstart = FALSE
	death = FALSE
	can_load_appearance = FALSE
	ghost_usable = TRUE
	short_desc = "You are a newly assembled IPC chassis awaiting initialization."
	flavour_text = "You were built in Robotics from a vacant positronic brain. Your task is to serve the station as a synthetic crewmember."
	category = "station"
	var/mob/living/carbon/human/target_shell

/obj/effect/mob_spawn/human/ipc_shell/Initialize(mapload, mob/living/carbon/human/new_shell)
	target_shell = new_shell
	if(target_shell)
		mob_name = target_shell.real_name
		name = "[target_shell.real_name] activation shell"
	. = ..()
	if(target_shell)
		var/area/shell_area = get_area(target_shell)
		notify_ghosts("[target_shell] is awaiting activation in [shell_area?.name].", ghost_sound = 'sound/misc/server-ready.ogg', enter_link = "<a href=?src=[REF(src)];activate=1>(Click to enter)</a>", source = src, action = NOTIFY_ATTACK, flashwindow = FALSE, ignore_dnr_observers = TRUE)

/obj/effect/mob_spawn/human/ipc_shell/Destroy()
	target_shell = null
	return ..()

/obj/effect/mob_spawn/human/ipc_shell/Topic(href, href_list)
	..()
	if(href_list["activate"])
		var/mob/dead/observer/ghost = usr
		if(istype(ghost))
			attack_ghost(ghost, FALSE)

/obj/effect/mob_spawn/human/ipc_shell/allow_spawn(mob/user, silent = FALSE)
	if(!target_shell || QDELETED(target_shell))
		return FALSE
	if(target_shell.key || target_shell.client)
		if(user && !silent)
			to_chat(user, "<span class='warning'>That IPC shell has already been activated.</span>")
		return FALSE
	return ..()

/obj/effect/mob_spawn/human/ipc_shell/can_latejoin()
	return !!target_shell && !QDELETED(target_shell) && !target_shell.key && !target_shell.client

/obj/effect/mob_spawn/human/ipc_shell/create(ckey, name, load_character)
	if(!target_shell || QDELETED(target_shell))
		qdel(src)
		return

	if(target_shell.key || target_shell.client)
		qdel(src)
		return

	var/obj/item/organ/brain/ipc/brain = target_shell.getorgan(/obj/item/organ/brain)
	if(!brain)
		brain = new /obj/item/organ/brain/ipc(target_shell)
		brain.Insert(target_shell, TRUE, TRUE, FALSE)

	target_shell.revive()
	target_shell.ckey = ckey
	ADD_TRAIT(target_shell, TRAIT_EXEMPT_HEALTH_EVENTS, GHOSTROLE_TRAIT)
	ADD_TRAIT(target_shell, TRAIT_NO_MIDROUND_ANTAG, GHOSTROLE_TRAIT)

	if(target_shell.mind)
		target_shell.mind.assigned_role = "IPC Shell"

	var/output_message = ""
	output_message += "<p class='medium'>You are <b>[target_shell.real_name]</b>.</p>"
	output_message += "<p>[short_desc]</p>"
	if(flavour_text)
		output_message += "<p>[flavour_text]</p>"
	to_chat(target_shell, examine_block(output_message))

	if(target_shell.ipc_name_pending)
		addtimer(CALLBACK(target_shell, TYPE_PROC_REF(/mob/living/carbon/human, ipc_prompt_designation)), 1 SECONDS)

	qdel(src)
