#define HERETIC_STAR_RANGE 7
#define HERETIC_STAR_LIFETIME (3 MINUTES)
#define HERETIC_STAR_BASE_LIMIT 2
#define HERETIC_STAR_EXPANDED_LIMIT 3
#define HERETIC_STAR_ASCENDED_LIMIT 5
#define HERETIC_STAR_ARRIVAL_RADIUS 1
#define HERETIC_STAR_FLARE_RADIUS 2
#define HERETIC_STAR_FLARE_DAMAGE 30
#define HERETIC_STAR_FLARE_COOLDOWN (25 SECONDS)
#define HERETIC_STAR_THREAD_COOLDOWN (3 SECONDS)
#define HERETIC_STAR_THREAD_SWEEP (1.5 SECONDS)
#define HERETIC_STAR_COLLAPSE_DELAY (1.5 SECONDS)
#define HERETIC_COSMIC_GUIDE_CRAFT "cosmic_guide"
#define HERETIC_COSMIC_GUIDE_CLUE "Над полом висит холодная точка света, тени от неё нет."
#define HERETIC_COSMIC_GUIDE_ALPHA 140
#define HERETIC_COSMIC_CAPTURE "cosmic"
#define HERETIC_COSMIC_INK "#b7e4ff"
#define HERETIC_COSMIC_ORBIT_RADIUS 20
#define HERETIC_COSMIC_ORBIT_POINTS 8
#define HERETIC_COSMIC_ORBIT_STEP (0.3 SECONDS)

/datum/eldritch_knowledge/base_cosmic
	name = "Карта без неба"
	summary = "Звёзды-ловушки ставятся одним нажатием, путеводные звёзды для ухода - Хваткой по полу."
	details = list(
		"Начните с «Зажечь звезду»: укажите пол до 7 клеток от себя, звёзды загорятся там и под вами.",
		"Между звёздами натягивается нить: враг на ней получает 10 ожогов, 25 урона выносливости и падает.",
		"Держатся 2 звезды по 3 минуты; новая при полном созвездии заменяет самую старую.",
		"Путеводная звезда: Хватка в «Помощи» по полу. До 4, по одной на отдел, без срока, 40 прочности.",
		"Звезда в новом отделе - шаг дела пути; к ней ведут Звёздная дорога и выход из изнанки.",
		"Готовую цель охоты в 2 клетках от своей путеводной звезды сердце за секунду уводит в изнанку.",
		"Экипаж видит холодную точку света без тени; жезл гасит звёзды. Нож и стекло на руне дают космический клинок.",
	)
	role = HERETIC_ROLE_CRAFT
	gain_text = "Между двумя точками лежит не пустота. Между ними лежит закон."
	route = PATH_COSMIC
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/glass)
	result_atoms = list(/obj/item/melee/sickly_blade/cosmic)
	resource_rules = list(
		"Созвездие: 2 звезды, с Третьей точкой 3, после вознесения 5; каждая живёт 3 минуты.",
		"Первое нажатие ставит пару вдоль свободной прямой, преграда оставляет только дальнюю звезду.",
		"Новая звезда тянет нить к самой свежей своей звезде со свободной прямой, иначе встаёт отдельно.",
		"Нить: 10 ожогов, 25 урона выносливости, падение на 0,7 секунды и замедление на 3 секунды.",
		"Одну цель нить ранит не чаще раза в 3 секунды; замедление от Хватки и пульса от нитей не защищает.",
		"При полном созвездии новая звезда заменяет старейшую, нажатие на свою звезду гасит её.",
		"Путеводные звёзды в созвездие не входят: до 4, по одной на отдел, без срока.",
	)
	var/list/stars = list()
	var/list/threads = list()
	var/list/beams = list()
	/// Путеводные звёзды ремесла, старейшая первой.
	var/list/obj/structure/heretic_guide_star/guide_stars = list()
	var/list/datum/status_effect/heretic_cosmic_orbit/orbits = list()
	var/datum/mind/astronomer
	var/obj/effect/proc_holder/spell/self/cosmic/manifest/manifest_spell
	var/clearing_stars = FALSE
	var/pulling = FALSE
	var/thread_sweep_timer
	var/ascension_active = FALSE
	var/collapse_pending_until = 0
	var/cosmic_failure
	COOLDOWN_DECLARE(guide_road_cooldown)

/datum/eldritch_knowledge/base_cosmic/on_body_gain(mob/living/user)
	if(!user?.mind || !QDELETED(manifest_spell))
		return
	astronomer = user.mind
	manifest_spell = new
	user.mind.AddSpell(manifest_spell)

/datum/eldritch_knowledge/base_cosmic/on_body_lose(mob/living/user)
	QDEL_NULL(manifest_spell)
	end_orbits()
	clear_stars()
	astronomer = null

/datum/eldritch_knowledge/base_cosmic/on_death(mob/user)
	end_orbits()

/datum/eldritch_knowledge/base_cosmic/Destroy()
	on_body_lose(astronomer?.current)
	for(var/obj/structure/heretic_guide_star/guide as anything in guide_stars.Copy())
		qdel(guide)
	guide_stars.Cut()
	return ..()

/datum/eldritch_knowledge/base_cosmic/proc/star_limit()
	if(ascension_active)
		return HERETIC_STAR_ASCENDED_LIMIT
	var/datum/antagonist/heretic/heretic = astronomer?.has_antag_datum(/datum/antagonist/heretic)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/cosmic_expansion) ? HERETIC_STAR_EXPANDED_LIMIT : HERETIC_STAR_BASE_LIMIT

/datum/eldritch_knowledge/base_cosmic/get_combat_resource_data()
	return combat_resource_payload("Звёзды", length(stars), star_limit())

/datum/eldritch_knowledge/base_cosmic/combat_resource_state()
	return "Путеводных звёзд: [length(guide_stars)] из [HERETIC_COSMIC_GUIDE_LIMIT]."

/datum/eldritch_knowledge/base_cosmic/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_failure_reason = null
	if(!proximity_flag || !isturf(target) || user.a_intent != INTENT_HELP)
		return FALSE
	return place_guide_star(user, target)

/datum/eldritch_knowledge/base_cosmic/proc/place_guide_star(mob/living/user, turf/place)
	grasp_failure_reason = null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || user.mind != astronomer || !istype(place))
		return FALSE
	if(locate(/obj/structure/heretic_guide_star) in place)
		grasp_failure_reason = "Здесь уже горит путеводная звезда."
		return FALSE
	if(!safe_star_turf(place))
		grasp_failure_reason = "Путеводная звезда встаёт только на свободный пол: не на стену, не в космос и не на лаву."
		return FALSE
	var/key = heretic.deed_key_for(place)
	var/counts_for_deed = is_station_level(place.z)
	if(counts_for_deed)
		grasp_failure_reason = heretic.deed_wait_reason(key)
		if(grasp_failure_reason)
			return FALSE
	for(var/obj/structure/heretic_guide_star/guide as anything in guide_stars.Copy())
		if(heretic.deed_key_for(guide) != key)
			continue
		log_game("[key_name(user)] гасит путеводную звезду Космоса в [AREACOORD(guide)]: в том же отделе зажжена новая.")
		guide_stars -= guide
		qdel(guide)
	while(length(guide_stars) >= HERETIC_COSMIC_GUIDE_LIMIT)
		var/obj/structure/heretic_guide_star/oldest = guide_stars[1]
		log_game("[key_name(user)] теряет путеводную звезду Космоса в [AREACOORD(oldest)]: её вытеснила новая.")
		guide_stars -= oldest
		qdel(oldest)
	guide_stars += new /obj/structure/heretic_guide_star(place, src)
	playsound(place, 'modular_bluemoon/sound/heretic/cosmic_energy.ogg', 30, TRUE)
	to_chat(user, span_eldritch("Путеводная звезда зажглась: [get_area_name(place, TRUE)]. Путеводных звёзд: [length(guide_stars)] из [HERETIC_COSMIC_GUIDE_LIMIT]."))
	log_game("[key_name(user)] зажигает путеводную звезду Космоса в [AREACOORD(place)].")
	if(counts_for_deed)
		heretic.advance_deed(key, place)
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_cosmic/pocket_exits(mob/living/user)
	. = list()
	for(var/obj/structure/heretic_guide_star/guide as anything in guide_stars)
		heretic_add_pocket_exit(., "Звезда - [get_area_name(guide, TRUE)]", heretic_pocket_landing(get_turf(guide)))

