#define HERETIC_STAR_RANGE 7
#define HERETIC_STAR_LIFETIME (3 MINUTES)
#define HERETIC_STAR_BASE_LIMIT 2
#define HERETIC_STAR_EXPANDED_LIMIT 3
#define HERETIC_STAR_ASCENDED_LIMIT 5

/datum/eldritch_knowledge/base_cosmic
	name = "Карта без неба"
	desc = "Открывает Путь Космоса: одним применением поставьте пару звёзд и перекройте проход опасной нитью. Нити обжигают, сбивают и замедляют врагов; звёзды можно разбить. Новые звёзды заменяют старые при полном лимите, поэтому созвездие легко перенести вслед за боем. Нож и лист стекла создают космический клинок."
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
	var/datum/antagonist/heretic/heretic = astronomer?.has_antag_datum(/datum/antagonist/heretic)
	if(heretic?.ascended)
		return HERETIC_STAR_ASCENDED_LIMIT
	return heretic?.get_knowledge(/datum/eldritch_knowledge/cosmic_expansion) ? HERETIC_STAR_EXPANDED_LIMIT : HERETIC_STAR_BASE_LIMIT

/datum/eldritch_knowledge/base_cosmic/get_combat_resource_data()
	return list("name" = "Звёзды", "value" = length(stars), "max" = star_limit(), "description" = "Первая пара создаётся одним применением; звёзды живут три минуты. Нити наносят 10 ожогов и 25 урона выносливости, сбивают на 0,7 секунды и замедляют на 3 секунды. До окончания замедления нити повторно не ранят. Звёзды можно разбить; новая заменяет старейшую при полном лимите.")

/datum/eldritch_knowledge/base_cosmic/proc/clear_stars()
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
	if(length(stars))
		var/obj/structure/heretic_star/last_star = stars[length(stars)]
		if(!star_line_clear(last_star, place))
			to_chat(user, span_warning("Звезда должна быть не дальше семи клеток от предыдущей, без стен между ними."))
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
	heretic.advance_deed(heretic.deed_key_for(place), place, silent = TRUE)
	return TRUE

/datum/eldritch_knowledge/base_cosmic/proc/manifest(turf/place, mob/living/user)
	if(user?.mind != astronomer || !IS_HERETIC(user) || !isturf(user.loc) || user.incapacitated() || !safe_star_turf(place) || !star_line_clear(user, place) || !(place in view(HERETIC_STAR_RANGE, user)))
		return FALSE
	for(var/obj/structure/heretic_star/star as anything in stars)
		if(star.loc == place)
			qdel(star)
			return TRUE
	if(length(stars))
		var/obj/structure/heretic_star/last_star = stars[length(stars)]
		if(!star_line_clear(last_star, place))
			clear_stars()
	if(length(stars) >= star_limit())
		qdel(stars[1])
	if(!length(stars) && place != get_turf(user))
		if(!add_star(get_turf(user), user))
			return FALSE
	return add_star(place, user)

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
	for(var/index in 1 to length(stars))
		if(index == length(stars) && length(stars) == 2)
			break
		var/obj/structure/heretic_star/start = stars[index]
		var/obj/structure/heretic_star/end = stars[index == length(stars) ? 1 : index + 1]
		if(!star_line_clear(start, end))
			continue
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

/datum/eldritch_knowledge/base_cosmic/proc/remove_star(obj/structure/heretic_star/star)
	stars -= star
	if(!clearing_stars)
		rebuild_threads()
		notify_resource_changed()

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
	for(var/index in 1 to length(stars))
		if(index == length(stars) && length(stars) == 2)
			break
		var/obj/structure/heretic_star/start = stars[index]
		var/obj/structure/heretic_star/end = stars[index == length(stars) ? 1 : index + 1]
		if(!star_line_clear(plan[start], plan[end]))
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
	if(!isliving(victim) || victim.has_status_effect(/datum/status_effect/cosmic_tether) || !can_affect(victim))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(astronomer.current)
	victim.apply_status_effect(/datum/status_effect/cosmic_tether)
	victim.adjustStaminaLoss(25)
	victim.adjustFireLoss(10)
	victim.Knockdown(0.7 SECONDS)
	new /obj/effect/temp_visual/heretic_path_feedback(get_turf(victim), "cosmic_ring", "#96d7ed", 6)
	playsound(victim, 'modular_bluemoon/sound/heretic/cosmic_energy.ogg', 25, TRUE)
	if(heretic.get_knowledge(/datum/eldritch_knowledge/cosmic_mark))
		victim.apply_status_effect(/datum/status_effect/eldritch/cosmic)
	if(heretic.ascended)
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
	return TRUE

/datum/eldritch_knowledge/base_cosmic/proc/pulse(mob/living/user, collapse = FALSE, list/telegraphed_turfs)
	if(user?.mind != astronomer || user.incapacitated() || !length(stars))
		return FALSE
	var/list/victims = list()
	for(var/obj/structure/heretic_star/star as anything in stars)
		if(star.z != user.z || get_dist(star, user) > HERETIC_STAR_RANGE)
			continue
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
			step_towards(victim, star)
			step_towards(victim, star)
			victim.apply_status_effect(/datum/status_effect/eldritch/cosmic)
		if(user)
			log_combat(user, victim, collapse ? "обрушил созвездие на" : "притянул пульсом созвездия")
	if(collapse)
		clear_stars()
	return TRUE

