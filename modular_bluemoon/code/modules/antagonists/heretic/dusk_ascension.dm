#define HERETIC_DUSK_NIGHT_STEP (0.5 SECONDS)
#define HERETIC_DUSK_NIGHT_LAMPS_PER_STEP 8
#define HERETIC_DUSK_SUN_TRAINING_RANGE 4
#define HERETIC_DUSK_SUN_SPLASH_GAP (1 SECONDS)
#define HERETIC_DUSK_SUN_LIGHT_RANGE 3
#define HERETIC_DUSK_SUN_LIGHT_POWER 0.6
#define HERETIC_DUSK_SUN_COLOR "#e8d9a8"
#define HERETIC_DUSK_NIGHT_PULSE (2 SECONDS)
#define HERETIC_DUSK_SUN_VIGNETTE_RANGE 5

/// Общие отсеки станции, где встаёт Чёрное солнце; в часовне - никогда.
/proc/heretic_dusk_sun_area(area/place)
	return heretic_station_public_area(place) && !istype(place, /area/service/chapel)

/// Свободный пол ближе всего к середине отсека на палубе, где его больше всего.
/proc/heretic_dusk_area_center(area/place)
	var/list/by_z = list()
	for(var/turf/open/tile in get_area_turfs(place.type))
		if(!is_station_level(tile.z) || isgroundlessturf(tile) || tile.is_blocked_turf(exclude_mobs = TRUE))
			continue
		var/key = "[tile.z]"
		LAZYADD(by_z[key], tile)
	var/list/turf/best_tiles
	for(var/key in by_z)
		if(length(by_z[key]) > length(best_tiles))
			best_tiles = by_z[key]
	if(!length(best_tiles))
		return null
	var/sum_x = 0
	var/sum_y = 0
	for(var/turf/tile as anything in best_tiles)
		sum_x += tile.x
		sum_y += tile.y
	var/center_x = sum_x / length(best_tiles)
	var/center_y = sum_y / length(best_tiles)
	var/turf/best
	var/best_distance
	for(var/turf/tile as anything in best_tiles)
		var/distance = (tile.x - center_x) ** 2 + (tile.y - center_y) ** 2
		if(!best || distance < best_distance)
			best = tile
			best_distance = distance
	return best

/datum/eldritch_knowledge/final_eldritch/dusk_final
	var/list/obj/structure/heretic_dusk_black_sun/suns = list()
	var/suns_raised = FALSE
	var/night_over = FALSE
	/// Погасшие отсеки => был ли включён их выключатель до ночи.
	var/list/area/dark_areas = list()
	var/list/lamp_queue = list()
	var/queue_timer
	var/night_timer
	var/noon_failure
	var/desecrate_failure
	var/desecrating = FALSE
	var/desecrate_broken = FALSE
	var/table_pass = FALSE
	var/datum/looping_sound/heretic_dusk_halo/halo_hum

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/dusk_of(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)

/datum/eldritch_knowledge/final_eldritch/dusk_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	. = ..()
	if(.)
		raise_suns(user)

/datum/eldritch_knowledge/final_eldritch/dusk_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(dusk)
		dusk.ascension_active = TRUE
		dusk.suns_standing = length(suns) > 0
		dusk.fill_charges("step")
		dusk.fill_charges("descent")
		dusk.refresh_light()
	if(!(user.pass_flags & PASSTABLE))
		user.pass_flags |= PASSTABLE
		table_pass = TRUE
	user.overlay_fullscreen("heretic_dusk_wings_halo", /atom/movable/screen/fullscreen/scaled/heretic_dusk/wings_halo)
	QDEL_NULL(halo_hum)
	halo_hum = new(user, TRUE)
	update_suns_alert()

/datum/eldritch_knowledge/final_eldritch/dusk_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(body)
	if(dusk)
		dusk.ascension_active = FALSE
		dusk.suns_standing = FALSE
		dusk.refresh_light()
	if(body)
		if(table_pass)
			body.pass_flags &= ~PASSTABLE
		body.clear_fullscreen("heretic_dusk_wings_halo", QDELETED(body) ? 0 : 1 SECONDS)
		body.clear_alert(HERETIC_DUSK_SUNS_ALERT)
	table_pass = FALSE
	QDEL_NULL(halo_hum)
	return ..()

/datum/eldritch_knowledge/final_eldritch/dusk_final/on_death(mob/user)
	. = ..()
	if(suns_raised && !night_over)
		end_night(TRUE)

