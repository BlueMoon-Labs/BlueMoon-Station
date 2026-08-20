/obj/structure/curtain_static
	name = "Base Curtain"
	desc = "Скрывает от глаз пикантные подробности."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "curtain_plastic"
	anchored = TRUE
	max_integrity = 50
	opacity = TRUE
	density = FALSE
	layer = BELOW_OPEN_DOOR_LAYER
	pass_flags = PASSTABLE | PASSGRILLE | PASSMACHINE | PASSSTRUCTURE
	custom_materials = null

/obj/structure/curtain_static/Initialize(mapload)
	. = ..()
	update_icon(UPDATE_OVERLAYS)

/obj/structure/curtain_static/update_overlays()
	. = ..()
	alpha = 0
	SSvis_overlays.add_vis_overlay(src, icon, icon_state, ABOVE_MOB_LAYER, plane, dir, add_appearance_flags = RESET_ALPHA) //you see mobs under it, but you hit them like they are above it

/obj/structure/curtain_static/examine(mob/user)
	. = ..()
	if(anchored)
		. += span_notice("<b>[anchored ? "П" : "Не п"]ривинчено</b> к полу.")
	. += span_notice("Может быть <b>разрезано</b> на части.")

/obj/structure/curtain_static/screwdriver_act(mob/living/user, obj/item/W)
	if(..())
		return TRUE
	add_fingerprint(user)
	var/action = anchored ? "откручивает [src] от пола" : "прикручивает [src] к полу"
	var/uraction = anchored ? "откручивать [src] от пола " : "прикручивать [src] к полу"
	user.visible_message(span_warning("[user] [action]."), span_notice("Ты начинаешь [uraction]..."), "Вы слышите звуки откручивания.")
	if(W.use_tool(src, user, 3 SECONDS, volume=100, extra_checks = CALLBACK(src, PROC_REF(check_anchored_state), anchored)))
		set_anchored(!anchored)
		to_chat(user, span_notice(" Ты [anchored ? "открутил" : "прикрутил"] [src]."))
	return TRUE

/obj/structure/curtain_static/wirecutter_act(mob/living/user, obj/item/W)
	user.visible_message(span_warning("[user] разрезает [src] на части."), span_notice("Ты стал разрезать [src] на части."), "Вы слышите звуки резки.")
	if(W.use_tool(src, user, 2 SECONDS, volume=100))
		to_chat(user, span_notice("Ты разрезал [src] на части."))
		deconstruct(TRUE)
	return TRUE

/obj/structure/curtain_static/proc/check_anchored_state(check_anchored)
	if(anchored != check_anchored)
		return FALSE
	return TRUE

/obj/structure/curtain_static/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(LAZYLEN(custom_materials))
			for(var/mat_path in custom_materials)
				var/datum/material/custom_material = SSmaterials.GetMaterialRef(mat_path)
				if(!custom_material.sheet_type)
					continue
				var/mat_count = round_down(custom_materials[mat_path]/MINERAL_MATERIAL_AMOUNT)
				var/obj/sheet = new custom_material.sheet_type(drop_location(), mat_count)
				transfer_fingerprints_to(sheet)
	return ..()

/obj/structure/curtain_static/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(iscarbon(AM))
		sound_effect()

/obj/structure/curtain_static/proc/sound_effect()
	playsound(src, 'sound/misc/wing_flap.ogg', 20, TRUE)

/obj/structure/curtain_static/plastic
	name = "Plastic Curtain"
	icon_state = "curtain_plastic"
	max_integrity = 100
	custom_materials = list(/datum/material/plastic = MINERAL_MATERIAL_AMOUNT)

/obj/structure/curtain_static/cloth
	name = "Clothes Curtain"
	icon_state = "curtain_cloth"
	max_integrity = 50
	custom_materials = list(/datum/material/cloth = MINERAL_MATERIAL_AMOUNT)

/obj/structure/curtain_static/cloth/sound_effect()
	playsound(src, 'sound/misc/fabric_flap.ogg', 20, TRUE)

/obj/structure/curtain_static/glass
	name = "Soft-Glass Curtain"
	icon_state = "curtain_glass"
	max_integrity = 70
	custom_materials = list(/datum/material/glass = MINERAL_MATERIAL_AMOUNT)
	opacity = FALSE
	var/electrochromatic_status = NOT_ELECTROCHROMATIC
	var/electrochromatic_id

