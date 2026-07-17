/**********************Mining Scanners**********************/
/obj/item/mining_scanner
	desc = "A scanner that checks surrounding rock for useful minerals; it can also be used to stop gibtonite detonations."
	name = "manual mining scanner"
	icon = 'icons/obj/device.dmi'
	icon_state = "miningmanual"
	item_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	var/cooldown = 35
	var/current_cooldown = 0
	var/range = 7

/obj/item/mining_scanner/attack_self(mob/user)
	if(!user.client)
		return
	if(current_cooldown <= world.time)
		current_cooldown = world.time + cooldown
		mineral_scan_pulse(get_turf(user), range, user)

//Debug item to identify all ore spread quickly
/obj/item/mining_scanner/admin

/obj/item/mining_scanner/admin/attack_self(mob/user)
	for(var/turf/closed/mineral/M in world)
		if(M.scan_state)
			M.icon_state = M.scan_state
	qdel(src)

/obj/item/t_scanner/adv_mining_scanner
	desc = "A scanner that automatically checks surrounding rock for useful minerals; it can also be used to stop gibtonite detonations. This one has an extended range."
	name = "advanced automatic mining scanner"
	icon_state = "adv_mining0"
	item_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	var/cooldown = 35
	var/current_cooldown = 0
	var/range = 7

/obj/item/t_scanner/adv_mining_scanner/lesser
	name = "automatic mining scanner"
	desc = "A scanner that automatically checks surrounding rock for useful minerals; it can also be used to stop gibtonite detonations."
	icon_state = "mining0"
	range = 4
	cooldown = 50

/obj/item/t_scanner/adv_mining_scanner/scan()
	if(current_cooldown <= world.time)
		current_cooldown = world.time + cooldown
		var/mob/holder = src
		while(holder && !ismob(holder))
			holder = holder.loc
		mineral_scan_pulse(get_turf(src), range, holder)

/proc/mineral_scan_pulse(turf/T, range = world.view, mob/scanner_user = null)
	var/list/minerals = list()
	for(var/turf/closed/mineral/M in range(range, T))
		if(M.scan_state)
			minerals += M
	if(LAZYLEN(minerals))
		for(var/turf/closed/mineral/M in minerals)
			var/obj/effect/temp_visual/mining_overlay/oldC = locate(/obj/effect/temp_visual/mining_overlay) in M
			if(oldC)
				qdel(oldC)
			var/obj/effect/temp_visual/mining_overlay/C = new /obj/effect/temp_visual/mining_overlay(M)
			C.icon_state = M.scan_state
			C.push_buried_ore_images(scanner_user, T, range)

/proc/can_see_buried_ore(mob/living/viewer)
	if(!viewer)
		return FALSE
	if(viewer.sight & SEE_TURFS)
		return TRUE
	if(HAS_TRAIT(viewer, TRAIT_MESON_VISION))
		return TRUE
	if(iscarbon(viewer))
		var/mob/living/carbon/C = viewer
		if(istype(C.glasses, /obj/item/clothing/glasses/material/mining))
			return TRUE
	return FALSE

/obj/effect/temp_visual/mining_overlay
	plane = HIGH_GAME_PLANE
	layer = FLASH_LAYER
	icon = 'icons/effects/ore_visuals.dmi'
	appearance_flags = 0 //to avoid having TILE_BOUND in the flags, so that the 480x480 icon states let you see it no matter where you are
	duration = 35
	pixel_x = -224
	pixel_y = -224
	var/list/client/buried_ore_images

/obj/effect/temp_visual/mining_overlay/Initialize(mapload)
	. = ..()
	animate(src, alpha = 0, time = duration, easing = EASE_IN)

/obj/effect/temp_visual/mining_overlay/Destroy()
	for(var/client/C in buried_ore_images)
		C.images -= buried_ore_images[C]
	buried_ore_images = null
	return ..()

/// World overlays cannot reach fully buried turfs; copy the icon onto meson-capable viewers.
/obj/effect/temp_visual/mining_overlay/proc/push_buried_ore_images(mob/scanner_user, turf/center, scan_range)
	var/turf/ore_turf = get_turf(src)
	if(!ore_turf)
		return

	var/list/mob/living/viewers = list()
	if(scanner_user?.client)
		viewers += scanner_user
	for(var/mob/living/L in range(scan_range, center))
		if(L.client)
			viewers |= L

	for(var/mob/living/L in viewers)
		if(!L.client || !can_see_buried_ore(L))
			continue
		var/image/I = image(icon, ore_turf, icon_state)
		I.pixel_x = -224
		I.pixel_y = -224
		I.appearance_flags = appearance_flags
		I.layer = layer
		I.plane = plane
		L.client.images += I
		LAZYSET(buried_ore_images, L.client, I)
		animate(I, alpha = 0, time = duration, easing = EASE_IN)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(remove_image_from_client), I, L.client), duration, TIMER_CLIENT_TIME)
