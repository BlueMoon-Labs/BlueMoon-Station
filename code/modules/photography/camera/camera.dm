
#define CAMERA_PICTURE_SIZE_HARD_LIMIT 21
#define CAMERA_EDITOR_ASK "ask"
#define CAMERA_EDITOR_OPEN "open"
#define CAMERA_EDITOR_SKIP "skip"

/obj/item/camera
	name = "camera"
	desc = "Фотоаппарат мгновенной печати."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "camera"
	item_state = "camera"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	light_color = LIGHT_COLOR_WHITE
	light_power = FLASH_LIGHT_POWER
	w_class = WEIGHT_CLASS_SMALL
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_NECK
	custom_materials = list(/datum/material/iron = 50, /datum/material/glass = 150)
	custom_price = PRICE_NORMAL
	var/flash_enabled = TRUE
	var/state_on = "camera"
	var/state_off = "camera_off"
	var/pictures_max = 30
	var/pictures_left = -1 // -1 = pictures_max
	var/on = TRUE
	var/cooldown = 6 SECONDS
	var/blending = FALSE		//lets not take pictures while the previous is still processing!
	var/see_ghosts = CAMERA_NO_GHOSTS //for the spoop of it
	var/obj/item/disk/holodisk/disk
	var/sound/custom_sound
	var/silent = FALSE
	var/picture_size_x = 4
	var/picture_size_y = 4
	var/picture_size_x_min = 1
	var/picture_size_y_min = 1
	var/picture_size_x_max = 4
	var/picture_size_y_max = 4
	var/can_customise = TRUE
	var/default_picture_name
	var/editor_mode = CAMERA_EDITOR_ASK

/obj/item/camera/Initialize(mapload)
	. = ..()
	if(pictures_left < 0)
		pictures_left = pictures_max

/obj/item/camera/examine(mob/user)
	. = ..()
	if(initial(flash_enabled))
		. += span_notice("Вспышка [flash_enabled ? "включена" : "выключена"]. Alt+ЛКМ переключает вспышку. При выключенной вспышке на снимке сохраняется освещение сцены.")
	. += "Осталось кадров: [pictures_left]."

/obj/item/camera/AltClick(mob/user)
	. = ..()
	if(!initial(flash_enabled) || !user.canUseTopic(src, BE_CLOSE, check_resting = FALSE))
		return
	flash_enabled = !flash_enabled
	to_chat(user, span_notice("Вспышка [flash_enabled ? "включена" : "выключена"]."))
	SStgui.update_uis(src)
	return TRUE

/obj/item/camera/attack_self(mob/user)
	ui_interact(user)

/obj/item/camera/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/camera/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PhotoCamera", "Настройки камеры")
		ui.set_autoupdate(FALSE)
		if(!ui.open())
			qdel(ui)

/obj/item/camera/ui_static_data(mob/user)
	return list(
		"canFlash" = initial(flash_enabled),
		"minWidth" = picture_size_x_min * 2 - 1,
		"maxWidth" = min(picture_size_x_max, CAMERA_PICTURE_SIZE_HARD_LIMIT) * 2 - 1,
		"minHeight" = picture_size_y_min * 2 - 1,
		"maxHeight" = min(picture_size_y_max, CAMERA_PICTURE_SIZE_HARD_LIMIT) * 2 - 1,
	)

/obj/item/camera/ui_data(mob/user)
	return list(
		"width" = picture_size_x * 2 - 1,
		"height" = picture_size_y * 2 - 1,
		"flashEnabled" = flash_enabled,
		"editorMode" = can_customise ? editor_mode : null,
		"hasDisk" = !QDELETED(disk),
	)

