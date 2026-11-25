
#define CAMERA_PICTURE_SIZE_HARD_LIMIT 21

/obj/item/camera
	name = "camera"
	icon = 'icons/obj/items_and_weapons.dmi'
	desc = "A polaroid camera."
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

/obj/item/camera/Initialize(mapload)
	. = ..()
	if(pictures_left < 0)
		pictures_left = pictures_max

/obj/item/camera/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Alt-click to change its focusing, allowing you to set how big of an area it will capture.</span>"
	if(initial(flash_enabled))
		. += span_notice("Вспышка [flash_enabled ? "включена" : "выключена"]. Ctrl+Shift+ЛКМ переключает вспышку. При выключенной вспышке на снимке сохраняется освещение сцены.")
	. += "It has [pictures_left] photos left."

/obj/item/camera/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE, check_resting = FALSE))
		return
	var/desired_x = input(user, "How high do you want the camera to shoot, between [picture_size_x_min] and [picture_size_x_max]?", "Zoom", picture_size_x) as num
	var/desired_y = input(user, "How wide do you want the camera to shoot, between [picture_size_y_min] and [picture_size_y_max]?", "Zoom", picture_size_y) as num
	picture_size_x = min(clamp(desired_x, picture_size_x_min, picture_size_x_max), CAMERA_PICTURE_SIZE_HARD_LIMIT)
	picture_size_y = min(clamp(desired_y, picture_size_y_min, picture_size_y_max), CAMERA_PICTURE_SIZE_HARD_LIMIT)
	return TRUE

/obj/item/camera/CtrlShiftClick(mob/user)
	. = ..()
	if(!initial(flash_enabled) || !user.canUseTopic(src, BE_CLOSE, check_resting = FALSE))
		return
	flash_enabled = !flash_enabled
	to_chat(user, span_notice("Вспышка [flash_enabled ? "включена" : "выключена"]."))
	return TRUE

/obj/item/camera/attack_self(mob/user)
	if(!disk)
		return
	to_chat(user, "<span class='notice'>You eject [disk] out the back of [src].</span>")
	user.put_in_hands(disk)
	disk = null

/obj/item/camera/attack(mob/living/carbon/human/M, mob/user)
	return

/obj/item/camera/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/camera_film))
		if(pictures_left)
			to_chat(user, "<span class='notice'>[src] still has some film in it!</span>")
			return
		if(!user.temporarilyRemoveItemFromInventory(I))
			return
		to_chat(user, "<span class='notice'>You insert [I] into [src].</span>")
		qdel(I)
		pictures_left = pictures_max
		return
	if(istype(I, /obj/item/disk/holodisk))
		if (!disk)
			if(!user.transferItemToLoc(I, src))
				to_chat(user, "<span class='warning'>[I] is stuck to your hand!</span>")
				return TRUE
			to_chat(user, "<span class='notice'>You slide [I] into the back of [src].</span>")
			disk = I
		else
			to_chat(user, "<span class='warning'>There's already a disk inside [src].</span>")
		return TRUE //no afterattack
	..()

//user can be atom or mob
/obj/item/camera/proc/can_target(atom/target, mob/user, prox_flag)
	if(!on || blending || !pictures_left)
		return FALSE
	var/turf/T = get_turf(target)
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
		if(!(get_turf(target) in view(world.view, user)))
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
			to_chat(user, "<span class='warning'>Invalid holodisk target.</span>")
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
	if(flash_enabled)
		flash_lighting_fx(8, light_power, light_color)
	blending = TRUE
	var/turf/target_turf = get_turf(target)
	if(!isturf(target_turf))
		blending = FALSE
		return FALSE
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
		photo_description += M.get_photo_description(src)

	var/psize_x = (size_x * 2 + 1) * world.icon_size
	var/psize_y = (size_y * 2 + 1) * world.icon_size
	var/list/subjects = photo_subjects_seen(mobs)
	var/icon/captured = camera_get_icon(turfs, target_turf, psize_x, psize_y)
	if(QDELETED(src))
		return FALSE
	var/datum/picture/P = new("picture", photo_description.Join(" "), captured, null, psize_x, psize_y, blueprints)
	P.subjects_seen = subjects
	after_picture(user, P, flag)
	blending = FALSE

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
		if(can_customise && !QDELETED(p) && p.open_camera_editor(user))
			return
		if(CONFIG_GET(flag/picture_logging_camera))
			picture.log_to_file()