/datum/eldritch_knowledge/base_cosmic/pocket_door(mob/living/user, mob/living/victim)
	if(!guide_door_holds(user, victim))
		return null
	return list("name" = "к путеводной звезде", "text" = "Холодная точка света рядом с [victim] раскрывается звёздной воронкой.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(guide_door_holds), user, victim))

/datum/eldritch_knowledge/base_cosmic/door_user_ready(mob/living/user)
	return user?.mind && user.mind == astronomer && user.stat == CONSCIOUS && !user.incapacitated() && isturf(user.loc)

/// Готовая цель не дальше HERETIC_COSMIC_DOOR_RANGE клеток от своей путеводной звезды, еретик вплотную к цели.
/datum/eldritch_knowledge/base_cosmic/proc/guide_door_holds(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!door_user_ready(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > 1 || !heretic?.hunt_target_ready(victim))
		return FALSE
	for(var/obj/structure/heretic_guide_star/guide as anything in guide_stars)
		if(guide.z == victim.z && get_dist(guide, victim) <= HERETIC_COSMIC_DOOR_RANGE)
			return TRUE
	return FALSE

/// Цель на своей Орбите, еретик не дальше HERETIC_COSMIC_DOOR_RANGE клеток от её звезды.
/datum/eldritch_knowledge/base_cosmic/proc/orbit_door_holds(mob/living/user, mob/living/victim)
	if(!door_user_ready(user) || QDELETED(victim))
		return FALSE
	for(var/datum/status_effect/heretic_cosmic_orbit/orbit as anything in orbits)
		if(orbit.owner == victim)
			return !QDELETED(orbit.star) && orbit.star.z == user.z && get_dist(user, orbit.star) <= HERETIC_COSMIC_DOOR_RANGE
	return FALSE

/datum/eldritch_knowledge/base_cosmic/on_craft_removed(atom/crafted, craft_id)
	if(craft_id != HERETIC_COSMIC_GUIDE_CRAFT)
		return
	guide_stars -= crafted
	if(!QDELETED(crafted))
		qdel(crafted)
	notify_resource_changed()

/datum/eldritch_knowledge/base_cosmic/proc/guide_stars_on_level(atom/origin)
	. = list()
	var/turf/origin_turf = get_turf(origin)
	for(var/obj/structure/heretic_guide_star/guide as anything in guide_stars)
		if(guide.z == origin_turf?.z)
			. += guide

/datum/eldritch_knowledge/base_cosmic/proc/choose_guide_star(mob/living/user)
	var/list/choices = list()
	for(var/obj/structure/heretic_guide_star/guide as anything in guide_stars_on_level(user))
		choices["[get_area_name(guide, TRUE)] ([get_dist(user, guide)] кл.)"] = guide
	if(length(choices) <= 1)
		return length(choices) ? choices[choices[1]] : null
	var/choice = tgui_input_list(user, "К какой путеводной звезде ведёт дорога?", "Звёздная дорога", choices)
	return choice ? choices[choice] : null

/// Причины отказа, не зависящие от выбранной звезды: их видно до меню выбора.
/datum/eldritch_knowledge/base_cosmic/proc/guide_road_start_failure(mob/living/user)
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/cosmic_step)
	if(user?.mind != astronomer || heretic?.selected_path != PATH_COSMIC || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	if(user.incapacitated(ignore_grab = TRUE))
		return "Вы не можете действовать: дождитесь окончания оглушения."
	if(!isturf(user.loc))
		return "Сначала выйдите из контейнера или укрытия на пол."
	var/area/origin_area = get_area(user)
	if((origin_area.area_flags & NOTELEPORT) || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return "Пространство здесь заперто для телепортации: звёздная дорога не открывается."
	if(!COOLDOWN_FINISHED(src, guide_road_cooldown))
		return "Дорога к путеводной звезде восстанавливается: осталось [heretic_capture_seconds_left(guide_road_cooldown)] с."
	return null

/datum/eldritch_knowledge/base_cosmic/proc/guide_road_failure(mob/living/user, obj/structure/heretic_guide_star/guide)
	. = guide_road_start_failure(user)
	if(.)
		return
	if(QDELETED(guide) || !(guide in guide_stars))
		return "Дорога ведёт только к вашей путеводной звезде."
	var/turf/origin = get_turf(user)
	var/turf/landing = get_turf(guide)
	if(landing.z != origin.z)
		return "Путеводная звезда на другом уровне: звёздная дорога не выходит за пределы уровня."
	if(landing == origin)
		return "Вы уже у этой путеводной звезды."
	var/area/landing_area = get_area(landing)
	if(landing_area.area_flags & NOTELEPORT)
		return "Путеводная звезда в зоне, запертой для телепортации: звёздная дорога туда не ведёт."
	if(!safe_star_turf(landing))
		return "У путеводной звезды нет свободного пола: выйти некуда."
	if(landing.is_blocked_turf(source_atom = user))
		return "У путеводной звезды кто-то стоит: выйти некуда."
	return null

/datum/eldritch_knowledge/base_cosmic/proc/guide_road_ready(mob/living/user, obj/structure/heretic_guide_star/guide)
	return !guide_road_failure(user, guide)

/datum/eldritch_knowledge/base_cosmic/proc/guide_road(mob/living/user, obj/structure/heretic_guide_star/guide)
	cosmic_failure = guide_road_failure(user, guide)
	if(cosmic_failure)
		return FALSE
	var/turf/origin = get_turf(user)
	var/obj/effect/temp_visual/heretic_vfx/thread/comet = heretic_vfx_thread(user, guide, heretic_path_ink(PATH_COSMIC), HERETIC_COSMIC_ROAD_CHANNEL)
	comet?.grow(HERETIC_COSMIC_ROAD_CHANNEL)
	user.visible_message(span_warning("От [user] вдаль протягивается светящийся хвост кометы."), span_notice("Вы ступаете на звёздную дорогу: две секунды стойте на месте."))
	playsound(user, 'modular_bluemoon/sound/heretic/cosmic_charge.ogg', 40, FALSE)
	if(!do_after(user, HERETIC_COSMIC_ROAD_CHANNEL, target = user, timed_action_flags = IGNORE_INCAPACITATED, extra_checks = CALLBACK(src, PROC_REF(guide_road_ready), user, guide)))
		qdel(comet)
		cosmic_failure = guide_road_failure(user, guide) || "Звёздная дорога прервана: две секунды стойте на месте."
		return FALSE
	cosmic_failure = guide_road_failure(user, guide)
	if(cosmic_failure)
		return FALSE
	var/turf/landing = get_turf(guide)
	if(!do_teleport(user, landing, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != landing)
		cosmic_failure = "Звёздная дорога не пропустила: что-то мешает переходу."
		return FALSE
	COOLDOWN_START(src, guide_road_cooldown, HERETIC_COSMIC_ROAD_COOLDOWN)
	new /obj/effect/temp_visual/heretic_spell/star_step(origin)
	new /obj/effect/temp_visual/heretic_spell/star_step(landing)
	playsound(landing, 'sound/magic/blink.ogg', 40, TRUE)
	log_game("[key_name(user)] уходит Звёздной дорогой к путеводной звезде из [AREACOORD(origin)] в [AREACOORD(landing)].")
	return TRUE

/datum/eldritch_knowledge/base_cosmic/proc/orbit_around(atom/star)
	for(var/datum/status_effect/heretic_cosmic_orbit/orbit as anything in orbits)
		if(orbit.star == star)
			return orbit
	return null

/datum/eldritch_knowledge/base_cosmic/proc/orbit_examine(atom/star)
	var/datum/status_effect/heretic_cosmic_orbit/orbit = orbit_around(star)
	return orbit ? span_warning("Вокруг звезды кружит [orbit.owner]. Разбейте звезду или коснитесь нулевым жезлом звезды или пленника.") : null

/datum/eldritch_knowledge/base_cosmic/proc/orbit_heart(atom/star, obj/item/item, mob/living/user, params)
	if(!istype(item, /obj/item/living_heart) || !astronomer || user?.mind != astronomer)
		return FALSE
	var/obj/item/living_heart/heart = item
	if(heart.owner_mind && heart.owner_mind != astronomer)
		return FALSE
	var/datum/status_effect/heretic_cosmic_orbit/orbit = orbit_around(star)
	if(!orbit?.owner)
		return FALSE
	item.melee_attack_chain(user, orbit.owner, params)
	return TRUE

/datum/eldritch_knowledge/base_cosmic/proc/end_orbits()
	for(var/datum/status_effect/heretic_cosmic_orbit/orbit as anything in orbits.Copy())
		qdel(orbit)

/datum/eldritch_knowledge/base_cosmic/proc/orbit_star_valid(atom/movable/star, mob/living/victim)
	if(QDELETED(star) || !isturf(star.loc) || star.z != victim.z || orbit_around(star))
		return FALSE
	if(!(star in stars) && !(star in guide_stars))
		return FALSE
	return get_dist(star, victim) <= HERETIC_COSMIC_ORBIT_RANGE && star_line_clear(star, victim)

/datum/eldritch_knowledge/base_cosmic/proc/orbit_star_for(mob/living/victim)
	var/best_distance = INFINITY
	for(var/atom/movable/star as anything in stars + guide_stars)
		var/distance = get_dist(star, victim)
		if(distance < best_distance && orbit_star_valid(star, victim))
			best_distance = distance
			. = star

/datum/eldritch_knowledge/base_cosmic/proc/orbit_ready(mob/living/victim)
	if(heretic_capture_downed(victim))
		return TRUE
	var/datum/status_effect/cosmic_tether/tether = victim.has_status_effect(/datum/status_effect/cosmic_tether)
	if(tether && tether.source_ref?.resolve() == src)
		return TRUE
	var/datum/status_effect/cosmic_thread_cooldown/thread = victim.has_status_effect(/datum/status_effect/cosmic_thread_cooldown)
	return thread && thread.source_ref?.resolve() == src

/datum/eldritch_knowledge/base_cosmic/proc/tether(mob/living/victim)
	victim.apply_status_effect(/datum/status_effect/cosmic_tether, src)
	var/datum/status_effect/cosmic_tether/effect = victim.has_status_effect(/datum/status_effect/cosmic_tether)
	if(effect)
		effect.source_ref = WEAKREF(src)

/datum/eldritch_knowledge/base_cosmic/proc/orbit_block_reason(mob/living/user, atom/target, check_ready = TRUE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/cosmic_orbit)
	if(user?.mind != astronomer || user?.stat == DEAD || heretic?.selected_path != PATH_COSMIC || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_capture_block_reason(user, target, HERETIC_COSMIC_CAPTURE)
	if(reason)
		return reason
	if(!door_user_ready(user))
		return "Вы не можете действовать: дождитесь окончания оглушения и выйдите на пол."
	var/mob/living/victim = target
	if(victim.has_status_effect(/datum/status_effect/heretic_cosmic_orbit))
		return "Цель уже кружит вокруг звезды."
	if(!isturf(victim.loc) || !orbit_star_for(victim))
		return "Цель должна стоять на полу не дальше двух клеток от вашей свободной звезды по открытой линии."
	if(check_ready && !orbit_ready(victim))
		return "Орбита берёт только сбитую с ног или обессиленную цель либо замедленную нитью, Притяжением или пульсом. Сон и добровольный отдых не в счёт."
	return null

/datum/eldritch_knowledge/base_cosmic/proc/orbit(mob/living/user, mob/living/victim)
	cosmic_failure = orbit_block_reason(user, victim)
	if(cosmic_failure)
		return FALSE
	var/atom/movable/star = orbit_star_for(victim)
	var/turf/place = get_turf(victim)
	new /obj/effect/temp_visual/heretic_path_feedback(place, "cosmic_ring", HERETIC_COSMIC_INK, HERETIC_COSMIC_ORBIT_TELEGRAPH)
	heretic_vfx_thread(star, victim, heretic_path_ink(PATH_COSMIC), HERETIC_COSMIC_ORBIT_TELEGRAPH)
	addtimer(CALLBACK(src, PROC_REF(seal_orbit), user, victim, star, place), HERETIC_COSMIC_ORBIT_TELEGRAPH)
	user.visible_message(span_danger("Вокруг [victim] вспыхивает звёздное кольцо, и ближняя звезда начинает тянуть!"), span_notice("Звезда берёт [victim] на орбиту."))
	playsound(place, 'modular_bluemoon/sound/heretic/cosmic_charge.ogg', 40, FALSE)
	return TRUE

/datum/eldritch_knowledge/base_cosmic/proc/seal_orbit(mob/living/user, mob/living/victim, atom/movable/star, turf/place)
	if(QDELETED(src) || QDELETED(user))
		return FALSE
	if(QDELETED(victim) || victim.loc != place)
		to_chat(user, span_warning("Цель ушла из звёздного кольца, и Орбита рассыпалась."))
		return FALSE
	if(!orbit_star_valid(star, victim))
		to_chat(user, span_warning("Звезду погасили или она уже держит пленника, и Орбита рассыпалась."))
		return FALSE
	var/reason = orbit_block_reason(user, victim, check_ready = FALSE)
	if(reason)
		to_chat(user, span_warning("Орбита рассыпалась: [reason]"))
		return FALSE
	var/datum/status_effect/heretic_cosmic_orbit/orbit = victim.apply_status_effect(/datum/status_effect/heretic_cosmic_orbit, src, star)
	if(!orbit || QDELETED(orbit))
		return FALSE
	log_combat(user, victim, "выводит на звёздную орбиту")
	return TRUE

/datum/eldritch_knowledge/base_cosmic/proc/pull_to_star(mob/living/victim, atom/movable/star)
	var/turf/core = get_turf(star)
	if(!core || victim.anchored || victim.buckled || victim.loc == core || core.is_blocked_turf(exclude_mobs = TRUE))
		return FALSE
	pulling = TRUE
	victim.forceMove(core)
	pulling = FALSE
	return TRUE

/datum/eldritch_knowledge/base_cosmic/proc/clear_stars()
	deltimer(thread_sweep_timer)
	thread_sweep_timer = null
	clearing_stars = TRUE
	QDEL_LIST(threads)
	QDEL_LIST(beams)
	QDEL_LIST(stars)
	clearing_stars = FALSE
	notify_resource_changed()

/datum/eldritch_knowledge/base_cosmic/proc/add_star(turf/place, mob/living/user)
	if(user?.mind != astronomer || !IS_HERETIC(user) || !isturf(user.loc) || user.incapacitated() || !safe_star_turf(place))
		return FALSE
	for(var/obj/structure/heretic_star/star as anything in stars)
		if(star.loc == place)
			qdel(star)
			return TRUE
	if(length(stars) >= star_limit())
		to_chat(user, span_warning("Созвездие заполнено. Погасите одну из своих звёзд повторным зажиганием на её месте."))
		return FALSE
	var/obj/structure/heretic_star/created = new(place)
	created.constellation = src
	stars += created
	notify_resource_changed()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/cosmic_resonance/resonance = heretic.get_knowledge(/datum/eldritch_knowledge/cosmic_resonance)
	if(resonance)
		created.max_integrity = resonance.passive_values[resonance.passive_level]
		created.obj_integrity = created.max_integrity
	rebuild_threads()
	playsound(place, 'modular_bluemoon/sound/heretic/cosmic_energy.ogg', 35, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_cosmic/proc/manifest(turf/place, mob/living/user)
	if(user?.mind != astronomer || !IS_HERETIC(user) || !isturf(user.loc) || user.incapacitated() || !(place in view(HERETIC_STAR_RANGE, user)))
		return FALSE
	for(var/obj/structure/heretic_star/star as anything in stars)
		if(star.loc == place)
			qdel(star)
			return TRUE
	if(!safe_star_turf(place))
		return FALSE
	var/turf/origin = get_turf(user)
	if(place != origin && !nearest_star(user) && star_line_clear(user, place))
		make_room_for_star()
		if(!add_star(origin, user))
			return FALSE
	make_room_for_star()
	return add_star(place, user)

/datum/eldritch_knowledge/base_cosmic/proc/can_trail_star(mob/living/user)
	var/turf/place = get_turf(user)
	// Ход обрабатывается раньше таймера в том же тике: ворота снимает finish_collapse, срок - запасной выход.
	if(collapse_pending_until && world.time <= collapse_pending_until + HERETIC_STAR_COLLAPSE_DELAY)
		return FALSE
	if(!ascension_active || user?.mind != astronomer || !IS_HERETIC(user) || !isturf(user.loc) || user.incapacitated() || !safe_star_turf(place))
		return FALSE
	for(var/obj/structure/heretic_star/star as anything in stars)
		if(star.loc == place)
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_cosmic/proc/trail_star(mob/living/user)
	if(!can_trail_star(user))
		return FALSE
	make_room_for_star()
	var/turf/place = get_turf(user)
	. = add_star(place, user)
	if(. && heretic_vfx_watched(user))
		heretic_cosmic_twinkle(place)

/datum/eldritch_knowledge/base_cosmic/proc/make_room_for_star()
	if(length(stars) >= star_limit())
		qdel(stars[1])

/datum/eldritch_knowledge/base_cosmic/proc/safe_star_turf(turf/place)
	return isopenturf(place) && !isspaceturf(place) && !istype(place, /turf/open/lava) && !place.is_blocked_turf(exclude_mobs = TRUE)

/datum/eldritch_knowledge/base_cosmic/proc/star_line_clear(atom/start, atom/end)
	var/turf/start_turf = get_turf(start)
	var/turf/end_turf = get_turf(end)
	if(!start_turf || !end_turf || start_turf.z != end_turf.z || get_dist(start_turf, end_turf) > HERETIC_STAR_RANGE)
		return FALSE
	for(var/turf/tile as anything in get_line(start_turf, end_turf))
		if(!safe_star_turf(tile))
			return FALSE
	return TRUE

/// Звезда тянет нить к самой свежей из более старых звёзд со свободной прямой; от трёх звёзд последняя замыкается на первую.
/datum/eldritch_knowledge/base_cosmic/proc/star_links()
	var/list/links = list()
	var/count = length(stars)
	if(count < 2)
		return links
	var/obj/structure/heretic_star/last_anchor
	for(var/index in 2 to count)
		var/obj/structure/heretic_star/star = stars[index]
		last_anchor = null
		for(var/previous = index - 1, previous >= 1, previous--)
			var/obj/structure/heretic_star/anchor = stars[previous]
			if(star_line_clear(anchor, star))
				links += list(list(anchor, star))
				last_anchor = anchor
				break
	var/obj/structure/heretic_star/first = stars[1]
	var/obj/structure/heretic_star/last = stars[count]
	if(count > 2 && last_anchor != first && star_line_clear(last, first))
		links += list(list(last, first))
	return links

/datum/eldritch_knowledge/base_cosmic/proc/rebuild_threads()
	var/list/unused_threads = threads.Copy()
	var/list/unused_beams = beams.Copy()
	threads.Cut()
	beams.Cut()
	if(clearing_stars || length(stars) < 2)
		QDEL_LIST(unused_threads)
		QDEL_LIST(unused_beams)
		return
	var/list/threads_by_turf = list()
	for(var/obj/effect/heretic_star_thread/thread as anything in unused_threads)
		if(!QDELETED(thread))
			threads_by_turf[thread.loc] = thread
	var/list/linked_turfs = list()
	for(var/list/link as anything in star_links())
		var/obj/structure/heretic_star/start = link[1]
		var/obj/structure/heretic_star/end = link[2]
		var/datum/beam/beam
		for(var/datum/beam/candidate as anything in unused_beams)
			if(!QDELETED(candidate) && candidate.origin == start && candidate.target == end)
				beam = candidate
				unused_beams -= candidate
				break
		if(!beam)
			beam = new(start, end, 'modular_bluemoon/icons/obj/heretic_effects.dmi', "cosmic_beam", INFINITY, HERETIC_STAR_RANGE + 1, /obj/effect/ebeam/heretic_constellation, null)
			beam.Draw()
		else if(beam.origin_oldloc != get_turf(start) || beam.target_oldloc != get_turf(end))
			beam.origin_oldloc = get_turf(start)
			beam.target_oldloc = get_turf(end)
			beam.Reset()
			beam.Draw()
		beams += beam
		for(var/turf/tile as anything in get_line(start, end))
			if(tile in linked_turfs)
				continue
			linked_turfs += tile
			var/obj/effect/heretic_star_thread/thread = threads_by_turf[tile]
			if(QDELETED(thread))
				thread = new(tile)
			else
				unused_threads -= thread
			thread.constellation = src
			thread.start = start
			thread.end = end
			threads += thread
	QDEL_LIST(unused_threads)
	QDEL_LIST(unused_beams)
	// Draw() луча может уступить тик, и за это время знание успевают удалить.
	if(QDELETED(src))
		QDEL_LIST(threads)
		QDEL_LIST(beams)
		return
	schedule_thread_sweep()

/datum/eldritch_knowledge/base_cosmic/proc/schedule_thread_sweep()
	if(!QDELETED(src) && !thread_sweep_timer && length(threads))
		thread_sweep_timer = addtimer(CALLBACK(src, PROC_REF(sweep_threads)), HERETIC_STAR_THREAD_SWEEP, TIMER_STOPPABLE)

/// Crossed не срабатывает для тех, кто уже стоит на нити или под кем она появилась.
/datum/eldritch_knowledge/base_cosmic/proc/sweep_threads()
	thread_sweep_timer = null
	for(var/obj/effect/heretic_star_thread/thread as anything in threads.Copy())
		for(var/mob/living/victim in thread.loc)
			thread.strike(victim)
	schedule_thread_sweep()

/datum/eldritch_knowledge/base_cosmic/proc/remove_star(obj/structure/heretic_star/star)
	stars -= star
	if(!clearing_stars)
		rebuild_threads()
		notify_resource_changed()

/datum/eldritch_knowledge/base_cosmic/proc/star_flare_turfs(obj/structure/heretic_star/star)
	var/list/affected = list()
	if(QDELETED(star) || !(star in stars) || star.constellation != src)
		return affected
	for(var/turf/place in range(HERETIC_STAR_FLARE_RADIUS, star))
		if(star_line_clear(star, place))
			affected += place
	return affected

/datum/eldritch_knowledge/base_cosmic/proc/flare_star(mob/living/user, obj/structure/heretic_star/star, turf/expected_place, list/telegraphed_turfs)
	if(QDELETED(star) || !(star in stars) || star.constellation != src || star.loc != expected_place || user?.mind != astronomer || !IS_HERETIC(user) || user.incapacitated() || !isturf(user.loc) || !(star in view(HERETIC_STAR_RANGE, user)) || !star_line_clear(user, star))
		return FALSE
	for(var/mob/living/victim in range(HERETIC_STAR_FLARE_RADIUS, star))
		if(!isturf(victim.loc) || !(victim.loc in telegraphed_turfs) || !star_line_clear(star, victim) || !can_affect(victim, chargecost = 1))
			continue
		victim.adjustFireLoss(HERETIC_STAR_FLARE_DAMAGE)
		log_combat(user, victim, "погасил звезду вспышкой возле")
	new /obj/effect/temp_visual/heretic_spell(get_turf(star))
	playsound(star, 'modular_bluemoon/sound/heretic/cosmic_expansion.ogg', 50, TRUE)
	qdel(star)
	return TRUE

/obj/item/heretic_path_relic/astrolabe/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	. = ..()
	if(istype(target, /obj/structure/heretic_star))
		flare(user, target)

/obj/item/heretic_path_relic/astrolabe/proc/can_flare(mob/living/user, obj/structure/heretic_star/star, turf/expected_place)
	if(!authorized(user) || !COOLDOWN_FINISHED(src, relic_cooldown) || QDELETED(star) || star.loc != expected_place)
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	return knowledge && user.mind == knowledge.astronomer && (star in knowledge.stars) && star.constellation == knowledge && (star in view(HERETIC_STAR_RANGE, user)) && knowledge.star_line_clear(user, star)

/obj/item/heretic_path_relic/astrolabe/proc/flare(mob/living/user, obj/structure/heretic_star/star)
	var/turf/place = get_turf(star)
	if(busy || !can_flare(user, star, place))
		return FALSE
	var/datum/eldritch_knowledge/base_cosmic/knowledge = star.constellation
	var/list/telegraphed_turfs = knowledge.star_flare_turfs(star)
	busy = TRUE
	for(var/turf/tile as anything in telegraphed_turfs)
		new /obj/effect/temp_visual/heretic_path_feedback(tile, "cosmic_carpet", "#efb780", alignment_time)
	star.visible_message(span_danger("Звезда сжимается в раскалённую точку!"))
	playsound(star, 'modular_bluemoon/sound/heretic/cosmic_charge.ogg', 40, FALSE)
	var/completed = do_after(user, alignment_time, target = user, extra_checks = CALLBACK(src, PROC_REF(can_flare), user, star, place))
	busy = FALSE
	if(!completed || !can_flare(user, star, place) || !knowledge.flare_star(user, star, place, telegraphed_turfs))
		return FALSE
	COOLDOWN_START(src, relic_cooldown, HERETIC_STAR_FLARE_COOLDOWN)
	return TRUE

/// Поворот сохраняет сами звёзды: повреждения и таймеры не сбрасываются.
/datum/eldritch_knowledge/base_cosmic/proc/rotation_targets(mob/living/user)
	if(user?.mind != astronomer || !IS_HERETIC(user) || user.incapacitated() || !isturf(user.loc) || length(stars) < 2)
		return null
	var/obj/structure/heretic_star/pivot = stars[1]
	if(!user.Adjacent(pivot))
		return null
	var/turf/center = get_turf(pivot)
	var/list/plan = list()
	var/list/visible = view(HERETIC_STAR_RANGE, user)
	for(var/obj/structure/heretic_star/star as anything in stars)
		if(star.z != user.z || get_dist(star, user) > HERETIC_STAR_RANGE || !(star in visible))
			return null
		var/turf/destination = locate(center.x + star.y - center.y, center.y - star.x + center.x, center.z)
		if(!safe_star_turf(destination) || destination.is_blocked_turf(source_atom = user))
			return null
		plan[star] = destination
	for(var/list/link as anything in star_links())
		if(!star_line_clear(plan[link[1]], plan[link[2]]))
			return null
	return plan

/datum/eldritch_knowledge/base_cosmic/proc/rotate_constellation(mob/living/user, list/expected_plan)
	var/list/current_plan = rotation_targets(user)
	if(!length(current_plan) || length(current_plan) != length(expected_plan))
		return FALSE
	for(var/obj/structure/heretic_star/star as anything in current_plan)
		if(current_plan[star] != expected_plan[star])
			return FALSE
	for(var/obj/structure/heretic_star/star as anything in current_plan)
		new /obj/effect/temp_visual/heretic_path_feedback(get_turf(star), "cosmic_cloud", "#88cce8", 8)
		star.forceMove(current_plan[star])
		new /obj/effect/temp_visual/heretic_path_feedback(get_turf(star), "cosmic_ring", "#b7e4ff", 8)
	rebuild_threads()
	playsound(user, 'modular_bluemoon/sound/heretic/cosmic_expansion.ogg', 45, FALSE)
	return TRUE

/// Те же клетки используются для предупреждения и проверки области схлопывания.
/datum/eldritch_knowledge/base_cosmic/proc/collapse_turfs(mob/living/user)
	var/list/affected = list()
	for(var/obj/structure/heretic_star/star as anything in stars)
		if(star.z != user.z || get_dist(star, user) > HERETIC_STAR_RANGE)
			continue
		for(var/turf/tile in range(2, star))
			if(star_line_clear(star, tile))
				affected |= tile
	return affected

/datum/eldritch_knowledge/base_cosmic/proc/stars_unchanged(list/snapshot)
	if(length(stars) != length(snapshot))
		return FALSE
	for(var/obj/structure/heretic_star/star as anything in stars)
		if(QDELETED(star) || get_turf(star) != snapshot[star])
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_cosmic/proc/nearest_star(atom/target, max_distance = HERETIC_STAR_RANGE)
	var/obj/structure/heretic_star/nearest
	var/distance = max_distance + 1
	for(var/obj/structure/heretic_star/star as anything in stars)
		if(star.z != target.z || !star_line_clear(star, target))
			continue
		var/candidate_distance = get_dist(star, target)
		if(candidate_distance < distance)
			distance = candidate_distance
			nearest = star
	return nearest

/datum/eldritch_knowledge/base_cosmic/proc/can_affect(mob/living/victim, chargecost = 0)
	return isliving(victim) && victim.stat != DEAD && astronomer?.current?.stat != DEAD && IS_HERETIC(astronomer?.current) && !IS_HERETIC(victim) && !IS_HERETIC_MONSTER(victim) && !victim.check_magic_resistance(chargecost = chargecost)

/datum/eldritch_knowledge/base_cosmic/proc/cross_thread(mob/living/victim)
	if(!isliving(victim) || victim.has_status_effect(/datum/status_effect/cosmic_thread_cooldown) || victim.has_status_effect(/datum/status_effect/heretic_cosmic_orbit) || !can_affect(victim))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(astronomer.current)
	victim.apply_status_effect(/datum/status_effect/cosmic_thread_cooldown, src)
	tether(victim)
	var/damage_before = victim.getFireLoss()
	victim.adjustStaminaLoss(25)
	victim.adjustFireLoss(10)
	if(victim.getFireLoss() > damage_before)
		heretic.advance_combat_deed(victim, PATH_COSMIC)
	victim.Knockdown(0.7 SECONDS)
	new /obj/effect/temp_visual/heretic_path_feedback(get_turf(victim), "cosmic_ring", "#96d7ed", 6)
	playsound(victim, 'modular_bluemoon/sound/heretic/cosmic_energy.ogg', 25, TRUE)
	if(heretic.get_knowledge(/datum/eldritch_knowledge/cosmic_mark))
		victim.apply_status_effect(/datum/status_effect/eldritch/cosmic, src)
	if(ascension_active)
		victim.adjustFireLoss(10)
	to_chat(victim, span_warning("Нить созвездия натягивается и вытягивает из вас силы!"))
	return TRUE

/datum/eldritch_knowledge/base_cosmic/proc/travel(mob/living/user, obj/structure/heretic_star/destination)
	if(QDELETED(destination) || !(destination in stars) || user?.mind != astronomer || user.incapacitated() || !isturf(user.loc) || !nearest_star(user, 1))
		return FALSE
	var/turf/landing = get_turf(destination)
	if(user.z != destination.z || !safe_star_turf(landing) || landing.is_blocked_turf(source_atom = user))
		return FALSE
	var/turf/origin = get_turf(user)
	if(!do_teleport(user, landing, channel = TELEPORT_CHANNEL_MAGIC))
		return FALSE
	new /obj/effect/temp_visual/heretic_spell/star_step(origin)
	new /obj/effect/temp_visual/heretic_spell/star_step(landing)
	playsound(landing, 'sound/magic/blink.ogg', 40, TRUE)
	if(get_turf(user) == landing)
		discharge_arrival(user, destination)
	return TRUE

/datum/eldritch_knowledge/base_cosmic/proc/discharge_arrival(mob/living/user, obj/structure/heretic_star/destination)
	if(QDELETED(destination) || !(destination in stars) || user?.mind != astronomer || user.incapacitated() || get_turf(user) != get_turf(destination))
		return FALSE
	var/discharged = FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	for(var/mob/living/victim in range(HERETIC_STAR_ARRIVAL_RADIUS, destination))
		var/datum/status_effect/eldritch/cosmic/mark = victim.has_status_effect(/datum/status_effect/eldritch/cosmic)
		if(mark?.constellation_ref?.resolve() != src || !isturf(victim.loc) || !star_line_clear(destination, victim) || !can_affect(victim, chargecost = 1))
			continue
		mark.on_effect()
		var/list/knowledge = heretic.get_all_knowledge()
		for(var/knowledge_type in knowledge)
			var/datum/eldritch_knowledge/entry = knowledge[knowledge_type]
			if(entry.route == PATH_COSMIC)
				entry.on_mark_detonated(user, victim)
		discharged = TRUE
		log_combat(user, victim, "активировал метку прибытием по Звёздной дороге")
	return discharged

/datum/eldritch_knowledge/base_cosmic/proc/pulse(mob/living/user, collapse = FALSE, list/telegraphed_turfs)
	if(user?.mind != astronomer || user.incapacitated() || !length(stars))
		return FALSE
	var/list/active_stars = list()
	for(var/obj/structure/heretic_star/star as anything in stars)
		if(star.z == user.z && get_dist(star, user) <= HERETIC_STAR_RANGE)
			active_stars += star
	if(!length(active_stars))
		return FALSE
	var/list/victims = list()
	for(var/obj/structure/heretic_star/star as anything in active_stars)
		if(collapse)
			new /obj/effect/temp_visual/heretic_spell(get_turf(star))
		else
			new /obj/effect/temp_visual/heretic_spell/domain(get_turf(star))
		for(var/mob/living/victim in range(2, star))
			if(collapse && !isnull(telegraphed_turfs) && !(get_turf(victim) in telegraphed_turfs))
				continue
			if(star_line_clear(star, victim))
				victims |= victim
	playsound(user, 'modular_bluemoon/sound/heretic/cosmic_expansion.ogg', collapse ? 50 : 35, TRUE)
	for(var/mob/living/victim as anything in victims)
		var/obj/structure/heretic_star/star = nearest_star(victim, 2)
		if(!star || !can_affect(victim, chargecost = 1))
			continue
		if(collapse)
			victim.adjustFireLoss(45)
			victim.Knockdown(1.5 SECONDS)
			pull_to_star(victim, star)
		else
			victim.adjustFireLoss(20)
			victim.adjustStaminaLoss(25)
			tether(victim)
			pulling = TRUE
			step_towards(victim, star)
			step_towards(victim, star)
			pulling = FALSE
			victim.apply_status_effect(/datum/status_effect/eldritch/cosmic, src)
		if(user)
			log_combat(user, victim, collapse ? "обрушил созвездие на" : "притянул пульсом созвездия")
	if(collapse)
		clear_stars()
	return TRUE

/obj/structure/heretic_star
	name = "Mansus star"
	desc = "Холодная звезда, приколотая к полу. Между такими звёздами натягиваются опасные видимые нити. Звезду можно разбить, а нулевой жезл гасит её одним касанием."
	icon = 'modular_bluemoon/icons/obj/heretic_effects.dmi'
	icon_state = "cosmic_star"
	anchored = TRUE
	density = FALSE
	max_integrity = 35
	obj_integrity = 35
	light_range = 2
	light_power = 1
	light_color = "#7bd7e8"
	var/datum/eldritch_knowledge/base_cosmic/constellation
	var/star_expires_at
	var/star_expiry_timer

/obj/structure/heretic_star/Initialize(mapload)
	. = ..()
	new /obj/effect/temp_visual/heretic_path_feedback(get_turf(src), "cosmic_gem", "#b5eaff", 12)
	SpinAnimation(80, -1)
	animate(src, alpha = 185, time = 15, loop = -1, flags = ANIMATION_PARALLEL)
	animate(alpha = 255, time = 15)
	star_expires_at = world.time + HERETIC_STAR_LIFETIME
	star_expiry_timer = addtimer(CALLBACK(src, PROC_REF(expire)), HERETIC_STAR_LIFETIME, TIMER_STOPPABLE)

/obj/structure/heretic_star/proc/expire()
	qdel(src)

/obj/structure/heretic_star/Destroy()
	deltimer(star_expiry_timer)
	star_expiry_timer = null
	if(isturf(loc))
		new /obj/effect/temp_visual/heretic_path_feedback(get_turf(src), "cosmic_cloud", "#7fabc9", 8)
	var/datum/eldritch_knowledge/base_cosmic/old_constellation = constellation
	constellation = null
	if(!QDELETED(old_constellation))
		old_constellation.remove_star(src)
	return ..()

/obj/structure/heretic_star/attackby(obj/item/item, mob/living/user, params)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	if(constellation?.orbit_heart(src, item, user, params))
		return STOP_ATTACK_PROC_CHAIN
	return ..()

/obj/structure/heretic_star/examine(mob/user)
	. = ..()
	var/orbit_line = constellation?.orbit_examine(src)
	if(orbit_line)
		. += orbit_line

/obj/structure/heretic_guide_star
	name = "cold point of light"
	desc = "Крошечная холодная звезда висит над полом. Хрупкая: её можно разбить или коснуться нулевым жезлом."
	icon = 'modular_bluemoon/icons/obj/heretic_effects.dmi'
	icon_state = "cosmic_star"
	anchored = TRUE
	density = FALSE
	alpha = HERETIC_COSMIC_GUIDE_ALPHA
	max_integrity = HERETIC_COSMIC_GUIDE_INTEGRITY
	light_range = 1
	light_power = 0.5
	light_color = "#7bd7e8"
	var/datum/weakref/cosmic_ref

/obj/structure/heretic_guide_star/Initialize(mapload, datum/eldritch_knowledge/base_cosmic/cosmic)
	. = ..()
	if(QDELETED(cosmic))
		return INITIALIZE_HINT_QDEL
	cosmic_ref = WEAKREF(cosmic)
	AddComponent(/datum/component/heretic_craft, cosmic, HERETIC_COSMIC_GUIDE_CRAFT, HERETIC_COSMIC_GUIDE_CLUE)
	new /obj/effect/temp_visual/heretic_path_feedback(get_turf(src), "cosmic_gem", "#b5eaff", 12)

/obj/structure/heretic_guide_star/attackby(obj/item/item, mob/living/user, params)
	var/datum/eldritch_knowledge/base_cosmic/cosmic = cosmic_ref?.resolve()
	if(cosmic?.orbit_heart(src, item, user, params))
		return STOP_ATTACK_PROC_CHAIN
	return ..()

/obj/structure/heretic_guide_star/examine(mob/user)
	. = ..()
	var/datum/eldritch_knowledge/base_cosmic/cosmic = cosmic_ref?.resolve()
	var/orbit_line = cosmic?.orbit_examine(src)
	if(orbit_line)
		. += orbit_line

/obj/structure/heretic_guide_star/Destroy()
	if(isturf(loc))
		new /obj/effect/temp_visual/heretic_path_feedback(get_turf(src), "cosmic_cloud", "#7fabc9", 8)
	cosmic_ref = null
	return ..()

/obj/effect/heretic_star_thread
	name = "constellation thread"
	desc = "Видимая нить соединяет две звезды. Враги, которые её пересекают или стоят на ней, получают ожоги, падают и замедляются. Разбейте звезду, чтобы разорвать нить."
	icon = null
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = SIGIL_LAYER
	var/datum/eldritch_knowledge/base_cosmic/constellation
	var/obj/structure/heretic_star/start
	var/obj/structure/heretic_star/end

/obj/effect/heretic_star_thread/Crossed(atom/movable/mover)
	. = ..()
	if(!constellation?.pulling)
		strike(mover)

/obj/effect/heretic_star_thread/proc/strike(mob/living/victim)
	if(!isliving(victim) || QDELETED(constellation) || QDELETED(start) || QDELETED(end) || !constellation.star_line_clear(start, end))
		return FALSE
	return constellation.cross_thread(victim)

/obj/effect/heretic_star_thread/Destroy()
	constellation = null
	start = null
	end = null
	return ..()

/obj/effect/ebeam/heretic_constellation
	name = "constellation thread"
	desc = "Видимая нить между звёздами. Разбейте одну из них, чтобы разорвать соединение."
	layer = SIGIL_LAYER
	alpha = 180

/datum/status_effect/cosmic_tether
	id = "cosmic_tether"
	duration = 3 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	/// Созвездие, чьё притяжение наложено последним.
	var/datum/weakref/source_ref

/datum/status_effect/cosmic_tether/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_cosmic/source)
	if(source)
		source_ref = WEAKREF(source)
	return ..()

/datum/status_effect/cosmic_tether/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/cosmic_tether)
	return TRUE

/datum/status_effect/cosmic_tether/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/cosmic_tether)
	return ..()

/datum/movespeed_modifier/cosmic_tether
	multiplicative_slowdown = 1.5

/datum/status_effect/cosmic_thread_cooldown
	id = "cosmic_thread_cooldown"
	duration = HERETIC_STAR_THREAD_COOLDOWN
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	var/datum/weakref/source_ref

/datum/status_effect/cosmic_thread_cooldown/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_cosmic/source)
	if(source)
		source_ref = WEAKREF(source)
	return ..()

/datum/status_effect/heretic_cosmic_orbit
	id = "heretic_cosmic_orbit"
	duration = HERETIC_COSMIC_ORBIT_DURATION
	tick_interval = HERETIC_COSMIC_ORBIT_STEP
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_cosmic_orbit
	examine_text = span_warning("SUBJECTPRONOUN кружит вокруг холодной звезды и не может вырваться. Разбейте звезду, коснитесь нулевым жезлом звезды или пленника или 2 секунды расталкивайте его.")
	var/datum/weakref/cosmic_ref
	var/atom/movable/star
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint
	var/applied = FALSE
	var/was_anchored = FALSE
	var/orbit_angle = 0
	var/base_pixel_w = 0
	var/base_pixel_z = 0

/datum/status_effect/heretic_cosmic_orbit/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_cosmic/cosmic, atom/movable/held_by)
	cosmic_ref = WEAKREF(cosmic)
	star = held_by
	return ..()

/datum/status_effect/heretic_cosmic_orbit/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_cosmic/cosmic = cosmic_ref?.resolve()
	if(!. || !cosmic || QDELETED(star) || !isturf(star.loc))
		return FALSE
	cosmic.orbits += src
	owner.pulledby?.stop_pulling()
	owner.buckled?.unbuckle_mob(owner, TRUE)
	cosmic.pulling = TRUE
	owner.forceMove(star.loc)
	cosmic.pulling = FALSE
	owner.stop_pulling()
	was_anchored = owner.anchored
	owner.set_anchored(TRUE)
	// Свой экземпляр не продлевает и не снимает чужой паралич.
	restraint = new(list(owner, HERETIC_COSMIC_ORBIT_DURATION, TRUE))
	base_pixel_w = owner.pixel_w
	base_pixel_z = owner.pixel_z
	applied = TRUE
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_owner_moved))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignals(owner, list(COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_LIVING_DEATH), PROC_REF(end_orbit))
	heretic_capture_hold(owner, HERETIC_COSMIC_CAPTURE)
	RegisterSignals(star, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED), PROC_REF(end_orbit))
	new /obj/effect/temp_visual/heretic_path_feedback(star.loc, "cosmic_ring", HERETIC_COSMIC_INK, 8)
	tick()
	owner.visible_message(span_danger("[owner] срывается с места и кружит вокруг холодной звезды!"), span_userdanger("Звезда поймала вас на орбиту: вы кружите вокруг неё и не можете вырваться!"))

