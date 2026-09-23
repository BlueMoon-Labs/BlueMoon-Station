#define HERETIC_TIDE_RANGE 5
#define HERETIC_TIDE_CHANNEL_MOVEMENT 2
#define HERETIC_TIDE_WAVE_RADIUS 2
#define HERETIC_TIDE_RELEASE_COST 2
#define HERETIC_TIDE_HARVEST_TIME (6 SECONDS)
#define HERETIC_TIDE_WELL_LIFETIME (12 SECONDS)
#define HERETIC_TIDE_WELL_INTERVAL (2 SECONDS)
#define HERETIC_TIDE_ASCENDED_CAPACITY 8
#define HERETIC_TIDE_PUDDLE_TIME (15 SECONDS)
#define HERETIC_TIDE_PRESSURE_INTERVAL (12 SECONDS)
#define HERETIC_TIDE_COLLISION_DAMAGE 8
#define HERETIC_TIDE_HARPOON_STAMINA 10
#define HERETIC_TIDE_HARPOON_DAMAGE 5
#define HERETIC_TIDE_PUDDLE_RISE (0.3 SECONDS)
#define HERETIC_TIDE_PUDDLE_DRAIN (0.6 SECONDS)
#define HERETIC_TIDE_PUDDLE_DRAIN_SCALE 0.85
#define HERETIC_TIDE_STEP_SPLASH_COOLDOWN (0.3 SECONDS)
#define HERETIC_TIDE_SWELL_TIME (0.6 SECONDS)
#define HERETIC_TIDE_VOICE_WAVE_TIME (0.9 SECONDS)
#define HERETIC_TIDE_VOICE_FLASH_RANGE 5
#define HERETIC_TIDE_VOICE_FLASH_POWER 1.5
#define HERETIC_TIDE_VOICE_FLASH_TIME (0.5 SECONDS)
#define HERETIC_TIDE_VOICE_QUAKE 0.15
#define HERETIC_TIDE_VOICE_QUAKE_RADIUS 7
#define HERETIC_TIDE_VOICE_QUAKE_TIME (0.4 SECONDS)

/datum/heretic_path/tide
	id = PATH_TIDE
	deed_type = /datum/heretic_deed/tide
	name = "Пучина"
	desc = "Сбивайте врагов приливом, смывайте их к стенам и затягивайте в чёрный водоворот."
	strengths = "Сильное перемещение и падения, опасная воронка, устойчивость на мокром полу. Вознёсшийся каждые 2 секунды заливает пол в двух клетках вокруг себя и оставляет мокрый след: враги в этой воде мокнут и замедляются, а сам он по ней ходит быстрее."
	weaknesses = "Сильные волны расходуют запас; преграды останавливают течение, а обрушение выдаёт себя заранее. Вознёсшегося держите дальше двух клеток, не идите по его мокрому следу и стреляйте издалека: вода не проходит сквозь стены, окна, закрытые двери и машины, а пристёгнутых и закреплённых его волна не сносит."
	knowledge = list(
		/datum/eldritch_knowledge/base_tide,
		/datum/eldritch_knowledge/tide_grasp,
		/datum/eldritch_knowledge/spell/tide_undertow,
		/datum/eldritch_knowledge/tide_mark,
		/datum/eldritch_knowledge/tide_bell,
		/datum/eldritch_knowledge/tide_upgrade,
		/datum/eldritch_knowledge/spell/tide_well,
		/datum/eldritch_knowledge/tide_depth,
		/datum/eldritch_knowledge/spell/tide_deluge,
		/datum/eldritch_knowledge/final_eldritch/tide_final,
	)

/datum/eldritch_knowledge/base_tide
	name = "Берег без солнца"
	desc = "Сбивайте врагов волной и смывайте их к стенам. Сброс давления доступен сразу; давление восстанавливается само и накапливается от ударов гарпунным клинком. Волны оставляют скользкий пол и замедляют намокших врагов на 8 секунд, даже в нескользящей обуви. Вы не скользите на воде. Нож и лист металла создают гарпунный клинок."
	gain_text = "Море ушло, но я всё ещё слышал, как оно дышит под моими ногами."
	route = PATH_TIDE
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/metal)
	result_atoms = list(/obj/item/melee/sickly_blade/tide)
	combat_resource = 2
	combat_resource_name = "Давление"
	combat_resource_desc = "Начальный запас 2 из 4. Восстановление: 1 за 12 секунд, с «Тысячей саженей» быстрее. Клинок даёт ещё 1 раз в 6 секунд, Хватка глубины — 2, метка — 1. Сброс и водоворот стоят 2, Обрушение расходует всё. Колокол меняет направление Сброса. Смерть сбрасывает запас."
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_tide/release
	grasp_visual = /obj/effect/temp_visual/heretic_tide/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/tide_grasp.ogg'
	grasp_catchphrase = "GE'LME SA'UKIA"
	var/mob/living/tide_body
	var/obj/structure/heretic_tide_well/active_well
	var/list/datum/status_effect/heretic_drenched/drenched = list()
	var/list/datum/status_effect/eldritch/tide/marks = list()
	var/inward_tide = FALSE
	var/tide_generation = 0
	var/ascension_active = FALSE
	var/static/list/water_sources = typecacheof(list(/obj/structure/sink, /obj/machinery/shower, /obj/structure/reagent_dispensers/watertank))
	COOLDOWN_DECLARE(ascended_pressure)
	COOLDOWN_DECLARE(harpoon_recovery)

/datum/eldritch_knowledge/base_tide/on_body_gain(mob/living/user)
	if(!user?.mind || tide_body == user)
		return
	if(tide_body)
		on_body_lose(tide_body)
	tide_body = user
	ADD_TRAIT(user, TRAIT_NOSLIPWATER, REF(src))
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	grant_combat_power(user)
	update_capacity()
	COOLDOWN_START(src, ascended_pressure, HERETIC_TIDE_PRESSURE_INTERVAL)

/datum/eldritch_knowledge/base_tide/on_body_lose(mob/living/user)
	if(tide_body)
		UnregisterSignal(tide_body, COMSIG_PARENT_QDELETING)
		REMOVE_TRAIT(tide_body, TRAIT_NOSLIPWATER, REF(src))
	tide_body = null
	remove_combat_power()
	clear_tide()

/datum/eldritch_knowledge/base_tide/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(tide_body)

/datum/eldritch_knowledge/base_tide/on_death(mob/user)
	clear_tide()
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_tide/Destroy()
	on_body_lose(tide_body)
	return ..()