/obj/item/camera/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return FALSE
	switch(action)
		if("set_width", "set_height")
			var/size = params["size"]
			if(!isnum(size))
				return FALSE
			// Кадр включает центральный тайл и одинаковый отступ с каждой стороны.
			var/setting = round(size / 2) + 1
			if(action == "set_width")
				picture_size_x = clamp(setting, picture_size_x_min, min(picture_size_x_max, CAMERA_PICTURE_SIZE_HARD_LIMIT))
			else
				picture_size_y = clamp(setting, picture_size_y_min, min(picture_size_y_max, CAMERA_PICTURE_SIZE_HARD_LIMIT))
			return TRUE
		if("toggle_flash")
			if(!initial(flash_enabled))
				return FALSE
			flash_enabled = !flash_enabled
			return TRUE
		if("set_editor_mode")
			var/mode = params["mode"]
			if(!can_customise || !(mode in list(CAMERA_EDITOR_ASK, CAMERA_EDITOR_OPEN, CAMERA_EDITOR_SKIP)))
				return FALSE
			editor_mode = mode
			return TRUE
		if("eject_disk")
			if(QDELETED(disk))
				return FALSE
			var/obj/item/disk/holodisk/ejected_disk = disk
			disk = null
			to_chat(ui.user, span_notice("Вы извлекаете [ejected_disk] из камеры."))
			ui.user.put_in_hands(ejected_disk)
			return TRUE
	return FALSE

/obj/item/camera/attack(mob/living/carbon/human/M, mob/user)
	return

/obj/item/camera/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/camera_film))
		if(pictures_left)
			to_chat(user, span_notice("В камере ещё осталась плёнка!"))
			return
		if(!user.temporarilyRemoveItemFromInventory(I))
			return
		to_chat(user, span_notice("Вы вставляете кассету с плёнкой в камеру."))
		qdel(I)
		pictures_left = pictures_max
		return
	if(istype(I, /obj/item/disk/holodisk))
		if (!disk)
			if(!user.transferItemToLoc(I, src))
				to_chat(user, span_warning("[I] прилип к вашей руке!"))
				return TRUE
			to_chat(user, span_notice("Вы вставляете голодиск в разъём на задней стороне камеры."))
			disk = I
			SStgui.update_uis(src)
		else
			to_chat(user, span_warning("В камере уже есть голодиск."))
		return TRUE //no afterattack
	..()

//user can be atom or mob
/obj/item/camera/proc/can_target(atom/target, mob/user, prox_flag)
	if(!on || blending || !pictures_left)
		return FALSE
	return camera_can_target(get_turf(target), user, flash_enabled)

/proc/camera_can_target(turf/T, mob/user, flash_enabled)
	if(!T || (isAI(user) && !GLOB.cameranet.checkTurfVis(T)))
		return FALSE
	if(flash_enabled)
		var/turf/view_center = get_turf(user)
		if(istype(user) && user.client && user.client.view != world.view && !(T in dview(user.client.view, view_center)))
			return FALSE
		return T in dview(world.view, view_center)
	if(istype(user))
		if(user.client && !(T in get_hear(user.client.view, user)))
			return FALSE
		else if(!(T in get_hear(world.view, user)))
			return FALSE
	else					//user is an atom
		if(!(T in view(world.view, user)))
			return FALSE
	return TRUE

/obj/item/camera/afterattack(atom/target, mob/user, flag)
	if (disk)
		if(ismob(target))
			if (disk.record)
				QDEL_NULL(disk.record)

			disk.record = new
			var/mob/M = target
			disk.record.caller_name = M.name
			disk.record.set_caller_image(M)
		else
			to_chat(user, span_warning("Голодиск не может записать эту цель."))
			return

	if(!can_target(target, user, flag))
		return

	on = FALSE

	var/realcooldown = cooldown
	var/mob/living/carbon/human/H = user
	if (HAS_TRAIT(H, TRAIT_PHOTOGRAPHER))
		realcooldown *= 0.5
	addtimer(CALLBACK(src, PROC_REF(cooldown)), realcooldown)

	icon_state = state_off

	INVOKE_ASYNC(src, PROC_REF(captureimage), target, user, flag, picture_size_x - 1, picture_size_y - 1)


/obj/item/camera/proc/cooldown()
	UNTIL(!blending)
	icon_state = state_on
	on = TRUE

/obj/item/camera/proc/show_picture(mob/user, datum/picture/selection)
	selection?.ui_interact(user)

