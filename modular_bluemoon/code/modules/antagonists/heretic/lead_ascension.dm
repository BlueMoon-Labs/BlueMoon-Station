#define HERETIC_LEAD_CRUCIBLE_DOUSE_GAP (1 SECONDS)
#define HERETIC_LEAD_CRUCIBLE_ATTEMPTS 20
#define HERETIC_LEAD_CRUCIBLE_TRAINING_RANGE 4
#define HERETIC_LEAD_CRUCIBLE_SEARCH_RANGE 10
#define HERETIC_LEAD_CRUCIBLE_LIGHT_RANGE 3
#define HERETIC_LEAD_CRUCIBLE_LIGHT_POWER 1
#define HERETIC_LEAD_CRUCIBLE_BROKEN_TIME (4 SECONDS)
#define HERETIC_LEAD_MISFIRE_MEMORY 8
#define HERETIC_LEAD_SHOT_NOTICE (5 SECONDS)

/datum/eldritch_knowledge/base_lead
	/// Клетки осечек заговорённого оружия на станции, новейшая последней: на них вознесение ставит тигли.
	var/list/turf/misfire_spots = list()

/datum/eldritch_knowledge/base_lead/proc/record_misfire_spot(turf/place)
	if(!isturf(place) || !is_station_level(place.z))
		return
	misfire_spots -= place
	misfire_spots += place
	if(length(misfire_spots) > HERETIC_LEAD_MISFIRE_MEMORY)
		misfire_spots.Cut(1, 2)

/datum/eldritch_knowledge/base_lead/proc/lead_finale()
	var/datum/antagonist/heretic/heretic = owner_heretic()
	return heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/lead_final)

/// Выстрел Шестизарядника бесплатен, пока вознёсшийся в своём теле и горит хоть один тигель.
/datum/eldritch_knowledge/base_lead/proc/crucible_shot()
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = lead_finale()
	return ascension_active && lead_body && finale?.applied_body == lead_body && finale.lit_crucibles() > 0

/datum/eldritch_knowledge/base_lead/proc/crucible_state()
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = lead_finale()
	if(!finale?.crucibles_raised)
		return ""
	return " Литейных тиглей горит: [finale.lit_crucibles()]."

/datum/eldritch_knowledge/final_eldritch/lead_final
	var/list/obj/structure/heretic_lead_crucible/crucibles = list()
	var/crucibles_raised = FALSE
	var/crucibles_spent = FALSE
	var/datum/weakref/last_shooter
	var/turf/last_shot_turf
	var/last_shot_at = 0
	var/to_shot_failure
	var/volley_failure
	var/volley_timer
	COOLDOWN_DECLARE(shot_notice)

/datum/eldritch_knowledge/final_eldritch/lead_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	. = ..()
	if(.)
		raise_crucibles(user)

/datum/eldritch_knowledge/final_eldritch/lead_final/on_death(mob/user)
	. = ..()
	if(crucibles_raised && !crucibles_spent)
		cool_crucibles()

/datum/eldritch_knowledge/final_eldritch/lead_final/on_lose(mob/user)
	. = ..()
	clear_crucibles()

/datum/eldritch_knowledge/final_eldritch/lead_final/on_ascended_body_deleted(mob/living/source)
	. = ..()
	if(crucibles_raised && !crucibles_spent)
		INVOKE_ASYNC(src, PROC_REF(cool_crucibles))

/datum/eldritch_knowledge/final_eldritch/lead_final/on_ascended_examine(datum/source, mob/examiner, list/examine_list)
	. = ..()
	var/lit = lit_crucibles()
	if(lit)
		examine_list += span_warning("Он слышит каждый взведённый курок станции: пока горят Литейные тигли ([lit]), он приходит на любой выстрел из огнестрела. Тушите тигли водой или пеной, разбивайте их и стреляйте лазерами.")

/datum/eldritch_knowledge/final_eldritch/lead_final/proc/lead_of(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)