/datum/eldritch_knowledge/base_tide/proc/clear_tide()
	tide_generation++
	QDEL_NULL(active_well)
	for(var/datum/status_effect/heretic_drenched/effect as anything in drenched.Copy())
		qdel(effect)
	drenched.Cut()
	for(var/datum/status_effect/eldritch/tide/mark as anything in marks.Copy())
		qdel(mark)
	marks.Cut()

/datum/eldritch_knowledge/base_tide/proc/can_use(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && isliving(user) && user == tide_body && !user.incapacitated() && isturf(user.loc) && heretic?.selected_path == PATH_TIDE && heretic.get_knowledge(type) == src

/datum/eldritch_knowledge/base_tide/proc/update_capacity()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(tide_body)
	var/datum/eldritch_knowledge/tide_depth/depth = heretic?.get_knowledge(/datum/eldritch_knowledge/tide_depth)
	combat_resource_max = ascension_active ? HERETIC_TIDE_ASCENDED_CAPACITY : depth ? depth.passive_values[depth.passive_level] : initial(combat_resource_max)
	combat_resource = min(combat_resource, combat_resource_max)
	notify_resource_changed()

/datum/eldritch_knowledge/base_tide/get_combat_resource_data()
	var/list/data = ..()
	data["description"] = "[combat_resource_desc] Сброс сейчас [inward_tide ? "притягивает" : "отталкивает"]."
	return data

/datum/eldritch_knowledge/base_tide/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(!can_use(user) || !proximity_flag || !COOLDOWN_FINISHED(src, resource_harvest) || !heretic_can_affect(user, target, chargecost = 0))
		return
	gain_combat_resource()
	COOLDOWN_START(src, resource_harvest, HERETIC_TIDE_HARVEST_TIME)

/datum/eldritch_knowledge/base_tide/on_life(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user) || !COOLDOWN_FINISHED(src, ascended_pressure))
		return
	gain_combat_resource()
	var/datum/eldritch_knowledge/tide_depth/depth = heretic?.get_knowledge(/datum/eldritch_knowledge/tide_depth)
	var/interval = HERETIC_TIDE_PRESSURE_INTERVAL - (depth ? 2 SECONDS * depth.passive_level : 0)
	COOLDOWN_START(src, ascended_pressure, ascension_active ? 4 SECONDS : interval)

