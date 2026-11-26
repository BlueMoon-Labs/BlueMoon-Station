#define HERETIC_DUSK_STEP_GAP (1 SECONDS)
#define HERETIC_DUSK_ECLIPSE_PULSE (2 SECONDS)
#define HERETIC_DUSK_ECLIPSE_BLINK (0.5 SECONDS)

/// Ни стена, ни окно, ни дверь не стоят между клетками.
/proc/heretic_dusk_line_clear(turf/start, turf/finish)
	if(!start || !finish || start.z != finish.z)
		return FALSE
	for(var/turf/tile as anything in get_line(start, finish))
		if(tile != start && tile != finish && !heretic_line_tile_open(tile))
			return FALSE
	return TRUE

/proc/heretic_dusk_landable(turf/spot)
	return isopenturf(spot) && !isgroundlessturf(spot) && !spot.is_blocked_turf(exclude_mobs = FALSE)

/// Пол у лампы: её клетка или соседняя свободная.
/proc/heretic_dusk_lamp_landing(obj/machinery/light/lamp)
	var/turf/spot = get_turf(lamp)
	if(heretic_dusk_landable(spot))
		return spot
	for(var/direction in GLOB.alldirs)
		var/turf/nearby = get_step(spot, direction)
		if(heretic_dusk_landable(nearby) && spot.Adjacent(nearby))
			return nearby
	return null

/// Гасит горящие переносные огни носителя на время.
/proc/heretic_dusk_douse(mob/living/carbon/human/bearer, time, source)
	. = 0
	for(var/obj/item/item as anything in heretic_dusk_carried_lights(bearer))
		if(istype(item, /obj/item/flashlight))
			var/obj/item/flashlight/torch = item
			torch.on = FALSE
			torch.update_brightness()
			ADD_TRAIT(torch, TRAIT_MOD_DISRUPTED, source)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dusk_undouse), WEAKREF(torch), source), time)
		else
			item.set_light_on(FALSE)
		.++

/proc/heretic_dusk_undouse(datum/weakref/item_ref, source)
	var/obj/item/item = item_ref?.resolve()
	if(item)
		REMOVE_TRAIT(item, TRAIT_MOD_DISRUPTED, source)

/datum/eldritch_knowledge/base_dusk/proc/beam_lamp(mob/living/target)
	var/turf/target_turf = get_turf(target)
	var/obj/machinery/light/best
	for(var/datum/component/heretic_dusk_lamp/hex as anything in lamps)
		var/obj/machinery/light/lamp = hex.parent
		if(lamp?.status != LIGHT_OK || lamp.z != target_turf?.z || get_dist(lamp, target_turf) > HERETIC_DUSK_BEAM_RANGE)
			continue
		if(!heretic_dusk_line_clear(get_turf(lamp), target_turf))
			continue
		if(!best || get_dist(lamp, target_turf) < get_dist(best, target_turf))
			best = lamp
	return best