/obj/item/camera/proc/captureimage(atom/target, mob/user, flag, size_x = 1, size_y = 1)
	var/use_flash = flash_enabled
	if(use_flash)
		flash_lighting_fx(8, light_power, light_color)
	blending = TRUE
	var/turf/target_turf = get_turf(target)
	var/datum/picture/picture
	if(target_turf)
		picture = capture_camera_picture(target_turf, user, size_x, size_y, use_flash, see_ghosts, target)
	if(picture)
		if(QDELETED(src))
			qdel(picture)
			return FALSE
		if(!silent)
			play_camera_shutter(loc, custom_sound)
		after_picture(user, picture, flag)
	blending = FALSE

/proc/capture_camera_picture(turf/target_turf, mob/user, size_x, size_y, flash_enabled, see_ghosts = FALSE, atom/target = target_turf)
	size_x = clamp(size_x, 0, CAMERA_PICTURE_SIZE_HARD_LIMIT)
	size_y = clamp(size_y, 0, CAMERA_PICTURE_SIZE_HARD_LIMIT)
	var/list/photo_description = list("На снимке участок размером [size_x * 2 + 1] × [size_y * 2 + 1] м.")
	var/ai_user = isAI(user)
	var/list/seen
	if(flash_enabled)
		// Вспышка освещает открытые участки кадра, даже если расчёт света ещё не обновился.
		var/turf/view_center = get_turf(user) || target_turf
		var/view_radius = max(abs(view_center.x - target_turf.x) + size_x, abs(view_center.y - target_turf.y) + size_y)
		seen = dview(view_radius, view_center)
	else
		var/list/viewlist = user?.client ? getviewsize(user.client.view) : getviewsize(world.view)
		var/view_radius = max(viewlist[1], viewlist[2]) + max(size_x, size_y)
		var/atom/view_center = istype(user) ? user : target
		seen = get_hear(view_radius, view_center)
	var/list/turfs = list()
	var/list/mobs = list()
	var/blueprints = FALSE
	var/turf/bottom_left = locate(max(1, target_turf.x - size_x), max(1, target_turf.y - size_y), target_turf.z)
	var/turf/top_right = locate(min(world.maxx, target_turf.x + size_x), min(world.maxy, target_turf.y + size_y), target_turf.z)
	for(var/turf/T in block(bottom_left, top_right))
		if((ai_user && GLOB.cameranet.checkTurfVis(T)) || (T in seen))
			turfs += T
			for(var/mob/M in T)
				mobs += M
			if(locate(/obj/item/areaeditor/blueprints) in T)
				blueprints = TRUE
	if(!length(turfs))
		turfs += target_turf
	for(var/i in mobs)
		var/mob/M = i
		photo_description += M.get_photo_description(see_ghosts)

	var/psize_x = (size_x * 2 + 1) * world.icon_size
	var/psize_y = (size_y * 2 + 1) * world.icon_size
	var/list/subjects = photo_subjects_seen(mobs)
	var/icon/captured = render_camera_frame(turfs, target_turf, psize_x, psize_y, !flash_enabled, see_ghosts)
	var/datum/picture/P = new("picture", photo_description.Join(" "), captured, null, psize_x, psize_y, blueprints)
	P.subjects_seen = subjects
	return P

/obj/item/camera/proc/after_picture(mob/user, datum/picture/picture, proximity_flag)
	printpicture(user, picture)

/obj/item/camera/proc/printpicture(mob/user, datum/picture/picture) //Normal camera proc for creating photos
	var/obj/item/photo/p = new(get_turf(src), picture)
	if(in_range(src, user)) //needed because of TK
		if(default_picture_name)
			picture.picture_name = default_picture_name
		p.set_picture(picture, TRUE, TRUE)
		user.put_in_hands(p)
		pictures_left--
		to_chat(user, span_notice("Осталось кадров: [pictures_left]."))
		if(can_customise && editor_mode != CAMERA_EDITOR_SKIP && !QDELETED(p) && user.client)
			p.offer_camera_editor(user, editor_mode == CAMERA_EDITOR_ASK)
			return
	if(CONFIG_GET(flag/picture_logging_camera))
		picture.log_to_file()

#undef CAMERA_EDITOR_ASK
#undef CAMERA_EDITOR_OPEN
#undef CAMERA_EDITOR_SKIP