/datum/eldritch_knowledge/base_tide/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag || !can_use(user) || !is_type_in_typecache(target, water_sources))
		return FALSE
	var/turf/open/place = get_turf(user)
	if(!istype(place))
		return FALSE
	place.MakeSlippery(TURF_WET_WATER, min_wet_time = HERETIC_TIDE_PUDDLE_TIME, wet_time_to_add = HERETIC_TIDE_PUDDLE_TIME)
	playsound(place, 'sound/effects/slosh.ogg', 50, TRUE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	heretic.advance_deed(heretic.deed_key_for(target), place)
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/line_clear(atom/start, atom/end, max_distance = HERETIC_TIDE_RANGE)
	return !line_failure(start, end, max_distance)

/datum/eldritch_knowledge/base_tide/proc/line_failure(atom/start, atom/end, max_distance = HERETIC_TIDE_RANGE)
	var/turf/origin = get_turf(start)
	var/turf/destination = get_turf(end)
	if(!origin || !destination || origin.z != destination.z || get_dist(origin, destination) > max_distance)
		return "Цель вне досягаемости: выберите её не дальше [max_distance] клеток на этом же уровне."
	if(!heretic_edge_line_clear(origin, destination))
		return "Линию перекрывает преграда: стена, закрытая дверь, окно или машина. Столы и перила течению не мешают, направленное окно держит воду только со своей стороны."
	return null

/datum/eldritch_knowledge/base_tide/proc/soak(mob/living/victim)
	return victim.apply_status_effect(/datum/status_effect/heretic_drenched, src)

/datum/eldritch_knowledge/base_tide/proc/wet_floor(turf/open/place)
	if(!istype(place) || isspaceturf(place) || istype(place, /turf/open/lava))
		return
	place.MakeSlippery(TURF_WET_WATER, min_wet_time = HERETIC_TIDE_PUDDLE_TIME, wet_time_to_add = 0)

/datum/eldritch_knowledge/base_tide/proc/move_with_tide(mob/living/victim, atom/center, inward, steps = 1, reach_center = FALSE, collide = TRUE)
	if(victim.anchored || victim.buckled || !isturf(victim.loc))
		return
	for(var/step_index in 1 to steps)
		if(inward && get_dist(victim, center) <= (reach_center ? 0 : 1))
			break
		var/direction = inward ? get_dir(victim, center) : get_dir(center, victim)
		if(!direction)
			break
		var/turf/destination = get_step(victim, direction)
		if(!destination || !isopenturf(destination) || destination.is_blocked_turf(exclude_mobs = TRUE))
			if(!collide)
				break
			victim.adjustBruteLoss(HERETIC_TIDE_COLLISION_DAMAGE)
			victim.Knockdown(1.5 SECONDS)
			new /obj/effect/temp_visual/heretic_tide/burst(get_turf(victim))
			break
		if(!step(victim, direction))
			break

/datum/eldritch_knowledge/base_tide/proc/release(mob/living/user, ascended_wave = FALSE)
	if(!can_use(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(ascended_wave)
		if(!ascension_active)
			return FALSE
	else if(!spend_combat_resource(HERETIC_TIDE_RELEASE_COST))
		return FALSE
	var/wave_radius = ascended_wave ? 3 : HERETIC_TIDE_WAVE_RADIUS
	var/turf/center = get_turf(user)
	if(ascended_wave)
		voice_fx(center, wave_radius)
	for(var/mob/living/victim in range(wave_radius, center))
		if(!isturf(victim.loc) || !line_clear(center, victim, wave_radius) || !heretic_can_affect(user, victim))
			continue
		var/damage_before = victim.getBruteLoss()
		victim.adjustBruteLoss(ascended_wave ? 30 : 18)
		if(victim.getBruteLoss() > damage_before)
			heretic.advance_combat_deed(victim, PATH_TIDE)
		victim.adjustStaminaLoss(ascended_wave ? 40 : 24)
		soak(victim)
		move_with_tide(victim, center, inward_tide, ascended_wave ? 3 : 2)
		victim.Knockdown(ascended_wave ? 3 SECONDS : 2.5 SECONDS)
		log_combat(user, victim, "поражает приливной волной")
	for(var/turf/tile in range(wave_radius, center))
		if(line_clear(center, tile, wave_radius))
			wet_floor(tile)
			new /obj/effect/temp_visual/heretic_tide/wave(tile)
	new /obj/effect/temp_visual/heretic_tide/wave(center)
	playsound(center, 'sound/effects/watersplash.ogg', 65, TRUE)
	return TRUE

/// Голос Пучины: вода встаёт короной вокруг героя, от него расходятся волна и пена, пол дрожит.
/datum/eldritch_knowledge/base_tide/proc/voice_fx(turf/center, radius)
	var/ink = heretic_path_ink(PATH_TIDE)
	new /obj/effect/temp_visual/heretic_tide_swell(center)
	new /obj/effect/temp_visual/heretic_tide_swell/front(center)
	heretic_vfx_shockwave(center, ink, radius, HERETIC_TIDE_VOICE_WAVE_TIME)
	heretic_vfx_burst(center, /particles/heretic_ascension/tide/foam)
	heretic_vfx_flash(center, ink, HERETIC_TIDE_VOICE_FLASH_RANGE, HERETIC_TIDE_VOICE_FLASH_POWER, HERETIC_TIDE_VOICE_FLASH_TIME)
	heretic_vfx_quake(center, HERETIC_TIDE_VOICE_QUAKE_RADIUS, HERETIC_TIDE_VOICE_QUAKE, HERETIC_TIDE_VOICE_QUAKE_TIME)

/datum/eldritch_knowledge/base_tide/proc/undertow(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user) || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/tide_undertow) || !isliving(victim) || victim.stat == DEAD || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || !isturf(victim.loc) || !line_clear(user, victim))
		return FALSE
	if(!heretic_can_affect(user, victim))
		return TRUE
	var/turf/origin = get_turf(victim)
	victim.adjustBruteLoss(15)
	victim.adjustStaminaLoss(20)
	soak(victim)
	move_with_tide(victim, user, TRUE, 3)
	victim.Knockdown(2 SECONDS)
	for(var/turf/tile as anything in get_line(get_turf(user), origin))
		wet_floor(tile)
		new /obj/effect/temp_visual/heretic_tide/wave(tile)
	playsound(victim, 'modular_bluemoon/sound/heretic/tide_grasp.ogg', 45, TRUE)
	log_combat(user, victim, "подтягивает отливом")
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/create_well(mob/living/user, turf/place)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user) || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/tide_well) || !isopenturf(place) || isspaceturf(place) || istype(place, /turf/open/lava) || !line_clear(user, place) || !spend_combat_resource(HERETIC_TIDE_RELEASE_COST))
		return FALSE
	QDEL_NULL(active_well)
	active_well = new(place, src)
	active_well.pulse(erupting = TRUE)
	playsound(place, 'sound/effects/watersplash.ogg', 45, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/can_prepare_deluge(mob/living/user, turf/origin, turf/center, expected_generation)
	return can_use(user) && tide_generation == expected_generation && origin && user.z == origin.z && get_dist(user, origin) <= HERETIC_TIDE_CHANNEL_MOVEMENT && combat_resource >= HERETIC_TIDE_RELEASE_COST && line_clear(user, center)

/datum/eldritch_knowledge/base_tide/proc/deluge_turfs(mob/living/user, turf/center)
	var/list/affected = list()
	if(!can_use(user) || !line_clear(user, center))
		return affected
	for(var/turf/tile in range(HERETIC_TIDE_WAVE_RADIUS, center))
		if(line_clear(center, tile, HERETIC_TIDE_WAVE_RADIUS))
			affected += tile
	return affected

/// Обрушение поражает только предупреждённые клетки, оставшиеся доступными после подготовки.
/datum/eldritch_knowledge/base_tide/proc/deluge(mob/living/user, turf/center, list/telegraphed_turfs, expected_generation)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user) || tide_generation != expected_generation || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/tide_deluge) || !length(telegraphed_turfs) || !line_clear(user, center) || combat_resource < HERETIC_TIDE_RELEASE_COST)
		return FALSE
	var/pressure = combat_resource
	spend_combat_resource(pressure)
	for(var/mob/living/victim in range(HERETIC_TIDE_WAVE_RADIUS, center))
		if(!isturf(victim.loc) || !(get_turf(victim) in telegraphed_turfs) || !line_clear(center, victim, HERETIC_TIDE_WAVE_RADIUS) || !heretic_can_affect(user, victim))
			continue
		victim.adjustBruteLoss(20 + pressure * 6)
		victim.adjustStaminaLoss(20 + pressure * 3)
		victim.Knockdown(2 SECONDS)
		soak(victim)
		new /obj/effect/temp_visual/heretic_tide/burst(get_turf(victim))
		log_combat(user, victim, "обрушивает толщу Пучины на")
	for(var/turf/tile as anything in telegraphed_turfs)
		if(line_clear(center, tile, HERETIC_TIDE_WAVE_RADIUS))
			wet_floor(tile)
	new /obj/effect/temp_visual/heretic_tide/burst(center)
	playsound(center, 'modular_bluemoon/sound/heretic/tide_deluge.ogg', 80, TRUE)
	return TRUE

/datum/status_effect/heretic_drenched
	id = "heretic_drenched"
	duration = 8 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_drenched
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/tide_ref
	/// Капли с намокшего; снятие воды отпускает их догореть на полу.
	var/obj/effect/abstract/heretic_particle_holder/drips

/datum/status_effect/heretic_drenched/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_tide/tide)
	if(QDELETED(tide))
		qdel(src)
		return
	tide_ref = WEAKREF(tide)
	return ..()

/datum/status_effect/heretic_drenched/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide || owner.stat == DEAD || IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner))
		return FALSE
	tide.drenched += src
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_drenched)
	drips = heretic_vfx_attach_particles(owner, /particles/heretic_ascension/tide/drip, FALSE)
	return TRUE

/datum/status_effect/heretic_drenched/on_remove()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	tide?.drenched.Remove(src)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_drenched)
	heretic_vfx_release_particles(owner, drips)
	drips = null
	return ..()

/datum/status_effect/heretic_drenched/be_replaced()
	on_remove()
	return ..()

/datum/status_effect/heretic_drenched/Destroy()
	. = ..()
	tide_ref = null
	return .

/datum/movespeed_modifier/heretic_drenched
	multiplicative_slowdown = 0.7
	blacklisted_movetypes = FLYING | FLOATING

/atom/movable/screen/alert/status_effect/heretic_drenched
	name = "Вода Пучины"
	desc = "Вода Пучины замедляет ваши шаги даже в нескользящей обуви. Полёт позволяет двигаться без этого замедления. Усиленный гарпун наносит вам ещё 5 ушибов, а хозяин воды может вернуть себе давление и немного выносливости. Вода исчезнет через 8 секунд после последнего попадания магии или шага по чёрной воде вознёсшегося."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_tide"

