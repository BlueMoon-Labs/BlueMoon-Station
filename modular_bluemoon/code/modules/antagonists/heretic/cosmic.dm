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

/datum/eldritch_knowledge/base_cosmic
	name = "Карта без неба"
	desc = "Открывает Путь Космоса: одним применением поставьте пару звёзд вдоль свободной прямой и перекройте проход опасной нитью. Преграда между вами и выбранным местом оставит только дальнюю звезду. Новая звезда тянет нить к самой свежей своей звезде, до которой есть свободная прямая, а если такой нет, встаёт отдельно и остальные не гаснут. Нити обжигают, сбивают и замедляют врагов, которые их пересекают или стоят на них; звёзды можно разбить. Новые звёзды заменяют старые при полном лимите, поэтому созвездие легко перенести вслед за боем. Нож и лист стекла создают космический клинок."
	gain_text = "Между двумя точками лежит не пустота. Между ними лежит закон."
	route = PATH_COSMIC
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/glass)
	result_atoms = list(/obj/item/melee/sickly_blade/cosmic)
	var/list/stars = list()
	var/list/threads = list()
	var/list/beams = list()
	var/datum/mind/astronomer
	var/obj/effect/proc_holder/spell/self/cosmic/manifest/manifest_spell
	var/clearing_stars = FALSE
	var/pulling = FALSE
	var/thread_sweep_timer
	var/ascension_active = FALSE
	var/collapse_pending_until = 0

/datum/eldritch_knowledge/base_cosmic/on_body_gain(mob/living/user)
	if(!user?.mind || !QDELETED(manifest_spell))
		return
	astronomer = user.mind
	manifest_spell = new
	user.mind.AddSpell(manifest_spell)

/datum/eldritch_knowledge/base_cosmic/on_body_lose(mob/living/user)
	QDEL_NULL(manifest_spell)
	clear_stars()
	astronomer = null

/datum/eldritch_knowledge/base_cosmic/Destroy()
	on_body_lose(astronomer?.current)
	return ..()

/datum/eldritch_knowledge/base_cosmic/proc/star_limit()
	if(ascension_active)
		return HERETIC_STAR_ASCENDED_LIMIT
	var/datum/antagonist/heretic/heretic = astronomer?.has_antag_datum(/datum/antagonist/heretic)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/cosmic_expansion) ? HERETIC_STAR_EXPANDED_LIMIT : HERETIC_STAR_BASE_LIMIT

/datum/eldritch_knowledge/base_cosmic/get_combat_resource_data()
	return list("name" = "Звёзды", "value" = length(stars), "max" = star_limit(), "description" = "Первая пара создаётся одним применением вдоль свободной прямой; преграда оставляет только дальнюю звезду. Звёзды живут три минуты. Нити наносят 10 ожогов и 25 урона выносливости, сбивают на 0,7 секунды и замедляют на 3 секунды. Одну цель нить ранит не чаще раза в 3 секунды, и когда её пересекают, и когда на ней стоят; замедление от хватки и пульса от нитей не защищает. Звёзды можно разбить; новая заменяет старейшую при полном лимите.")

/datum/eldritch_knowledge/base_cosmic/proc/clear_stars()
	deltimer(thread_sweep_timer)
	thread_sweep_timer = null
	clearing_stars = TRUE
	QDEL_LIST(threads)
	QDEL_LIST(beams)
	QDEL_LIST(stars)
	clearing_stars = FALSE
	notify_resource_changed()

/datum/eldritch_knowledge/base_cosmic/proc/add_star(turf/place, mob/living/user, counts_for_deed = TRUE)
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
	if(counts_for_deed)
		heretic.advance_deed(heretic.deed_key_for(place), place, silent = TRUE)
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
	. = add_star(place, user, counts_for_deed = FALSE)
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
	schedule_thread_sweep()

/datum/eldritch_knowledge/base_cosmic/proc/schedule_thread_sweep()
	if(!thread_sweep_timer && length(threads))
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
	if(!isliving(victim) || victim.has_status_effect(/datum/status_effect/cosmic_thread_cooldown) || !can_affect(victim))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(astronomer.current)
	victim.apply_status_effect(/datum/status_effect/cosmic_thread_cooldown)
	victim.apply_status_effect(/datum/status_effect/cosmic_tether)
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
		else
			victim.adjustFireLoss(20)
			victim.adjustStaminaLoss(25)
			victim.apply_status_effect(/datum/status_effect/cosmic_tether)
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