/datum/eldritch_knowledge/final_eldritch/dusk_final/on_lose(mob/user)
	. = ..()
	clear_suns()

/datum/eldritch_knowledge/final_eldritch/dusk_final/Destroy()
	clear_suns()
	return ..()

/datum/eldritch_knowledge/final_eldritch/dusk_final/on_ascended_body_deleted(mob/living/source)
	. = ..()
	if(suns_raised && !night_over)
		INVOKE_ASYNC(src, PROC_REF(end_night), TRUE)

/datum/eldritch_knowledge/final_eldritch/dusk_final/on_ascended_examine(datum/source, mob/examiner, list/examine_list)
	. = ..()
	examine_list += span_warning("Это падший ангел: крылья из тени и обгоревших перьев, перевёрнутый нимб, свет из трещин кожи. Святая вода, нулевой жезл и Библия капеллана жгут его, часовня - святая земля.")
	if(length(suns))
		examine_list += span_warning("Пока стоят Чёрные солнца ([length(suns)]), ночь держится, а он лечится от каждой отнятой тени. Разбейте солнца: святая вода и нулевой жезл бьют их сильнее.")

/// Долгая ночь: Чёрные солнца встают в общих отсеках, свет там гаснет волнами.
/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/raise_suns(mob/living/user)
	if(suns_raised)
		return FALSE
	suns_raised = TRUE
	var/list/area_names = list()
	var/list/spots = sun_spots(user)
	for(var/turf/spot as anything in spots)
		var/obj/structure/heretic_dusk_black_sun/sun = new(spot, src, simulated ? null : get_area(spot))
		if(QDELETED(sun))
			continue
		suns += sun
		area_names += spots[spot]
	if(!length(suns))
		night_over = TRUE
		log_game("[key_name(user)]: Чёрным солнцам Сумрака не нашлось места.")
		return FALSE
	for(var/obj/structure/heretic_dusk_black_sun/sun as anything in suns)
		if(sun.night_area)
			darken_area(sun.night_area)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(dusk)
		dusk.suns_standing = TRUE
	var/rotten = dusk?.covenant == HERETIC_DUSK_COVENANT_ROT
	if(rotten)
		for(var/obj/structure/heretic_dusk_black_sun/sun as anything in suns)
			sun.start_rot(dusk)
	update_suns_alert()
	night_pulse()
	var/where = english_list(area_names)
	log_game("[key_name(user)] ставит Чёрные солнца Сумрака: [where].")
	to_chat(user, span_eldritch("Наступает долгая ночь. Чёрные солнца встали: [where]. Пока стоит хоть одно, свет там не вернётся, вы лечитесь от каждой отнятой тени и раз в [HERETIC_DUSK_FREE_STEP_COOLDOWN / (1 SECONDS)] секунд шагаете в тень без заряда."))
	if(!simulated)
		message_admins("[key_name_admin(user)] ставит Чёрные солнца Сумрака: [where].")
		priority_announce("Над станцией наступает долгая ночь. Вознёсшийся еретик Сумрака поднял Чёрные солнца - перевёрнутые нимбы над отсеками: [where]. Там гаснет свет, и выключатели его не зажгут, пока солнце стоит. Разбейте солнца: [HERETIC_DUSK_SUN_INTEGRITY] прочности, святая вода снимает [HERETIC_DUSK_SUN_HOLY_DAMAGE], нулевой жезл раскалывает за два удара, Библия капеллана - [HERETIC_DUSK_SUN_PRAYER_DAMAGE]. Святую воду наливают в часовне, варят химик и бармен, она есть в снабжении.[rotten ? " Вокруг солнц растёт зелёный налёт скверны: наступивший на него заражается, смывают его очиститель, швабра и святая вода." : ""]", "Долгая ночь", 'sound/misc/notice1.ogg')
	return TRUE