/datum/status_effect/eldritch/tide
	id = "tide_mark"
	mark_name = "Метка Пучины"
	mark_alert_state = "sigil_tide"
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_tide_effects.dmi'
	effect_sprite = "tide_mark"
	detonation_sound = 'sound/effects/watersplash.ogg'
	detonation_visual = /obj/effect/temp_visual/heretic_tide/burst
	var/datum/weakref/tide_ref

/datum/status_effect/eldritch/tide/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_tide/tide)
	if(tide)
		tide_ref = WEAKREF(tide)
	return ..()

/datum/status_effect/eldritch/tide/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide)
		return FALSE
	tide.marks += src
	return TRUE

/datum/status_effect/eldritch/tide/on_remove()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	tide?.marks.Remove(src)
	return ..()

/datum/status_effect/eldritch/tide/on_effect()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide?.can_use(tide.tide_body) && heretic_can_affect(tide.tide_body, owner, chargecost = 0))
		owner.adjustBruteLoss(8)
		owner.adjustStaminaLoss(12)
	return ..()

/obj/structure/heretic_tide_well
	name = "abyssal whirlpool"
	desc = "Вода вращается над сухим полом и тянет всё живое к чёрной воронке. Разбейте её или коснитесь нулевым жезлом, чтобы оборвать течение."
	icon = 'modular_bluemoon/icons/obj/heretic_tide_well.dmi'
	icon_state = "tide_whirlpool"
	pixel_x = -32
	pixel_y = -32
	anchored = TRUE
	density = FALSE
	max_integrity = 60
	layer = BELOW_MOB_LAYER
	var/datum/weakref/tide_ref
	var/expires_at
	var/outward = FALSE
	COOLDOWN_DECLARE(well_pulse)

/obj/structure/heretic_tide_well/Initialize(mapload, datum/eldritch_knowledge/base_tide/tide)
	. = ..()
	if(QDELETED(tide))
		return INITIALIZE_HINT_QDEL
	tide_ref = WEAKREF(tide)
	expires_at = world.time + HERETIC_TIDE_WELL_LIFETIME
	COOLDOWN_START(src, well_pulse, HERETIC_TIDE_WELL_INTERVAL)
	START_PROCESSING(SSobj, src)

/obj/structure/heretic_tide_well/Destroy()
	STOP_PROCESSING(SSobj, src)
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide?.active_well == src)
		tide.active_well = null
	tide_ref = null
	return ..()

/obj/structure/heretic_tide_well/process()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide || QDELETED(tide.tide_body) || tide.tide_body.stat == DEAD || !IS_HERETIC(tide.tide_body) || world.time >= expires_at)
		qdel(src)
		return PROCESS_KILL
	if(!COOLDOWN_FINISHED(src, well_pulse))
		return
	COOLDOWN_START(src, well_pulse, HERETIC_TIDE_WELL_INTERVAL)
	pulse()

/obj/structure/heretic_tide_well/proc/pulse(erupting = FALSE)
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	var/mob/living/user = tide?.tide_body
	if(!tide || QDELETED(user) || user.stat == DEAD || !IS_HERETIC(user) || !tide.line_clear(user, src, 7) || world.time >= expires_at)
		return FALSE
	for(var/mob/living/victim in range(HERETIC_TIDE_WAVE_RADIUS, src))
		if(!isturf(victim.loc) || !tide.line_clear(src, victim, HERETIC_TIDE_WAVE_RADIUS) || !heretic_can_affect(user, victim))
			continue
		var/in_core = !outward && get_dist(victim, src) <= 1
		victim.adjustBruteLoss(erupting ? 12 : in_core ? 12 : 6)
		victim.adjustStaminaLoss(erupting ? 18 : in_core ? 12 : 8)
		tide.soak(victim)
		tide.move_with_tide(victim, src, !outward, reach_center = TRUE, collide = !outward)
		if(erupting || in_core)
			victim.Knockdown(erupting ? 1.5 SECONDS : 0.6 SECONDS)
		log_combat(user, victim, outward ? "оттесняет водоворотом" : "затягивает водоворотом")
	for(var/turf/tile in range(HERETIC_TIDE_WAVE_RADIUS, src))
		if(tide.line_clear(src, tile, HERETIC_TIDE_WAVE_RADIUS))
			tide.wet_floor(tile)
	new /obj/effect/temp_visual/heretic_tide/wave(get_turf(src))
	return TRUE

/obj/structure/heretic_tide_well/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	return ..()

/obj/item/melee/sickly_blade/tide
	name = "abyssal harpoon"
	desc = "Изогнутый гарпун с бронзовой рукоятью. Внутри лезвия колышется чёрная вода, которой неведомы берега."
	icon = 'modular_bluemoon/icons/obj/heretic_tide.dmi'
	icon_state = "tide_blade"
	item_state = "tide_blade"
	route = PATH_TIDE
	mark_type = /datum/status_effect/eldritch/tide

/obj/item/heretic_path_relic/tide_bell
	name = "drowned bell"
	desc = "Водолазный колокол, умещающийся в ладони. Применение в руке меняет притяжение и отталкивание Сброса давления. Щелчок по своей воронке в пяти клетках обращает её наружу или обратно. Наружное течение отталкивает на клетку с 6 ушибами и 8 урона выносливости, без падения и удара о стену. Срок жизни воронки сохраняется. Общая перезарядка — 10 секунд."
	icon_state = "tide_bell"

/obj/item/heretic_path_relic/tide_bell/attack_self(mob/living/user)
	ring(user)

/obj/item/heretic_path_relic/tide_bell/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	if(istype(target, /obj/structure/heretic_tide_well))
		return redirect_well(user, target)
	return ..()

/obj/item/heretic_path_relic/tide_bell/proc/redirect_well(mob/living/user, obj/structure/heretic_tide_well/well)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!authorized(user) || !tide?.can_use(user) || !COOLDOWN_FINISHED(src, relic_cooldown) || QDELETED(well) || well.tide_ref?.resolve() != tide || world.time >= well.expires_at || !tide.line_clear(user, well))
		return FALSE
	well.outward = !well.outward
	well.color = well.outward ? "#7fb9c8" : initial(well.color)
	well.desc = well.outward ? "Вода расходится от центра. Раз в две секунды течение отталкивает на клетку, нанося 6 ушибов и 8 урона выносливости без падения. Разбейте воронку или коснитесь нулевым жезлом, чтобы оборвать течение." : initial(well.desc)
	COOLDOWN_START(src, relic_cooldown, 10 SECONDS)
	well.visible_message(span_warning("[well] меняет течение: вода теперь [well.outward ? "расходится от центра" : "стягивается в воронку"]!"))
	playsound(well, 'modular_bluemoon/sound/heretic/tide_bell.ogg', 45, FALSE)
	return TRUE

