#define HERETIC_HAMMER_ANVIL_DOUSE_GAP (1.5 SECONDS)
#define HERETIC_HAMMER_DEAD_ANVIL_CRUMBLE (60 SECONDS)
#define HERETIC_HAMMER_ANVIL_ATTEMPTS 30
#define HERETIC_HAMMER_ANVIL_TRAINING_RANGE 4
#define HERETIC_HAMMER_ANVIL_LIGHT_RANGE 3
#define HERETIC_HAMMER_ANVIL_LIGHT_POWER 1.2

/datum/eldritch_knowledge/final_eldritch/hammer_final
	name = "Последний удар"
	summary = "Великий Молот и 3 Раскалённые наковальни: пока стоят, вы лечитесь, а раз в 90 секунд станцию бьёт Набат."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне станции; станция узнаёт место обряда.",
		"Молот становится Великим: в двух руках удар бьёт соседей цели на 12 и отбрасывает их, мехи и борги - вчетверо.",
		"Пока Великий Молот в двух руках, снаряды ранят вас на 50% слабее, со стойкой - на 60%; Накал копится до 12 и не стынет.",
		"В 3 общих отсеках падают Раскалённые наковальни; станции объявят, где они. Со смертью вознёсшегося они гаснут.",
		"Пока стоит хоть одна наковальня, с Молотом в двух руках вы лечите 2 ушиба в секунду.",
		"Раз в 90 секунд Набат: экипаж на этаже наковальни чувствует удар молота по станции.",
		"Горячую наковальню не разбить, касание обжигает; 3 струи воды или пены или ведро воды её остужают, затем 200 прочности.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Я поднял Молот, и станция подо мной зазвенела, как заготовка. Теперь я знаю, что из неё выкую."
	route = PATH_HAMMER
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	var/list/obj/structure/heretic_hammer_hot_anvil/hot_anvils = list()
	var/anvils_raised = FALSE
	var/anvils_spent = FALSE
	var/toll_timer

/datum/eldritch_knowledge/final_eldritch/hammer_final/proc/hammer_of(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_hammer)

/datum/eldritch_knowledge/final_eldritch/hammer_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	. = ..()
	if(!.)
		return
	forge_great(user)
	raise_anvils(user)

/datum/eldritch_knowledge/final_eldritch/hammer_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	if(hammer)
		hammer.ascension_active = TRUE
		hammer.anvils_hot = standing_anvils() > 0
		hammer.gain_combat_resource(0)
	update_anvil_alert()

/datum/eldritch_knowledge/final_eldritch/hammer_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(body)
	if(hammer)
		hammer.ascension_active = FALSE
		hammer.anvils_hot = FALSE
		hammer.gain_combat_resource(0)
	body?.clear_alert(HERETIC_HAMMER_ANVIL_ALERT)
	return ..()

/datum/eldritch_knowledge/final_eldritch/hammer_final/on_life(mob/user)
	. = ..()
	var/mob/living/body = user
	if(!finished || applied_body != body || body.stat == DEAD || !standing_anvils() || !heretic_hammer_held(body, TRUE))
		return
	if(body.getBruteLoss() > 0)
		body.adjustBruteLoss(-HERETIC_HAMMER_HOT_ANVIL_HEAL * SSprocessing.wait / (1 SECONDS))

/datum/eldritch_knowledge/final_eldritch/hammer_final/on_death(mob/user)
	. = ..()
	if(anvils_raised && !anvils_spent)
		cool_anvils()

/datum/eldritch_knowledge/final_eldritch/hammer_final/on_lose(mob/user)
	. = ..()
	clear_anvils()

/datum/eldritch_knowledge/final_eldritch/hammer_final/Destroy()
	clear_anvils()
	return ..()

/datum/eldritch_knowledge/final_eldritch/hammer_final/on_ascended_body_deleted(mob/living/source)
	. = ..()
	if(anvils_raised && !anvils_spent)
		INVOKE_ASYNC(src, PROC_REF(cool_anvils))

/datum/eldritch_knowledge/final_eldritch/hammer_final/on_ascended_examine(datum/source, mob/examiner, list/examine_list)
	. = ..()
	var/standing = standing_anvils()
	if(standing)
		examine_list += span_warning("Где-то на станции стоят Раскалённые наковальни ([standing]): пока стоит хоть одна, его раны затягиваются окалиной. Остудите их водой или пеной и разбейте.")