/// Клетка солнца => название отсека; на полигоне солнца встают рядом.
/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/sun_spots(mob/living/user)
	. = list()
	var/turf/origin = get_turf(user)
	if(simulated)
		var/list/turf/nearby = list()
		for(var/turf/open/place in range(HERETIC_DUSK_SUN_TRAINING_RANGE, origin))
			if(get_dist(place, origin) > 1 && istype(get_area(place), /area/antag_training) && !place.is_blocked_turf(exclude_mobs = TRUE))
				nearby += place
		while(length(.) < HERETIC_DUSK_SUNS && length(nearby))
			var/turf/place = pick_n_take(nearby)
			.[place] = get_area_name(place, TRUE)
		return
	var/list/area/candidates = list()
	for(var/area_type in GLOB.the_station_areas)
		var/area/place_area = GLOB.areas_by_type[area_type]
		if(heretic_dusk_sun_area(place_area))
			candidates += place_area
	shuffle_inplace(candidates)
	for(var/area/place_area as anything in candidates)
		if(length(.) >= HERETIC_DUSK_SUNS)
			break
		var/turf/place = heretic_dusk_area_center(place_area)
		if(place)
			.[place] = get_area_name(place, TRUE)

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/darken_area(area/place)
	if(!place || (place in dark_areas))
		return
	dark_areas[place] = place.lightswitch
	place.lightswitch = FALSE
	heretic_dusk_update_switches(place)
	RegisterSignal(place, COMSIG_AREA_POWER_CHANGE, PROC_REF(on_area_power))
	for(var/obj/machinery/light/lamp in place)
		queue_lamp(lamp, TRUE)

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/restore_area(area/place)
	if(!(place in dark_areas))
		return
	var/was_on = dark_areas[place]
	dark_areas -= place
	UnregisterSignal(place, COMSIG_AREA_POWER_CHANGE)
	place.lightswitch = was_on
	heretic_dusk_update_switches(place)
	for(var/obj/machinery/light/lamp in place)
		queue_lamp(lamp, FALSE)

/// Выключатель в погасшем отсеке зажёг свет: пока солнце стоит, ночь гасит его снова.
/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/on_area_power(area/source)
	SIGNAL_HANDLER
	if(night_over || !source.lightswitch)
		return
	source.lightswitch = FALSE
	heretic_dusk_update_switches(source)
	for(var/obj/machinery/light/lamp in source)
		queue_lamp(lamp, TRUE)

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/queue_lamp(obj/machinery/light/lamp, dim)
	lamp_queue[WEAKREF(lamp)] = dim
	if(!queue_timer)
		queue_timer = addtimer(CALLBACK(src, PROC_REF(process_lamps)), HERETIC_DUSK_NIGHT_STEP, TIMER_STOPPABLE)

/// Лампы гаснут и загораются волнами, не больше восьми за шаг.
/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/process_lamps()
	queue_timer = null
	var/done = 0
	while(length(lamp_queue) && done < HERETIC_DUSK_NIGHT_LAMPS_PER_STEP)
		var/datum/weakref/lamp_ref = lamp_queue[1]
		var/dim = lamp_queue[lamp_ref]
		lamp_queue.Cut(1, 2)
		var/obj/machinery/light/lamp = lamp_ref.resolve()
		if(!lamp)
			continue
		if(dim)
			heretic_dusk_dim_lamp(lamp, 0)
		else
			heretic_dusk_restore_lamp(lamp_ref)
		done++
	if(length(lamp_queue))
		queue_timer = addtimer(CALLBACK(src, PROC_REF(process_lamps)), HERETIC_DUSK_NIGHT_STEP, TIMER_STOPPABLE)
	return done

/// Солнце разбито: свет волной возвращается в его отсек.
/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/sun_down(obj/structure/heretic_dusk_black_sun/sun, quiet = FALSE)
	suns -= sun
	var/area/place = sun.night_area
	var/shared = FALSE
	for(var/obj/structure/heretic_dusk_black_sun/other as anything in suns)
		if(other.night_area == place)
			shared = TRUE
	if(place && !shared)
		restore_area(place)
	update_suns_alert()
	if(quiet || night_over)
		return
	log_game("Чёрное солнце Сумрака разбито в [AREACOORD(sun)], стоит ещё [length(suns)].")
	if(applied_body)
		to_chat(applied_body, span_userdanger(length(suns) ? "Чёрное солнце в [get_area_name(sun, TRUE)] разбито. Стоит ещё: [length(suns)]." : "Последнее Чёрное солнце разбито: ночь отступает."))
	if(!length(suns))
		night_retreats()

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/night_retreats(by_death = FALSE)
	if(night_over)
		return FALSE
	night_over = TRUE
	deltimer(night_timer)
	night_timer = null
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(applied_body)
	if(dusk)
		dusk.suns_standing = FALSE
	update_suns_alert()
	log_game("Долгая ночь Сумрака отступает[by_death ? " со смертью вознёсшегося" : ": экипаж разбил последнее Чёрное солнце"].")
	if(simulated)
		return TRUE
	message_admins("Долгая ночь Сумрака отступает[by_death ? " со смертью вознёсшегося" : ""].")
	priority_announce(by_death ? "Вознёсшийся еретик Сумрака пал, и Чёрные солнца угасли вместе с ним. Ночь отступает: свет возвращается в отсеки." : "Последнее Чёрное солнце разбито. Ночь отступает: свет возвращается в отсеки, а вознёсшийся еретик Сумрака больше не лечится от отнятых теней.", "Ночь отступает", 'modular_bluemoon/sound/heretic/dusk_dawn.ogg')
	return TRUE

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/end_night(by_death = FALSE)
	night_retreats(by_death)
	for(var/obj/structure/heretic_dusk_black_sun/sun as anything in suns.Copy())
		sun.quiet_fall = TRUE
		qdel(sun)

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/clear_suns()
	night_over = TRUE
	deltimer(night_timer)
	night_timer = null
	for(var/obj/structure/heretic_dusk_black_sun/sun as anything in suns.Copy())
		sun.quiet_fall = TRUE
		qdel(sun)
	suns.Cut()
	for(var/area/place as anything in dark_areas.Copy())
		restore_area(place)