/datum/eldritch_knowledge/final_eldritch/lead_final/proc/lit_crucibles()
	. = 0
	for(var/obj/structure/heretic_lead_crucible/crucible as anything in crucibles)
		if(crucible.lit)
			.++

/// Вознесение ставит Литейные тигли в общих местах станции: сначала у мест осечек заговорённого оружия, остальные - в коридорах.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/raise_crucibles(mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(crucibles_raised || !lead)
		return FALSE
	crucibles_raised = TRUE
	var/list/area_names = list()
	var/list/spots = crucible_spots(user, lead)
	for(var/turf/spot as anything in spots)
		crucibles += new /obj/structure/heretic_lead_crucible(spot, src)
		area_names += spots[spot]
	if(!length(crucibles))
		crucibles_spent = TRUE
		log_game("[key_name(user)]: Литейным тиглям Свинца не нашлось места.")
		return FALSE
	RegisterSignal(SSdcs, COMSIG_GLOB_GUN_FIRED, PROC_REF(on_gunshot))
	stop_drum()
	drum_timer = addtimer(CALLBACK(src, PROC_REF(drum_beat)), HERETIC_LEAD_DRUM_PERIOD, TIMER_STOPPABLE)
	update_crucible_alert()
	var/where = english_list(area_names)
	log_game("[key_name(user)] ставит Литейные тигли Свинца: [where].")
	to_chat(user, span_eldritch("Литейные тигли встали: [where]. Пока горит хоть один, вы слышите выстрелы из огнестрела на станции, «На выстрел» переносит к стрелку, а Шестизарядник не тратит Свинец."))
	if(!simulated)
		message_admins("[key_name_admin(user)] ставит Литейные тигли Свинца: [where].")
		priority_announce("Вознёсшийся еретик Свинца поставил Литейные тигли: [where]. Пока горит хоть один, он слышит каждый выстрел из огнестрела на станции и за секунду приходит к стрелку, а его револьвер стреляет без счёта. Раз в минуту бьёт далёкий барабан: каждый третий удар заряжает револьвер Последним патроном - пуля сквозь двоих после красной линии и прицела на груди. Остудите тигли водой или пеной из огнетушителя, по [HERETIC_LEAD_CRUCIBLE_DOUSES] струи на каждый, или разбейте их; нулевой жезл раскалывает тигель за два удара. Лазеры его не зовут.", "Литейные тигли", 'sound/misc/notice1.ogg')
	return TRUE

/// Клетка тигля => как её назвать станции: тигель у осечки в закрытом отсеке встаёт в ближайшем общем коридоре, и объявление называет этот отсек.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/crucible_spots(mob/living/user, datum/eldritch_knowledge/base_lead/lead)
	. = list()
	var/turf/origin = get_turf(user)
	var/training = istype(get_area(origin), /area/antag_training)
	var/list/area/used = list()
	if(!training)
		for(var/index in length(lead.misfire_spots) to 1 step -1)
			if(length(.) >= HERETIC_LEAD_CRUCIBLES)
				break
			var/turf/misfire = lead.misfire_spots[index]
			var/turf/place = crucible_landing(misfire, training)
			var/area/place_area = get_area(place)
			if(place && !(place_area in used) && !(place in .))
				var/area/misfire_area = get_area(misfire)
				.[place] = misfire_area == place_area ? get_area_name(place, TRUE) : "[get_area_name(place, TRUE)] у отсека [get_area_name(misfire, TRUE)]"
				used += place_area
	var/list/turf/nearby = list()
	if(training)
		for(var/turf/open/place in range(HERETIC_LEAD_CRUCIBLE_TRAINING_RANGE, origin))
			if(get_dist(place, origin) > 1)
				nearby += place
	for(var/attempt in 1 to HERETIC_LEAD_CRUCIBLE_ATTEMPTS)
		if(length(.) >= HERETIC_LEAD_CRUCIBLES)
			break
		var/turf/place = training ? (length(nearby) ? pick_n_take(nearby) : null) : (find_heretic_hallway_turf() || find_heretic_station_turf(for_escape = TRUE))
		place = crucible_landing(place, training)
		if(!place || (place in .))
			continue
		var/area/place_area = get_area(place)
		if(!training && (place_area in used) && attempt <= HERETIC_LEAD_CRUCIBLE_ATTEMPTS / 2)
			continue
		.[place] = get_area_name(place, TRUE)
		used |= place_area