/datum/status_effect/heretic_cosmic_orbit/tick()
	orbit_angle = (orbit_angle + 360 / HERETIC_COSMIC_ORBIT_POINTS) % 360
	animate(owner, pixel_w = base_pixel_w + round(HERETIC_COSMIC_ORBIT_RADIUS * cos(orbit_angle)), pixel_z = base_pixel_z + round(HERETIC_COSMIC_ORBIT_RADIUS * sin(orbit_angle)), time = HERETIC_COSMIC_ORBIT_STEP, flags = ANIMATION_PARALLEL)

/datum/status_effect/heretic_cosmic_orbit/proc/on_owner_moved(datum/source)
	SIGNAL_HANDLER
	if(owner.loc != star?.loc)
		qdel(src)

/datum/status_effect/heretic_cosmic_orbit/proc/on_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	user.visible_message(span_warning("[user] касается [source] нулевым жезлом, и звёздная орбита рвётся."), span_notice("Вы касаетесь [source] нулевым жезлом, и орбита рвётся."))
	log_game("[key_name(user)] срывает звёздную орбиту с [key_name(source)] нулевым жезлом в [AREACOORD(source)].")
	qdel(src)
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_cosmic_orbit/proc/end_orbit(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_cosmic_orbit/on_remove()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_ATTACKBY, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_LIVING_DEATH))
		heretic_capture_unhold(owner, HERETIC_COSMIC_CAPTURE)
		if(star)
			UnregisterSignal(star, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
		// Чужой Paralyze мог продлить этот экземпляр: тогда он остаётся.
		if(!QDELETED(restraint) && restraint.duration <= duration)
			qdel(restraint)
		owner.set_anchored(was_anchored)
		animate(owner, pixel_w = base_pixel_w, pixel_z = base_pixel_z, time = HERETIC_COSMIC_ORBIT_STEP, flags = ANIMATION_PARALLEL)
		heretic_capture_release(owner, HERETIC_COSMIC_CAPTURE)
	restraint = null
	star = null
	var/datum/eldritch_knowledge/base_cosmic/cosmic = cosmic_ref?.resolve()
	cosmic?.orbits -= src
	cosmic_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_cosmic_orbit
	name = "Орбита"
	desc = "Звезда держит вас на орбите до 10 секунд. Товарищ может разбить звезду, коснуться нулевым жезлом звезды или вас или 2 секунды вас расталкивать."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "cosmic_orbiting"

/datum/status_effect/eldritch/cosmic
	id = "cosmic_mark"
	mark_name = "Метка Космоса"
	mark_alert_state = "sigil_cosmic"
	effect_sprite = "emark7"
	detonation_sound = 'modular_bluemoon/sound/heretic/cosmic_expansion.ogg'
	detonation_visual = /obj/effect/temp_visual/heretic_path_feedback/cosmic_mark
	var/datum/weakref/constellation_ref

/datum/status_effect/eldritch/cosmic/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_cosmic/constellation)
	if(!QDELETED(constellation))
		constellation_ref = WEAKREF(constellation)
	. = ..()
	if(linked_alert)
		linked_alert.desc = "Клинок Космоса или прибытие хозяина метки по Звёздной дороге активируют её: 10 ожогов и 15 урона выносливости. Держитесь дальше одной клетки от его звёзд. Метка исчезнет через 15 секунд."