/obj/structure/heretic_star/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
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
	desc = "Укажите свободную видимую клетку до семи клеток от вас; можно нажать на предмет или существо на ней. Звезда появится в выбранном месте; если рядом с вами нет ни одной своей звезды, а до места есть свободная прямая, ещё одна загорится под вами. Новая звезда тянет нить к самой свежей своей звезде, до которой есть свободная прямая; если такой нет, она встаёт отдельно, а остальные звёзды не гаснут. При полном лимите новая звезда заменяет старейшую. Нажатие на свою звезду гасит её."
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
	desc = "Стоя рядом со своей звездой, переместитесь к другой видимой звезде созвездия. Прибытие активирует ваши метки Космоса на врагах в одной клетке от выхода: 10 ожогов и 15 урона выносливости. Заблокированная точка не принимает путешественника."
	clothes_req = FALSE
	range = HERETIC_STAR_RANGE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"
	charge_max = 18 SECONDS
	action_icon_state = "space_crawl"
	active_msg = "Укажите звезду, к которой хотите переместиться."
	deactive_msg = "Вы отпускаете звёздную нить."

/obj/effect/proc_holder/spell/self/cosmic/step/can_cast(mob/user, skipcharge, silent)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!. || !heretic_check(user, heretic?.selected_path == PATH_COSMIC && knowledge && !user.incapacitated(), silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	if(!knowledge.nearest_star(user, 1))
		if(!silent)
			to_chat(user, span_warning("Сначала встаньте рядом со своей звездой."))
		return FALSE
	return TRUE

/obj/effect/proc_holder/spell/self/cosmic/step/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	return istype(target, /obj/structure/heretic_star) && (target in knowledge?.stars) && target.loc != user.loc

/obj/effect/proc_holder/spell/self/cosmic/step/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!length(targets) || !can_target(targets[1], user, TRUE) || !knowledge.travel(user, targets[1]))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/cosmic/pulse
	name = "Гравитационный пульс"
	desc = "Ваши звёзды в семи клетках наносят врагам рядом 20 ожогов и 25 урона выносливости, подтягивают на две клетки и замедляют на 3 секунды. Радиус каждой звезды — две клетки. Накладывает метку Космоса. Без своих звёзд в семи клетках пульс не срабатывает и не уходит на перезарядку."
	charge_max = 22 SECONDS
	action_icon_state = "cosmic_domain"

/obj/effect/proc_holder/spell/self/cosmic/pulse/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!knowledge?.pulse(user))
		heretic_revert_cast(user, "Рядом нет ваших звёзд: пульс исходит только от звёзд не дальше семи клеток.")

/obj/effect/proc_holder/spell/self/cosmic/collapse
	name = "Схлопнуть созвездие"
	desc = "Через 1,5 секунды звёзды в семи клетках наносят врагам рядом 45 ожогов и сбивают на 1,5 секунды. Можно двигаться во время предупреждения. Всё созвездие расходуется; враги могут покинуть подсвеченную область или разбить звезду. Если звезду разобьют или сдвинут, вас оглушат или рядом не останется своих звёзд, схлопывание сорвётся, а перезарядка вернётся."
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
	desc = "Призовите рядом с собой Звездочёта: у него 400 здоровья, он следует за вами и раз в 3 секунды бьёт лучом в 20 ожогов ближайшего врага в семи клетках, если линию не закрывают стены, окна или закрытые двери. Врагов в крите, без сознания и под антимагией он не трогает, а сквозь союзников Мансуса луч проходит. Отстав больше чем на 12 клеток, Звездочёт переносится к вам; двери сам не открывает. Пока он жив, второго не призвать. Его гибель или ваша смерть запускают перезарядку в 3 минуты."
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

/datum/eldritch_knowledge/cosmic_grasp
	name = "Притяжение"
	desc = "Хватка Мансуса наносит ещё 15 ожогов и замедляет на 3 секунды. Если рядом есть ваша звезда, противника также подтягивает на одну клетку к ней. Преграды останавливают притяжение. Замедление не защищает от нитей: притянутый на нить враг получает и её удар."
	cost = 1
	route = PATH_COSMIC

/datum/eldritch_knowledge/cosmic_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!proximity_flag || !isliving(target) || !knowledge?.can_affect(target))
		return FALSE
	var/mob/living/victim = target
	victim.adjustFireLoss(15)
	victim.apply_status_effect(/datum/status_effect/cosmic_tether)
	var/obj/structure/heretic_star/star = knowledge.nearest_star(target, 4)
	if(star)
		step_towards(target, star)
	return TRUE