/// Сама клетка или ближайшая годная: на полигоне соседняя, на станции - ближайшая в общем коридоре или зале.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/crucible_landing(turf/spot, training)
	if(crucible_spot_valid(spot, training))
		return spot
	if(!isturf(spot))
		return null
	if(training)
		for(var/direction in GLOB.alldirs)
			var/turf/nearby = get_step(spot, direction)
			if(crucible_spot_valid(nearby, training))
				return nearby
		return null
	var/turf/best
	var/best_distance
	for(var/turf/open/place in range(HERETIC_LEAD_CRUCIBLE_SEARCH_RANGE, spot))
		var/distance = get_dist_euclidian(place, spot)
		if((!best || distance < best_distance) && crucible_spot_valid(place, training))
			best = place
			best_distance = distance
	return best

/datum/eldritch_knowledge/final_eldritch/lead_final/proc/crucible_spot_valid(turf/place, training)
	var/area/place_area = get_area(place)
	if(!isopenturf(place) || isgroundlessturf(place) || !place_area || (place_area.area_flags & NOTELEPORT) || place.is_blocked_turf(exclude_mobs = TRUE))
		return FALSE
	if(locate(/obj/structure/heretic_lead_crucible) in place)
		return FALSE
	return training ? istype(place_area, /area/antag_training) : (is_station_level(place.z) && heretic_station_public_area(place_area))

/// Тигель остыл или разбит; how = null - тихо, когда тигли гасит смерть или снятие роли.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/crucible_out(obj/structure/heretic_lead_crucible/crucible, how)
	if(!how)
		return
	var/left = lit_crucibles()
	log_game("Литейный тигель Свинца [how] в [AREACOORD(crucible)], горит ещё [left].")
	if(applied_body)
		to_chat(applied_body, span_userdanger((left ? "Литейный тигель в [get_area_name(crucible, TRUE)] [how]. Горит ещё: [left]." : "Последний Литейный тигель [how]: выстрелы станции больше не зовут вас.")))
	update_crucible_alert()
	if(!left)
		crucibles_quenched()

/// Последний тигель погас: перенос на выстрел пропадает навсегда, станция узнаёт об этом.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/crucibles_quenched(by_death = FALSE)
	if(crucibles_spent)
		return FALSE
	crucibles_spent = TRUE
	UnregisterSignal(SSdcs, COMSIG_GLOB_GUN_FIRED)
	stop_drum()
	last_shooter = null
	last_shot_turf = null
	revoke_to_shot()
	update_crucible_alert()
	log_game("Литейные тигли Свинца остыли[by_death ? " со смертью вознёсшегося" : ": экипаж погасил последний"].")
	if(simulated)
		return TRUE
	message_admins("Литейные тигли Свинца остыли[by_death ? " со смертью вознёсшегося" : ": экипаж погасил последний"].")
	priority_announce(by_death ? "Литейные тигли остыли вместе с вознёсшимся еретиком Свинца." : "Последний Литейный тигель погас. Вознёсшийся еретик Свинца больше не слышит выстрелов станции и не приходит на них, а его револьвер снова тратит Свинец.", "Литейные тигли остыли", 'sound/misc/notice2.ogg')
	return TRUE

/datum/eldritch_knowledge/final_eldritch/lead_final/proc/cool_crucibles()
	for(var/obj/structure/heretic_lead_crucible/crucible as anything in crucibles)
		crucible.go_out(null)
	crucibles_quenched(by_death = TRUE)

