#define HK47_CRASH_SPARKS 4
#define HK47_CRASH_DEBRIS_CHANCE 50
#define HK47_CRASH_SHAKE_DURATION 2
#define HK47_CRASH_SHAKE_STRENGTH 1
#define HK47_CRASH_TRAIL_JITTER 4
#define HK47_CRASH_SHADOW_ALPHA 200

/datum/round_event/ghost_role/hk47
	/// Как прибыл последний HK-47: для сообщения админам и лога.
	var/arrival_text
	var/turf/arrival_turf

/datum/round_event/ghost_role/hk47/proc/roll_legend()
	return pickweight(HK47_LEGEND_WEIGHTS)

/datum/round_event/ghost_role/hk47/proc/roll_crash()
	return prob(HK47_CRASH_CHANCE)

/// Игрок получает HK-47 и роль ещё до посадки: легенда и первый контракт выбираются по живым целям станции.
/datum/round_event/ghost_role/hk47/proc/launch_hk47(player_key, turf/fallback_landing)
	var/mob/living/carbon/human/droid = create_hk47(null)
	enlist_hk47(droid, player_key)
	var/datum/component/hk47_voice_cues/cues = droid.GetComponent(/datum/component/hk47_voice_cues)
	cues?.await_arrival()
	var/datum/antagonist/hk47/antag = droid.mind.has_antag_datum(/datum/antagonist/hk47)
	var/legend = antag.assign_legend(roll_legend())
	if(legend != HK47_STATUS_COVERT)
		var/turf/parcel_landing = pick_parcel_turf(legend, antag)
		if(parcel_landing)
			arrive_parcel(droid, parcel_landing, legend)
			return droid
	if(roll_crash())
		arrive_crash(droid, fallback_landing)
	else
		arrive_capsule(droid, fallback_landing)
	return droid

/datum/round_event/ghost_role/hk47/proc/enlist_hk47(mob/living/carbon/human/droid, player_key)
	if(player_key)
		droid.key = player_key
	droid.mind_initialize()
	droid.mind.assigned_role = ROLE_HK47
	droid.mind.add_antag_datum(/datum/antagonist/hk47)

/datum/round_event/ghost_role/hk47/proc/pick_parcel_turf(legend, datum/antagonist/hk47/antag)
	var/list/area_types = HK47_CARGO_AREAS
	if(legend == HK47_STATUS_BODYGUARD)
		var/datum/mind/vip = antag.active_contract?.target_mind()
		area_types = hk47_department_areas(vip?.assigned_role) + area_types
	return hk47_floor_in_areas(area_types)

/datum/round_event/ghost_role/hk47/proc/arrive_capsule(mob/living/carbon/human/droid, turf/landing)
	var/obj/structure/closet/supplypod/hk47/covert/pod = new
	droid.forceMove(pod)
	var/obj/effect/pod_landingzone/zone = new(landing, pod)
	zone.set_light(0)
	arrival_text = "тихой капсулой"
	arrival_turf = landing
	return pod

/// Посылка: ящик с HK-47 в капсуле; дроид выходит, открыв ящик изнутри, или его вскрывает экипаж.
/datum/round_event/ghost_role/hk47/proc/arrive_parcel(mob/living/carbon/human/droid, turf/landing, legend)
	var/official = legend == HK47_STATUS_LICENSED
	var/pod_type = official ? /obj/structure/closet/supplypod/hk47/official : /obj/structure/closet/supplypod/hk47/anonymous
	var/obj/structure/closet/supplypod/pod = new pod_type
	var/parcel_type = official ? /obj/structure/closet/crate/hk47_parcel : /obj/structure/closet/crate/hk47_parcel/anonymous
	var/obj/structure/closet/crate/hk47_parcel/parcel = new parcel_type(pod)
	droid.forceMove(parcel)
	new /obj/effect/pod_landingzone(landing, pod)
	to_chat(droid, span_notice("Вы едете в ящике посылки. Когда капсула откроется, выберитесь движением или сопротивлением - или дождитесь, пока ящик вскроют."))
	arrival_text = official ? "посылкой ЦК" : "анонимной посылкой"
	arrival_turf = landing
	return parcel

/// Крушение: огненный болид падает на клетку, дроид приходит в себя среди обломков; ни взрыва, ни пробоины.
/datum/round_event/ghost_role/hk47/proc/arrive_crash(mob/living/carbon/human/droid, turf/landing)
	droid.reset_perspective(landing)
	arrival_text = "крушением"
	arrival_turf = landing
	return new /obj/effect/temp_visual/hk47_crash_fall(landing, droid)