/// Экипаж в погасших отсеках и у Чёрных солнц видит виньетку ночи, пока стоит хоть одно солнце.
/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/night_pulse()
	night_timer = null
	if(night_over || !length(suns))
		return 0
	. = 0
	for(var/mob/living/carbon/human/witness as anything in GLOB.human_list)
		if(witness.stat == DEAD || IS_HERETIC(witness) || IS_HERETIC_MONSTER(witness) || !in_night(witness))
			continue
		witness.apply_status_effect(/datum/status_effect/heretic_dusk_eclipsed)
		.++
	night_timer = addtimer(CALLBACK(src, PROC_REF(night_pulse)), HERETIC_DUSK_NIGHT_PULSE, TIMER_STOPPABLE)

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/in_night(mob/living/witness)
	var/turf/spot = get_turf(witness)
	if(!spot)
		return FALSE
	if(get_area(spot) in dark_areas)
		return TRUE
	for(var/obj/structure/heretic_dusk_black_sun/sun as anything in suns)
		if(sun.z == spot.z && get_dist(sun, spot) <= HERETIC_DUSK_SUN_VIGNETTE_RANGE)
			return TRUE
	return FALSE

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/update_suns_alert()
	var/mob/living/body = applied_body
	if(!body)
		return
	if(!length(suns))
		body.clear_alert(HERETIC_DUSK_SUNS_ALERT)
		return
	var/atom/movable/screen/alert/heretic_dusk_suns/alert = body.throw_alert(HERETIC_DUSK_SUNS_ALERT, /atom/movable/screen/alert/heretic_dusk_suns)
	alert?.desc = "Чёрных солнц стоит: [length(suns)]. Пока стоит хоть одно, в их отсеках нет света, вы лечитесь от каждой отнятой тени, раз в [HERETIC_DUSK_FREE_STEP_COOLDOWN / (1 SECONDS)] секунд шагаете в тень без заряда, а Хватка держит полностью и в полутени."

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/noon_block_reason(mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(!dusk || user != applied_body)
		return "Способность доступна только вознёсшемуся в своём теле."
	return dusk.cast_block_reason(user)

/// Полдень в полночь: свет собирается в вознёсшемся 1,5 секунды и слепит смотрящих, гася их фонарики.
/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/noon(mob/living/user)
	noon_failure = noon_block_reason(user)
	if(noon_failure)
		return 0
	var/turf/center = get_turf(user)
	heretic_vfx_gather(center, HERETIC_DUSK_SUN_COLOR, HERETIC_DUSK_NOON_RADIUS, HERETIC_DUSK_NOON_TELEGRAPH)
	heretic_dusk_sound(center, "noon_charge", 80, FALSE)
	user.visible_message(span_danger("Свет со всех сторон стекается к [user], нимб разгорается добела - отвернитесь!"), span_notice("Вы собираете полдень."))
	if(!do_after(user, HERETIC_DUSK_NOON_TELEGRAPH, target = user, timed_action_flags = IGNORE_HELD_ITEM))
		noon_failure = "Полдень сорвался: вас прервали."
		return 0
	. = 0
	for(var/mob/living/victim in heretic_field_view(HERETIC_DUSK_NOON_RADIUS, user))
		if(victim == user || victim.stat == DEAD || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || !heretic_can_affect(user, victim))
			continue
		if(ishuman(victim))
			heretic_dusk_douse(victim, HERETIC_DUSK_NOON_DOUSE, REF(src))
		if(is_A_facing_B(victim, user) && victim.flash_act(1, type = /atom/movable/screen/fullscreen/tiled/flash/heretic_dusk, duration = HERETIC_DUSK_NOON_BLIND))
			victim.blind_eyes(HERETIC_DUSK_NOON_BLIND / (2 SECONDS))
			victim.apply_status_effect(/datum/status_effect/heretic_dusk_afterglow, HERETIC_DUSK_NOON_BLIND)
			log_combat(user, victim, "ослепляет Полднем в полночь")
			.++
	heretic_vfx_flash(center, HERETIC_DUSK_SUN_COLOR, HERETIC_DUSK_NOON_RADIUS, 3, 0.6 SECONDS)
	heretic_dusk_sound(center, "noon", 80, FALSE)
	new /obj/effect/temp_visual/heretic_dusk_wave(center)
	GLOB.heretic_sky.event(src)
	log_game("[key_name(user)] раскрывает Полдень в полночь Сумрака в [AREACOORD(center)], ослеплено: [.].")

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/desecrate_block_reason(mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(!dusk?.can_use(user) || user != applied_body)
		return "Способность доступна только вознёсшемуся в своём теле."
	if(GLOB.heretic_dusk_chapel_desecrated)
		return "Часовня уже осквернена."
	if(!istype(get_area(user), /area/service/chapel))
		return "Осквернить можно только часовню: войдите в неё."
	if(desecrating)
		return "Осквернение уже идёт."
	return null

/// Осквернение: 20 секунд в часовне; урон больше 20 за раз или святая вода прерывают, успех снимает святость до конца раунда.
/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/desecrate(mob/living/user)
	desecrate_failure = desecrate_block_reason(user)
	if(desecrate_failure)
		return FALSE
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	desecrating = TRUE
	desecrate_broken = FALSE
	RegisterSignal(user, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_desecrate_hurt))
	RegisterSignal(dusk, COMSIG_HERETIC_DUSK_HOLY, PROC_REF(on_desecrate_holy))
	var/turf/center = get_turf(user)
	for(var/obj/machinery/light/lamp as anything in heretic_dusk_nearest_lamps(center, HERETIC_DUSK_ECLIPSE_RADIUS * 2, HERETIC_DUSK_ECLIPSE_LAMPS))
		heretic_dusk_dim_lamp(lamp, 1 SECONDS)
	new /obj/effect/temp_visual/heretic_dusk/mark_burst(center)
	user.visible_message(span_danger("Над [user] переворачивается нимб, и свет часовни судорожно мигает!"), span_notice("Вы оскверняете святую землю. Не дайте прервать себя [HERETIC_DUSK_DESECRATE_TIME / (1 SECONDS)] секунд."))
	log_game("[key_name(user)] начинает осквернение часовни Сумраком в [AREACOORD(center)].")
	if(!simulated)
		message_admins("[key_name_admin(user)] начинает осквернение часовни Сумраком.")
		priority_announce("В часовне что-то происходит: вознёсшийся еретик Сумрака оскверняет святую землю. Прервите его: сильный удар или святая вода сорвут обряд.", "Часовня", 'sound/misc/notice1.ogg')
	. = do_after(user, HERETIC_DUSK_DESECRATE_TIME, target = user, timed_action_flags = IGNORE_HELD_ITEM, extra_checks = CALLBACK(src, PROC_REF(desecrate_holds)))
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMAGE)
	if(dusk)
		UnregisterSignal(dusk, COMSIG_HERETIC_DUSK_HOLY)
	desecrating = FALSE
	if(!. || desecrate_broken)
		desecrate_failure = "Осквернение сорвано: вас прервали ударом, святой водой или вы сошли с места."
		log_game("[key_name(user)]: осквернение часовни Сумраком сорвано.")
		return FALSE
	return finish_desecration(user)