/obj/item/heretic_path_relic/tide_bell/proc/ring(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!authorized(user) || !tide?.can_use(user) || !COOLDOWN_FINISHED(src, relic_cooldown))
		return FALSE
	tide.inward_tide = !tide.inward_tide
	tide.notify_resource_changed()
	COOLDOWN_START(src, relic_cooldown, 10 SECONDS)
	to_chat(user, span_eldritch("Колокол зовёт [tide.inward_tide ? "прилив: Сброс притягивает противников" : "отлив: Сброс отталкивает противников"]."))
	new /obj/effect/temp_visual/heretic_tide/wave(get_turf(user))
	flick("tide_bell_ring", src)
	playsound(user, 'modular_bluemoon/sound/heretic/tide_bell.ogg', 45, FALSE)
	return TRUE

/obj/effect/temp_visual/heretic_tide
	icon = 'modular_bluemoon/icons/obj/heretic_tide_effects.dmi'
	icon_state = "tide_wave"
	duration = 0.8 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_tide/grasp
	icon_state = "tide_grasp"

/obj/effect/temp_visual/heretic_tide/wave

/obj/effect/temp_visual/heretic_tide/burst
	icon_state = "tide_burst"
	duration = 1.9 SECONDS

/obj/effect/temp_visual/heretic_tide/warning
	icon_state = "tide_warning"
	duration = 2 SECONDS

/// Корона воды вокруг вознёсшегося: задняя половина уходит под героя, передняя встаёт перед ним.
/obj/effect/temp_visual/heretic_tide_swell
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "tide_swell_back"
	layer = BELOW_MOB_LAYER
	randomdir = FALSE
	duration = HERETIC_TIDE_SWELL_TIME

/obj/effect/temp_visual/heretic_tide_swell/front
	icon_state = "tide_swell_front"
	layer = ABOVE_MOB_LAYER

/// Пучина: капли стекают с намокшего и падают к ногам.
/particles/heretic_ascension/tide/drip
	icon_state = list("water_drop" = 1)
	count = 8
	spawning = 0.35
	position = generator("box", list(-8, -4, 0), list(8, 10, 0))
	velocity = list(0, -0.3, 0)
	gravity = list(0, -0.25)
	friction = 0
	lifespan = 0.9 SECONDS
	fade = 0.3 SECONDS
	fadein = 0.1 SECONDS

/// Пучина: брызги из-под шага по своей воде.
/particles/heretic_ascension/tide/step
	count = 8
	spawning = 8
	position = generator("box", list(-6, -13, 0), list(6, -9, 0))
	velocity = generator("box", list(-1.5, 1.5, 0), list(1.5, 3, 0))
	gravity = list(0, -0.45)
	friction = 0.02
	lifespan = 0.5 SECONDS
	fade = 0.2 SECONDS

/// Пучина: пена разлетается кольцом от Голоса Пучины.
/particles/heretic_ascension/tide/foam
	velocity = generator("circle", 4, 7)
	gravity = list(0, -0.2)
	friction = 0.12
	lifespan = 1 SECONDS
	fade = 0.4 SECONDS

/obj/effect/proc_holder/spell/self/heretic_tide
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "tide_release"
	action_background_icon_state = "bg_ecult"
	charge_max = 20 SECONDS