/proc/hk47_crash_impact(mob/living/droid, turf/site)
	playsound(site, 'sound/effects/meteorimpact.ogg', 80, TRUE)
	do_sparks(HK47_CRASH_SPARKS, FALSE, site)
	new /obj/effect/temp_visual/fire(site)
	new /obj/effect/temp_visual/small_smoke(site)
	new /obj/effect/decal/cleanable/robot_debris(site)
	new /obj/effect/decal/cleanable/ash/large(site)
	for(var/turf/open/nearby in RANGE_TURFS(1, site))
		if(nearby == site || isspaceturf(nearby) || !prob(HK47_CRASH_DEBRIS_CHANCE))
			continue
		var/debris_type = pick(/obj/effect/decal/cleanable/robot_debris, /obj/effect/decal/cleanable/oil, /obj/effect/decal/cleanable/glass, /obj/effect/decal/cleanable/ash)
		new debris_type(nearby)
	for(var/mob/listener as anything in SSspatial_grid.orthogonal_range_search(site, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, HK47_CRASH_RUMBLE_RANGE))
		to_chat(listener, span_warning("Совсем рядом что-то с грохотом рушится на станцию: пол вздрагивает, слышен скрежет металла."))
		if(isliving(listener))
			shake_camera(listener, HK47_CRASH_SHAKE_DURATION, HK47_CRASH_SHAKE_STRENGTH)
	if(!droid)
		return
	droid.forceMove(site)
	droid.reset_perspective()
	droid.Paralyze(HK47_CRASH_PARALYZE)
	droid.visible_message(span_danger("[droid] падает сверху в снопе искр и обломков!"), span_userdanger("Удар о палубу. Системы перезапускаются..."))

/proc/hk47_floor_in_areas(list/area_types)
	for(var/area_type in area_types)
		for(var/area/location as anything in shuffle(get_areas(area_type)))
			var/list/floors = minor_crew_area_floors(location)
			if(length(floors))
				return pick(floors)
	return null

/// Отсек должности: куда доброжелатель шлёт посылку с телохранителем.
/proc/hk47_department_areas(role)
	if(role in GLOB.security_positions)
		return list(/area/security/office, /area/security/brig, /area/security)
	if(role in GLOB.engineering_positions)
		return list(/area/engineering/lobby, /area/engineering/main, /area/engineering)
	if(role in GLOB.medical_positions)
		return list(/area/medical/medbay/lobby, /area/medical/medbay/central, /area/medical)
	if(role in GLOB.science_positions)
		return list(/area/science/research/lobby, /area/science/research, /area/science)
	if(role in GLOB.supply_positions)
		return list(/area/cargo/office, /area/cargo/storage, /area/cargo)
	if(role in GLOB.civilian_positions)
		return list(/area/service/bar, /area/service/cafeteria, /area/hallway/secondary/service)
	if(role in GLOB.command_positions)
		return list(/area/command/bridge, /area/command)
	return list(/area/hallway/primary/central, /area/hallway)

/obj/structure/closet/supplypod/hk47/covert
	effectStealth = TRUE

/obj/structure/closet/supplypod/hk47/official
	style = STYLE_CENTCOM
	effectQuiet = FALSE

/obj/structure/closet/supplypod/hk47/anonymous
	style = STYLE_BOX
	effectQuiet = FALSE

/obj/structure/closet/crate/hk47_parcel
	name = "CentCom contractor parcel"
	desc = "Опечатанный ящик ЦК с отметкой «подрядчик, вскрыть получателю». Внутри что-то тяжёлое, металлическое и, кажется, гудит."
	icon_state = "weaponcrate"

/obj/structure/closet/crate/hk47_parcel/anonymous
	name = "anonymous parcel"
	desc = "Деревянный ящик без обратного адреса, на крышке надпись: «От анонимного доброжелателя». Внутри что-то тяжёлое, металлическое и, кажется, гудит."
	icon_state = "wooden"

/// Болид заходит наискось и сверху, светится на месте посадки и тянет за собой огненно-дымный след.
/obj/effect/temp_visual/hk47_crash_fall
	name = "falling wreck"
	icon = 'icons/obj/wizard.dmi'
	icon_state = "fireball"
	layer = FLY_LAYER
	randomdir = FALSE
	duration = HK47_CRASH_FALL_TIME
	pixel_z = HK47_CRASH_FALL_HEIGHT
	light_range = 2
	light_power = 0.8
	light_color = LIGHT_COLOR_FIRE
	var/datum/weakref/passenger_ref
	var/landed = FALSE
	var/start_x = 0
	var/fall_started = 0
	var/trail_timer
	var/obj/effect/temp_visual/hk47_crash_shadow/shadow