/datum/eldritch_knowledge/final_eldritch/hammer_final/proc/standing_anvils()
	return anvils_spent ? 0 : length(hot_anvils)

/// Все Молоты при еретике становятся Великими; нет ни одного - кузня даёт новый.
/datum/eldritch_knowledge/final_eldritch/hammer_final/proc/forge_great(mob/living/user)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	if(!hammer)
		return null
	var/obj/item/melee/sickly_blade/hammer/great/forged
	for(var/obj/item/melee/sickly_blade/hammer/old in user.GetAllContents())
		if(old.great)
			forged = old
			continue
		var/atom/holder = old.loc
		var/was_held = user.is_holding(old)
		var/slot = (holder == user && !was_held) ? old.current_equipped_slot : null
		qdel(old)
		forged = new(get_turf(user))
		hammer.track_blade(forged, user)
		if(was_held)
			user.put_in_hands(forged)
		else if(slot)
			user.equip_to_slot_if_possible(forged, slot, disable_warning = TRUE)
		else if(holder != user && !QDELETED(holder))
			SEND_SIGNAL(holder, COMSIG_TRY_STORAGE_INSERT, forged, user, TRUE, TRUE)
		if(isturf(forged.loc) && !user.put_in_hands(forged))
			to_chat(user, span_warning("Руки заняты: Великий Молот лёг у ваших ног."))
	if(!forged)
		forged = new(get_turf(user))
		hammer.track_blade(forged, user)
		user.put_in_hands(forged)
	heretic_vfx_burst(user, /particles/heretic_ascension/hammer)
	to_chat(user, span_eldritch("Молот в руках раскаляется добела и тяжелеет: теперь это Великий Молот."))
	return forged

/// Вознесение роняет Раскалённые наковальни в общие отсеки станции.
/datum/eldritch_knowledge/final_eldritch/hammer_final/proc/raise_anvils(mob/living/user)
	if(anvils_raised)
		return FALSE
	anvils_raised = TRUE
	var/list/area_names = list()
	var/list/spots = anvil_spots(user)
	for(var/turf/spot as anything in spots)
		hot_anvils += new /obj/structure/heretic_hammer_hot_anvil(spot, src)
		area_names += spots[spot]
	if(!length(hot_anvils))
		anvils_spent = TRUE
		log_game("[key_name(user)]: Раскалённым наковальням Молота не нашлось места.")
		return FALSE
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	hammer?.anvils_hot = TRUE
	hammer?.notify_resource_changed()
	toll_timer = addtimer(CALLBACK(src, PROC_REF(toll)), HERETIC_HAMMER_TOLL_PERIOD, TIMER_STOPPABLE)
	update_anvil_alert()
	var/where = english_list(area_names)
	log_game("[key_name(user)] роняет Раскалённые наковальни Молота: [where].")
	to_chat(user, span_eldritch("Раскалённые наковальни упали: [where]. Пока стоит хоть одна, вы лечитесь с Молотом в двух руках, а станцию раз в [HERETIC_HAMMER_TOLL_PERIOD / (1 SECONDS)] секунд бьёт Набат."))
	if(!simulated)
		message_admins("[key_name_admin(user)] роняет Раскалённые наковальни Молота: [where].")
		priority_announce("Вознёсшийся еретик Молота обрушил на станцию Раскалённые наковальни: [where]. Пока стоит хоть одна, его раны затягиваются, а раз в [HERETIC_HAMMER_TOLL_PERIOD / (1 SECONDS)] секунд станцию сотрясает Набат. Горячую наковальню не разбить, а касание обжигает: остудите каждую [HERETIC_HAMMER_HOT_ANVIL_DOUSES] струями воды или пены из огнетушителя или ведром воды, затем разбейте.", "Раскалённые наковальни", 'sound/misc/notice1.ogg')
	return TRUE

/datum/eldritch_knowledge/final_eldritch/hammer_final/proc/anvil_spots(mob/living/user)
	. = list()
	var/turf/origin = get_turf(user)
	var/training = istype(get_area(origin), /area/antag_training)
	var/list/turf/nearby = list()
	if(training)
		for(var/turf/open/place in range(HERETIC_HAMMER_ANVIL_TRAINING_RANGE, origin))
			if(get_dist(place, origin) > 1)
				nearby += place
	var/list/area/used = list()
	for(var/attempt in 1 to HERETIC_HAMMER_ANVIL_ATTEMPTS)
		if(length(.) >= HERETIC_HAMMER_HOT_ANVILS)
			break
		var/turf/place = training ? (length(nearby) ? pick_n_take(nearby) : null) : (find_heretic_hallway_turf() || find_heretic_station_turf(for_escape = TRUE))
		if(!anvil_spot_valid(place, training, .))
			continue
		var/area/place_area = get_area(place)
		if(!training && (place_area in used) && attempt <= HERETIC_HAMMER_ANVIL_ATTEMPTS / 2)
			continue
		.[place] = get_area_name(place, TRUE)
		used |= place_area