/obj/structure/heretic_star
	name = "звезда Мансуса"
	desc = "Холодная звезда, приколотая к полу. Между такими звёздами натягиваются опасные видимые нити. Звезду можно разбить."
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
	name = "нить созвездия"
	desc = "Видимая нить соединяет две звезды. Враги получают ожоги, падают и замедляются. Разбейте звезду, чтобы разорвать нить."
	icon = null
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = SIGIL_LAYER
	var/datum/eldritch_knowledge/base_cosmic/constellation
	var/obj/structure/heretic_star/start
	var/obj/structure/heretic_star/end

/obj/effect/heretic_star_thread/Crossed(atom/movable/mover)
	. = ..()
	if(!isliving(mover) || QDELETED(constellation) || QDELETED(start) || QDELETED(end))
		return
	if(!constellation.star_line_clear(start, end))
		return
	constellation.cross_thread(mover)

/obj/effect/heretic_star_thread/Destroy()
	constellation = null
	start = null
	end = null
	return ..()

/obj/effect/ebeam/heretic_constellation
	name = "нить созвездия"
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

/datum/status_effect/eldritch/cosmic
	id = "cosmic_mark"
	mark_name = "Метка Космоса"
	mark_alert_state = "sigil_cosmic"
	effect_sprite = "emark7"
	detonation_sound = 'modular_bluemoon/sound/heretic/cosmic_expansion.ogg'
	detonation_visual = /obj/effect/temp_visual/heretic_path_feedback/cosmic_mark

/datum/status_effect/eldritch/cosmic/on_effect()
	owner.adjustStaminaLoss(15)
	owner.adjustFireLoss(10)
	return ..()

/obj/item/melee/sickly_blade/cosmic
	name = "космический клинок"
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
	return . && heretic?.selected_path == PATH_COSMIC && !user.incapacitated()

/obj/effect/proc_holder/spell/self/cosmic/manifest
	parent_type = /obj/effect/proc_holder/spell/pointed
	name = "Зажечь звезду"
	desc = "Укажите видимый пол до семи клеток. Первое применение сразу создаёт пару звёзд: под вами и в выбранном месте. При полном лимите новая звезда заменяет старейшую; если старое созвездие слишком далеко или за стеной, создаётся новая пара. Нажатие на свою звезду гасит её."
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
	return . && heretic?.selected_path == PATH_COSMIC && !user.incapacitated()

/obj/effect/proc_holder/spell/self/cosmic/manifest/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	return isturf(target) && knowledge?.safe_star_turf(target) && knowledge.star_line_clear(user, target)

/obj/effect/proc_holder/spell/self/cosmic/manifest/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!length(targets) || !knowledge?.manifest(targets[1], user))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/cosmic/step
	parent_type = /obj/effect/proc_holder/spell/pointed
	name = "Звёздная дорога"
	desc = "Стоя рядом со своей звездой, нажмите способность и щёлкните по другой видимой звезде своего созвездия. Заблокированная точка не принимает путешественника."
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
	if(!. || heretic?.selected_path != PATH_COSMIC || !knowledge || user.incapacitated())
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
		revert_cast(user)

/obj/effect/proc_holder/spell/self/cosmic/pulse
	name = "Гравитационный пульс"
	desc = "Ваши звёзды в семи клетках наносят врагам рядом 20 ожогов и 25 урона выносливости, подтягивают на две клетки и замедляют на 3 секунды. Радиус каждой звезды — две клетки. Накладывает метку Космоса."
	charge_max = 22 SECONDS
	action_icon_state = "cosmic_domain"

/obj/effect/proc_holder/spell/self/cosmic/pulse/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!knowledge?.pulse(user))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/cosmic/collapse
	name = "Схлопнуть созвездие"
	desc = "Через 1,5 секунды звёзды в семи клетках наносят врагам рядом 45 ожогов и сбивают на 1,5 секунды. Можно двигаться во время предупреждения. Всё созвездие расходуется; враги могут покинуть подсвеченную область или разбить звезду."
	charge_max = 35 SECONDS
	action_icon_state = "star_blast"
	var/collapse_pending = FALSE

/obj/effect/proc_holder/spell/self/cosmic/collapse/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(collapse_pending || !length(knowledge?.stars))
		revert_cast(user)
		return
	var/list/star_snapshot = list()
	for(var/obj/structure/heretic_star/star as anything in knowledge.stars)
		star_snapshot[star] = get_turf(star)
		star.visible_message(span_danger("Звезда вспыхивает. Созвездие вот-вот схлопнется!"))
	playsound(user, 'modular_bluemoon/sound/heretic/cosmic_charge.ogg', 40, FALSE)
	var/list/telegraphed_turfs = knowledge.collapse_turfs(user)
	for(var/turf/tile as anything in telegraphed_turfs)
		new /obj/effect/temp_visual/heretic_path_feedback(tile, "cosmic_carpet", "#efb780", 1.5 SECONDS)
	collapse_pending = TRUE
	addtimer(CALLBACK(src, PROC_REF(finish_collapse), WEAKREF(user), WEAKREF(knowledge), star_snapshot, telegraphed_turfs), 1.5 SECONDS)