/// Часовня осквернена до конца раунда: святой земли больше нет.
/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/finish_desecration(mob/living/user)
	if(GLOB.heretic_dusk_chapel_desecrated)
		return FALSE
	GLOB.heretic_dusk_chapel_desecrated = TRUE
	log_game("[key_name(user)] оскверняет часовню Сумраком в [AREACOORD(user)]: святой земли больше нет.")
	if(!simulated)
		message_admins("[key_name_admin(user)] осквернил часовню Сумраком.")
		priority_announce("Часовня осквернена: святой земли на станции больше нет. Святая вода, нулевой жезл и Библия жгут еретика Сумрака по-прежнему, но в часовне - как обычно.", "Часовня", 'sound/misc/notice2.ogg')
	return TRUE

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/desecrate_holds()
	return !desecrate_broken

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/on_desecrate_hurt(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(damage > HERETIC_DUSK_DESECRATE_BREAK)
		desecrate_broken = TRUE

/datum/eldritch_knowledge/final_eldritch/dusk_final/proc/on_desecrate_holy(datum/source, kind)
	SIGNAL_HANDLER
	desecrate_broken = TRUE

/datum/looping_sound/heretic_dusk_halo
	mid_sounds = list('modular_bluemoon/sound/heretic/dusk_halo_hum.ogg' = 1)
	mid_length = 6 SECONDS
	volume = 20
	extra_range = -4
	/// Носитель нимба слышит его весь финал, поэтому себе гул тише, чем окружающим.
	var/bearer_volume = 7

/datum/looping_sound/heretic_dusk_halo/play(soundfile, volume_override)
	var/mob/living/bearer = parent
	if(!istype(bearer))
		return ..()
	playsound(bearer, soundfile, volume, vary, extra_range, falloff_exponent = falloff_exponent, pressure_affected = pressure_affected, falloff_distance = falloff_distance, excluded_listeners = list(bearer))
	bearer.playsound_local(get_turf(bearer), soundfile, bearer_volume, vary, pressure_affected = FALSE)

/datum/looping_sound/heretic_dusk_sun
	mid_sounds = list('modular_bluemoon/sound/heretic/dusk_sun_hum.ogg' = 1)
	mid_length = 6 SECONDS
	volume = 40
	extra_range = -2

/proc/heretic_dusk_update_switches(area/place)
	place.update_appearance()
	for(var/obj/machinery/light_switch/light_switch in place)
		light_switch.update_appearance()

/obj/effect/proc_holder/spell/self/heretic_dusk/proc/dusk_finale(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/dusk_final)

/obj/effect/proc_holder/spell/self/heretic_dusk/noon
	name = "Полдень в полночь"
	desc = "Ангел раскрывает лик. Свет 1,5 секунды стекается к вам, затем каждый, кто стоит в 5 клетках и смотрит на вас, слепнет на 6 секунд; тёмные очки и сварочные маски защищают. У всех людей вокруг на 15 секунд гаснут фонарики и переносные огни. Перезарядка 45 секунд."
	summary = "Через 1,5 секунды смотрящие на вас в 5 клетках слепнут на 6 секунд, их фонарики гаснут на 15."
	charge_max = HERETIC_DUSK_NOON_COOLDOWN
	action_icon_state = "dusk_noon"

/obj/effect/proc_holder/spell/self/heretic_dusk/noon/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = dusk_finale(user)
	if(!finale)
		heretic_revert_cast(user)
		return
	finale.noon(user)
	if(finale.noon_failure)
		heretic_revert_cast(user, finale.noon_failure)

/obj/effect/proc_holder/spell/self/heretic_dusk/desecrate
	name = "Осквернение"
	desc = "Постойте 20 секунд в часовне: над вами переворачивается нимб, свет часовни мигает, станция узнаёт об этом. Урон больше 20 за один удар или святая вода срывают обряд. Успех оскверняет часовню до конца раунда: святая земля пропадает, нулевой жезл и Библия в ней работают как обычно. Один раз за раунд."
	summary = "20 секунд в часовне: удар больше 20 или святая вода срывают, успех снимает святость часовни."
	charge_max = 5 SECONDS
	holy_ground_allowed = TRUE
	action_icon_state = "dusk_desecrate"

/obj/effect/proc_holder/spell/self/heretic_dusk/desecrate/block_reason(mob/living/user)
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = dusk_finale(user)
	return finale ? finale.desecrate_block_reason(user) : "Способность недоступна вашему пути или текущему телу."

/obj/effect/proc_holder/spell/self/heretic_dusk/desecrate/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = dusk_finale(user)
	if(!finale?.desecrate(user))
		heretic_revert_cast(user, finale?.desecrate_failure)

/atom/movable/screen/alert/heretic_dusk_suns
	name = "Чёрные солнца"
	desc = "Пока стоит хоть одно Чёрное солнце, в их отсеках нет света, вы лечитесь от каждой отнятой тени и раз в 10 секунд шагаете в тень без заряда."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dusk_suns"

/// Кольцо-импульс Сумрака на кульминации и спаде завесы: пиксельное кольцо холодного золота, за ним летят перья.
/obj/effect/temp_visual/heretic_dusk_wave
	icon = 'modular_bluemoon/icons/effects/heretic_dusk_wave.dmi'
	icon_state = "dusk_wave"
	duration = 0.6 SECONDS
	pixel_x = -64
	pixel_y = -64
	layer = BELOW_MOB_LAYER
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/heretic_dusk_wave/Initialize(mapload)
	. = ..()
	add_overlay(emissive_appearance(icon, icon_state, offset_spokesman = src))

/// Чёрное солнце: перевёрнутый нимб над отсеком; пока стоит, свет там не вернётся.
/obj/structure/heretic_dusk_black_sun
	name = "black sun"
	desc = "Над полом висит тёмный диск в короне больного белого света - перевёрнутый нимб размером с человека. Под ним гаснут лампы, и выключатели их не зажигают. Его можно разбить: святая вода, нулевой жезл и Библия капеллана бьют его особенно сильно, обычное оружие тоже работает."
	icon = HERETIC_DUSK_FX_ICON
	icon_state = "dusk_black_sun"
	anchored = TRUE
	density = TRUE
	max_integrity = HERETIC_DUSK_SUN_INTEGRITY
	resistance_flags = FIRE_PROOF | LAVA_PROOF | ACID_PROOF
	var/datum/weakref/finale_ref
	var/area/night_area
	var/quiet_fall = FALSE
	var/datum/looping_sound/heretic_dusk_sun/humming
	/// Налёт скверны вокруг солнца Завета Скверны.
	var/list/datum/weakref/rot_decals = list()
	var/datum/weakref/rot_source
	var/rot_timer
	COOLDOWN_DECLARE(splash_gap)
	COOLDOWN_DECLARE(prayer_gap)

/obj/structure/heretic_dusk_black_sun/Initialize(mapload, datum/eldritch_knowledge/final_eldritch/dusk_final/finale, area/dark_area)
	. = ..()
	if(QDELETED(finale))
		return INITIALIZE_HINT_QDEL
	finale_ref = WEAKREF(finale)
	night_area = dark_area
	RegisterSignal(src, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))
	update_appearance()
	set_light(HERETIC_DUSK_SUN_LIGHT_RANGE, HERETIC_DUSK_SUN_LIGHT_POWER, HERETIC_DUSK_SUN_COLOR)
	heretic_dusk_sound(src, "sun_rise", 70, FALSE)
	humming = new(src, TRUE)

