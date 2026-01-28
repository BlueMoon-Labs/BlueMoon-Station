// Train appartment stuff
// Не код, а пиздец полнейший, перепишу как будет настроение, благо работает и не лагает
/obj/effect/projector
	name = "fake window projector"
	icon = 'icons/turf/decals.dmi'
	icon_state = "arrows_red"
	invisibility = 100					// показывваем только избранным
	flags_1 = NO_SCREENTIPS_1
	var/image/projection
	var/projection_state = "stand"		// если null (ну или FALSE), то принимается название для спрайта без приписки и лишних _
	var/list/viewers = list()			// зрители проекции
	var/projection_pixel_y_offset = 0	// офсетт от стандартных штук, надстройка just_in_case
	var/projection_pixel_x_offset = 0	// офсетт от стандартных штук, надстройка just_in_case
	var/list/valid_area = list(/area/hilbertshotelstorage)	// зона в которой мы не показываем проекцию и не удаляемся
	var/projection_icon = 'modular_bluemoon/icons/projection/grass.dmi'
	var/projection_icon_state = "grass"
	var/area/hilbertshotel/own_area
	color = "#524b7a"

/obj/effect/projector/head
	projection_icon = 'modular_bluemoon/icons/projection/rails.dmi'
	projection_icon_state = "rails"

/obj/effect/projector/Initialize(mapload)
	if(istype(get_area(src), /area/hilbertshotel))
		var/area/hilbertshotel/HILBERT = get_area(src)
		own_area = HILBERT
		HILBERT.projectors += src
	update_icon(UPDATE_OVERLAYS)
	return ..()

/obj/effect/projector/update_overlays()
	. = ..()
	projection = image(projection_icon, src, "[projection_icon_state][projection_state ? "_[projection_state]" : ""]", ABOVE_MOB_LAYER)
	projection.plane =	EMISSIVE_BLOCKER_PLANE
	projection.color = color
	projection.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	switch(dir)
		if(NORTH)
			projection.pixel_y = 64
			projection.pixel_x = -353
		if(SOUTH)
			projection.pixel_y = -224
			projection.pixel_x = -353
	projection.pixel_y += projection_pixel_y_offset
	projection.pixel_x += projection_pixel_x_offset
	. += projection

/area/hilbertshotel
	var/list/projectors = list()

/obj/effect/projector/proc/on_mob_login(mob/viewer)
	SIGNAL_HANDLER
	AddProjection(viewer, FALSE)

///Makes the mind able to see this effect
/obj/effect/projector/proc/AddProjection(mob/viewer, add_to_viewers)
	if(!projection)
		update_icon(UPDATE_OVERLAYS)
	if(add_to_viewers)
		viewers += viewer
	if(viewer.client)
		viewer.client.images += projection

///Makes the mind not able to see this effect
/obj/effect/projector/proc/RemoveProjection(mob/viewer)
	if(viewer in viewers)
		viewers -= viewer
		UnregisterSignal(viewer, COMSIG_MOB_CLIENT_LOGIN)
	if(viewer.client)
		viewer.client.images -= projection

/obj/effect/projector/proc/UpdateProjection()
	for(var/mob/viewer in viewers)
		viewer.client?.images -= projection
	update_icon(UPDATE_OVERLAYS)
	for(var/mob/viewer in viewers)
		viewer.client?.images += projection

/obj/effect/projector/Destroy()
	for(var/mob/M in viewers)
		RemoveProjection(M)

	viewers = null	// проверяем дважды, да
	projection = null
	if(own_area)
		own_area.projectors -= src
	. = ..()

/obj/effect/projector/forceMove(atom/destination)
	. = ..()
	var/area/hilbertshotel/current_area = get_area(src)
	if(current_area == own_area)
		return

	if(istype(current_area))
		own_area = current_area
		current_area.projectors += src
		return

	if(current_area.type in valid_area)
		for(var/mob/viewer in viewers)
			UnregisterSignal(viewer, COMSIG_MOB_CLIENT_LOGIN)
		return
	// Значит мы не в допустимой для проектора зоне, **ВЗРЫВ**
	qdel(src)

/area/hilbertshotel/Entered(mob/living/L, atom/OldLoc)
	. = ..()
	if(projectors && projectors.len && istype(L))
		if(!L.mind)
			return
		for(var/obj/effect/projector/P in projectors)
			P.RegisterSignal(L, COMSIG_MOB_CLIENT_LOGIN, TYPE_PROC_REF(/obj/effect/projector, on_mob_login))
			P.AddProjection(L, TRUE)

/area/hilbertshotel/Exited(mob/living/L)
	. = ..()
	if(istype(L))
		if(!L.mind)
			return
		if(projectors && projectors.len)
			for(var/obj/effect/projector/P in projectors)
				P.RemoveProjection(L)
		L.stop_sound_channel(CHANNEL_AMBIENCE)


// Indestructible away mission ladders which link based on a mapped ID and height value rather than X/Y/Z.
/obj/hotel_things/train/fake_door
	name = "door"
	desc = "An extremely sturdy metal ladder."
	icon = 'modular_bluemoon/smiley/aesthetics/airlock/icons/airlocks/hatch/centcom.dmi'
	icon_state = "fake_on"
	resistance_flags = INDESTRUCTIBLE
	anchored = TRUE
	var/teleport_x = 0
	var/teleport_y = 0