/datum/eldritch_knowledge/final_eldritch/lead_final/proc/clear_crucibles()
	UnregisterSignal(SSdcs, COMSIG_GLOB_GUN_FIRED)
	deltimer(volley_timer)
	volley_timer = null
	stop_drum()
	for(var/obj/structure/heretic_lead_crucible/crucible as anything in crucibles.Copy())
		crucible.finale_ref = null
		qdel(crucible)
	crucibles.Cut()
	last_shooter = null
	last_shot_turf = null

/datum/eldritch_knowledge/final_eldritch/lead_final/proc/revoke_to_shot()
	ascension_spells -= /obj/effect/proc_holder/spell/self/heretic_lead/to_shot
	for(var/obj/effect/proc_holder/spell/self/heretic_lead/to_shot/spell in ascension_spell_instances)
		ascension_spell_instances -= spell
		qdel(spell)

/datum/eldritch_knowledge/final_eldritch/lead_final/proc/update_crucible_alert()
	var/mob/living/body = applied_body
	if(!body)
		return
	var/lit = lit_crucibles()
	if(!lit)
		body.clear_alert(HERETIC_LEAD_CRUCIBLE_ALERT)
		return
	var/atom/movable/screen/alert/heretic_lead_crucibles/alert = body.throw_alert(HERETIC_LEAD_CRUCIBLE_ALERT, /atom/movable/screen/alert/heretic_lead_crucibles)
	alert?.desc = "Литейных тиглей горит: [lit]. Пока горит хоть один, вы слышите выстрелы из огнестрела на станции, «На выстрел» переносит к стрелку, а Шестизарядник не тратит Свинец. Экипаж гасит тигли водой и пеной или разбивает их."

/datum/eldritch_knowledge/final_eldritch/lead_final/proc/shot_place_valid(turf/place)
	if(!isturf(place))
		return FALSE
	return simulated ? istype(get_area(place), /area/antag_training) : is_station_level(place.z)

/// Вознёсшийся слышит каждый выстрел из огнестрела на станции, пока горит тигель.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/on_gunshot(datum/source, obj/item/gun/gun, mob/living/shooter, atom/target, fired)
	SIGNAL_HANDLER
	if(!heretic_lead_gunshot(gun, fired) || !isliving(shooter) || IS_HERETIC(shooter) || IS_HERETIC_MONSTER(shooter) || !lit_crucibles())
		return
	var/turf/place = get_turf(shooter)
	if(!shot_place_valid(place))
		return
	last_shooter = WEAKREF(shooter)
	last_shot_turf = place
	last_shot_at = world.time
	for(var/obj/effect/proc_holder/spell/self/heretic_lead/to_shot/spell in ascension_spell_instances)
		spell.action?.UpdateButtons()
	var/mob/living/body = applied_body
	if(body && body.stat != DEAD && COOLDOWN_FINISHED(src, shot_notice))
		COOLDOWN_START(src, shot_notice, HERETIC_LEAD_SHOT_NOTICE)
		to_chat(body, span_eldritch("Курок щёлкнул: стреляют в [get_area_name(place, TRUE)]. «На выстрел» перенесёт вас к стрелку."))

/// Свободная клетка рядом со стрелком; ушёл со станции или исчез - рядом с местом выстрела.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/shot_landing()
	var/mob/living/shooter = last_shooter?.resolve()
	var/turf/center = last_shot_turf
	var/turf/shooter_turf = get_turf(shooter)
	if(shooter && isturf(shooter.loc) && shot_place_valid(shooter_turf))
		center = shooter_turf
	if(!center)
		return null
	for(var/direction in GLOB.alldirs)
		var/turf/nearby = get_step(center, direction)
		if(heretic_lead_landable(nearby) && center.Adjacent(nearby))
			return nearby
	return heretic_lead_landable(center) ? center : null