/// Лик поворачивается к указанной цели (turn), как Лик ангела; не повернувшийся смотрит только вперёд.
/datum/eldritch_knowledge/base_dusk/proc/beam_block_reason(mob/living/user, atom/target, check_cost = TRUE, turn = FALSE)
	var/reason = cast_block_reason(user, HERETIC_DUSK_FORM_FACE)
	if(reason)
		return reason
	var/mob/living/victim = target
	if(!istype(victim) || victim == user || victim.stat == DEAD)
		return "Укажите живую цель."
	if(IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
		return "Это союзник Мансуса: еретики и их слуги защищены от этой способности."
	if(turn && victim.z == user.z)
		user.face_atom(victim)
	if(victim.z != user.z || !is_A_facing_B(user, victim))
		return "Цель должна стоять перед вами: приёмы Лика бьют только вперёд."
	if(!beam_lamp(victim))
		return "Цель не видит ни одна ваша лампа: нужна заговорённая лампа не дальше [HERETIC_DUSK_BEAM_RANGE] клеток от неё без стен между ними."
	return check_cost ? cost_reason(1) : null

/datum/eldritch_knowledge/base_dusk/proc/lamp_beam(mob/living/user, mob/living/victim)
	dusk_failure = beam_block_reason(user, victim, turn = TRUE)
	if(dusk_failure)
		return FALSE
	var/obj/machinery/light/lamp = beam_lamp(victim)
	if(!heretic_can_affect(user, victim, chargecost = 1))
		dusk_failure = "Защита от магии гасит луч."
		return FALSE
	if(!spend_combat_resource(dusk_cost(1)))
		return FALSE
	var/damage = HERETIC_DUSK_BEAM_DAMAGE
	var/list/obj/machinery/light/chain = covenant == HERETIC_DUSK_COVENANT_SERAPH ? beam_chain(lamp) : list()
	var/obj/machinery/light/relay = lamp
	for(var/obj/machinery/light/link as anything in chain)
		link.Beam(relay, icon_state = "dusk_lamp_beam", icon = 'modular_bluemoon/icons/obj/heretic_dusk_beam.dmi', time = 0.4 SECONDS)
		relay = link
		damage += HERETIC_DUSK_SERAPH_CHAIN_DAMAGE
	if(covenant == HERETIC_DUSK_COVENANT_SERAPH && victim.get_eye_protection() > 0)
		damage /= 2
	lamp.Beam(victim, icon_state = "dusk_lamp_beam", icon = 'modular_bluemoon/icons/obj/heretic_dusk_beam.dmi', time = 0.4 SECONDS)
	victim.adjustFireLoss(damage)
	heretic_dusk_sound(lamp, "beam", 50, TRUE)
	if(!QDELETED(victim))
		victim.visible_message(span_danger("Лампа над [victim] вспыхивает, и луч больного белого света бьёт [victim]!"), span_userdanger("Лампа бьёт вас лучом! Уйдите от неё подальше или за стену."))
	log_combat(user, victim, "бьёт Лучом лампы Сумрака", addition = "лампа в [AREACOORD(lamp)], ламп в цепи: [length(chain)], урон [damage]")
	lesson_event("beam", victim)
	return TRUE

/// Нимб: свет приходит к лампе у цели по цепи других заговорённых ламп, каждая добавляет жара.
/datum/eldritch_knowledge/base_dusk/proc/beam_chain(obj/machinery/light/last)
	. = list()
	var/list/used = list(last)
	while(length(.) < HERETIC_DUSK_SERAPH_CHAIN)
		var/obj/machinery/light/next
		for(var/datum/component/heretic_dusk_lamp/hex as anything in lamps)
			var/obj/machinery/light/candidate = hex.parent
			if((candidate in used) || candidate?.status != LIGHT_OK || candidate.z != last.z || get_dist(candidate, last) > HERETIC_DUSK_BEAM_RANGE)
				continue
			if(!heretic_dusk_line_clear(get_turf(candidate), get_turf(last)))
				continue
			if(!next || get_dist(candidate, last) < get_dist(next, last))
				next = candidate
		if(!next)
			break
		. += next
		used += next
		last = next

/datum/eldritch_knowledge/base_dusk
	/// Хватка ложится на цель на свету: grip_time() даёт короткое удержание.
	var/grip_short = FALSE

/// Тень цели держит полную Хватку: цель в тени, в затмении или с отнятой, выжженной или гнилой тенью.
/datum/eldritch_knowledge/base_dusk/proc/grip_light_ok(mob/living/victim)
	if(shadowed_by_me(victim) || in_eclipse(victim))
		return TRUE
	var/threshold = (ascension_active && suns_standing) ? HERETIC_DUSK_BRIGHT_LUM : HERETIC_DUSK_LIT_LUM
	return heretic_dusk_light(get_turf(victim)) < threshold

/datum/eldritch_knowledge/base_dusk/proc/grip_block_reason(mob/living/user, atom/target, check_cost = TRUE)
	var/reason = cast_block_reason(user, HERETIC_DUSK_FORM_WING)
	if(reason)
		return reason
	if(!knows(/datum/eldritch_knowledge/spell/dusk_grip))
		return "Способность недоступна вашему пути или текущему телу."
	reason = heretic_capture_block_reason(user, target, HERETIC_DUSK_CAPTURE)
	if(reason)
		return reason
	var/mob/living/victim = target
	if(!isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > HERETIC_DUSK_GRIP_RANGE)
		return "Цель должна стоять не дальше [HERETIC_DUSK_GRIP_RANGE] клеток на вашем этаже."
	if(victim.has_status_effect(/datum/status_effect/heretic_dusk_grip))
		return "Цель уже прибита тенью."
	return check_cost ? cost_reason(HERETIC_DUSK_GRIP_COST) : null

/// Хватка тени: под целью вспухает тень, через 0,8 секунды она прибивает цель; на свету - короче.
/datum/eldritch_knowledge/base_dusk/proc/grip(mob/living/user, mob/living/victim)
	dusk_failure = grip_block_reason(user, victim)
	if(dusk_failure)
		return FALSE
	var/spent = dusk_cost(HERETIC_DUSK_GRIP_COST)
	if(!spend_combat_resource(spent))
		return FALSE
	new /obj/effect/temp_visual/heretic_dusk/grip_rise(get_turf(victim))
	heretic_dusk_sound(victim, "wing_twitch", 25, TRUE)
	to_chat(victim, span_userdanger("Ваша тень вспухает и раскидывает крылья! На свету она удержит вас короче - шагните на свет или бегите!"))
	addtimer(CALLBACK(src, PROC_REF(grip_land), WEAKREF(user), WEAKREF(victim), spent), HERETIC_DUSK_GRIP_TELEGRAPH)
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/grip_land(datum/weakref/user_ref, datum/weakref/victim_ref, spent)
	var/mob/living/user = user_ref?.resolve()
	var/mob/living/victim = victim_ref?.resolve()
	var/reason = user ? grip_block_reason(user, victim, FALSE) : "Хозяина тени больше нет."
	if(reason)
		if(user && owner_heretic())
			gain_combat_resource(spent)
			grip_missed(user)
			to_chat(user, span_warning("Хватка тени сорвалась: [reason] Сумрак возвращён, Хватка готова через [HERETIC_DUSK_GRIP_MISS_COOLDOWN / (1 SECONDS)] с."))
		return FALSE
	grip_short = !grip_light_ok(victim)
	var/datum/status_effect/heretic_dusk_grip/grip = victim.apply_status_effect(/datum/status_effect/heretic_dusk_grip, src)
	var/short = grip_short
	grip_short = FALSE
	if(QDELETED(grip))
		gain_combat_resource(spent)
		grip_missed(user)
		return FALSE
	if(short)
		to_chat(user, span_notice("Цель на свету: тень удержит её [grip_time(TRUE) / (1 SECONDS)] с вместо [grip_time(FALSE) / (1 SECONDS)]. Полную Хватку дают тень, Локальное затмение и отнятая или выжженная тень[covenant == HERETIC_DUSK_COVENANT_ROT ? ", а у Скверны - и носитель" : ""]."))
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	heretic?.advance_combat_deed(victim, PATH_DUSK)
	log_combat(user, victim, "прибивает Хваткой тени Сумрака")
	if(covenant == HERETIC_DUSK_COVENANT_ROT)
		infect_rot(victim)
	lesson_event("grip", victim)
	return TRUE

/// Сорвавшаяся на телеграфе Хватка не съедает весь откат.
/datum/eldritch_knowledge/base_dusk/proc/grip_missed(mob/living/user)
	if(!user?.mind)
		return
	var/obj/effect/proc_holder/spell/pointed/heretic_dusk/grip/power = locate() in user.mind.spell_list
	if(!power || power.charge_counter >= power.charge_max)
		return
	power.charge_counter = max(power.charge_counter, power.charge_max - HERETIC_DUSK_GRIP_MISS_COOLDOWN)
	power.action?.UpdateButtons()

/datum/eldritch_knowledge/base_dusk/proc/descent_landing(mob/living/user, mob/living/victim)
	var/turf/victim_turf = get_turf(victim)
	var/turf/user_turf = get_turf(user)
	var/turf/best
	for(var/direction in GLOB.alldirs)
		var/turf/spot = get_step(victim_turf, direction)
		if(!heretic_dusk_landable(spot) || !victim_turf.Adjacent(spot) || heretic_dusk_holy_ground(spot))
			continue
		if(!best || get_dist_euclidian(spot, user_turf) < get_dist_euclidian(best, user_turf))
			best = spot
	return best

/datum/eldritch_knowledge/base_dusk/proc/descent_block_reason(mob/living/user, atom/target, check_cost = TRUE)
	var/reason = cast_block_reason(user, HERETIC_DUSK_FORM_FACE)
	if(reason)
		return reason
	if(!knows(/datum/eldritch_knowledge/spell/dusk_covenant))
		return "Способность недоступна вашему пути или текущему телу."
	var/mob/living/victim = target
	if(!istype(victim) || victim == user || victim.stat == DEAD)
		return "Укажите живую цель."
	if(!heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
		return (IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim)) ? "Это союзник Мансуса: еретики и их слуги защищены от этой способности." : "Цель защищена от магии."
	if(!isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > HERETIC_DUSK_DESCENT_RANGE)
		return "Цель должна стоять не дальше [HERETIC_DUSK_DESCENT_RANGE] клеток на вашем этаже."
	if(get_dist(user, victim) <= 1)
		return "Вы уже рядом с целью."
	if(!heretic_dusk_lit(get_turf(victim)))
		return "Цель в тени: Нисхождение падает только туда, где светло."
	if(user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return "Что-то держит вас на месте."
	var/turf/landing = descent_landing(user, victim)
	if(!landing)
		return "Рядом с целью нет свободного пола, или там святая земля."
	if(!heretic_dusk_line_clear(get_turf(user), landing))
		return "На пути прыжка стена, окно или дверь."
	var/area/landing_area = get_area(landing)
	if(landing_area.area_flags & NOTELEPORT)
		return "Зона закрыта для переноса."
	if(charges["descent"] < 1)
		return "Нисхождение ещё не готово: заряд вернётся через [charge_wait("descent")] с."
	return check_cost ? cost_reason(1) : null

/// Нисхождение: полсекунды столба света в точке приземления, затем прыжок; задетая цель падает на секунду.
/datum/eldritch_knowledge/base_dusk/proc/descent(mob/living/user, mob/living/victim)
	dusk_failure = descent_block_reason(user, victim)
	if(dusk_failure)
		return FALSE
	var/spent = dusk_cost(1)
	if(!spend_combat_resource(spent) || !use_charge("descent"))
		return FALSE
	var/turf/landing = descent_landing(user, victim)
	new /obj/effect/temp_visual/heretic_dusk/pillar(landing)
	heretic_vfx_flash(landing, "#ece4cc", 1, 1.5, HERETIC_DUSK_DESCENT_TELEGRAPH)
	heretic_dusk_sound(landing, "descent_charge", 60, TRUE)
	to_chat(victim, span_userdanger("Рядом с вами встаёт столб света - сверху падает что-то с крыльями! Уйдите со света!"))
	user.visible_message(span_warning("[user] вскидывает культи крыльев, глаза вспыхивают белым!"), span_notice("Вы нисходите."))
	if(!do_after(user, HERETIC_DUSK_DESCENT_TELEGRAPH, target = user, timed_action_flags = IGNORE_HELD_ITEM))
		gain_combat_resource(spent)
		refund_charge("descent")
		dusk_failure = "Нисхождение сорвалось: вас сдвинули или прервали. Сумрак и заряд возвращены."
		return FALSE
	if(!heretic_dusk_landable(landing) || !heretic_dusk_line_clear(get_turf(user), landing))
		gain_combat_resource(spent)
		refund_charge("descent")
		dusk_failure = "Нисхождение сорвалось: точку приземления заняли. Сумрак и заряд возвращены."
		return FALSE
	var/turf/origin = get_turf(user)
	user.forceMove(landing)
	user.pixel_y += 12
	animate(user, pixel_y = user.pixel_y - 12, time = 0.2 SECONDS, easing = BOUNCE_EASING)
	new /obj/effect/temp_visual/heretic_dusk/glare(landing)
	heretic_dusk_sound(landing, "descent_land", 60, TRUE)
	log_game("[key_name(user)] нисходит Сумраком из [AREACOORD(origin)] в [AREACOORD(landing)].")
	if(covenant == HERETIC_DUSK_COVENANT_SERAPH)
		new /obj/effect/heretic_dusk_light_burn(landing, src)
	if(!QDELETED(victim) && get_dist(victim, landing) <= 1 && heretic_dusk_lit(get_turf(victim)) && heretic_can_affect(user, victim))
		victim.Knockdown(HERETIC_DUSK_DESCENT_KNOCKDOWN)
		victim.adjustBruteLoss(HERETIC_DUSK_DESCENT_DAMAGE)
		if(QDELETED(victim))
			return TRUE
		victim.visible_message(span_danger("[user] обрушивается рядом с [victim] в столбе света и сбивает [victim] с ног!"), span_userdanger("Вас сбивает с ног свет, падающий с крыльями!"))
		var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
		heretic?.advance_combat_deed(victim, PATH_DUSK)
		log_combat(user, victim, "сбивает Нисхождением Сумрака")
		lesson_event("descent", victim)
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/glare_block_reason(mob/living/user, atom/target, check_cost = TRUE)
	var/reason = cast_block_reason(user, HERETIC_DUSK_FORM_FACE)
	if(reason)
		return reason
	if(!knows(/datum/eldritch_knowledge/spell/dusk_glare))
		return "Способность недоступна вашему пути или текущему телу."
	return check_cost ? cost_reason(1) : null

/datum/eldritch_knowledge/base_dusk/proc/overload_target(mob/living/user, atom/target)
	var/mob/living/carbon/human/bearer = target
	if(!istype(bearer) || bearer == user || bearer.stat == DEAD || bearer.z != user.z || get_dist(user, bearer) > HERETIC_DUSK_OVERLOAD_RANGE)
		return null
	return length(heretic_dusk_carried_lights(bearer)) ? bearer : null

/// Лик ангела: перегрузка чужого фонарика или взгляд конусом вперёд.
/datum/eldritch_knowledge/base_dusk/proc/glare(mob/living/user, atom/target)
	dusk_failure = glare_block_reason(user, target)
	if(dusk_failure)
		return FALSE
	var/mob/living/carbon/human/bearer = overload_target(user, target)
	if(bearer && (IS_HERETIC(bearer) || IS_HERETIC_MONSTER(bearer)))
		dusk_failure = "Это союзник Мансуса: еретики и их слуги защищены от этой способности."
		return FALSE
	if(!spend_combat_resource(dusk_cost(1)))
		return FALSE
	if(bearer)
		return overload(user, bearer)
	return glare_cone(user, target)

/datum/eldritch_knowledge/base_dusk/proc/overload(mob/living/user, mob/living/carbon/human/bearer)
	var/doused = heretic_dusk_douse(bearer, HERETIC_DUSK_OVERLOAD_JAM, REF(src))
	new /obj/effect/temp_visual/heretic_dusk/overload(get_turf(bearer))
	heretic_dusk_sound(bearer, "overload", 50, TRUE)
	var/blinded = FALSE
	var/blind = glare_blind()
	if(heretic_can_affect(user, bearer) && bearer.flash_act(1, type = /atom/movable/screen/fullscreen/tiled/flash/heretic_dusk, duration = blind))
		bearer.blind_eyes(blind / (2 SECONDS))
		bearer.apply_status_effect(/datum/status_effect/heretic_dusk_afterglow, blind)
		blinded = TRUE
	bearer.visible_message(span_danger("Свет в руках [bearer] вспыхивает ликом ангела и бьёт [bearer] в лицо!"), span_userdanger("Ваш фонарик вспыхивает чужим ликом и гаснет!"))
	log_combat(user, bearer, "перегружает Ликом ангела фонарик", addition = "огней погашено: [doused][blinded ? ", ослеплён" : ""]")
	lesson_event("overload", bearer, blinded)
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/glare_range()
	return covenant == HERETIC_DUSK_COVENANT_SERAPH ? HERETIC_DUSK_SERAPH_GLARE_RANGE : HERETIC_DUSK_GLARE_RANGE

/datum/eldritch_knowledge/base_dusk/proc/glare_blind()
	return covenant == HERETIC_DUSK_COVENANT_SERAPH ? HERETIC_DUSK_SERAPH_GLARE_BLIND : HERETIC_DUSK_GLARE_BLIND

/datum/eldritch_knowledge/base_dusk/proc/glare_cone(mob/living/user, atom/target)
	var/direction = get_dir(user, target) || user.dir
	user.setDir(direction)
	var/list/directions = list(direction, turn(direction, 45), turn(direction, -45))
	var/blinded = 0
	var/reach = glare_range()
	var/blind = glare_blind()
	for(var/mob/living/victim in heretic_field_view(reach, user))
		if(victim == user || victim.stat == DEAD || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || get_dist(user, victim) > reach)
			continue
		if(!(get_dir(user, victim) in directions) || !is_A_facing_B(victim, user))
			continue
		if(!heretic_can_affect(user, victim))
			continue
		if(victim.flash_act(1, type = /atom/movable/screen/fullscreen/tiled/flash/heretic_dusk, duration = blind))
			victim.blind_eyes(blind / (2 SECONDS))
			victim.apply_status_effect(/datum/status_effect/heretic_dusk_afterglow, blind)
			blinded++
			log_combat(user, victim, "ослепляет Ликом ангела")
		else
			to_chat(victim, span_warning("Ослепительный лик бьёт в лицо, но защита глаз держит свет."))
	var/obj/effect/temp_visual/heretic_dusk/glare/flash = new(get_turf(user))
	flash.setDir(direction)
	heretic_dusk_sound(user, "glare", 60, TRUE)
	user.visible_message(span_danger("Над [user] на миг раскрывается ослепительный лик ангела!"), span_notice("Вы поднимаете лицо к ним. Ослеплено: [blinded]."))
	lesson_event("glare", user, blinded)
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/free_step_ready()
	return ascension_active && suns_standing && COOLDOWN_FINISHED(src, free_step)

/datum/eldritch_knowledge/base_dusk/proc/lamp_target(mob/living/user, atom/target)
	return target == user || get_turf(target) == get_turf(user) || (istype(target, /obj/machinery/light) && target.GetComponent(/datum/component/heretic_dusk_lamp))

/datum/eldritch_knowledge/base_dusk/proc/step_block_reason(mob/living/user, atom/target)
	var/reason = cast_block_reason(user, HERETIC_DUSK_FORM_WING, TRUE)
	if(reason)
		return reason
	if(!knows(/datum/eldritch_knowledge/spell/dusk_step))
		return "Способность недоступна вашему пути или текущему телу."
	if(world.time < step_jam_until)
		return "Фонарь в лицо сбил вашу тень: Шаг вернётся через [heretic_capture_seconds_left(step_jam_until)] с."
	if(charges["step"] < 1 && !free_step_ready())
		return (holy_blood || in_holy_ground) ? "Зарядов Шага нет, а святое держит их: уйдите из часовни и дождитесь, пока святая вода выйдет из крови." : "Зарядов Шага нет: следующий вернётся через [charge_wait("step")] с."
	if(user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return "Что-то держит вас на месте: в тень не шагнуть."
	var/area/origin_area = get_area(user)
	if(origin_area.area_flags & NOTELEPORT)
		return "Зона закрыта для переноса."
	if(lamp_target(user, target))
		return length(lamps_on_z(user.z)) ? null : "На этом этаже нет ваших заговорённых ламп."
	var/mob/living/victim = target
	if(!istype(victim) || victim.stat == DEAD)
		return "Шаг в тень ведёт только в чужую тень: укажите человека в поле зрения, свою лампу или себя, чтобы выбрать лампу."
	return step_spot_reason(user, victim)

/datum/eldritch_knowledge/base_dusk/proc/step_spot(mob/living/user, mob/living/victim)
	return get_step(victim, get_dir(user, victim))

/datum/eldritch_knowledge/base_dusk/proc/step_spot_reason(mob/living/user, mob/living/victim)
	var/shadowed = shadowed_by_me(victim)
	if(victim.z != user.z || get_dist(user, victim) > (shadowed ? HERETIC_DUSK_STEP_SHADOW_RANGE : HERETIC_DUSK_STEP_RANGE))
		return "Тень должна лежать не дальше [HERETIC_DUSK_STEP_RANGE] клеток на вашем этаже; отнятая или выжженная - [HERETIC_DUSK_STEP_SHADOW_RANGE]."
	var/turf/behind = step_spot(user, victim)
	if(!heretic_dusk_landable(behind))
		return "За [victim] с дальней от вас стороны стена, преграда или другой человек: шагнуть некуда."
	if(!shadowed && heretic_dusk_light(behind) >= HERETIC_DUSK_BRIGHT_LUM)
		return "За [victim] с дальней от вас стороны слишком ярко: тень там не держится."
	if(heretic_dusk_holy_ground(behind))
		return "За [victim] с дальней от вас стороны святая земля: тень туда не ведёт."
	var/area/landing_area = get_area(behind)
	if(landing_area.area_flags & NOTELEPORT)
		return "Зона закрыта для переноса."
	return null

/datum/eldritch_knowledge/base_dusk/proc/spend_step()
	if(free_step_ready())
		COOLDOWN_START(src, free_step, HERETIC_DUSK_FREE_STEP_COOLDOWN)
		return "free"
	return use_charge("step") ? "charge" : null

/datum/eldritch_knowledge/base_dusk/proc/refund_step(spent)
	if(spent == "free")
		COOLDOWN_RESET(src, free_step)
	else if(spent == "charge")
		refund_charge("step")

/// Шаг в тень: за человека на дальнюю от вас сторону мгновенно, к своей лампе - за 2 секунды.
/datum/eldritch_knowledge/base_dusk/proc/shadow_step(mob/living/user, atom/target)
	dusk_failure = step_block_reason(user, target)
	if(dusk_failure)
		return FALSE
	if(lamp_target(user, target))
		return lamp_step(user, target)
	var/turf/origin = get_turf(user)
	var/turf/destination = step_spot(user, target)
	var/spent = spend_step()
	if(!spent)
		return FALSE
	new /obj/effect/temp_visual/heretic_dusk/puddle(origin)
	new /obj/effect/temp_visual/heretic_dusk/step_out(origin)
	if(!do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != destination)
		refund_step(spent)
		dusk_failure = "Шаг сорвался: перенос что-то остановило. Заряд сохранён."
		return FALSE
	arrive_from_shadow(user, origin, destination)
	user.setDir(get_dir(user, target))
	lesson_event("step", target)
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/arrive_from_shadow(mob/living/user, turf/origin, turf/destination)
	new /obj/effect/temp_visual/heretic_dusk/puddle(destination)
	new /obj/effect/temp_visual/heretic_dusk/step_in(destination)
	heretic_dusk_sound(origin, "step", 50, TRUE)
	heretic_dusk_sound(destination, "step", 50, TRUE)
	strike_until = world.time + HERETIC_DUSK_STRIKE_WINDOW
	destination.visible_message(span_warning("Из чернильной лужи поднимается [user], отряхивая с крыльев тень."))
	log_game("[key_name(user)] шагает в тень Сумраком из [AREACOORD(origin)] в [AREACOORD(destination)].")

/datum/eldritch_knowledge/base_dusk/proc/lamp_step(mob/living/user, atom/target)
	var/list/lamps_here = lamps_on_z(user.z)
	var/obj/machinery/light/lamp = (target in lamps_here) ? target : null
	if(!lamp)
		var/list/choices = list()
		for(var/obj/machinery/light/option as anything in lamps_here)
			choices["[length(choices) + 1]. [get_area_name(option, TRUE)]"] = option
		var/choice = length(choices) == 1 ? choices[1] : tgui_input_list(user, "К какой лампе уйти?", "Шаг в тень", choices)
		lamp = choices[choice]
	if(QDELETED(lamp))
		dusk_failure = "Шаг в тень отменён."
		return FALSE
	var/turf/destination = heretic_dusk_lamp_landing(lamp)
	if(!destination || heretic_dusk_holy_ground(destination))
		dusk_failure = "У лампы нет свободного пола, или там святая земля."
		return FALSE
	var/turf/origin = get_turf(user)
	new /obj/effect/temp_visual/heretic_dusk/puddle(origin)
	new /obj/effect/temp_visual/heretic_dusk/step_out(origin)
	user.visible_message(span_warning("[user] опускается в чернильную лужу собственной тени!"), span_notice("Вы уходите в тень лампы - [get_area_name(lamp, TRUE)]."))
	if(!do_after(user, HERETIC_DUSK_STEP_LAMP_TIME, target = user, timed_action_flags = IGNORE_HELD_ITEM))
		dusk_failure = "Шаг в тень сорвался: вас сдвинули или прервали."
		return FALSE
	dusk_failure = step_block_reason(user, lamp)
	if(dusk_failure)
		return FALSE
	destination = heretic_dusk_lamp_landing(lamp)
	var/spent = destination && spend_step()
	if(!spent)
		dusk_failure = "Шаг в тень сорвался: у лампы не осталось места."
		return FALSE
	if(!do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != destination)
		refund_step(spent)
		dusk_failure = "Шаг сорвался: перенос что-то остановило. Заряд сохранён."
		return FALSE
	arrive_from_shadow(user, origin, destination)
	lesson_event("lamp_step", lamp)
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/eclipse_block_reason(mob/living/user, check_cost = TRUE)
	var/reason = cast_block_reason(user)
	if(reason)
		return reason
	if(!knows(/datum/eldritch_knowledge/spell/dusk_eclipse))
		return "Способность недоступна вашему пути или текущему телу."
	if(eclipse_until > world.time || eclipse_timer)
		return "Затмение уже стоит."
	return check_cost ? cost_reason(HERETIC_DUSK_ECLIPSE_COST) : null

/// Локальное затмение: лампы рядом мигают 1,5 секунды и гаснут на 25 секунд.
/datum/eldritch_knowledge/base_dusk/proc/eclipse(mob/living/user)
	dusk_failure = eclipse_block_reason(user)
	if(dusk_failure || !spend_combat_resource(dusk_cost(HERETIC_DUSK_ECLIPSE_COST)))
		return FALSE
	var/turf/center = get_turf(user)
	var/list/datum/weakref/lamp_refs = list()
	for(var/obj/machinery/light/lamp as anything in heretic_dusk_nearest_lamps(center, HERETIC_DUSK_ECLIPSE_RADIUS, HERETIC_DUSK_ECLIPSE_LAMPS))
		if(lamp.flickering)
			continue
		lamp_refs += WEAKREF(lamp)
		heretic_dusk_dim_lamp(lamp, HERETIC_DUSK_ECLIPSE_BLINK)
	heretic_dusk_sound(center, "eclipse_warn", 60, TRUE)
	user.visible_message(span_danger("[user] разворачивает крыло над лампами, и свет вокруг судорожно мигает!"), span_notice("Вы закрываете крылом свет."))
	eclipse_timer = addtimer(CALLBACK(src, PROC_REF(start_eclipse), center, lamp_refs), HERETIC_DUSK_ECLIPSE_TELEGRAPH, TIMER_STOPPABLE)
	log_game("[key_name(user)] начинает Локальное затмение Сумрака в [AREACOORD(center)], ламп: [length(lamp_refs)].")
	lesson_event("eclipse", center, length(lamp_refs))
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/start_eclipse(turf/center, list/datum/weakref/lamp_refs)
	eclipse_timer = null
	if(!dusk_body || dusk_body.stat == DEAD)
		return FALSE
	for(var/datum/weakref/lamp_ref as anything in lamp_refs)
		heretic_dusk_dim_lamp(lamp_ref.resolve(), HERETIC_DUSK_ECLIPSE_TIME)
	eclipse_center = center
	eclipse_until = world.time + HERETIC_DUSK_ECLIPSE_TIME
	eclipse_zone = new(center, HERETIC_DUSK_ECLIPSE_RADIUS)
	heretic_dusk_sound(center, "eclipse", 60, TRUE)
	heretic_dusk_sound(center, "lamp_out", 40, TRUE)
	eclipse_pulse()
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/eclipse_pulse()
	eclipse_timer = null
	if(!eclipse_center || world.time >= eclipse_until)
		end_eclipse()
		return
	for(var/mob/living/carbon/human/witness in range(HERETIC_DUSK_ECLIPSE_RADIUS, eclipse_center))
		if(witness.stat != DEAD && !IS_HERETIC(witness) && !IS_HERETIC_MONSTER(witness))
			witness.apply_status_effect(/datum/status_effect/heretic_dusk_eclipsed)
	eclipse_timer = addtimer(CALLBACK(src, PROC_REF(eclipse_pulse)), HERETIC_DUSK_ECLIPSE_PULSE, TIMER_STOPPABLE)

/datum/eldritch_knowledge/base_dusk/proc/end_eclipse()
	deltimer(eclipse_timer)
	eclipse_timer = null
	QDEL_NULL(eclipse_zone)
	eclipse_center = null
	eclipse_until = 0

/obj/effect/proc_holder/spell/pointed/heretic_dusk
	clothes_req = FALSE
	invocation_type = "none"
	selection_type = "view"
	aim_assist = FALSE
	heretic_stun_check = TRUE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"
	active_msg = "Вы поднимаете взгляд."
	deactive_msg = "Вы опускаете взгляд."
	var/required_form

/obj/effect/proc_holder/spell/pointed/heretic_dusk/proc/dusk_of(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)

/obj/effect/proc_holder/spell/pointed/heretic_dusk/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	var/reason = dusk ? dusk.cast_block_reason(user, required_form, usable_while_grabbed) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_dusk/beam
	name = "Луч лампы"
	desc = "В облике Лика за единицу Сумрака укажите цель: Лик поворачивается к ней, и ваша заговорённая лампа бьёт её лучом на 12 ожогов. Лампа должна быть не дальше 7 клеток от цели, а стены, окна и двери не должны стоять между ними. У Завета Нимба свет приходит к лампе цепью: до 2 других ваших ламп, каждая в 7 клетках от предыдущей, добавляют по 4 ожога, но по цели в тёмных очках или сварочной маске луч Нимба бьёт вдвое слабее. Святая вода в крови делает луч дороже на единицу. Перезарядка 8 секунд."
	summary = "В Лике за единицу Сумрака вы поворачиваетесь к цели, и своя лампа в 7 клетках бьёт её лучом на 12 ожогов."
	charge_max = HERETIC_DUSK_BEAM_COOLDOWN
	range = HERETIC_DUSK_SIGHT_RANGE
	aim_assist_radius = 1
	required_form = HERETIC_DUSK_FORM_FACE
	action_icon_state = "dusk_beam"

/obj/effect/proc_holder/spell/pointed/heretic_dusk/beam/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	var/reason = dusk ? dusk.beam_block_reason(user, target, turn = !silent) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason, target = target)

/obj/effect/proc_holder/spell/pointed/heretic_dusk/beam/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(!length(targets) || !dusk?.lamp_beam(user, targets[1]))
		heretic_revert_cast(user, dusk?.dusk_failure)

/obj/effect/proc_holder/spell/pointed/heretic_dusk/grip
	name = "Хватка тени"
	desc = "В облике Крыла за 2 Сумрака тень цели в 7 клетках вспухает и через 0,8 секунды прибивает её к полу: в тени, в Локальном затмении и по отнятой или выжженной вами тени - на 10 секунд, на свету - лишь на 5. Святая вода на цели или на вас, нулевой жезл и Библия капеллана рвут Хватку сразу, растолкать её можно за 2 секунды, фонарик по цели укорачивает её вдвое. Прибитую цель охоты сердце уводит в изнанку. Перо в намерении «Схватить» по прибитой цели вплотную в облике Крыла за 2 секунды утягивает её в тень: 40 ушибов цели, вам 25 здоровья; свет в лицо, два попадания по вам или одно от 10 урона и «растолкать» срывают. У Завета Крыла Хватка держит на 3 секунды дольше, у Завета Скверны заражает цель, а носителя скверны держит полностью и на свету. Сорвавшаяся Хватка возвращает Сумрак и готова снова через 5 секунд. Перезарядка 25 секунд."
	summary = "В Крыле за 2 Сумрака цель в 7 клетках через 0,8 секунды прибита к полу: в тени на 10 секунд, на свету на 5."
	charge_max = HERETIC_DUSK_GRIP_COOLDOWN
	range = HERETIC_DUSK_GRIP_RANGE
	aim_assist_radius = 1
	required_form = HERETIC_DUSK_FORM_WING
	action_icon_state = "dusk_grip"

/obj/effect/proc_holder/spell/pointed/heretic_dusk/grip/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	var/reason = dusk ? dusk.grip_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason, target = target)

/obj/effect/proc_holder/spell/pointed/heretic_dusk/grip/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(!length(targets) || !dusk?.grip(user, targets[1]))
		heretic_revert_cast(user, dusk?.dusk_failure)

/obj/effect/proc_holder/spell/pointed/heretic_dusk/descent
	name = "Нисхождение"
	desc = "В облике Лика за единицу Сумрака прыгните к цели на освещённой клетке не дальше 4 клеток. За полсекунды до прыжка в точке приземления встаёт столб света; задетая цель получает 12 ушибов и падает на 1,5 секунды. Стены, окна и двери на пути не пускают, в часовню прыжок не ведёт. У Завета Нимба приземление оставляет ожог света 3 на 3 клетки на 6 секунд: экипаж в нём подсвечен и замедлен, кроме тех, кто в тёмных очках или сварочной маске. Заряд возвращается за 12 секунд."
	summary = "В Лике за единицу Сумрака прыжок к цели на свету в 4 клетках: столб света, затем 12 ушибов и падение."
	charge_max = HERETIC_DUSK_STEP_GAP
	range = HERETIC_DUSK_DESCENT_RANGE
	aim_assist_radius = 1
	required_form = HERETIC_DUSK_FORM_FACE
	action_icon_state = "dusk_descent"

/obj/effect/proc_holder/spell/pointed/heretic_dusk/descent/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	var/reason = dusk ? dusk.descent_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason, target = target)