/datum/status_effect/eldritch/cosmic/on_effect()
	owner.adjustStaminaLoss(15)
	owner.adjustFireLoss(10)
	return ..()

/obj/item/melee/sickly_blade/cosmic
	name = "cosmic blade"
	desc = "Серп, внутри которого движутся далёкие звёзды. Удар по метке Космоса обжигает и изматывает жертву."
	icon = 'modular_bluemoon/icons/obj/heretic.dmi'
	icon_state = "cosmic_blade"
	item_state = "cosmic_blade"
	route = PATH_COSMIC
	mark_type = /datum/status_effect/eldritch/cosmic

/obj/effect/proc_holder/spell/self/cosmic
	clothes_req = FALSE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "star_touch"
	action_background_icon_state = "bg_ecult"
	charge_max = 20 SECONDS

/obj/effect/proc_holder/spell/self/cosmic/can_cast(mob/user, skipcharge, silent)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return . && heretic_check(user, heretic?.selected_path == PATH_COSMIC && !user.incapacitated(), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/cosmic/manifest
	parent_type = /obj/effect/proc_holder/spell/pointed
	name = "Зажечь звезду"
	desc = "Укажите свободный пол до семи клеток от себя. Если рядом с вами нет своей звезды, вторая загорится под вами и между ними натянется нить; нажатие на свою звезду гасит её."
	summary = "Звезда на пол до 7 клеток; без своей звезды рядом вторая встаёт под вами, между ними нить."
	clothes_req = FALSE
	range = HERETIC_STAR_RANGE
	selection_type = "view"
	aim_assist = FALSE
	self_castable = TRUE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "star_touch"
	action_background_icon_state = "bg_ecult"
	active_msg = "Укажите свободный пол для новой звезды."
	deactive_msg = "Вы отпускаете звёздную нить."
	charge_max = 6 SECONDS

/obj/effect/proc_holder/spell/self/cosmic/manifest/can_cast(mob/user, skipcharge, silent)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return . && heretic_check(user, heretic?.selected_path == PATH_COSMIC && !user.incapacitated(), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/cosmic/manifest/intercept_check(mob/user, atom/target, silent = FALSE)
	return ..(user, get_turf(target), silent)

/obj/effect/proc_holder/spell/self/cosmic/manifest/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!knowledge)
		return FALSE
	var/turf/place = get_turf(target)
	for(var/obj/structure/heretic_star/star as anything in knowledge.stars)
		if(star.loc == place)
			return TRUE
	if(knowledge.safe_star_turf(place))
		return TRUE
	if(!silent)
		to_chat(user, span_warning("Здесь звезде мешает преграда. Выберите свободный пол; существа и лежащие предметы не мешают."))
	return FALSE

/obj/effect/proc_holder/spell/self/cosmic/manifest/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!length(targets) || !knowledge?.manifest(get_turf(targets[1]), user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/cosmic/step
	parent_type = /obj/effect/proc_holder/spell/pointed
	name = "Звёздная дорога"
	desc = "Стоя вплотную к своей звезде, укажите другую звезду созвездия. Щелчок по себе ведёт к путеводной звезде на этом уровне: 2 секунды на месте, даже в чужой хватке."
	summary = "Перенос к звезде созвездия, а щелчком по себе - к путеводной звезде на уровне."
	clothes_req = FALSE
	range = HERETIC_STAR_RANGE
	self_castable = TRUE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"
	charge_max = 18 SECONDS
	action_icon_state = "space_crawl"
	active_msg = "Укажите звезду или щёлкните по себе, чтобы выбрать путеводную звезду."
	deactive_msg = "Вы отпускаете звёздную нить."

/obj/effect/proc_holder/spell/self/cosmic/step/can_cast(mob/user, skipcharge, silent)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!. || !heretic_check(user, heretic?.selected_path == PATH_COSMIC && knowledge && !user.incapacitated(ignore_grab = TRUE), silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	if(length(knowledge.guide_stars_on_level(user)) || (knowledge.nearest_star(user, 1) && !user.incapacitated()))
		return TRUE
	if(!silent)
		to_chat(user, span_warning("Встаньте рядом со своей звездой или зажгите на этом уровне путеводную звезду Хваткой в «Помощи» по полу."))
	return FALSE

/obj/effect/proc_holder/spell/self/cosmic/step/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!knowledge)
		return FALSE
	if(target == user)
		return heretic_check(user, length(knowledge.guide_stars_on_level(user)), silent, "На этом уровне нет ваших путеводных звёзд: зажгите их Хваткой в «Помощи» по полу.")
	if(istype(target, /obj/structure/heretic_guide_star))
		return heretic_check(user, (target in knowledge.guide_stars), silent, "Дорога ведёт только к вашей путеводной звезде.")
	return istype(target, /obj/structure/heretic_star) && (target in knowledge.stars) && target.loc != user.loc

/obj/effect/proc_holder/spell/self/cosmic/step/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!length(targets) || !knowledge || !can_target(targets[1], user, TRUE))
		heretic_revert_cast(user)
		return
	var/atom/target = targets[1]
	if(istype(target, /obj/structure/heretic_star))
		if(!knowledge.travel(user, target))
			heretic_revert_cast(user, user.incapacitated() ? "Из чужой хватки дорога ведёт только к путеводной звезде: щёлкните по себе." : null)
		return
	var/obj/structure/heretic_guide_star/guide = target
	if(target == user)
		var/reason = knowledge.guide_road_start_failure(user)
		if(reason)
			heretic_revert_cast(user, reason)
			return
		guide = knowledge.choose_guide_star(user)
		if(!guide)
			revert_cast(user)
			return
	if(!knowledge.guide_road(user, guide))
		heretic_revert_cast(user, knowledge.cosmic_failure)

/obj/effect/proc_holder/spell/self/cosmic/pulse
	name = "Гравитационный пульс"
	desc = "Ваши звёзды в семи клетках бьют врагов в двух клетках от себя: 20 ожогов, 25 урона выносливости, притяжение на две клетки и метка Космоса."
	summary = "Звёзды в 7 клетках бьют, подтягивают и метят врагов в 2 клетках от себя."
	charge_max = 22 SECONDS
	action_icon_state = "cosmic_domain"

/obj/effect/proc_holder/spell/self/cosmic/pulse/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!knowledge?.pulse(user))
		heretic_revert_cast(user, "Рядом нет ваших звёзд: пульс исходит только от звёзд не дальше семи клеток.")