/obj/effect/proc_holder/spell/self/heretic_tide/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	return ..() && heretic_check(user, tide?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_tide/release
	name = "Сброс давления"
	desc = "За 2 давления обдайте врагов в двух клетках волной: 18 ушибов, 24 урона выносливости, падение на 2,5 секунды и снос на две клетки. Упор в стену добавляет 8 ушибов. Колокол меняет отталкивание на притяжение."
	charge_max = 15 SECONDS

/obj/effect/proc_holder/spell/self/heretic_tide/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!tide?.release(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_tide/leviathan
	name = "Голос Пучины"
	desc = "Бесплатная волна в трёх клетках: 30 ушибов, 40 урона выносливости, падение на 3 секунды и снос на три клетки. Упор в стену добавляет 8 ушибов. Пристёгнутых и закреплённых не сносит. Доступно после вознесения."
	charge_max = 30 SECONDS
	action_icon_state = "tide_ascend"

/obj/effect/proc_holder/spell/self/heretic_tide/leviathan/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!tide?.release(user, ascended_wave = TRUE))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_tide
	clothes_req = FALSE
	invocation_type = "none"
	range = HERETIC_TIDE_RANGE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "tide_undertow"
	action_background_icon_state = "bg_ecult"
	charge_max = 20 SECONDS
	active_msg = "Укажите цель для магии Пучины."
	deactive_msg = "Вы отпускаете течение."

/obj/effect/proc_holder/spell/pointed/heretic_tide/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	return ..() && heretic_check(user, tide?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/pointed/heretic_tide/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!heretic_check(user, tide, silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	var/reason = tide.line_failure(user, target)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_tide/undertow
	name = "Отлив"
	desc = "Притяните противника в пяти клетках на три клетки ближе: 15 ушибов, 20 урона выносливости и падение на 2 секунды. Не требует давления. Стены, закрытые двери, окна и машины защищают, столы и перила - нет. Закрепление и пристёгивание мешают перемещению."

/obj/effect/proc_holder/spell/pointed/heretic_tide/undertow/can_target(atom/target, mob/user, silent)
	if(!heretic_check(user, isliving(target) && target != user, silent, "Цели нет: Отлив тянет только живого противника, а не пол или предмет."))
		return FALSE
	return ..() && heretic_check(user, heretic_can_affect(user, target, chargecost = 0), silent, "Эту цель не притянуть: она мертва или защищена от магии.", target = target)

/obj/effect/proc_holder/spell/pointed/heretic_tide/undertow/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!length(targets) || !tide?.undertow(user, targets[1]))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_tide/well
	name = "Чёрный водоворот"
	desc = "За 2 давления создайте воронку на 12 секунд. При появлении она бьёт в двух клетках на 12 ушибов и 18 выносливости, сбивает и притягивает. Затем каждые 2 секунды затягивает глубже: на краю 6 ушибов и 8 выносливости, в центре и рядом с ним — 12 и 12 с коротким падением. Воронка имеет 60 прочности и действует, пока вы в семи клетках без преград."
	charge_max = 30 SECONDS
	action_icon_state = "tide_well"

/obj/effect/proc_holder/spell/pointed/heretic_tide/well/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!length(targets) || !tide?.create_well(user, get_turf(targets[1])))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_tide/deluge
	name = "Обрушение толщи"
	desc = "После двух секунд подготовки обрушьте весь запас на область в пяти клетках, радиус две клетки: 20 ушибов + 6 за давление, 20 выносливости + 3 за давление и падение на 2 секунды. Требует хотя бы 2 давления. Из подсвеченной области можно выйти. Во время подготовки можно сместиться до двух клеток от исходной позиции; выбранная область не движется. Потеря видимости, выход за дальность или оглушение срывают удар без расхода давления."
	charge_max = 40 SECONDS
	action_icon_state = "tide_deluge"

/obj/effect/proc_holder/spell/pointed/heretic_tide/deluge/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/turf/center = length(targets) ? get_turf(targets[1]) : null
	if(!tide?.can_use(user) || tide.combat_resource < HERETIC_TIDE_RELEASE_COST || !tide.line_clear(user, center))
		heretic_revert_cast(user)
		return
	var/list/telegraphed_turfs = tide.deluge_turfs(user, center)
	var/expected_generation = tide.tide_generation
	var/turf/origin = get_turf(user)
	for(var/turf/tile as anything in telegraphed_turfs)
		new /obj/effect/temp_visual/heretic_tide/warning(tile)
	user.visible_message(span_danger("[user] поднимает руки. Над полом проступает чёрная вода — сейчас обрушится прилив!"))
	playsound(center, 'modular_bluemoon/sound/heretic/tide_charge.ogg', 50, FALSE)
	if(!do_after(user, 2 SECONDS, target = center, timed_action_flags = IGNORE_USER_LOC_CHANGE, extra_checks = CALLBACK(tide, TYPE_PROC_REF(/datum/eldritch_knowledge/base_tide, can_prepare_deluge), user, origin, center, expected_generation)) || QDELETED(src) || QDELETED(tide) || !tide.deluge(user, center, telegraphed_turfs, expected_generation))
		if(!QDELETED(src))
			heretic_revert_cast(user, "Подготовка сорвана: можно сместиться не дальше двух клеток от её начала. Сохраняйте видимость выбранной области в пяти клетках и возможность действовать; давление сохранено.")

/datum/eldritch_knowledge/tide_grasp
	name = "Хватка глубины"
	desc = "Хватка Мансуса по противнику даёт 2 единицы давления и покрывает цель замедляющей водой Пучины на 8 секунд. Антимагия и союзники не дают давления."
	gain_text = "На дне нет воздуха, но ладонь помнит вес каждого вдоха."
	cost = 1
	route = PATH_TIDE

/datum/eldritch_knowledge/tide_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!proximity_flag || !tide?.can_use(user) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	tide.gain_combat_resource(2)
	tide.soak(target)
	return TRUE

/datum/eldritch_knowledge/spell/tide_undertow
	name = "Отлив"
	desc = "Отлив притягивает врага в пяти клетках на три клетки ближе, наносит 15 ушибов и 20 урона выносливости, сбивает на 2 секунды и покрывает водой Пучины. Не требует давления, перезарядка 20 секунд. Стены, закрытые двери, окна и машины защищают от течения; столы, стойки и перила его не останавливают."
	gain_text = "Я звал с берега. Ответ пришёл из-под ног."
	cost = 1
	route = PATH_TIDE
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_tide/undertow

/datum/eldritch_knowledge/tide_mark
	name = "Метка Пучины"
	desc = "Хватка Мансуса оставляет на противнике метку на 15 секунд. Попадание гарпунным клинком взрывает её: 8 ушибов, 12 урона выносливости и единица давления владельцу клинка."
	gain_text = "Вода отступила, оставив на коже очертания невозможного берега."
	cost = 2
	route = PATH_TIDE

/datum/eldritch_knowledge/tide_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!proximity_flag || !tide?.can_use(user) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/tide, tide)
	return TRUE

/datum/eldritch_knowledge/tide_bell
	name = "Звон затонувшего храма"
	desc = "Лист золота и металлический прут создают затонувший колокол. Применение в руке меняет притяжение и отталкивание Сброса давления. Щелчок колоколом по своей воронке в пяти клетках обращает её наружу или обратно. Наружное течение раз в 2 секунды отталкивает на клетку с 6 ушибами и 8 урона выносливости, без падения и удара о стену. Переключение не даёт дополнительного пульса и не продлевает воронку. Давление не расходуется; общая перезарядка 10 секунд. Можно иметь один колокол; он слушается только своего создателя."
	gain_text = "В затонувшем храме всё ещё звонят к утренней службе."
	cost = 1
	route = PATH_TIDE
	required_atoms = list(/obj/item/stack/sheet/mineral/gold, /obj/item/stack/rods)
	result_atoms = list(/obj/item/heretic_path_relic/tide_bell)

/datum/eldritch_knowledge/tide_bell/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/tide_bell/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/tide_bell)

/datum/eldritch_knowledge/tide_upgrade
	name = "Гарпун утопленника"
	desc = "Гарпун наносит ещё 5 ушибов при каждом попадании по намокшему противнику. Раз в 6 секунд удар по цели с вашей водой Пучины дополнительно возвращает 1 давление и восстанавливает вам 10 выносливости. Намокание и обычный сбор давления от клинка сохраняются."
	gain_text = "Лезвие узнало тех, кого однажды коснулось море."
	cost = 2
	route = PATH_TIDE

/datum/eldritch_knowledge/tide_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!proximity_flag || !tide?.can_use(user) || !heretic_can_affect(user, target, chargecost = 0))
		return
	var/mob/living/victim = target
	var/datum/status_effect/heretic_drenched/water = victim.has_status_effect(/datum/status_effect/heretic_drenched)
	if(!water)
		return
	victim.adjustBruteLoss(HERETIC_TIDE_HARPOON_DAMAGE)
	if(!COOLDOWN_FINISHED(tide, harpoon_recovery) || water.tide_ref?.resolve() != tide)
		return
	COOLDOWN_START(tide, harpoon_recovery, HERETIC_TIDE_HARVEST_TIME)
	tide.gain_combat_resource()
	var/mob/living/wielder = user
	wielder.adjustStaminaLoss(-HERETIC_TIDE_HARPOON_STAMINA)
	new /obj/effect/temp_visual/heretic_tide/grasp(get_turf(victim))
	playsound(victim, 'modular_bluemoon/sound/heretic/tide_grasp.ogg', 30, TRUE)