/obj/effect/proc_holder/spell/pointed/heretic_dusk/descent/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(!length(targets) || !dusk?.descent(user, targets[1]))
		heretic_revert_cast(user, dusk?.dusk_failure)

/obj/effect/proc_holder/spell/pointed/heretic_dusk/glare
	name = "Лик ангела"
	desc = "В облике Лика за единицу Сумрака раскройте лик в сторону, куда указали: все, кто стоит перед вами в 3 клетках и смотрит на вас, слепнут на 4 секунды; у Завета Нимба - в 4 клетках на 6 секунд. Тёмные очки и сварочные маски защищают. Указав на человека с горящим фонариком в 7 клетках, вы перегружаете его свет: вспышка в лицо и 10 секунд без фонарика. Перезарядка 20 секунд, на освещённой клетке вдвое быстрее."
	summary = "В Лике за единицу Сумрака слепнут смотрящие на вас в конусе 3 клеток; или вспышка чужого фонарика в 7 клетках."
	charge_max = HERETIC_DUSK_GLARE_COOLDOWN
	range = HERETIC_DUSK_OVERLOAD_RANGE
	required_form = HERETIC_DUSK_FORM_FACE
	action_icon_state = "dusk_glare"

/obj/effect/proc_holder/spell/pointed/heretic_dusk/glare/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	var/reason = dusk ? dusk.glare_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_dusk/glare/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(!length(targets) || !dusk?.glare(user, targets[1]))
		heretic_revert_cast(user, dusk?.dusk_failure)
		return
	if(dusk.lit)
		charge_counter = charge_max / 2