/datum/eldritch_knowledge/spell/cosmic_step
	name = "Звёздная дорога"
	desc = "Перемещайтесь от одной своей звезды к другой. Для входа нужно стоять не дальше одной клетки от звезды; выход должен быть свободен. После изучения метки Космоса прибытие также активирует ваши метки на врагах в одной клетке от выхода."
	cost = 1
	route = PATH_COSMIC
	spell_to_add = /obj/effect/proc_holder/spell/self/cosmic/step

/datum/eldritch_knowledge/cosmic_mark
	name = "Метка Космоса"
	desc = "Хватка Мансуса и нити созвездия накладывают метку Космоса. Клинок или ваше прибытие по Звёздной дороге в одной клетке от жертвы взрывают метку: 10 ожогов и 15 урона выносливости. Уходите вдоль созвездия и возвращайтесь к отмеченным целям."
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
	desc = "Созвездие вмещает три звезды. Последняя соединяется с первой, образуя замкнутую фигуру, если путь свободен."
	cost = 1
	route = PATH_COSMIC

/datum/eldritch_knowledge/cosmic_upgrade
	name = "Орбитальный серп"
	desc = "Удары космическим клинком в двух клетках от вашей звезды дополнительно наносят 10 ожогов."
	cost = 2
	route = PATH_COSMIC

/datum/eldritch_knowledge/cosmic_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(!isliving(target))
		return
	var/mob/living/victim = target
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(knowledge?.can_affect(victim) && knowledge.nearest_star(victim, 2))
		victim.adjustFireLoss(10)

/datum/eldritch_knowledge/spell/cosmic_pulse
	name = "Гравитационный пульс"
	desc = "Звёзды наносят врагам в двух клетках 20 ожогов и 25 урона выносливости, подтягивают на две клетки, замедляют на 3 секунды и накладывают метку Космоса. Одна цель получает эффект один раз за применение; само притяжение через нить не ранит, но после пульса нити бьют как обычно. Без своих звёзд в семи клетках пульс не срабатывает и не уходит на перезарядку. Перезарядка 22 секунды."
	cost = 1
	route = PATH_COSMIC
	spell_to_add = /obj/effect/proc_holder/spell/self/cosmic/pulse

/datum/eldritch_knowledge/cosmic_resonance
	name = "Неподвижный небосвод"
	desc = "Прочность всех звёзд возрастает с 35 до 70 и восстанавливается. Лист стекла и лист золота создают астролябию: рядом с первой звездой она за полторы секунды поворачивает созвездие на четверть оборота. Наведите её на свою видимую звезду до семи клеток, чтобы за полторы секунды погасить только её вспышкой: 30 ожогов врагам в двух клетках. Остальные звёзды, их повреждения и срок жизни сохраняются. Стены мешают вспышке; разрушение выбранной звезды отменяет её. Вспышка и поворот делят перезарядку 25 секунд. Можно иметь одну астролябию."
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
	desc = "Через 1,5 секунды после предупреждения звёзды в семи клетках наносят врагам в радиусе двух клеток 45 ожогов и сбивают на 1,5 секунды. Во время предупреждения можно двигаться. Всё созвездие расходуется; новое можно поставить одним применением. Если звезду разобьют или сдвинут, вас оглушат или рядом не останется своих звёзд, схлопывание сорвётся, а перезарядка вернётся."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_COSMIC
	spell_to_add = /obj/effect/proc_holder/spell/self/cosmic/collapse

/datum/eldritch_knowledge/final_eldritch/cosmic_final
	parallax_scene = ANTAG_SCENE_HERETIC_COSMIC
	name = "Небо внутри"
	desc = "После трёх назначенных душ принесите на руну три человеческих трупа. Начало обряда раскроет его место всей станции и даст экипажу 30 секунд, чтобы помешать. После вознесения вы получаете общую стойкость вознесения. Предел созвездия увеличивается до пяти звёзд, а урон нитей ожогами - с 10 до 20. За каждые 4 секунды движения под вами сама загорается звезда; при полном созвездии она заменяет старейшую. В космосе вас не сносит инерцией. Способность Звездочёт призывает парящее создание в 400 здоровья: оно следует за вами и раз в 3 секунды бьёт лучом в 20 ожогов ближайшего врага в семи клетках на открытой линии. Звездочёт один; его гибель или ваша смерть запускают перезарядку призыва в 3 минуты. Экипаж может убить его отдельно, а звёзды гасит нулевой жезл. Смерть снимает эти усиления, оживление возвращает."
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