/datum/eldritch_knowledge/final_eldritch/lead_final/proc/to_shot_block_reason(mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(!lead?.can_use(user) || user != applied_body)
		return "Способность недоступна вашему пути или текущему телу."
	if(!lit_crucibles())
		return "Все Литейные тигли погасли: выстрелы станции больше не зовут вас."
	if(!last_shot_turf || world.time > last_shot_at + HERETIC_LEAD_SHOT_MEMORY)
		return "За последние [HERETIC_LEAD_SHOT_MEMORY / (1 SECONDS)] секунд на станции никто не стрелял из огнестрела."
	if(user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return "Что-то держит вас на месте: на выстрел не уйти."
	var/turf/destination = shot_landing()
	if(!destination)
		return "Рядом со стрелком нет свободного пола."
	if(destination.z == user.z && get_dist(user, destination) <= 1)
		return "Вы уже у стрелка."
	var/area/origin_area = get_area(user)
	var/area/destination_area = get_area(destination)
	if((origin_area.area_flags & NOTELEPORT) || (destination_area.area_flags & NOTELEPORT))
		return "Зона закрыта для телепортации: на выстрел не уйти."
	return null

/// «На выстрел»: секунда на месте под красным перекрестием у стрелка, затем перенос к нему.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/to_shot(mob/living/user)
	to_shot_failure = to_shot_block_reason(user)
	if(to_shot_failure)
		return FALSE
	var/turf/origin = get_turf(user)
	new /obj/effect/temp_visual/heretic_lead/to_shot_mark(shot_landing())
	playsound(origin, 'modular_bluemoon/sound/heretic/lead_to_shot_out.ogg', 60, TRUE)
	user.visible_message(span_warning("[user] вскидывает голову, будто услышал выстрел, и начинает таять в пороховом дыму!"), span_notice("Вы идёте на выстрел."))
	if(!do_after(user, HERETIC_LEAD_TO_SHOT_TIME, target = user, timed_action_flags = IGNORE_HELD_ITEM))
		to_shot_failure = "Перенос сорвался: вы сдвинулись или вас прервали."
		return FALSE
	to_shot_failure = to_shot_block_reason(user)
	if(to_shot_failure)
		return FALSE
	var/turf/destination = shot_landing()
	if(!do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != destination)
		to_shot_failure = "Перенос сорвался: что-то его остановило."
		return FALSE
	heretic_lead_powder_smoke(origin)
	new /obj/effect/temp_visual/heretic_lead/ricochet(destination)
	playsound(destination, 'modular_bluemoon/sound/heretic/lead_to_shot_in.ogg', 70, TRUE)
	destination.visible_message(span_danger("Из порохового дыма рядом шагает [user]!"))
	log_game("[key_name(user)] переносится На выстрел Свинца из [AREACOORD(origin)] в [AREACOORD(destination)].")
	return TRUE

/// Живые враги в поле зрения: сначала люди с разумом, ближние первыми.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/volley_targets(mob/living/user)
	. = list()
	var/list/candidates = list()
	for(var/mob/living/victim in heretic_field_view(HERETIC_LEAD_VOLLEY_RANGE, user))
		if(victim == user || victim.stat == DEAD || !isturf(victim.loc) || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
			continue
		candidates[victim] = get_dist(user, victim) + (victim.mind ? 0 : HERETIC_LEAD_VOLLEY_RANGE + 1)
	sortTim(candidates, GLOBAL_PROC_REF(cmp_numeric_asc), TRUE)
	for(var/mob/living/victim as anything in candidates)
		if(length(.) >= HERETIC_LEAD_VOLLEY_TARGETS)
			break
		. += victim

/// Последний залп: красные линии прицела ко всем целям, через полторы секунды - по пуле в каждую.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/volley(mob/living/user)
	volley_failure = null
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(!lead?.can_use(user) || user != applied_body)
		volley_failure = "Последний залп доступен только вознёсшемуся в своём теле."
		return 0
	var/list/mob/living/targets = volley_targets(user)
	if(!length(targets))
		volley_failure = "В [HERETIC_LEAD_VOLLEY_RANGE] клетках не видно врагов."
		return 0
	var/list/datum/weakref/marked = list()
	for(var/mob/living/victim as anything in targets)
		user.Beam(victim, icon_state = "lead_aim_line", icon = HERETIC_LEAD_FX_ICON, time = HERETIC_LEAD_VOLLEY_DELAY, maxdistance = HERETIC_LEAD_VOLLEY_RANGE * 2)
		to_chat(victim, span_userdanger("На вас легла красная линия прицела! Через [replacetext("[HERETIC_LEAD_VOLLEY_DELAY / (1 SECONDS)]", ".", ",")] секунды выстрел: уйдите за угол или укройтесь."))
		marked += WEAKREF(victim)
		log_combat(user, victim, "берёт на прицел Последним залпом")
	user.visible_message(span_danger("От [user] к [length(targets)] целям тянутся красные линии прицела!"), span_notice("Целей на прицеле: [length(targets)]."))
	heretic_lead_sound(user, "rain_warn", 60)
	deltimer(volley_timer)
	volley_timer = addtimer(CALLBACK(src, PROC_REF(volley_fire), WEAKREF(user), marked), HERETIC_LEAD_VOLLEY_DELAY, TIMER_STOPPABLE)
	return length(targets)

/// Пули летят туда, где цель стоит сейчас: кто ушёл за угол, того закроет стена.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/volley_fire(datum/weakref/user_ref, list/datum/weakref/marked)
	volley_timer = null
	var/mob/living/user = user_ref?.resolve()
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(!user || user != applied_body || !lead?.can_use(user))
		if(user)
			to_chat(user, span_warning("Последний залп сорвался: вы не смогли выстрелить."))
		return list()
	. = list()
	var/turf/origin = get_turf(user)
	for(var/datum/weakref/victim_ref as anything in marked)
		var/mob/living/victim = victim_ref.resolve()
		if(!victim || victim.stat == DEAD || !isturf(victim.loc) || victim.z != user.z)
			continue
		var/obj/item/projectile/bullet = volley_shot(user, lead, origin, victim)
		if(bullet)
			. += bullet
	heretic_lead_sound(user, "shot", 75, TRUE)
	GLOB.heretic_sky.event(src)
	log_game("[key_name(user)] даёт Последний залп Свинца: пуль [length(.)] в [AREACOORD(origin)].")

/obj/item/projectile/bullet/heretic_lead/volley
	name = "last volley bullet"
	damage = HERETIC_LEAD_VOLLEY_DAMAGE
	armour_penetration = BULLET_BR4

/obj/effect/proc_holder/spell/self/heretic_lead/proc/lead_finale(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/lead_final)

/obj/effect/proc_holder/spell/self/heretic_lead/final_volley
	name = "Последний залп"
	desc = "Возьмите на прицел до 6 видимых врагов не дальше 8 клеток: к каждому протянется красная линия, видная всем. Через 1,5 секунды в каждого летит пуля на 35 ушибов туда, где он стоит; бронежилет её ослабит. Ушедшего за угол пуля достанет рикошетом от ближайшей стены вполовину силы, если позволяет угол; укрытого со всех сторон не найдёт. Перезарядка 30 секунд."
	summary = "До 6 врагов в 8 клетках: линии прицела на 1,5 секунды, затем пуля на 35 ушибов в каждого."
	charge_max = HERETIC_LEAD_VOLLEY_COOLDOWN
	action_icon_state = "lead_final_volley"

/obj/effect/proc_holder/spell/self/heretic_lead/final_volley/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = lead_finale(user)
	if(!finale?.volley(user))
		heretic_revert_cast(user, finale?.volley_failure)

/obj/effect/proc_holder/spell/self/heretic_lead/to_shot
	name = "На выстрел"
	desc = "Пока горит хоть один Литейный тигель, за секунду перенеситесь к стрелку последнего выстрела из огнестрела на станции, если стреляли не дольше 15 секунд назад; этаж не важен. За секунду до вас у стрелка вспыхивает красное перекрестие, на прежнем месте остаётся пороховой дым. Зоны без телепортации не пускают. Перезарядка 30 секунд."
	summary = "Пока горят тигли: за секунду к стрелку последнего выстрела на станции за 15 секунд."
	charge_max = HERETIC_LEAD_TO_SHOT_COOLDOWN
	action_icon_state = "lead_to_shot"

/obj/effect/proc_holder/spell/self/heretic_lead/to_shot/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = lead_finale(user)
	var/reason = finale ? finale.to_shot_block_reason(user) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/self/heretic_lead/to_shot/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = lead_finale(user)
	if(!finale?.to_shot(user))
		heretic_revert_cast(user, finale?.to_shot_failure)

/atom/movable/screen/alert/heretic_lead_crucibles
	name = "Литейные тигли"
	desc = "Пока горит хоть один Литейный тигель, вы слышите выстрелы из огнестрела на станции, «На выстрел» переносит к стрелку, а Шестизарядник не тратит Свинец."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "lead_crucibles"

/datum/looping_sound/heretic_lead_crucible
	mid_sounds = list('modular_bluemoon/sound/heretic/lead_crucible_bubble_1.ogg' = 1, 'modular_bluemoon/sound/heretic/lead_crucible_bubble_2.ogg' = 1)
	mid_length = 3 SECONDS
	volume = 30
	extra_range = -5

/// Литейный тигель вознесения: пока кипит, вознёсшийся слышит выстрелы станции и приходит на них.
/obj/structure/heretic_lead_crucible
	name = "foundry crucible"
	desc = "Чугунный котёл на треноге, до краёв полный кипящего свинца, под ним гудит пламя. Пока горит хоть один такой тигель, вознёсшийся еретик Свинца слышит каждый выстрел из огнестрела на станции и за секунду приходит к стрелку, а его револьвер стреляет без счёта; раз в минуту где-то бьёт тяжёлый барабан, и каждый третий удар заряжает револьвер Последним патроном. Остудите тигель тремя струями воды или пены из огнетушителя или разбейте его; нулевой жезл раскалывает тигель за два удара."
	icon = HERETIC_LEAD_FX_ICON
	icon_state = "lead_crucible"
	anchored = TRUE
	density = TRUE
	max_integrity = HERETIC_LEAD_CRUCIBLE_INTEGRITY
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	var/lit = TRUE
	var/douses = 0
	var/datum/weakref/finale_ref
	var/datum/looping_sound/heretic_lead_crucible/bubbling
	COOLDOWN_DECLARE(douse_gap)

/obj/structure/heretic_lead_crucible/Initialize(mapload, datum/eldritch_knowledge/final_eldritch/lead_final/finale)
	. = ..()
	if(QDELETED(finale))
		return INITIALIZE_HINT_QDEL
	finale_ref = WEAKREF(finale)
	RegisterSignal(src, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))
	bubbling = new(src, TRUE)
	update_crucible()
	heretic_vfx_burst(src, /particles/heretic_ascension/lead)
	heretic_vfx_flash(src, LIGHT_COLOR_FIRE, HERETIC_LEAD_CRUCIBLE_LIGHT_RANGE, HERETIC_LEAD_CRUCIBLE_LIGHT_POWER * 2)

/obj/structure/heretic_lead_crucible/Destroy()
	if(lit)
		go_out("разбит")
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = finale_ref?.resolve()
	finale?.crucibles -= src
	finale_ref = null
	QDEL_NULL(bubbling)
	return ..()

/obj/structure/heretic_lead_crucible/proc/update_crucible()
	cut_overlays()
	icon_state = lit ? "lead_crucible" : "lead_crucible_cold"
	if(lit)
		add_overlay(emissive_appearance(icon, "lead_crucible_glow", offset_spokesman = src))
		set_light(HERETIC_LEAD_CRUCIBLE_LIGHT_RANGE, HERETIC_LEAD_CRUCIBLE_LIGHT_POWER, LIGHT_COLOR_FIRE)
	else
		set_light(0)

/// Тигель гаснет навсегда; how - для еретика и логов, null - тихо.
/obj/structure/heretic_lead_crucible/proc/go_out(how)
	if(!lit)
		return FALSE
	lit = FALSE
	QDEL_NULL(bubbling)
	update_crucible()
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = finale_ref?.resolve()
	finale?.crucible_out(src, how)
	return TRUE

/obj/structure/heretic_lead_crucible/proc/on_exposed(atom/source, list/reagents)
	SIGNAL_HANDLER
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water) || istype(reagent, /datum/reagent/firefighting_foam))
			douse()
			return