/// Наковальня не встаёт вплотную к другой, у двери и в проходе шириной в клетку: рядом должно остаться 3 свободных стороны.
/datum/eldritch_knowledge/final_eldritch/hammer_final/proc/anvil_spot_valid(turf/place, training, list/chosen)
	var/area/place_area = get_area(place)
	if(!isopenturf(place) || isgroundlessturf(place) || !place_area || (place_area.area_flags & NOTELEPORT) || place.is_blocked_turf(exclude_mobs = TRUE))
		return FALSE
	if((locate(/obj/structure/heretic_hammer_hot_anvil) in range(1, place)) || (locate(/obj/machinery/door) in range(1, place)))
		return FALSE
	for(var/turf/other as anything in chosen)
		if(get_dist(other, place) <= 1)
			return FALSE
	var/free_sides = 0
	for(var/direction in GLOB.cardinals)
		var/turf/side = get_step(place, direction)
		if(isopenturf(side) && !isgroundlessturf(side) && !side.is_blocked_turf(exclude_mobs = TRUE))
			free_sides++
	if(free_sides < 3)
		return FALSE
	return training ? istype(place_area, /area/antag_training) : (is_station_level(place.z) && heretic_station_public_area(place_area))

/// Набат: экипаж на этажах наковальни чувствует удар молота по станции.
/datum/eldritch_knowledge/final_eldritch/hammer_final/proc/toll()
	toll_timer = null
	if(anvils_spent || !length(hot_anvils))
		return
	var/list/levels = list()
	for(var/obj/structure/heretic_hammer_hot_anvil/anvil as anything in hot_anvils)
		levels |= anvil.z
	var/sound_file = heretic_hammer_sound(null, "toll", 0)
	for(var/mob/living/listener in GLOB.player_list)
		if(listener == applied_body || !(listener.z in levels) || listener.stat == DEAD)
			continue
		shake_camera(listener, 2, 1)
		listener.playsound_local(get_turf(listener), sound_file, 40, FALSE)
		to_chat(listener, span_warning("Пол вздрагивает: станцию бьёт молот. Где-то рядом гудит Раскалённая наковальня."))
	log_game("Набат Молота: этажей [length(levels)], наковален [length(hot_anvils)].")
	toll_timer = addtimer(CALLBACK(src, PROC_REF(toll)), HERETIC_HAMMER_TOLL_PERIOD, TIMER_STOPPABLE)

/// Наковальня остыла или разбита; how = null - тихо.
/datum/eldritch_knowledge/final_eldritch/hammer_final/proc/anvil_changed(obj/structure/heretic_hammer_hot_anvil/anvil, how)
	if(!how)
		return
	if(anvils_spent)
		log_game("Остывшая наковальня Молота [how] в [AREACOORD(anvil)], осталось [length(hot_anvils)].")
		return
	var/left = standing_anvils()
	log_game("Раскалённая наковальня Молота [how] в [AREACOORD(anvil)], стоит ещё [left].")
	if(applied_body)
		to_chat(applied_body, span_userdanger((left ? "Раскалённая наковальня в [get_area_name(anvil, TRUE)] [how]. Стоит ещё: [left]." : "Последняя Раскалённая наковальня [how]: кузня больше не лечит вас.")))
	update_anvil_alert()
	if(!left)
		anvils_broken()

/datum/eldritch_knowledge/final_eldritch/hammer_final/proc/anvils_broken(by_death = FALSE)
	if(anvils_spent)
		return FALSE
	anvils_spent = TRUE
	deltimer(toll_timer)
	toll_timer = null
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(applied_body)
	if(hammer)
		hammer.anvils_hot = FALSE
		hammer.notify_resource_changed()
	update_anvil_alert()
	log_game("Раскалённые наковальни Молота пали[by_death ? " со смертью вознёсшегося" : ": экипаж разбил последнюю"].")
	if(simulated)
		return TRUE
	message_admins("Раскалённые наковальни Молота пали[by_death ? " со смертью вознёсшегося" : ": экипаж разбил последнюю"].")
	priority_announce(by_death ? "Раскалённые наковальни остыли вместе с вознёсшимся еретиком Молота." : "Последняя Раскалённая наковальня разбита. Набат стих, а раны вознёсшегося еретика Молота больше не затягиваются сами.", "Раскалённые наковальни пали", 'sound/misc/notice2.ogg')
	return TRUE