/obj/effect/proc_holder/spell/self/cosmic/collapse
	name = "Схлопывание"
	desc = "Через 1,5 секунды звёзды в семи клетках взрываются: 45 ожогов, падение и притяжение к звезде. Созвездие расходуется, путеводные звёзды остаются."
	summary = "Через 1,5 секунды звёзды взрываются: 45 ожогов, враги стягиваются к звёздам."
	charge_max = 35 SECONDS
	action_icon_state = "star_blast"
	var/collapse_pending = FALSE

/obj/effect/proc_holder/spell/self/cosmic/collapse/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(collapse_pending || !length(knowledge?.stars))
		heretic_revert_cast(user)
		return
	var/list/telegraphed_turfs = knowledge.collapse_turfs(user)
	if(!length(telegraphed_turfs))
		heretic_revert_cast(user, "Рядом нет ваших звёзд: схлопнуть можно только звёзды не дальше семи клеток.")
		return
	var/list/star_snapshot = list()
	for(var/obj/structure/heretic_star/star as anything in knowledge.stars)
		star_snapshot[star] = get_turf(star)
		star.visible_message(span_danger("Звезда вспыхивает. Созвездие вот-вот схлопнется!"))
	playsound(user, 'modular_bluemoon/sound/heretic/cosmic_charge.ogg', 40, FALSE)
	for(var/turf/tile as anything in telegraphed_turfs)
		new /obj/effect/temp_visual/heretic_path_feedback(tile, "cosmic_carpet", "#efb780", HERETIC_STAR_COLLAPSE_DELAY)
	collapse_pending = TRUE
	knowledge.collapse_pending_until = world.time + HERETIC_STAR_COLLAPSE_DELAY
	addtimer(CALLBACK(src, PROC_REF(finish_collapse), WEAKREF(user), WEAKREF(knowledge), star_snapshot, telegraphed_turfs), HERETIC_STAR_COLLAPSE_DELAY)