/// Струя воды или пены: третья остужает тигель; брызги одной струи считаются за одну.
/obj/structure/heretic_lead_crucible/proc/douse()
	if(!lit || !COOLDOWN_FINISHED(src, douse_gap))
		return FALSE
	COOLDOWN_START(src, douse_gap, HERETIC_LEAD_CRUCIBLE_DOUSE_GAP)
	douses++
	heretic_vfx_burst(src, /particles/heretic_ascension/steam)
	playsound(src, pick('modular_bluemoon/sound/heretic/lead_crucible_quench_1.ogg', 'modular_bluemoon/sound/heretic/lead_crucible_quench_2.ogg'), 60, TRUE)
	var/left = HERETIC_LEAD_CRUCIBLE_DOUSES - douses
	if(left > 0)
		visible_message(span_notice("[src] шипит и окутывается паром, свинец темнеет. Ещё струй до остывания: [left]."))
		return TRUE
	visible_message(span_notice("Свинец в [src] густеет и застывает серой коркой: тигель остыл."))
	go_out("остужен")
	return TRUE

/obj/structure/heretic_lead_crucible/attackby(obj/item/item, mob/living/user, params)
	if(!istype(item, /obj/item/nullrod))
		return ..()
	user.do_attack_animation(src)
	user.changeNext_move(CLICK_CD_MELEE)
	visible_message(span_warning("[user] бьёт [src] нулевым жезлом, и по чугуну бежит трещина."))
	take_damage(max_integrity / 2, BRUTE, MELEE, FALSE)
	return TRUE