/datum/eldritch_knowledge/final_eldritch/hammer_final/proc/cool_anvils()
	anvils_broken(by_death = TRUE)
	for(var/obj/structure/heretic_hammer_hot_anvil/anvil as anything in hot_anvils)
		anvil.forge_died()

/datum/eldritch_knowledge/final_eldritch/hammer_final/proc/clear_anvils()
	deltimer(toll_timer)
	toll_timer = null
	for(var/obj/structure/heretic_hammer_hot_anvil/anvil as anything in hot_anvils.Copy())
		anvil.finale_ref = null
		qdel(anvil)
	hot_anvils.Cut()

/datum/eldritch_knowledge/final_eldritch/hammer_final/proc/update_anvil_alert()
	var/mob/living/body = applied_body
	if(!body)
		return
	var/standing = standing_anvils()
	if(!standing)
		body.clear_alert(HERETIC_HAMMER_ANVIL_ALERT)
		return
	var/atom/movable/screen/alert/heretic_hammer_anvils/alert = body.throw_alert(HERETIC_HAMMER_ANVIL_ALERT, /atom/movable/screen/alert/heretic_hammer_anvils)
	alert?.desc = "Раскалённых наковален стоит: [standing]. Пока стоит хоть одна, вы лечите ушибы по [HERETIC_HAMMER_HOT_ANVIL_HEAL] в секунду с Молотом в двух руках, а раз в [HERETIC_HAMMER_TOLL_PERIOD / (1 SECONDS)] секунд станцию бьёт Набат. Экипаж остужает их водой и пеной и разбивает."

/datum/eldritch_knowledge/base_hammer/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!ascension_active)
		return ..()
	var/limit_reason = blade_limit_reason(user)
	if(limit_reason)
		finish_failure_reason = limit_reason
		return FALSE
	track_blade(new /obj/item/melee/sickly_blade/hammer/great(loc), user)
	return TRUE

/obj/item/melee/sickly_blade/hammer/great
	name = "great hammer of the last blow"
	desc = "Огромный молот, раскалённый добела: по бойку бегут огненные швы, от рукояти пышет жаром горна. Каждый удар им отдаётся гулом в стенах."
	icon_state = "hammer_great"
	item_state = "hammer_great"
	base_state = "hammer_great"
	wielded_state = null
	great = TRUE

/atom/movable/screen/alert/heretic_hammer_anvils
	name = "Раскалённые наковальни"
	desc = "Пока стоит хоть одна Раскалённая наковальня, вы лечитесь с Молотом в двух руках, а станцию раз в 90 секунд бьёт Набат."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "hammer_anvils"

/datum/looping_sound/heretic_hammer_anvil
	mid_sounds = list('modular_bluemoon/sound/heretic/hammer_heat.ogg' = 1)
	mid_length = 4 SECONDS
	volume = 25
	extra_range = -5

/// Раскалённая наковальня вознесения: горячую не разбить, вода и пена остужают, затем её разбивают.
/obj/structure/heretic_hammer_hot_anvil
	name = "white-hot anvil"
	desc = "Огромная наковальня, раскалённая докрасна, вросла в палубу. Воздух над ней дрожит от жара, а изнутри доносится далёкий звон. Пока стоит хоть одна такая, вознёсшийся еретик Молота залечивает раны, а станцию раз в 90 секунд бьёт Набат. Горячую её не разбить, а касание обжигает: остудите тремя струями воды или пены из огнетушителя или ведром воды, затем разбейте."
	icon = HERETIC_HAMMER_LARGE_ICON
	icon_state = "hot_anvil"
	pixel_x = -16
	anchored = TRUE
	density = TRUE
	max_integrity = HERETIC_HAMMER_HOT_ANVIL_INTEGRITY
	resistance_flags = FIRE_PROOF | LAVA_PROOF | ACID_PROOF
	var/hot = TRUE
	var/douses = 0
	/// Вознёсшийся погиб: остывшая наковальня скоро рассыпется.
	var/forge_dead = FALSE
	/// Что стало с наковальней, для логов: разбита или рассыпалась.
	var/fate = "разбита"
	var/datum/weakref/finale_ref
	var/datum/looping_sound/heretic_hammer_anvil/hum
	COOLDOWN_DECLARE(douse_gap)