/obj/structure/curtain_static/glass/examine(mob/user)
	. = ..()
	if(electrochromatic_status != NOT_ELECTROCHROMATIC)
		. += span_notice("Оснащено электрохромной тонировкой.")

/obj/structure/curtain_static/glass/attackby(obj/item/I, mob/living/user, params)
	add_fingerprint(user)
	if(istype(I, /obj/item/electronics/electrochromatic_kit) && user.a_intent != INTENT_HARM)
		var/obj/item/electronics/electrochromatic_kit/K = I
		if(electrochromatic_status != NOT_ELECTROCHROMATIC)
			to_chat(user, span_warning("[src] уже оснащено тонировкой!"))
			return
		if(!K.id)
			to_chat(user, span_warning("ID [K] не установлено!"))
			return
		if(!user.temporarilyRemoveItemFromInventory(K))
			to_chat(user, span_warning("[K] застряло в руке!"))
			return
		user.visible_message(span_notice("[user] устанавливает [K] в [src]."), span_notice("Вы установили [K] в [src]."))
		make_electrochromatic(K.id)
		qdel(K)
	return ..()

/obj/structure/curtain_static/glass/deconstruct(disassembled)
	if(!(flags_1 & NODECONSTRUCT_1) && !disassembled)
		var/obj/item/shard/shard = new /obj/item/shard(drop_location())
		transfer_fingerprints_to(shard)
		qdel(src)
		return
	return ..()

/obj/structure/curtain_static/glass/Destroy()
	if(obj_integrity == 0)
		playsound(src, "shatter", 70, 1)
	if(electrochromatic_status != NOT_ELECTROCHROMATIC)
		new /obj/item/electronics/electrochromatic_kit(drop_location())
	remove_electrochromatic()
	return ..()

/obj/structure/curtain_static/glass/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			playsound(loc, 'sound/effects/glasshit.ogg', 90, 1)
		if(BURN)
			playsound(src.loc, 'sound/items/welder.ogg', 100, 1)

/obj/structure/curtain_static/glass/proc/refresh_electrochromatic_opacity()
	if(electrochromatic_status == ELECTROCHROMATIC_DIMMED)
		set_opacity(TRUE)
	else
		set_opacity(FALSE)

/obj/structure/curtain_static/glass/proc/electrochromatic_dim()
	if(electrochromatic_status == ELECTROCHROMATIC_DIMMED)
		return
	electrochromatic_status = ELECTROCHROMATIC_DIMMED
	var/current = color
	add_atom_colour("#222222", FIXED_COLOUR_PRIORITY)
	var/newcolor = color
	if(color != current)
		color = current
		animate(src, color = newcolor, time = 2)
	refresh_electrochromatic_opacity()
	update_icon()

/obj/structure/curtain_static/glass/proc/electrochromatic_off()
	if(electrochromatic_status == ELECTROCHROMATIC_OFF)
		return
	electrochromatic_status = ELECTROCHROMATIC_OFF
	var/current = color
	remove_atom_colour(FIXED_COLOUR_PRIORITY, "#222222")
	var/newcolor = color
	if(color != current)
		color = current
		animate(src, color = newcolor, time = 2)
	refresh_electrochromatic_opacity()
	update_icon()

/obj/structure/curtain_static/glass/proc/remove_electrochromatic()
	electrochromatic_off()
	electrochromatic_status = NOT_ELECTROCHROMATIC
	if(!electrochromatic_id)
		return
	var/list/L = GLOB.electrochromatic_window_lookup["[electrochromatic_id]"]
	if(L)
		L -= src
	electrochromatic_id = null
	refresh_electrochromatic_opacity()
	update_icon()

/obj/structure/curtain_static/glass/proc/make_electrochromatic(new_id = electrochromatic_id)
	remove_electrochromatic()
	if(!new_id)
		CRASH("Attempted to make electrochromatic with null ID.")
	electrochromatic_id = new_id
	electrochromatic_status = ELECTROCHROMATIC_OFF
	LAZYINITLIST(GLOB.electrochromatic_window_lookup["[electrochromatic_id]"])
	GLOB.electrochromatic_window_lookup[electrochromatic_id] |= src
	refresh_electrochromatic_opacity()
	update_icon()