/datum/eldritch_knowledge/spell/tide_well
	name = "Чёрный водоворот"
	desc = "За 2 давления создайте в пяти клетках воронку на 12 секунд. Первый удар в радиусе двух клеток: 12 ушибов, 18 выносливости, падение на 1,5 секунды и притяжение. Затем каждые 2 секунды она тянет на клетку и бьёт: на краю 6 ушибов и 8 выносливости, в центре и рядом — 12 и 12 с падением на 0,6 секунды. Воронка имеет 60 прочности, разрушается жезлом и работает в семи клетках от вас без преград. Одновременно одна; перезарядка 30 секунд."
	gain_text = "Воронка ведёт не вниз. Она ведёт домой."
	cost = 1
	route = PATH_TIDE
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_tide/well

/datum/eldritch_knowledge/tide_depth
	name = "Тысяча саженей"
	desc = "Предел давления возрастает до 5, а восстановление ускоряется до единицы за 10 секунд. Дальнейшие ступени дают 6 и 7 давления, восстановление за 8 и 6 секунд."
	gain_text = "У глубины нет дна. Есть лишь предел того, что я готов вместить."
	cost = 2
	route = PATH_TIDE
	passive_values = list(5, 6, 7)
	passive_desc = "Запас давления: 5 / 6 / 7. Восстановление единицы: 10 / 8 / 6 секунд. Вознесение даёт запас 8 и восстановление за 4 секунды."

/datum/eldritch_knowledge/tide_depth/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	tide?.update_capacity()

/datum/eldritch_knowledge/tide_depth/on_passive_upgrade(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	tide?.update_capacity()

/datum/eldritch_knowledge/spell/tide_deluge
	name = "Обрушение толщи"
	desc = "После двух секунд подготовки обрушьте весь запас давления на область радиусом две клетки в пяти клетках от вас: 20 ушибов + 6 за давление, 20 выносливости + 3 за давление и падение на 2 секунды. При полном начальном запасе это 44 ушиба и 32 выносливости. Нужно хотя бы 2 давления. Стены защищают, из области можно выйти; сорванная подготовка сохраняет запас. Перезарядка 40 секунд. Во время подготовки можно сместиться до двух клеток от исходной позиции; выбранная область не движется. Потеря видимости, выход за дальность или оглушение срывают удар без расхода давления."
	gain_text = "Я услышал треск стекла. Между нами и морем никогда не было ничего прочнее."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_TIDE
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_tide/deluge

/datum/eldritch_knowledge/final_eldritch/tide_final
	parallax_scene = ANTAG_SCENE_HERETIC_TIDE
	name = "Владыка Пучины"
	desc = "После трёх назначенных душ принесите три человеческих трупа. Обряд раскрывает место станции и длится 30 секунд. Вознесение даёт запас давления 8 и восстанавливает единицу за 4 секунды. Вы получаете общую стойкость вознесения. Каждые 2 секунды пол в двух клетках вокруг вас заливает чёрная вода, если путь до клетки не перекрыт стеной, закрытой дверью, окном или машиной (столы и перила воду пропускают, направленное окно держит её только со своей стороны); каждый ваш шаг тоже оставляет лужу. Без обновления вода уходит через 4 секунды. Враги в воде и вошедшие в неё мокнут на 8 секунд и замедляются даже в нескользящей обуви; пока они стоят в воде, намокание продлевается. По своей воде вы двигаетесь быстрее. Пол от неё не становится скользким. Голос Пучины раз в 30 секунд бесплатно бьёт в радиусе трёх клеток: 30 ушибов, 40 выносливости, падение на 3 секунды и снос на три клетки, пристёгнутых и закреплённых не сносит. Смерть снимает эти усиления, оживление возвращает."
	gain_text = "Берег исчез. Осталось только моё дыхание, и море дышало вместе со мной. Теперь оно разливалось у моих ног, куда бы я ни шёл."
	route = PATH_TIDE
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_tide/leviathan)
	var/datum/weakref/tide_knowledge_ref

/datum/eldritch_knowledge/final_eldritch/tide_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!tide)
		return
	tide_knowledge_ref = WEAKREF(tide)
	tide.ascension_active = TRUE
	tide.update_capacity()
	user.AddComponent(/datum/component/heretic_tide_flood, tide)

/datum/eldritch_knowledge/final_eldritch/tide_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_tide_flood))
	var/datum/eldritch_knowledge/base_tide/tide = tide_knowledge_ref?.resolve()
	tide_knowledge_ref = null
	if(tide)
		tide.ascension_active = FALSE
		tide.update_capacity()
	return ..()

/// Прилив: пол вокруг вознёсшегося залит его водой, враги в ней мокнут, а сам он по ней ходит быстрее.
/datum/component/heretic_tide_flood
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/tide_ref
	var/list/obj/effect/heretic_tide_puddle/puddles = list()
	var/flood_timer
	COOLDOWN_DECLARE(step_splash)

/datum/component/heretic_tide_flood/Initialize(datum/eldritch_knowledge/base_tide/tide)
	if(!isliving(parent) || QDELETED(tide))
		return COMPONENT_INCOMPATIBLE
	tide_ref = WEAKREF(tide)

/datum/component/heretic_tide_flood/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	flood()

/datum/component/heretic_tide_flood/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_EXAMINE))
	var/mob/living/owner = parent
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_flow)

/datum/component/heretic_tide_flood/Destroy()
	deltimer(flood_timer)
	flood_timer = null
	var/list/old_puddles = puddles
	puddles = list()
	QDEL_LIST(old_puddles)
	tide_ref = null
	return ..()

/datum/component/heretic_tide_flood/proc/flood()
	deltimer(flood_timer)
	flood_timer = addtimer(CALLBACK(src, PROC_REF(flood)), HERETIC_TIDE_FLOOD_INTERVAL, TIMER_STOPPABLE)
	var/mob/living/owner = parent
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide?.ascension_active || owner.stat == DEAD || !isturf(owner.loc))
		return
	var/turf/center = owner.loc
	for(var/turf/open/tile in RANGE_TURFS(HERETIC_TIDE_FLOOD_RADIUS, center))
		if(!tide.line_clear(center, tile, HERETIC_TIDE_FLOOD_RADIUS) || !wet_tile(tile))
			continue
		for(var/mob/living/victim in tile)
			soak(victim)
	update_haste()

/datum/component/heretic_tide_flood/proc/wet_tile(turf/open/tile)
	if(!istype(tile) || isgroundlessturf(tile) || istype(tile, /turf/open/lava))
		return FALSE
	var/obj/effect/heretic_tide_puddle/puddle = own_puddle(tile)
	if(puddle)
		puddle.refresh()
	else
		new /obj/effect/heretic_tide_puddle(tile, src)
	return TRUE