/obj/effect/proc_holder/spell/self/cosmic/collapse/proc/finish_collapse(datum/weakref/user_ref, datum/weakref/knowledge_ref, list/star_snapshot, list/telegraphed_turfs)
	collapse_pending = FALSE
	var/mob/living/user = user_ref.resolve()
	var/datum/eldritch_knowledge/base_cosmic/knowledge = knowledge_ref.resolve()
	if(!user || !knowledge || !knowledge.stars_unchanged(star_snapshot))
		return FALSE
	return knowledge.pulse(user, collapse = TRUE, telegraphed_turfs = telegraphed_turfs)

/obj/effect/proc_holder/spell/self/cosmic/alignment
	name = "Великое соединение"
	desc = "Мгновенно создаёт созвездие вокруг вас на свободных клетках. Прежние звёзды гаснут. Доступно после вознесения."
	charge_max = 35 SECONDS
	action_icon_state = "cosmic_rune"

/obj/effect/proc_holder/spell/self/cosmic/alignment/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	if(!heretic?.ascended || !knowledge || !knowledge.safe_star_turf(get_turf(user)))
		revert_cast(user)
		return
	knowledge.clear_stars()
	knowledge.add_star(get_turf(user), user)
	for(var/direction in GLOB.cardinals)
		knowledge.add_star(get_step(get_step(user, direction), direction), user)

/datum/eldritch_knowledge/cosmic_grasp
	name = "Притяжение"
	desc = "Хватка Мансуса наносит ещё 15 ожогов и замедляет на 3 секунды. Если рядом есть ваша звезда, противника также подтягивает на одну клетку к ней. Преграды останавливают притяжение."
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
	desc = "Перемещайтесь от одной своей звезды к другой. Для входа нужно стоять не дальше одной клетки от звезды; выход должен быть свободен."
	cost = 1
	route = PATH_COSMIC
	spell_to_add = /obj/effect/proc_holder/spell/self/cosmic/step

/datum/eldritch_knowledge/cosmic_mark
	name = "Метка Космоса"
	desc = "Хватка Мансуса и нити созвездия накладывают метку Космоса. Ваш клинок взрывает её, нанося 10 ожогов и 15 урона выносливости."
	cost = 2
	route = PATH_COSMIC

/datum/eldritch_knowledge/cosmic_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!isliving(target))
		return FALSE
	var/mob/living/victim = target
	if(IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || victim.check_magic_resistance())
		return FALSE
	victim.apply_status_effect(/datum/status_effect/eldritch/cosmic)
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
	desc = "Звёзды наносят врагам в двух клетках 20 ожогов и 25 урона выносливости, подтягивают на две клетки, замедляют на 3 секунды и накладывают метку Космоса. Одна цель получает эффект один раз за применение, без дополнительного удара нитей. Перезарядка 22 секунды."
	cost = 1
	route = PATH_COSMIC
	spell_to_add = /obj/effect/proc_holder/spell/self/cosmic/pulse

/datum/eldritch_knowledge/cosmic_resonance
	name = "Неподвижный небосвод"
	desc = "Прочность всех звёзд возрастает с 35 до 70 и восстанавливается. Лист стекла и лист золота создают астролябию: рядом с первой звездой она за полторы секунды поворачивает созвездие на четверть оборота. Преграды мешают повороту, срок жизни звёзд сохраняется. Можно иметь одну астролябию."
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
	desc = "Через 1,5 секунды после предупреждения звёзды в семи клетках наносят врагам в радиусе двух клеток 45 ожогов и сбивают на 1,5 секунды. Во время предупреждения можно двигаться. Всё созвездие расходуется; новое можно поставить одним применением."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_COSMIC
	spell_to_add = /obj/effect/proc_holder/spell/self/cosmic/collapse

/datum/eldritch_knowledge/final_eldritch/cosmic_final
	parallax_scene = ANTAG_SCENE_HERETIC_COSMIC
	name = "Небо внутри"
	desc = "После трёх назначенных душ принесите на руну три человеческих трупа. Начало обряда раскроет его место всей станции и даст экипажу 30 секунд, чтобы помешать. Вознесение расширяет созвездие до пяти звёзд, добавляет ожоги от нитей и позволяет мгновенно выстраивать созвездие вокруг себя."
	route = PATH_COSMIC
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_traits = list(TRAIT_NOBREATH)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/cosmic/alignment)

/datum/eldritch_knowledge/final_eldritch/cosmic_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	on_body_gain(user)
	return TRUE

#undef HERETIC_STAR_RANGE
#undef HERETIC_STAR_LIFETIME
#undef HERETIC_STAR_BASE_LIMIT
#undef HERETIC_STAR_EXPANDED_LIMIT
#undef HERETIC_STAR_ASCENDED_LIMIT