/obj/effect/proc_holder/spell/self/cosmic/collapse/proc/finish_collapse(datum/weakref/user_ref, datum/weakref/knowledge_ref, list/star_snapshot, list/telegraphed_turfs)
	collapse_pending = FALSE
	var/mob/living/user = user_ref.resolve()
	var/datum/eldritch_knowledge/base_cosmic/knowledge = knowledge_ref.resolve()
	if(knowledge)
		knowledge.collapse_pending_until = 0
	if(!user || !knowledge)
		return FALSE
	if(!knowledge.stars_unchanged(star_snapshot))
		heretic_revert_cast(user, "Звезду разбили или сдвинули во время предупреждения, схлопывание сорвалось. Перезарядка возвращена.")
		return FALSE
	if(!knowledge.pulse(user, collapse = TRUE, telegraphed_turfs = telegraphed_turfs))
		heretic_revert_cast(user, "Схлопывание сорвалось: рядом не осталось ваших звёзд. Перезарядка возвращена.")
		return FALSE
	return TRUE

/obj/effect/proc_holder/spell/self/cosmic/stargazer
	name = "Звездочёт"
	desc = "Призовите Звездочёта: он следует за вами и раз в 3 секунды бьёт лучом ближайшего врага в семи клетках. Его гибель или ваша смерть запускают перезарядку в 3 минуты."
	summary = "Звездочёт: 400 здоровья, луч в 20 ожогов по врагу раз в 3 секунды."
	charge_max = HERETIC_STARGAZER_COOLDOWN
	action_icon_state = "cosmic_rune"