/obj/structure/heretic_hammer_hot_anvil/Initialize(mapload, datum/eldritch_knowledge/final_eldritch/hammer_final/finale)
	. = ..()
	if(QDELETED(finale))
		return INITIALIZE_HINT_QDEL
	finale_ref = WEAKREF(finale)
	RegisterSignal(src, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))
	hum = new(src, TRUE)
	update_anvil()
	heretic_hammer_sound(src, "hot_anvil_land", 80, TRUE, 4)
	new /obj/effect/temp_visual/heretic_hammer/great_shockwave(loc)
	heretic_vfx_burst(src, /particles/heretic_ascension/hammer)
	heretic_vfx_flash(src, LIGHT_COLOR_FIRE, HERETIC_HAMMER_ANVIL_LIGHT_RANGE, HERETIC_HAMMER_ANVIL_LIGHT_POWER * 2)
	for(var/mob/living/nearby in range(1, src))
		shake_camera(nearby, 3, 2)

/obj/structure/heretic_hammer_hot_anvil/Destroy()
	var/datum/eldritch_knowledge/final_eldritch/hammer_final/finale = finale_ref?.resolve()
	finale_ref = null
	QDEL_NULL(hum)
	if(finale)
		finale.hot_anvils -= src
		finale.anvil_changed(src, fate)
	return ..()

/obj/structure/heretic_hammer_hot_anvil/proc/update_anvil()
	cut_overlays()
	icon_state = hot ? "hot_anvil" : "hot_anvil_quenched"
	if(hot)
		name = initial(name)
		desc = "Огромная наковальня, раскалённая докрасна, вросла в палубу. Воздух над ней дрожит от жара, а изнутри доносится далёкий звон. Пока стоит хоть одна такая, вознёсшийся еретик Молота залечивает раны, а станцию раз в [HERETIC_HAMMER_TOLL_PERIOD / (1 SECONDS)] секунд бьёт Набат. Горячую её не разбить, а касание обжигает: остудите [HERETIC_HAMMER_HOT_ANVIL_DOUSES] струями воды или пены из огнетушителя или ведром воды, затем разбейте."
		set_light(HERETIC_HAMMER_ANVIL_LIGHT_RANGE, HERETIC_HAMMER_ANVIL_LIGHT_POWER * (HERETIC_HAMMER_HOT_ANVIL_DOUSES - douses) / HERETIC_HAMMER_HOT_ANVIL_DOUSES, LIGHT_COLOR_FIRE)
		return
	name = "cooled anvil"
	desc = forge_dead ? "Почерневшая наковальня, вросшая в палубу. Кузня за ней погасла, это просто железо: скоро она рассыпется окалиной." : "Почерневшая наковальня, вросшая в палубу: вода остудила её, и теперь её можно разбить."
	set_light(0)

/// Наковальня остыла: теперь её можно разбить; how - для еретика и логов, null - тихо.
/obj/structure/heretic_hammer_hot_anvil/proc/quench(how)
	if(!hot)
		return FALSE
	hot = FALSE
	QDEL_NULL(hum)
	update_anvil()
	heretic_vfx_burst(src, /particles/heretic_ascension/steam)
	if(how)
		visible_message(span_notice("[src] с шипением чернеет и остывает: теперь её можно разбить."))
		heretic_hammer_sound(src, "quench", 60, TRUE)
		var/datum/eldritch_knowledge/final_eldritch/hammer_final/finale = finale_ref?.resolve()
		finale?.anvil_changed(src, how)
	return TRUE

/// Вознёсшийся погиб: наковальня гаснет молча и через минуту рассыпается.
/obj/structure/heretic_hammer_hot_anvil/proc/forge_died()
	if(forge_dead)
		return
	forge_dead = TRUE
	if(!quench(null))
		update_anvil()
	addtimer(CALLBACK(src, PROC_REF(crumble)), HERETIC_HAMMER_DEAD_ANVIL_CRUMBLE)

/obj/structure/heretic_hammer_hot_anvil/proc/crumble()
	visible_message(span_notice("[src] рассыпается грудой окалины."))
	fate = "рассыпалась"
	qdel(src)

