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

/atom/movable/screen/swarmer/core_stats
	name = "Swarmer core status"
	icon = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	maptext_x = -112
	maptext_y = 34
	maptext_width = 144
	maptext_height = 56

/datum/hud/swarmer
	var/atom/movable/screen/swarmer/core_arrow/core_arrow
	var/core_angle
	var/atom/movable/screen/swarmer/core_stats/core_stats
	var/core_tracking = FALSE

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
	core_stats = new(null, src)
	infodisplay += core_stats

/datum/hud/swarmer/Destroy()
	detach_core_tracking()
	core_arrow = null
	core_stats = null
	return ..()

/// Вход и выход клиента уже слушает базовый HUD; своя подписка на те же сигналы затирала его обработчики.
/datum/hud/swarmer/proc/attach_core_tracking()
	core_tracking = TRUE
	if(mymob.client)
		start_core_tracking(mymob)

/datum/hud/swarmer/proc/detach_core_tracking()
	core_tracking = FALSE
	if(mymob)
		stop_core_tracking(mymob, mymob.client)

/datum/hud/swarmer/on_client_login(datum/source, client/new_client)
	. = ..()
	if(core_tracking)
		start_core_tracking(source)

/datum/hud/swarmer/on_client_logout(datum/source, client/old_client)
	. = ..()
	if(core_tracking)
		stop_core_tracking(source, old_client)

/datum/hud/swarmer/proc/start_core_tracking(mob/source)
	SIGNAL_HANDLER
	RegisterSignal(source, COMSIG_MOVABLE_MOVED, PROC_REF(update_core_arrow), override = TRUE)
	update_core_arrow()
	update_core_stats()

/datum/hud/swarmer/proc/stop_core_tracking(mob/source, client/leaving_client)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_MOVABLE_MOVED)
	if(core_arrow)
		leaving_client?.screen -= core_arrow
		core_arrow.screen_loc = null
	if(core_stats)
		leaving_client?.screen -= core_stats
		core_stats.screen_loc = null

/datum/hud/swarmer/proc/update_core_stats()
	var/mob/living/simple_animal/hostile/swarmer/swarmer = mymob
	if(!core_stats || !swarmer?.client)
		return
	if(!core_stats.screen_loc)
		core_stats.screen_loc = ui_swarmer_core
	var/datum/team/swarmer_team/team = swarmer.team
	var/obj/structure/swarmer/core/core = team?.swarmer_core
	var/metal = round(team?.metallic_resources || 0, 0.01)
	var/organic = round(team?.organic_resources || 0, 0.01)
	var/analyzers = team?.analyzer_status || "0/0"
	var/core_health = core ? "[core.obj_integrity]/[core.max_integrity]" : "нет"
	var/core_color = core && core.obj_integrity < core.max_integrity ? COLOR_RED : COLOR_WHITE
	var/label = MAPTEXT("<div align='right'>Металл: [metal]<br>Органика: [organic]<br>Анализаторы: [analyzers]<br><font color='[core_color]'>Ядро: [core_health]</font></div>")
	if(core_stats.maptext != label)
		core_stats.maptext = label

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

	var/angle = distance > 1 ? Get_Angle(body_turf, core_turf) : null
	if(angle != core_angle)
		core_angle = angle
		core_arrow.transform = isnull(angle) ? null : matrix(angle, MATRIX_ROTATE)

/atom/movable/screen/act_intent/swarmer
	icon = 'icons/mob/screen_swarmer.dmi'
	screen_loc = ui_borg_intents