/obj/effect/proc_holder/spell/self/cosmic/stargazer/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/finale = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/cosmic_final)
	if(!heretic_check(user, finale?.finished && finale.applied_body == user, silent, "Сначала завершите вознесение."))
		return FALSE
	return heretic_check(user, QDELETED(finale.stargazer), silent, "Звездочёт уже парит рядом с вами: второго не призвать, пока он жив.")

/obj/effect/proc_holder/spell/self/cosmic/stargazer/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/finale = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/cosmic_final)
	if(!finale?.summon_stargazer(user))
		heretic_revert_cast(user)
		return
	// Перезарядка начинается с гибели Звездочёта, а не с призыва.
	charge_counter = charge_max
	recharging = FALSE

/obj/effect/proc_holder/spell/self/cosmic/orbit
	parent_type = /obj/effect/proc_holder/spell/pointed
	name = "Орбита"
	desc = "Укажите сбитую или скованную звёздами цель в двух клетках от своей звезды: через секунду она 10 секунд кружит у звезды. Цель охоты на орбите сердце за секунду уводит к звёздам в изнанку. Товарищ растолкает пленника за 2 секунды."
	summary = "10 секунд держит поверженную цель на орбите вашей звезды."
	clothes_req = FALSE
	range = HERETIC_STAR_RANGE
	selection_type = "view"
	aim_assist_radius = 1
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "cosmic_orbit"
	action_background_icon_state = "bg_ecult"
	active_msg = "Укажите поверженную цель рядом со своей звездой."
	deactive_msg = "Вы отпускаете звёздную нить."
	charge_max = HERETIC_COSMIC_ORBIT_COOLDOWN

/obj/effect/proc_holder/spell/self/cosmic/orbit/can_cast(mob/user, skipcharge, silent)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return . && heretic_check(user, heretic?.selected_path == PATH_COSMIC && heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic) && !user.incapacitated(), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/cosmic/orbit/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!heretic_check(user, knowledge, silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	var/reason = knowledge.orbit_block_reason(user, target)
	return heretic_check(user, !reason, silent, reason, target = target)

/obj/effect/proc_holder/spell/self/cosmic/orbit/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!length(targets) || !knowledge?.orbit(user, targets[1]))
		heretic_revert_cast(user, knowledge?.cosmic_failure)

/datum/eldritch_knowledge/cosmic_grasp
	name = "Притяжение"
	summary = "Хватка жжёт ещё на 15 и замедляет на 3 секунды, а рядом со звездой подтягивает к ней."
	details = list(
		"Своя звезда не дальше 4 клеток по свободной линии подтягивает врага на клетку; преграды останавливают.",
		"Замедлённый Притяжением враг 3 секунды годится для Орбиты.",
		"Замедление не защищает от нитей: притянутый на нить враг получает и её удар.",
	)
	role = HERETIC_ROLE_GRASP
	cost = 1
	route = PATH_COSMIC

/datum/eldritch_knowledge/cosmic_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!proximity_flag || !isliving(target) || !knowledge?.can_affect(target))
		return FALSE
	var/mob/living/victim = target
	victim.adjustFireLoss(15)
	knowledge.tether(victim)
	var/obj/structure/heretic_star/star = knowledge.nearest_star(target, 4)
	if(star)
		step_towards(target, star)
	return TRUE

/datum/eldritch_knowledge/spell/cosmic_step
	name = "Звёздная дорога"
	summary = "Переносит между звёздами созвездия, а к путеводной звезде - с любого места уровня."
	details = list(
		"Встаньте вплотную к своей звезде и укажите другую звезду созвездия: перенос мгновенный.",
		"Щелчок по себе ведёт к путеводной звезде на этом уровне, видимую звезду можно указать сразу.",
		"К путеводной звезде - 2 секунды на месте, от вас к ней тянется хвост кометы.",
		"Дорога к путеводной звезде работает и в чужой хватке, но сдвиг с места её срывает.",
		"Прибытие к звезде созвездия взрывает ваши метки Космоса в клетке от выхода: 10 ожогов, 15 выносливости.",
		"Перезарядка 18 секунд, дорога к путеводной звезде - раз в 30 секунд.",
		"Наручники, щит разума, зоны без телепортации и занятый выход закрывают дорогу.",
	)
	role = HERETIC_ROLE_ESCAPE
	cost = 1
	route = PATH_COSMIC
	spell_to_add = /obj/effect/proc_holder/spell/self/cosmic/step

/datum/eldritch_knowledge/cosmic_mark
	name = "Метка Космоса"
	summary = "Хватка и нити ставят метку Космоса, клинок или ваше прибытие рядом её взрывают."
	details = list(
		"Взрыв метки: 10 ожогов и 15 урона выносливости.",
		"Прибытие по Звёздной дороге к звезде созвездия взрывает метки в клетке от выхода.",
		"Метка держится 15 секунд: уходите вдоль созвездия и возвращайтесь к отмеченным.",
	)
	role = HERETIC_ROLE_MARK
	cost = 2
	route = PATH_COSMIC

/datum/eldritch_knowledge/cosmic_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!proximity_flag || !knowledge || !isliving(target))
		return FALSE
	var/mob/living/victim = target
	if(IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || victim.check_magic_resistance())
		return FALSE
	victim.apply_status_effect(/datum/status_effect/eldritch/cosmic, knowledge)
	return TRUE

/datum/eldritch_knowledge/cosmic_expansion
	name = "Третья точка"
	summary = "Созвездие вмещает три звезды, последняя замыкается на первую."
	details = list(
		"Если прямая между последней и первой звездой свободна, нити складываются в треугольник.",
		"Путеводные звёзды в этот лимит не входят.",
	)
	role = HERETIC_ROLE_PASSIVE
	cost = 1
	route = PATH_COSMIC

/datum/eldritch_knowledge/spell/cosmic_orbit
	name = "Орбита"
	summary = "Держит сбитую или скованную звёздами цель на орбите вашей звезды 10 секунд."
	details = list(
		"Цель не дальше 2 клеток от своей звезды, обычной или путеводной, по открытой линии.",
		"Годится сбитая с ног или обессиленная цель либо замедленная нитью, Притяжением или пульсом.",
		"Секунду вокруг цели горит кольцо: если она сошла с клетки или вас оглушили, Орбита рассыпается.",
		"Затем цель 10 секунд кружит у звезды: не действует, её не утащить; «Помощь» не будит, растолкать - 2 секунды.",
		"Цель охоты на Орбите сердце за секунду уводит к звёздам в изнанку.",
		"Разбитая звезда или нулевой жезл по звезде или пленнику освобождают его. Защита от магии спасает от Орбиты.",
		"После Орбиты цель минуту к ней невосприимчива и 15 секунд - к любому захвату. Перезарядка 40 секунд.",
	)
	role = HERETIC_ROLE_CAPTURE
	cost = 2
	route = PATH_COSMIC
	spell_to_add = /obj/effect/proc_holder/spell/self/cosmic/orbit