/obj/effect/proc_holder/spell/pointed/heretic_dusk/step
	name = "Шаг в тень"
	desc = "В облике Крыла шагните в чужую тень: за человека в поле зрения не дальше 9 клеток - на клетку за ним с дальней от вас стороны, если она свободна и не на ярком свету. К цели с отнятой или выжженной вами тенью и к носителю вашей скверны - до 14 клеток и на свет. Укажите себя или свою лампу, чтобы за 2 секунды уйти к заговорённой лампе на этаже. В часовню Шаг не ведёт. 2 заряда по 6 секунд, у Завета Крыла - 3, но фонарь в лицо Крылу сбивает Шаг на 3 секунды; святая вода в крови и часовня держат заряды. Первый удар Пером в 2 секунды после Шага - Удар из тени."
	summary = "В Крыле за заряд - за человека в 9 клетках, на дальнюю от вас сторону, или к лампе; 2 заряда по 6 секунд."
	charge_max = HERETIC_DUSK_STEP_GAP
	range = HERETIC_DUSK_STEP_SHADOW_RANGE
	aim_assist_radius = 1
	usable_while_grabbed = TRUE
	required_form = HERETIC_DUSK_FORM_WING
	action_icon_state = "dusk_step"

/obj/effect/proc_holder/spell/pointed/heretic_dusk/step/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	var/reason = dusk ? dusk.step_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_dusk/step/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(!length(targets) || !dusk?.shadow_step(user, targets[1]))
		heretic_revert_cast(user, dusk?.dusk_failure)