/obj/structure/heretic_lead_crucible/deconstruct(disassembled = TRUE)
	var/turf/place = get_turf(src)
	if(place)
		visible_message(span_danger("[src] раскалывается, и свинец растекается по полу, тут же застывая."))
		new /obj/effect/temp_visual/heretic_lead/crucible_broken(place)
		playsound(place, pick('modular_bluemoon/sound/heretic/lead_crucible_quench_1.ogg', 'modular_bluemoon/sound/heretic/lead_crucible_quench_2.ogg'), 60, TRUE)
	return ..()

/obj/structure/heretic_lead_crucible/examine(mob/user)
	. = ..()
	if(!lit)
		. += span_notice("Тигель остыл: свинец в нём застыл серой коркой, еретику он больше не служит.")
		return
	. += span_warning("Свинец кипит. До остывания струй воды или пены: [HERETIC_LEAD_CRUCIBLE_DOUSES - douses]. Прочность: [round(obj_integrity / max_integrity * 100)]%.")

/obj/effect/temp_visual/heretic_lead/to_shot_mark
	icon_state = "lead_crosshair"
	duration = HERETIC_LEAD_TO_SHOT_TIME
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_lead/crucible_broken
	name = "broken crucible"
	icon_state = "lead_crucible_broken"
	duration = HERETIC_LEAD_CRUCIBLE_BROKEN_TIME

/obj/effect/temp_visual/heretic_lead/crucible_broken/Initialize(mapload)
	. = ..()
	animate(src, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

#undef HERETIC_LEAD_CRUCIBLE_DOUSE_GAP
#undef HERETIC_LEAD_CRUCIBLE_ATTEMPTS
#undef HERETIC_LEAD_CRUCIBLE_TRAINING_RANGE
#undef HERETIC_LEAD_CRUCIBLE_SEARCH_RANGE
#undef HERETIC_LEAD_CRUCIBLE_LIGHT_RANGE
#undef HERETIC_LEAD_CRUCIBLE_LIGHT_POWER
#undef HERETIC_LEAD_CRUCIBLE_BROKEN_TIME
#undef HERETIC_LEAD_MISFIRE_MEMORY
#undef HERETIC_LEAD_SHOT_NOTICE