/obj/hotel_things/train/fake_door/proc/travel(mob/user, is_ghost)
	var/turf/T = locate(src.x + teleport_x, src.y + teleport_y, src.z)
	if(!istype(T))
		return
	if(!is_ghost)
		user.visible_message("[user] goes through the [src].","<span class='notice'>You coming through the [src].</span>")
	var/atom/movable/AM
	if(user.pulling)
		AM = user.pulling
		AM.forceMove(T)
	if(user.buckled && !user.buckled.anchored)
		var/atom/movable/seating = user.buckled
		seating.forceMove(T)
		user.forceMove(T)
		seating.buckle_mob(user, TRUE, TRUE)
	else
		user.forceMove(T)
	if(AM)
		user.start_pulling(AM)

/obj/hotel_things/train/fake_door/proc/use(mob/user, is_ghost=FALSE)
	if(!is_ghost && !in_range(src, user))
		return

	travel(user, is_ghost)

/obj/hotel_things/train/fake_door/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	use(user)

/obj/hotel_things/train/fake_door/attack_paw(mob/user)
	return use(user)

/obj/hotel_things/train/fake_door/attackby(obj/item/W, mob/user, params)
	return use(user)

/obj/hotel_things/train/fake_door/attack_robot(mob/living/silicon/robot/R)
	if(R.Adjacent(src))
		return use(R)

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/hotel_things/train/fake_door/attack_ghost(mob/dead/observer/user)
	use(user, TRUE)
	return ..()

/obj/structure/window/plastitanium/train_fake
	flags_1 = PREVENT_CLICK_UNDER_1 | NODECONSTRUCT_1
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	density = FALSE
	canSmoothWith = list(/obj/effect/glass_smooth, /obj/structure/window/plastitanium/train_fake)

/obj/structure/grille/indestructable/fake
	density = FALSE

/obj/structure/curtain/fake
	alpha = 128
	layer = 3.21

/obj/structure/curtain/fake/update_icon_state()
	switch(open)
		if(TRUE)
			icon_state = replacetext(initial(icon_state), "open", "closed")
		if(FALSE)
			icon_state = replacetext(initial(icon_state), "closed", "open")

/obj/effect/glass_smooth
	invisibility = 100
	icon = 'icons/turf/decals.dmi'
	icon_state = "arrows_red"

/obj/hotel_things/train/console
	name = "Train terminal"
	icon = 'goon/icons/obj/160x160.dmi'
	icon_state = "shuttlecock_syndie"
	layer = 5
	plane = 12
	color = "#777777"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	flags_1 = NODECONSTRUCT_1
	anchored = TRUE
	var/list/valid_area = list(/area/hilbertshotelstorage)	// зона в которой мы не работает, но и не удаляемся
	var/moving = FALSE
	var/cooldown = 5 MINUTES
	var/cooldown_timer
	var/next_sound

/obj/hotel_things/train/console/proc/use(mob/user)
	if(!in_range(src, user))
		return
	if(cooldown_timer && world.time < cooldown_timer + cooldown)
		to_chat(user, "<span class='notice'>[src] сейчас перезаряжается, ожидайте.</span>")
		return

	cooldown_timer = world.time
	change_moving(user)

/obj/hotel_things/train/console/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	use(user)

/obj/hotel_things/train/console/attack_paw(mob/user)
	return use(user)

/obj/hotel_things/train/console/attackby(obj/item/W, mob/user, params)
	return use(user)

/obj/hotel_things/train/console/attack_robot(mob/living/silicon/robot/R)
	if(R.Adjacent(src))
		return use(R)

/obj/hotel_things/train/console/proc/change_moving(mob/user)
	var/area/hilbertshotel/HILBERT = get_area(src)
	if(!istype(HILBERT))
		return
	moving = !moving
	for(var/obj/effect/projector/projector in HILBERT.projectors)
		projector.projection_state = moving ? "moving" : "stand"
		projector.UpdateProjection()
	if(moving)
		START_PROCESSING(SSobj, src)
	else
		STOP_PROCESSING(SSobj, src)
		var/area/hilbertshotel/current_area = get_area(src)
		if(!istype(current_area))
			return PROCESS_KILL
		for(var/mob/M in GLOB.player_list)
			if(!M.client)
				continue
			var/area/hilbertshotel/M_area = get_area(M)
			if(!istype(M_area))
				continue
			if(M_area.roomnumber != current_area.roomnumber)
				continue
			M.stop_sound_channel(CHANNEL_AMBIENCE)

/obj/hotel_things/train/console/forceMove(atom/destination)
	. = ..()
	var/area/hilbertshotel/current_area = get_area(src)
	if(istype(current_area))
		if(moving)
			START_PROCESSING(SSobj, src)
			return

	if(current_area.type in valid_area)
		if(moving)
			STOP_PROCESSING(SSobj, src)
			return

	// Значит мы не в допустимой зоне **ВЗРЫВ**
	qdel(src)

/obj/hotel_things/train/console/process(delta_time)
	if(next_sound > world.time)
		return
	next_sound = world.time + 1 MINUTES + 16 SECONDS
	var/area/hilbertshotel/current_area = get_area(src)
	if(!istype(current_area))
		return PROCESS_KILL
	for(var/mob/M in GLOB.player_list)
		if(!M.client)
			continue
		var/area/hilbertshotel/M_area = get_area(M)
		if(!istype(M_area))
			continue
		if(M_area.roomnumber != current_area.roomnumber)
			continue
		SEND_SOUND(M, sound('modular_bluemoon/sound/ambience/train.ogg', volume = 30, channel = CHANNEL_AMBIENCE))

/obj/effect/light_emitter/train
	set_luminosity = 2
	set_cap = 1
	light_color = COLOR_BLUE