/obj/structure/heretic_dusk_black_sun/Destroy()
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = finale_ref?.resolve()
	finale?.sun_down(src, quiet_fall)
	finale_ref = null
	night_area = null
	QDEL_NULL(humming)
	deltimer(rot_timer)
	for(var/datum/weakref/decal_ref as anything in rot_decals)
		qdel(decal_ref.resolve())
	rot_decals.Cut()
	rot_source = null
	return ..()

/obj/structure/heretic_dusk_black_sun/proc/start_rot(datum/eldritch_knowledge/base_dusk/dusk)
	rot_source = WEAKREF(dusk)
	grow_rot()

/// Солнце Скверны раз в 20 секунд роняет вокруг себя пятно налёта, не больше восьми.
/obj/structure/heretic_dusk_black_sun/proc/grow_rot()
	rot_timer = null
	var/datum/eldritch_knowledge/base_dusk/dusk = rot_source?.resolve()
	if(!dusk)
		return null
	for(var/datum/weakref/decal_ref as anything in rot_decals.Copy())
		if(!decal_ref.resolve())
			rot_decals -= decal_ref
	var/obj/effect/decal/cleanable/heretic_dusk_rot/decal
	if(length(rot_decals) < HERETIC_DUSK_ROT_DECALS)
		var/list/turf/options = list()
		for(var/turf/open/spot in range(HERETIC_DUSK_ROT_DECAL_RANGE, src))
			if(spot != loc && !isgroundlessturf(spot) && !spot.is_blocked_turf(exclude_mobs = TRUE) && !(locate(/obj/effect/decal/cleanable/heretic_dusk_rot) in spot))
				options += spot
		if(length(options))
			decal = new(pick(options), null, dusk)
			if(!QDELETED(decal))
				rot_decals += WEAKREF(decal)
	rot_timer = addtimer(CALLBACK(src, PROC_REF(grow_rot)), HERETIC_DUSK_ROT_DECAL_PERIOD, TIMER_STOPPABLE)
	return decal