/datum/eldritch_knowledge/spell/cosmic_orbit/pocket_door(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/cosmic = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!cosmic?.orbit_door_holds(user, victim))
		return null
	return list("name" = "к звёздам", "text" = "Звезда, вокруг которой кружит [victim], втягивает пленника в себя.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(cosmic, TYPE_PROC_REF(/datum/eldritch_knowledge/base_cosmic, orbit_door_holds), user, victim))

/datum/eldritch_knowledge/spell/cosmic_pulse
	name = "Гравитационный пульс"
	summary = "Ваши звёзды в 7 клетках бьют врагов в 2 клетках, подтягивают их и ставят метку."
	details = list(
		"20 ожогов, 25 урона выносливости, притяжение на 2 клетки и замедление на 3 секунды.",
		"Одна цель получает эффект раз за применение; притяжение через нить не ранит, потом нити бьют как обычно.",
		"Без своих звёзд в 7 клетках пульс не срабатывает и не уходит на перезарядку.",
		"Перезарядка 22 секунды.",
	)
	role = HERETIC_ROLE_CONTROL
	cost = 1
	route = PATH_COSMIC
	spell_to_add = /obj/effect/proc_holder/spell/self/cosmic/pulse

/datum/eldritch_knowledge/cosmic_resonance
	name = "Неподвижный небосвод"
	summary = "Прочность звёзд созвездия от 70, а стекло и золото на руне дают астролябию."
	details = list(
		"Прочность звёзд созвездия от 70 и сразу восстанавливается; путеводные остаются на 40.",
		"Астролябия у первой звезды за 1,5 секунды поворачивает созвездие на четверть оборота.",
		"Щелчок астролябией по своей звезде в 7 клетках через 1,5 секунды сжигает её: 30 ожогов в 2 клетках.",
		"Стены закрывают от вспышки, разбитая звезда её отменяет; остальные звёзды целы.",
		"Поворот и вспышка делят перезарядку 25 секунд; астролябия одна.",
	)
	role = HERETIC_ROLE_RELIC
	cost = 2
	route = PATH_COSMIC
	required_atoms = list(/obj/item/stack/sheet/glass, /obj/item/stack/sheet/mineral/gold)
	result_atoms = list(/obj/item/heretic_path_relic/astrolabe)

/datum/eldritch_knowledge/cosmic_resonance/on_gain(mob/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	for(var/obj/structure/heretic_star/star as anything in knowledge?.stars)
		star.max_integrity = passive_values[passive_level]
		star.obj_integrity = star.max_integrity

/datum/eldritch_knowledge/spell/cosmic_collapse
	name = "Схлопывание"
	summary = "Через 1,5 секунды звёзды рядом взрываются: 45 ожогов, падение и притяжение к звезде."
	details = list(
		"Бьют ваши звёзды в 7 клетках, каждая - в радиусе 2 клеток; область подсвечена заранее.",
		"45 ожогов, падение на 1,5 секунды, все поражённые стягиваются на клетку своей звезды.",
		"Во время предупреждения можно двигаться; созвездие расходуется, путеводные звёзды - нет.",
		"Разбитая или сдвинутая звезда, ваше оглушение или звёзды вне 7 клеток срывают удар и возвращают перезарядку.",
		"Перезарядка 35 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_COSMIC
	spell_to_add = /obj/effect/proc_holder/spell/self/cosmic/collapse

/datum/eldritch_knowledge/final_eldritch/cosmic_final
	parallax_scene = ANTAG_SCENE_HERETIC_COSMIC
	name = "Небо внутри"
	summary = "Под шагами загораются звёзды, нити жгут вдвое сильнее, рядом парит Звездочёт."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; место обряда 30 секунд видно всей станции.",
		"Созвездие до 5 звёзд, нити жгут на 20 вместо 10.",
		"За каждые 4 секунды движения под вами загорается звезда, при полном созвездии - вместо старейшей.",
		"Космос не сносит вас инерцией.",
		"Звездочёт: 400 здоровья, раз в 3 секунды луч в 20 ожогов по ближайшему врагу в 7 клетках.",
		"Звездочёт один; его гибель или ваша смерть запускают перезарядку призыва в 3 минуты.",
		"Смерть снимает эти усиления, оживление возвращает; звёзды гасит нулевой жезл.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Небо внутри открыло глаз. Теперь за мной идёт тот, кто смотрит на звёзды, и под каждым моим шагом загорается новая."
	route = PATH_COSMIC
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_traits = list(TRAIT_SPACEWALK)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/cosmic/stargazer)
	var/datum/weakref/cosmic_knowledge_ref
	var/mob/living/simple_animal/heretic_stargazer/stargazer

/datum/eldritch_knowledge/final_eldritch/cosmic_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/cosmic = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!cosmic)
		return
	cosmic.ascension_active = TRUE
	cosmic.notify_resource_changed()
	cosmic_knowledge_ref = WEAKREF(cosmic)
	user.AddComponent(/datum/component/heretic_cosmic_wake, cosmic)

/datum/eldritch_knowledge/final_eldritch/cosmic_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_cosmic_wake))
	dismiss_stargazer()
	var/datum/eldritch_knowledge/base_cosmic/cosmic = cosmic_knowledge_ref?.resolve()
	if(cosmic)
		cosmic.ascension_active = FALSE
		cosmic.notify_resource_changed()
	cosmic_knowledge_ref = null
	return ..()

/datum/eldritch_knowledge/final_eldritch/cosmic_final/proc/summon_stargazer(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!finished || !heretic || applied_body != user || user.incapacitated() || !isturf(user.loc) || !QDELETED(stargazer))
		return FALSE
	var/turf/landing = get_turf(user)
	for(var/turf/candidate in orange(1, user))
		if(isopenturf(candidate) && !candidate.is_blocked_turf())
			landing = candidate
			break
	stargazer = new(landing, src)
	stargazer.mind_initialize()
	var/datum/antagonist/heretic_monster/servant = new
	servant.set_master(heretic)
	stargazer.mind.add_antag_datum(servant)
	playsound(landing, 'modular_bluemoon/sound/heretic/cosmic_expansion.ogg', 50, TRUE)
	user.visible_message(span_danger("Над [user] раскрывается звёздная прореха, и из неё выплывает Звездочёт!"))
	log_game("[key_name(user)] призывает Звездочёта в [AREACOORD(user)].")
	stargazer.arrive(user)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/cosmic_final/proc/dismiss_stargazer()
	if(!QDELETED(stargazer))
		stargazer.dissolve()
	stargazer = null

/// Перезарядка призыва считается от потери Звездочёта, в том числе вместе с телом героя.
/datum/eldritch_knowledge/final_eldritch/cosmic_final/proc/stargazer_lost(mob/living/simple_animal/heretic_stargazer/lost)
	if(!lost || stargazer != lost)
		return
	stargazer = null
	ascension_spell_ready_at[/obj/effect/proc_holder/spell/self/cosmic/stargazer] = world.time + HERETIC_STARGAZER_COOLDOWN
	for(var/obj/effect/proc_holder/spell/self/cosmic/stargazer/spell in ascension_spell_instances)
		spell.charge_counter = 0
		spell.start_recharge()
		spell.action?.UpdateButtons()
	if(applied_body)
		to_chat(applied_body, span_warning("Звездочёт угас. Новый откликнется через [DisplayTimeText(HERETIC_STARGAZER_COOLDOWN)]."))

/datum/component/heretic_cosmic_wake
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/cosmic_ref
	var/last_step_time = 0
	var/moving_time = 0

/datum/component/heretic_cosmic_wake/Initialize(datum/eldritch_knowledge/base_cosmic/cosmic)
	if(!isliving(parent) || QDELETED(cosmic))
		return COMPONENT_INCOMPATIBLE
	cosmic_ref = WEAKREF(cosmic)

/datum/component/heretic_cosmic_wake/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/heretic_cosmic_wake/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_EXAMINE))

/datum/component/heretic_cosmic_wake/proc/on_moved(mob/living/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	var/elapsed = world.time - last_step_time
	last_step_time = world.time
	if(forced || elapsed > HERETIC_COSMIC_WAKE_STEP_GAP)
		return
	moving_time = min(moving_time + elapsed, HERETIC_COSMIC_WAKE_INTERVAL)
	if(moving_time < HERETIC_COSMIC_WAKE_INTERVAL)
		return
	var/datum/eldritch_knowledge/base_cosmic/cosmic = cosmic_ref?.resolve()
	if(!cosmic?.can_trail_star(source))
		return
	moving_time = 0
	INVOKE_ASYNC(cosmic, TYPE_PROC_REF(/datum/eldritch_knowledge/base_cosmic, trail_star), source)

/datum/component/heretic_cosmic_wake/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Под [source.ru_ego()] шагами загораются звёзды: за каждые 4 секунды движения новая, не больше пяти сразу, и нити между ними жгут. Звёзды можно разбить, нулевой жезл гасит их касанием. Космос [source.ru_ego()] не сносит, а рядом может парить Звездочёт - его берёт только летальное оружие, и его можно убить отдельно.")

#undef HERETIC_STAR_RANGE
#undef HERETIC_STAR_LIFETIME
#undef HERETIC_STAR_BASE_LIMIT
#undef HERETIC_STAR_EXPANDED_LIMIT
#undef HERETIC_STAR_ASCENDED_LIMIT
#undef HERETIC_STAR_ARRIVAL_RADIUS
#undef HERETIC_STAR_FLARE_RADIUS
#undef HERETIC_STAR_FLARE_DAMAGE
#undef HERETIC_STAR_FLARE_COOLDOWN
#undef HERETIC_STAR_THREAD_COOLDOWN
#undef HERETIC_STAR_THREAD_SWEEP
#undef HERETIC_STAR_COLLAPSE_DELAY
#undef HERETIC_COSMIC_GUIDE_CRAFT
#undef HERETIC_COSMIC_GUIDE_CLUE
#undef HERETIC_COSMIC_GUIDE_ALPHA
#undef HERETIC_COSMIC_CAPTURE
#undef HERETIC_COSMIC_INK
#undef HERETIC_COSMIC_ORBIT_RADIUS
#undef HERETIC_COSMIC_ORBIT_POINTS
#undef HERETIC_COSMIC_ORBIT_STEP
