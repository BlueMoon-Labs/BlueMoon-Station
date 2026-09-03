/// Portal-themed visuals and voice lines for station porta turrets.
/datum/component/aperture_turret_skin
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/last_raised
	var/last_fired = 0
	var/last_had_targets = FALSE
	var/shooting_until = 0
	var/next_search_vo = 0

/datum/component/aperture_turret_skin/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_ICON, PROC_REF(on_update_icon), override = TRUE)
	RegisterSignal(parent, COMSIG_OBJ_BREAK, PROC_REF(on_break))

/datum/component/aperture_turret_skin/Initialize()
	if(!istype(parent, /obj/machinery/porta_turret))
		return COMPONENT_INCOMPATIBLE
	var/obj/machinery/porta_turret/turret = parent
	setup_turret(turret)
	last_raised = turret.raised
	last_fired = turret.last_fired
	START_PROCESSING(SSobj, src)
	return ..()

/datum/component/aperture_turret_skin/Destroy(force)
	STOP_PROCESSING(SSobj, src)
	return ..()

/datum/component/aperture_turret_skin/proc/setup_turret(obj/machinery/porta_turret/turret)
	turret.name = "Sentry Turret"
	turret.desc = "An Aperture Science security turret. It watches you with suspicious enthusiasm."
	turret.icon = APERTURE_TURRET_ICON
	if(turret.cover)
		qdel(turret.cover)
		turret.cover = null
	turret.has_cover = FALSE
	turret.invisibility = 0
	turret.always_up = TRUE
	turret.underlays.Cut()
	turret.cut_overlay()
	if(turret.on && turret.anchored && !(turret.machine_stat & BROKEN))
		turret.popUp()
	else
		turret.raised = FALSE
		turret.layer = OBJ_LAYER
	var/fire_sound = pick(GLOB.aperture_turret_fire_sounds)
	turret.stun_projectile_sound = fire_sound
	turret.lethal_projectile_sound = fire_sound
	if(turret.nonlethal_projectile_sound)
		turret.nonlethal_projectile_sound = fire_sound
	turret.update_icon()

/datum/component/aperture_turret_skin/proc/get_icon_state(obj/machinery/porta_turret/turret)
	if(!turret.anchored)
		return "off"
	if(turret.machine_stat & BROKEN)
		return "died"
	if(!turret.powered() || !turret.on)
		return "off"
	if(world.time < shooting_until)
		return "shoots"
	if(turret.raised)
		return "shoots"
	return "on"

/datum/component/aperture_turret_skin/proc/on_update_icon(datum/source, updates)
	SIGNAL_HANDLER
	if(!(updates & UPDATE_ICON_STATE))
		return
	var/obj/machinery/porta_turret/turret = parent
	turret.icon = APERTURE_TURRET_ICON
	turret.icon_state = get_icon_state(turret)
	return COMSIG_ATOM_NO_UPDATE_ICON_STATE

/datum/component/aperture_turret_skin/proc/on_break(datum/source, damage_flag)
	SIGNAL_HANDLER
	var/obj/machinery/porta_turret/turret = parent
	playsound(turret, 'modular_bluemoon/portal/sound/Звуки турелей/Гибель.ogg', 90, TRUE)
	for(var/obj/machinery/porta_turret/nearby in view(7, turret))
		if(nearby == turret || !nearby.GetComponent(/datum/component/aperture_turret_skin))
			continue
		if(prob(35))
			playsound(nearby, pick(GLOB.aperture_turret_ally_death_vo), 80, TRUE)

/datum/component/aperture_turret_skin/process(delta_time)
	var/obj/machinery/porta_turret/turret = parent
	if(QDELETED(turret))
		return PROCESS_KILL

	if(turret.invisibility)
		turret.invisibility = 0

	if(turret.raised && !last_raised)
		playsound(turret, pick(GLOB.aperture_turret_deploy_sounds), 80, TRUE)
		if(prob(40))
			playsound(turret, pick(GLOB.aperture_turret_deploy_vo), 80, TRUE)

	if(!turret.raised && last_raised)
		playsound(turret, 'modular_bluemoon/portal/sound/Звуки турелей/Отключение.ogg', 70, TRUE)
		if(prob(50))
			playsound(turret, pick(GLOB.aperture_turret_disable_vo), 80, TRUE)

	if(turret.last_fired > last_fired)
		last_fired = turret.last_fired
		shooting_until = world.time + 0.4 SECONDS
		var/fire_sound = pick(GLOB.aperture_turret_fire_sounds)
		turret.stun_projectile_sound = fire_sound
		turret.lethal_projectile_sound = fire_sound
		if(turret.nonlethal_projectile_sound)
			turret.nonlethal_projectile_sound = fire_sound
		if(prob(60))
			playsound(turret, pick(GLOB.aperture_turret_active_vo), 85, TRUE)
		turret.update_icon()

	var/has_targets = LAZYLEN(turret.cached_targets) > 0
	if(last_had_targets && !has_targets && !turret.raised)
		playsound(turret, pick(GLOB.aperture_turret_lost_target_vo), 75, TRUE)

	if(turret.on && turret.anchored && !(turret.machine_stat & BROKEN) && turret.powered() && !turret.raised && world.time > next_search_vo)
		if(prob(8))
			playsound(turret, pick(GLOB.aperture_turret_search_vo), 70, TRUE)
			next_search_vo = world.time + rand(10 SECONDS, 25 SECONDS)

	if(shooting_until && world.time >= shooting_until)
		shooting_until = 0
		turret.update_icon()

	last_had_targets = has_targets
	last_raised = turret.raised

/obj/machinery/porta_turret/update_icon_state()
	var/datum/component/aperture_turret_skin/skin = GetComponent(/datum/component/aperture_turret_skin)
	if(skin)
		icon = APERTURE_TURRET_ICON
		icon_state = skin.get_icon_state(src)
		return
	return ..()

/proc/apply_glados_ai_core_skin(obj/structure/ai_core/core)
	if(!istype(core) || QDELETED(core))
		return
	if(core.state < GLASS_CORE)
		return
	core.icon = APERTURE_GLADOS_ICON
	core.icon_state = APERTURE_GLADOS_ICON_WIGGLE
	core.update_appearance()

/obj/structure/ai_core/update_icon_state()
	if(HAS_TRAIT(SSstation, STATION_TRAIT_APERTURE_SCIENCE) && state >= GLASS_CORE)
		icon = APERTURE_GLADOS_ICON
		icon_state = APERTURE_GLADOS_ICON_WIGGLE
		return
	return ..()