/obj/structure/heretic_dusk_black_sun/update_icon_state()
	icon_state = obj_integrity <= max_integrity / 2 ? "dusk_black_sun_cracked" : "dusk_black_sun"
	return ..()

/obj/structure/heretic_dusk_black_sun/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "dusk_black_sun_glow", offset_spokesman = src)

/obj/structure/heretic_dusk_black_sun/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = TRUE, attack_dir, armour_penetration = 0)
	. = ..()
	if(!QDELETED(src))
		update_appearance()

/obj/structure/heretic_dusk_black_sun/proc/on_exposed(atom/source, list/reagents, datum/reagents/holder, method, volume_modifier, show_message)
	SIGNAL_HANDLER
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water/holywater))
			holy_splash()
			return

/obj/structure/heretic_dusk_black_sun/proc/holy_splash()
	if(!COOLDOWN_FINISHED(src, splash_gap))
		return FALSE
	COOLDOWN_START(src, splash_gap, HERETIC_DUSK_SUN_SPLASH_GAP)
	visible_message(span_notice("Святая вода шипит на [src], и корона света вокруг диска дымится."))
	heretic_dusk_sound(src, "sun_crack", 55, TRUE)
	INVOKE_ASYNC(src, TYPE_PROC_REF(/obj, take_damage), HERETIC_DUSK_SUN_HOLY_DAMAGE, BURN, MAGIC, FALSE)
	return TRUE