/datum/component/heretic_tide_flood/proc/own_puddle(atom/place)
	if(!isturf(place))
		return null
	for(var/obj/effect/heretic_tide_puddle/puddle in place)
		if(!QDELETED(puddle) && puddle.flood_ref?.resolve() == src)
			return puddle
	return null

/datum/component/heretic_tide_flood/proc/soak(mob/living/victim)
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide?.ascension_active || !heretic_can_affect(parent, victim, chargecost = 0))
		return
	var/datum/status_effect/heretic_drenched/water = victim.has_status_effect(/datum/status_effect/heretic_drenched)
	if(water?.tide_ref?.resolve() == tide)
		water.refresh()
	else
		tide.soak(victim)

/datum/component/heretic_tide_flood/proc/update_haste()
	var/mob/living/owner = parent
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide?.ascension_active && owner.stat != DEAD && own_puddle(owner.loc))
		owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_flow)
	else
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_flow)

/datum/component/heretic_tide_flood/proc/puddle_gone(obj/effect/heretic_tide_puddle/puddle)
	puddles -= puddle
	var/mob/living/owner = parent
	if(owner.loc == puddle.loc)
		update_haste()

/datum/component/heretic_tide_flood/proc/on_moved(mob/living/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide?.ascension_active && source.stat != DEAD)
		if(wet_tile(source.loc) && COOLDOWN_FINISHED(src, step_splash) && heretic_vfx_watched(source))
			splash_step(source.loc)
	update_haste()

/// Брызги из-под шага по своей воде.
/datum/component/heretic_tide_flood/proc/splash_step(turf/place)
	COOLDOWN_START(src, step_splash, HERETIC_TIDE_STEP_SPLASH_COOLDOWN)
	heretic_vfx_burst(place, /particles/heretic_ascension/tide/step, HERETIC_VFX_BURST_TIME / 3, FALSE)

/datum/component/heretic_tide_flood/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("У его ног разливается чёрная вода, за ним тянется мокрый след: пол в двух клетках от него залит, вошедшие в воду мокнут и замедляются, а по своей воде он ходит быстрее. Держитесь дальше двух клеток, не идите по следу и стреляйте издалека; стены, окна, закрытые двери и машины воду не пропускают, пристёгнутых и закреплённых его волна не сносит.")

/obj/effect/heretic_tide_puddle
	name = "abyssal water"
	desc = "Чёрная вода Пучины стоит на сухом полу. Вошедший в неё намокает и замедляется. Без хозяина рядом вода уходит за несколько секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_tide_effects.dmi'
	icon_state = "tide_puddle"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FLOOR_PLANE
	layer = ABOVE_NORMAL_TURF_LAYER
	var/datum/weakref/flood_ref
	var/expires_at
	var/expiry_timer

/obj/effect/heretic_tide_puddle/Initialize(mapload, datum/component/heretic_tide_flood/flood)
	. = ..()
	if(QDELETED(flood))
		return INITIALIZE_HINT_QDEL
	flood_ref = WEAKREF(flood)
	flood.puddles += src
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	alpha = 0
	flick("tide_puddle_spread", src)
	animate(src, alpha = 255, time = HERETIC_TIDE_PUDDLE_RISE, easing = SINE_EASING | EASE_OUT)
	refresh()

/obj/effect/heretic_tide_puddle/Destroy()
	if(isturf(loc))
		drain_away()
	deltimer(expiry_timer)
	expiry_timer = null
	var/datum/component/heretic_tide_flood/flood = flood_ref?.resolve()
	flood?.puddle_gone(src)
	flood_ref = null
	return ..()

/// Обновлённая вода держится ещё полный срок.
/obj/effect/heretic_tide_puddle/proc/refresh()
	deltimer(expiry_timer)
	expires_at = world.time + HERETIC_TIDE_FLOOD_LIFETIME
	expiry_timer = QDEL_IN_STOPPABLE(src, HERETIC_TIDE_FLOOD_LIFETIME)

/// Ушедшая вода, в срок или раньше, не пропадает рывком: её отпечаток стекает на месте.
/obj/effect/heretic_tide_puddle/proc/drain_away()
	var/obj/effect/temp_visual/heretic_vfx/ghost/drain = new(loc, src, null, HERETIC_TIDE_PUDDLE_DRAIN)
	if(QDELETED(drain))
		return
	drain.alpha = drain.model_share(255)
	drain.transform = matrix()
	animate(drain, alpha = 0, transform = matrix(HERETIC_TIDE_PUDDLE_DRAIN_SCALE, 0, 0, 0, HERETIC_TIDE_PUDDLE_DRAIN_SCALE, 0), time = HERETIC_TIDE_PUDDLE_DRAIN, easing = SINE_EASING | EASE_IN)

/obj/effect/heretic_tide_puddle/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/datum/component/heretic_tide_flood/flood = flood_ref?.resolve()
	if(flood && isliving(arrived))
		flood.soak(arrived)

/datum/movespeed_modifier/heretic_tide_flow
	multiplicative_slowdown = -HERETIC_TIDE_FLOOD_HASTE

#undef HERETIC_TIDE_RANGE
#undef HERETIC_TIDE_CHANNEL_MOVEMENT
#undef HERETIC_TIDE_WAVE_RADIUS
#undef HERETIC_TIDE_RELEASE_COST
#undef HERETIC_TIDE_HARVEST_TIME
#undef HERETIC_TIDE_WELL_LIFETIME
#undef HERETIC_TIDE_WELL_INTERVAL
#undef HERETIC_TIDE_ASCENDED_CAPACITY
#undef HERETIC_TIDE_PUDDLE_TIME
#undef HERETIC_TIDE_PRESSURE_INTERVAL
#undef HERETIC_TIDE_COLLISION_DAMAGE
#undef HERETIC_TIDE_HARPOON_STAMINA
#undef HERETIC_TIDE_HARPOON_DAMAGE
#undef HERETIC_TIDE_PUDDLE_RISE
#undef HERETIC_TIDE_PUDDLE_DRAIN
#undef HERETIC_TIDE_PUDDLE_DRAIN_SCALE
#undef HERETIC_TIDE_STEP_SPLASH_COOLDOWN
#undef HERETIC_TIDE_SWELL_TIME
#undef HERETIC_TIDE_VOICE_WAVE_TIME
#undef HERETIC_TIDE_VOICE_FLASH_RANGE
#undef HERETIC_TIDE_VOICE_FLASH_POWER
#undef HERETIC_TIDE_VOICE_FLASH_TIME
#undef HERETIC_TIDE_VOICE_QUAKE
#undef HERETIC_TIDE_VOICE_QUAKE_RADIUS
#undef HERETIC_TIDE_VOICE_QUAKE_TIME