/obj/effect/temp_visual/hk47_crash_fall/Initialize(mapload, mob/living/passenger)
	. = ..()
	passenger_ref = WEAKREF(passenger)
	start_x = pick(-1, 1) * HK47_CRASH_FALL_DRIFT
	pixel_x = start_x
	transform = matrix() * 2
	fall_started = world.time
	animate(src, pixel_x = 0, pixel_z = 0, time = duration, easing = LINEAR_EASING)
	shadow = new(loc)
	playsound(src, 'sound/weapons/mortar_long_whistle.ogg', 70, FALSE)
	emit_trail()

/// Посадка и при истечении эффекта, и при его досрочном удалении: дроид не должен остаться в пустоте.
/obj/effect/temp_visual/hk47_crash_fall/Destroy()
	deltimer(trail_timer)
	trail_timer = null
	QDEL_NULL(shadow)
	land()
	return ..()

/obj/effect/temp_visual/hk47_crash_fall/proc/emit_trail()
	trail_timer = null
	if(landed || QDELETED(src))
		return
	var/remaining = 1 - clamp((world.time - fall_started) / duration, 0, 1)
	new /obj/effect/temp_visual/hk47_crash_trail(loc, round(start_x * remaining), round(HK47_CRASH_FALL_HEIGHT * remaining))
	trail_timer = addtimer(CALLBACK(src, PROC_REF(emit_trail)), HK47_CRASH_TRAIL_STEP, TIMER_STOPPABLE)

/obj/effect/temp_visual/hk47_crash_fall/proc/land()
	if(landed)
		return
	landed = TRUE
	var/turf/site = get_turf(src)
	if(site)
		hk47_crash_impact(passenger_ref?.resolve(), site)

/// Клуб огня, который остывает в дым и рассеивается на месте, где только что пролетел болид.
/obj/effect/temp_visual/hk47_crash_trail
	name = "smoke trail"
	icon = 'icons/effects/effects.dmi'
	icon_state = "smoke"
	layer = FLY_LAYER
	randomdir = FALSE
	duration = HK47_CRASH_TRAIL_FADE
	color = "#ffa040"

/obj/effect/temp_visual/hk47_crash_trail/Initialize(mapload, offset_x, offset_z)
	. = ..()
	pixel_x = offset_x + rand(-HK47_CRASH_TRAIL_JITTER, HK47_CRASH_TRAIL_JITTER)
	pixel_z = offset_z + rand(-HK47_CRASH_TRAIL_JITTER, HK47_CRASH_TRAIL_JITTER)
	transform = matrix() * 0.9
	animate(src, color = "#3c3c3c", alpha = 0, transform = matrix() * 2, time = duration)

/obj/effect/temp_visual/hk47_crash_shadow
	name = "crash shadow"
	icon = 'icons/effects/light_overlays/light_32.dmi'
	icon_state = "light"
	color = "#000000"
	alpha = 0
	layer = LOW_OBJ_LAYER
	randomdir = FALSE
	duration = HK47_CRASH_FALL_TIME

/obj/effect/temp_visual/hk47_crash_shadow/Initialize(mapload)
	. = ..()
	transform = matrix() * 0.3
	animate(src, alpha = HK47_CRASH_SHADOW_ALPHA, transform = matrix() * 1.5, time = duration)

/// Голос прибытия - в момент, когда HK впервые встаёт на палубу: из капсулы, ящика или обломков крушения.
/datum/component/hk47_voice_cues/proc/await_arrival()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_arrival_moved))

/datum/component/hk47_voice_cues/proc/on_arrival_moved(mob/living/source)
	SIGNAL_HANDLER
	if(!isturf(source.loc))
		return
	UnregisterSignal(source, COMSIG_MOVABLE_MOVED)
	hk47_upgrade_voice(source, "hk47_activate", forced = TRUE)

#undef HK47_CRASH_SPARKS
#undef HK47_CRASH_DEBRIS_CHANCE
#undef HK47_CRASH_SHAKE_DURATION
#undef HK47_CRASH_SHAKE_STRENGTH
#undef HK47_CRASH_TRAIL_JITTER
#undef HK47_CRASH_SHADOW_ALPHA