/obj/structure/heretic_hammer_hot_anvil/proc/on_exposed(atom/source, list/reagents, datum/reagents/holder, method, volume_modifier, show_message, from_gas)
	SIGNAL_HANDLER
	if(!hot || from_gas)
		return
	var/water = 0
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water) || istype(reagent, /datum/reagent/firefighting_foam))
			water += reagent.volume * (volume_modifier || 1)
	if(water <= 0)
		return
	if(water >= HERETIC_HAMMER_HOT_ANVIL_BUCKET)
		douses = HERETIC_HAMMER_HOT_ANVIL_DOUSES
		quench("остужена")
		return
	douse()

/// Струя воды или пены: третья остужает наковальню; брызги одной струи считаются за одну.
/obj/structure/heretic_hammer_hot_anvil/proc/douse(ignore_gap = FALSE)
	if(!hot || (!ignore_gap && !COOLDOWN_FINISHED(src, douse_gap)))
		return FALSE
	COOLDOWN_START(src, douse_gap, HERETIC_HAMMER_ANVIL_DOUSE_GAP)
	douses++
	heretic_vfx_burst(src, /particles/heretic_ascension/steam)
	heretic_hammer_sound(src, "quench", 50, TRUE)
	var/left = HERETIC_HAMMER_HOT_ANVIL_DOUSES - douses
	if(left > 0)
		update_anvil()
		visible_message(span_notice("[src] шипит и окутывается паром, металл темнеет. Ещё струй до остывания: [left]."))
		return TRUE
	quench("остужена")
	return TRUE

/obj/structure/heretic_hammer_hot_anvil/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir, armour_penetration = 0)
	if(hot)
		return 0
	return ..()

/// Взрыв горячую наковальню не разбивает: жар сбивает, как одна струя.
/obj/structure/heretic_hammer_hot_anvil/ex_act(severity, target, origin)
	if(!hot)
		return ..()
	douse(ignore_gap = TRUE)

/obj/structure/heretic_hammer_hot_anvil/wave_ex_act(power, datum/wave_explosion/explosion, dir)
	if(!hot)
		return ..()
	douse(ignore_gap = TRUE)
	return power

/obj/structure/heretic_hammer_hot_anvil/attackby(obj/item/item, mob/living/user, params)
	if(hot && !(IS_HERETIC(user) || IS_HERETIC_MONSTER(user)) && !istype(item, /obj/item/reagent_containers) && !istype(item, /obj/item/extinguisher))
		to_chat(user, span_warning("[item] отскакивает от раскалённого металла: горячую наковальню не разбить."))
	return ..()

/obj/structure/heretic_hammer_hot_anvil/attack_hand(mob/living/user, act_intent, attackchain_flags)
	. = ..()
	if(. || !hot || !istype(user) || IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return
	user.apply_damage(HERETIC_HAMMER_HOT_ANVIL_BURN, BURN, (user.active_hand_index % 2) ? BODY_ZONE_L_ARM : BODY_ZONE_R_ARM)
	to_chat(user, span_userdanger("Вы касаетесь раскалённой наковальни и отдёргиваете обожжённую руку!"))
	return TRUE

/obj/structure/heretic_hammer_hot_anvil/deconstruct(disassembled = TRUE)
	var/turf/place = get_turf(src)
	if(place)
		visible_message(span_danger("[src] раскалывается пополам и осыпается окалиной."))
		heretic_hammer_sound(place, "anvil_break", 70, TRUE)
		new /obj/effect/temp_visual/heretic_hammer/anvil_land(place)
	return ..()

/obj/structure/heretic_hammer_hot_anvil/examine(mob/user)
	. = ..()
	if(!hot)
		. += span_notice("Наковальня остыла: теперь её можно разбить. Прочность: [round(obj_integrity / max_integrity * 100)]%.")
		return
	. += span_warning("Металл раскалён. До остывания струй воды или пены: [HERETIC_HAMMER_HOT_ANVIL_DOUSES - douses]; ведро воды остудит сразу.")

#undef HERETIC_HAMMER_ANVIL_DOUSE_GAP
#undef HERETIC_HAMMER_DEAD_ANVIL_CRUMBLE
#undef HERETIC_HAMMER_ANVIL_ATTEMPTS
#undef HERETIC_HAMMER_ANVIL_TRAINING_RANGE
#undef HERETIC_HAMMER_ANVIL_LIGHT_RANGE
#undef HERETIC_HAMMER_ANVIL_LIGHT_POWER