/obj/structure/heretic_dusk_black_sun/attackby(obj/item/item, mob/living/user, params)
	if(istype(item, /obj/item/nullrod))
		user.do_attack_animation(src)
		user.changeNext_move(CLICK_CD_MELEE)
		visible_message(span_warning("[user] бьёт [src] нулевым жезлом, и по диску бежит трещина."))
		heretic_dusk_sound(src, "sun_crack", 60, TRUE)
		take_damage(max_integrity / 2, BRUTE, MELEE, FALSE)
		return TRUE
	if(istype(item, /obj/item/storage/book/bible) && user.mind?.isholy)
		user.do_attack_animation(src)
		user.changeNext_move(CLICK_CD_MELEE)
		if(!COOLDOWN_FINISHED(src, prayer_gap))
			to_chat(user, span_warning("Молитва ещё не собралась: подождите [heretic_capture_seconds_left(prayer_gap)] с."))
			return TRUE
		COOLDOWN_START(src, prayer_gap, HERETIC_DUSK_SUN_PRAYER_COOLDOWN)
		visible_message(span_warning("[user] читает молитву над [src], и корона света вокруг диска меркнет."))
		heretic_dusk_sound(src, "sun_crack", 60, TRUE)
		take_damage(HERETIC_DUSK_SUN_PRAYER_DAMAGE, BURN, MAGIC, FALSE)
		return TRUE
	return ..()

/obj/structure/heretic_dusk_black_sun/deconstruct(disassembled = TRUE)
	var/turf/place = get_turf(src)
	if(place && !quiet_fall)
		visible_message(span_danger("[src] раскалывается, и корона света осыпается звенящими осколками."))
		new /obj/effect/temp_visual/heretic_dusk/sun_broken(place)
		heretic_dusk_sound(place, "sun_break", 70, TRUE)
	return ..()

/obj/structure/heretic_dusk_black_sun/examine(mob/user)
	. = ..()
	. += span_warning("Прочность: [round(obj_integrity / max_integrity * 100)]%. Святая вода снимает [HERETIC_DUSK_SUN_HOLY_DAMAGE], нулевой жезл раскалывает за два удара, Библия капеллана - [HERETIC_DUSK_SUN_PRAYER_DAMAGE] раз в [HERETIC_DUSK_SUN_PRAYER_COOLDOWN / (1 SECONDS)] секунд.")
	if(rot_source)
		. += span_warning("Корона гниёт, и вокруг диска расползается зелёный налёт скверны: наступивший заражается. Налёт смывают очиститель, швабра и святая вода; разбитое солнце забирает его с собой.")

#undef HERETIC_DUSK_NIGHT_STEP
#undef HERETIC_DUSK_NIGHT_LAMPS_PER_STEP
#undef HERETIC_DUSK_SUN_TRAINING_RANGE
#undef HERETIC_DUSK_SUN_SPLASH_GAP
#undef HERETIC_DUSK_SUN_LIGHT_RANGE
#undef HERETIC_DUSK_SUN_LIGHT_POWER
#undef HERETIC_DUSK_SUN_COLOR
#undef HERETIC_DUSK_NIGHT_PULSE
#undef HERETIC_DUSK_SUN_VIGNETTE_RANGE
