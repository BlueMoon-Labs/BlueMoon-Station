/atom/movable/screen/swarmer
	icon = 'icons/mob/screen_swarmer.dmi'

/atom/movable/screen/swarmer/Click()
	if(!isswarmer(usr))
		return FALSE
	return TRUE

/atom/movable/screen/swarmer/toggle_light
	name = "Переключить свет"
	desc = "Включает или выключает встроенную подсветку."
	icon_state = "ui_light"

/atom/movable/screen/swarmer/toggle_light/Click()
	if(!..())
		return
	var/mob/living/simple_animal/hostile/swarmer/swarmer = usr
	swarmer.toggle_light()

/atom/movable/screen/swarmer/contact_swarmers
	name = "Связь роя"
	desc = "Отправить сообщение всем свармерам, если они, конечно, есть."
	icon_state = "ui_contact_swarmers"

/atom/movable/screen/swarmer/contact_swarmers/Click()
	if(!..())
		return
	var/mob/living/simple_animal/hostile/swarmer/swarmer = usr
	swarmer.contact_swarmers()

/atom/movable/screen/swarmer/core_arrow
	name = "Swarmer core direction"
	icon = 'icons/mob/swarmer_core_arrow.dmi'
	icon_state = "arrow"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/swarmer/core_metal
	name = "Swarmer core metal"
	icon = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	maptext_x = -100
	maptext_y = 8
	maptext_width = 96
	maptext_height = 16

/datum/hud/swarmer
	var/atom/movable/screen/swarmer/core_arrow/core_arrow
	var/core_angle
	var/atom/movable/screen/swarmer/core_metal/core_metal
	var/displayed_metal

/datum/hud/swarmer/New(mob/owner)
	..()
	var/atom/movable/screen/using

	healthdoll = new /atom/movable/screen/healthdoll/living(null, src)
	infodisplay += healthdoll

	using = new /atom/movable/screen/act_intent/swarmer(null, src)
	using.icon_state = mymob.a_intent
	static_inventory += using
	action_intent = using

	using = new /atom/movable/screen/swarmer/toggle_light(null, src)
	using.screen_loc = ui_drop_throw
	static_inventory += using

	using = new /atom/movable/screen/swarmer/contact_swarmers(null, src)
	using.screen_loc = ui_inventory
	static_inventory += using

	core_arrow = new(null, src)
	infodisplay += core_arrow
	core_metal = new(null, src)
	infodisplay += core_metal

/datum/hud/swarmer/Destroy()
	detach_core_tracking()
	core_arrow = null
	core_metal = null
	return ..()

/datum/hud/swarmer/proc/attach_core_tracking()
	RegisterSignal(mymob, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(start_core_tracking))
	RegisterSignal(mymob, COMSIG_MOB_CLIENT_LOGOUT, PROC_REF(stop_core_tracking))
	if(mymob.client)
		start_core_tracking(mymob)

/datum/hud/swarmer/proc/detach_core_tracking()
	if(mymob)
		stop_core_tracking(mymob, mymob.client)
		UnregisterSignal(mymob, list(COMSIG_MOB_CLIENT_LOGIN, COMSIG_MOB_CLIENT_LOGOUT))

/datum/hud/swarmer/proc/start_core_tracking(mob/source)
	SIGNAL_HANDLER
	RegisterSignal(source, COMSIG_MOVABLE_MOVED, PROC_REF(update_core_arrow), override = TRUE)
	update_core_arrow()
	update_core_metal()

/datum/hud/swarmer/proc/stop_core_tracking(mob/source, client/leaving_client)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_MOVABLE_MOVED)
	if(core_arrow)
		leaving_client?.screen -= core_arrow
		core_arrow.screen_loc = null
	if(core_metal)
		leaving_client?.screen -= core_metal
		core_metal.screen_loc = null

/datum/hud/swarmer/proc/update_core_metal()
	var/mob/living/simple_animal/hostile/swarmer/swarmer = mymob
	if(!core_metal || !swarmer?.client)
		return
	if(!core_metal.screen_loc)
		core_metal.screen_loc = ui_swarmer_core
	var/metal = round(swarmer.team?.metallic_resources || 0, 0.01)
	if(isnull(displayed_metal) || displayed_metal != metal)
		displayed_metal = metal
		core_metal.maptext = MAPTEXT("<div align='right'>Металл: [metal]</div>")

/datum/hud/swarmer/proc/update_core_arrow()
	SIGNAL_HANDLER
	var/mob/living/simple_animal/hostile/swarmer/swarmer = mymob
	if(!core_arrow || !swarmer?.client)
		return
	var/turf/core_turf = get_turf(swarmer.team?.swarmer_core)
	var/turf/body_turf = get_turf(swarmer)
	if(!core_turf || !body_turf || core_turf.z != body_turf.z)
		if(core_arrow.screen_loc)
			core_arrow.screen_loc = null
		return

	var/distance = get_dist(body_turf, core_turf)
	var/state = "arrow"
	switch(distance)
		if(0 to 1)
			state = "core"
		if(2 to 8)
			state = "arrow8"
		if(9 to 15)
			state = "arrow7"
		if(16 to 22)
			state = "arrow6"
		if(23 to 29)
			state = "arrow5"
		if(30 to 36)
			state = "arrow4"
		if(37 to 43)
			state = "arrow3"
		if(44 to 50)
			state = "arrow2"
		if(51 to 57)
			state = "arrow1"
		if(58 to 64)
			state = "arrow0"
	if(core_arrow.icon_state != state)
		core_arrow.icon_state = state
	if(!core_arrow.screen_loc)
		core_arrow.screen_loc = ui_swarmer_core

	var/angle = distance ? Get_Angle(body_turf, core_turf) : null
	if(angle != core_angle)
		core_angle = angle
		core_arrow.transform = isnull(angle) ? null : matrix(angle, MATRIX_ROTATE)

/atom/movable/screen/act_intent/swarmer
	icon = 'icons/mob/screen_swarmer.dmi'
	screen_loc = ui_borg_intents