/obj/effect/proc_holder/spell/self/heretic_dusk
	clothes_req = FALSE
	invocation_type = "none"
	heretic_stun_check = TRUE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"
	/// Работает на святой земле и у вознёсшегося.
	var/holy_ground_allowed = FALSE

/obj/effect/proc_holder/spell/self/heretic_dusk/proc/dusk_of(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)

/obj/effect/proc_holder/spell/self/heretic_dusk/proc/block_reason(mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(!dusk)
		return "Способность недоступна вашему пути или текущему телу."
	if(holy_ground_allowed)
		return dusk.can_use(user, usable_while_grabbed) ? null : "Способность недоступна вашему пути или текущему телу."
	return dusk.cast_block_reason(user, null, usable_while_grabbed)

/obj/effect/proc_holder/spell/self/heretic_dusk/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/reason = block_reason(user)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/self/heretic_dusk/form
	name = "Смена облика"
	desc = "Мгновенно смените облик. Лик копит Сумрак на освещённой клетке, быстрее на свету, слепит и бьёт светом, но его взгляд и луч бьют только перед собой - к цели луча он поворачивается сам; на освещённой клетке каждый удар Пером в Лике жжёт ещё на 4. Крыло копит Сумрак в тени, быстрее в тени, видит в темноте холодными сумерками, хватает и проходит по чужим теням, а спереди его закрывают крылья: удары и снаряды в лицо слабее на 50%. Во тьме экипаж видит отблеск его глаз, а луч фонаря в лицо или вспышка рядом гасят его тёмное зрение на 5 секунд, если глаза не защищены. Первый удар Пером в 2 секунды после смены облика - Удар из тени: 15 ушибов сверху и замедление. В намерении «Вред» смена облика сама бьёт врагов рядом, в «Обезоружить» - только тех, кто бил вас последние 10 секунд или держит вас, в «Помощи» и «Схватить» облик меняется без удара: из Лика в Крыло крылья мечут 3 пера в ближайших врагов в 4 клетках (6 ушибов, кровь и замедление), из Крыла в Лик над головой загорается знак, и через полсекунды нимб вспыхивает в 1 клетке - оглушение на 1 секунду и путаница; тёмные очки и сварочные маски держат вспышку. Лик пьёт лазер, попавший ему в лицо, раз в 4 секунды: луч не ранит, а даёт единицу Сумрака. Выплеснутая святая вода жжёт по объёму - от 3 ожогов за брызги до 15 за 10 единиц и больше, не чаще раза в 3 секунды, - сбивает облик и запирает смену на 8 секунд; пока смена заперта, облик снова не сбивается. Перезарядка 3 секунды; у вознёсшегося - без перезарядки."
	summary = "Лик копит Сумрак на свету, Крыло - в тени; мгновенно, перезарядка 3 секунды."
	charge_max = HERETIC_DUSK_FORM_COOLDOWN
	usable_while_grabbed = TRUE
	holy_ground_allowed = TRUE
	action_icon_state = "dusk_eyes"

/obj/effect/proc_holder/spell/self/heretic_dusk/form/block_reason(mob/living/user)
	. = ..()
	if(.)
		return
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(world.time < dusk.form_locked_until)
		return "Святое сбило ваш облик: сменить его можно через [heretic_capture_seconds_left(dusk.form_locked_until)] с."

/obj/effect/proc_holder/spell/self/heretic_dusk/form/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(!dusk?.toggle_form(user))
		heretic_revert_cast(user, dusk?.dusk_failure)
		return
	if(dusk.ascension_active)
		charge_counter = charge_max

/obj/effect/proc_holder/spell/self/heretic_dusk/eclipse
	name = "Локальное затмение"
	desc = "За 3 Сумрака до 8 ближайших целых ламп в 4 клетках мигают 1,5 секунды и гаснут на 25 секунд; выключатель или починка зажигают их раньше. Внутри затмения Хватка тени держит полные 10 секунд и на свету, экипаж видит тёмную виньетку, а фонарики и факелы светят как обычно. Перезарядка 60 секунд."
	summary = "За 3 Сумрака лампы в 4 клетках мигают и гаснут на 25 секунд; внутри Хватка держит полностью и на свету."
	charge_max = HERETIC_DUSK_ECLIPSE_COOLDOWN
	action_icon_state = "dusk_eclipse"

/obj/effect/proc_holder/spell/self/heretic_dusk/eclipse/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(!dusk?.eclipse(user))
		heretic_revert_cast(user, dusk?.dusk_failure)

/// Фонарь полуночи: в руке копит Сумрак в любом облике и показывает носителей света, в руке же гасит лампы рядом.
/obj/item/heretic_path_relic/dusk_lantern
	name = "midnight lantern"
	desc = "Старый фонарь из потемневшей латуни, над крышкой - треснувшее кольцо нимба, на столбике висят обгоревшие перья. За тёмным стеклом вместо огня колышется чёрное пламя - маленькое чёрное солнце в венце больного света, и вокруг него свет становится тусклее."
	icon = HERETIC_DUSK_ICON
	icon_state = "dusk_lantern"
	item_state = "dusk_lantern"
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/heretic_path_relic/dusk_lantern/attack_self(mob/living/user)
	if(!authorized(user))
		to_chat(user, span_warning("Фонарь холоден: чёрное пламя за стеклом даже не шевелится."))
		return
	if(!COOLDOWN_FINISHED(src, relic_cooldown))
		to_chat(user, span_warning("Чёрное пламя ещё не набралось тьмы: [heretic_capture_seconds_left(relic_cooldown)] с."))
		return
	var/list/obj/machinery/light/lamps = heretic_dusk_nearest_lamps(user, HERETIC_DUSK_LANTERN_RANGE, HERETIC_DUSK_LANTERN_LAMPS)
	if(!length(lamps))
		to_chat(user, span_warning("Рядом нет горящих ламп."))
		return
	COOLDOWN_START(src, relic_cooldown, HERETIC_DUSK_LANTERN_COOLDOWN)
	var/dimmed = 0
	for(var/obj/machinery/light/lamp as anything in lamps)
		if(!lamp.flickering && heretic_dusk_dim_lamp(lamp, HERETIC_DUSK_LANTERN_TIME))
			dimmed++
	heretic_dusk_sound(src, "lantern", 50, TRUE)
	heretic_dusk_sound(lamps[1], "lamp_out", 40, TRUE)
	user.visible_message(span_warning("[user] поднимает фонарь с чёрным пламенем, и лампы вокруг гаснут одна за другой."), span_notice("Ламп погашено: [dimmed]."))
	log_game("[key_name(user)] гасит Фонарём полуночи ламп: [dimmed] в [AREACOORD(user)].")
	var/datum/eldritch_knowledge/knowledge = knowledge_ref?.resolve()
	knowledge?.lesson_event("lantern", src, dimmed)

#undef HERETIC_DUSK_STEP_GAP
#undef HERETIC_DUSK_ECLIPSE_PULSE
#undef HERETIC_DUSK_ECLIPSE_BLINK
