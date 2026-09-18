#define HERETIC_SPIRIT_RANGE 5
#define HERETIC_SPIRIT_SOUL_LIMIT 3
#define HERETIC_SPIRIT_DRAIN_LIMIT 25
#define HERETIC_SPIRIT_REAP_DELAY (2 SECONDS)
#define HERETIC_SPIRIT_RECOVERY (10 SECONDS)
#define HERETIC_SPIRIT_HARVEST (6 SECONDS)
#define HERETIC_SPIRIT_STEP_RANGE 3
#define HERETIC_SPIRIT_DRAIN_PER_TICK 2.5
#define HERETIC_SPIRIT_STAMINA_RESTORE 15
#define HERETIC_SPIRIT_LANTERN_HEAL 12
#define HERETIC_SPIRIT_BLADE_BONUS 6
#define HERETIC_SPIRIT_HOOK_INCOME (6 SECONDS)
#define HERETIC_SPIRIT_REAP_NEAR_DAMAGE 15

/datum/heretic_path/spirit
	id = PATH_SPIRIT
	deed_type = /datum/heretic_deed/spirit
	name = "Дух"
	desc = "Станьте перевозчиком живых: отделяйте души от тел, вынуждайте врага вернуться к оставленному силуэту и собирайте плату за переправу. Душа остаётся на поле боя, пока её хозяин продолжает сражаться."
	strengths = "Разлучение сразу ранит врага. Отход от души истощает выносливость, а Жатва бьёт второй раз, пока связь цела: вдали от души сильнее, рядом слабее. Удары крюком по связанному телу и взрыв метки приносят оболы. Переправа встаёт рядом с врагом и переносит лежащую жертву, которую вы тащите, а фонарь собирает плату и лечит."
	weaknesses = "Душу можно погасить касанием или разбить без вреда хозяину. Возврат на клетку души после отхода обрывает связь вместе с Жатвой; стены, окна, закрытые двери, антимагия и расстояние больше пяти клеток тоже. Запас и истощение ограничены."
	knowledge = list(
		/datum/eldritch_knowledge/base_spirit,
		/datum/eldritch_knowledge/spirit_grasp,
		/datum/eldritch_knowledge/spell/spirit_step,
		/datum/eldritch_knowledge/spirit_mark,
		/datum/eldritch_knowledge/spirit_relic,
		/datum/eldritch_knowledge/spirit_upgrade,
		/datum/eldritch_knowledge/spell/spirit_reap,
		/datum/eldritch_knowledge/spirit_temper,
		/datum/eldritch_knowledge/spell/spirit_bell,
		/datum/eldritch_knowledge/final_eldritch/spirit_final,
	)

/datum/eldritch_knowledge/base_spirit
	name = "Монета под языком"
	desc = "Нож и лист серебра создают клинок перевозчика. «Разлучение» за один обол наносит цели в пяти клетках 20 ушибов и 15 урона выносливости, оставляя её душу на месте на 10 секунд. Отход дальше одной клетки от души наносит до 25 выносливости за всю связь. Касание своей души или возвращение на её клетку после отхода гасит связь. Удар крюком по телу с вашей душой возвращает обол, не чаще раза в 6 секунд. Перезарядка 12 секунд."
	gain_text = "Я положил монету под язык. На другом берегу назвали моё имя."
	route = PATH_SPIRIT
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/mineral/silver)
	result_atoms = list(/obj/item/melee/sickly_blade/spirit)
	combat_resource = 3
	combat_resource_max = 5
	combat_resource_name = "Оболы"
	combat_resource_desc = "Начальный запас 3 из 5. По одному оболу каждые 10 секунд восстанавливаются только первые две монеты. Удар крюком по телу, чью душу отделили вы, даёт обол не чаще раза в 6 секунд; взрыв Метки Духа крюком — ещё обол. Коснитесь отделённой вами души живого разумного врага: связь исчезнет, вы получите обол и восстановите 15 выносливости, не чаще раза в 6 секунд. Новое дело пути даёт обол. Разлучение и Переправа стоят 1, Заупокойный звон — 2. Одновременно существуют три души; смерть и смена тела гасят их и обнуляют запас."
	combat_resource_action = /obj/effect/proc_holder/spell/pointed/heretic_spirit/sever
	grasp_visual = /obj/effect/temp_visual/heretic_spirit/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/spirit_grasp.ogg'
	var/mob/living/spirit_body
	var/list/datum/status_effect/heretic_spirit/separated/souls = list()
	var/list/datum/status_effect/eldritch/spirit/marks = list()
	var/list/obj/effect/temp_visual/heretic_spirit/visuals = list()
	var/ascension_active = FALSE
	var/crossing_failure
	COOLDOWN_DECLARE(spirit_recovery)
	COOLDOWN_DECLARE(spirit_harvest)
	COOLDOWN_DECLARE(spirit_hook_income)

/datum/eldritch_knowledge/base_spirit/on_body_gain(mob/living/user)
	if(!user?.mind || spirit_body == user)
		return
	if(spirit_body)
		on_body_lose(spirit_body)
	spirit_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	grant_combat_power(user)
	update_capacity()
	COOLDOWN_START(src, spirit_recovery, HERETIC_SPIRIT_RECOVERY)

/datum/eldritch_knowledge/base_spirit/on_body_lose(mob/living/user)
	if(spirit_body)
		UnregisterSignal(spirit_body, COMSIG_PARENT_QDELETING)
	clear_spirit()
	spirit_body = null
	ascension_active = FALSE
	combat_resource = 0
	remove_combat_power()
	notify_resource_changed()

/datum/eldritch_knowledge/base_spirit/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(spirit_body)

/datum/eldritch_knowledge/base_spirit/on_death(mob/user)
	clear_spirit()
	combat_resource = 0
	COOLDOWN_START(src, spirit_recovery, HERETIC_SPIRIT_RECOVERY)
	notify_resource_changed()

/datum/eldritch_knowledge/base_spirit/Destroy()
	on_body_lose(spirit_body)
	return ..()

/datum/eldritch_knowledge/base_spirit/proc/clear_spirit()
	QDEL_LIST(souls)
	QDEL_LIST(marks)
	QDEL_LIST(visuals)

/datum/eldritch_knowledge/base_spirit/proc/clear_knowledge_effects(datum/eldritch_knowledge/required)
	for(var/datum/status_effect/heretic_spirit/separated/soul as anything in souls.Copy())
		if(soul.knowledge_ref?.resolve() == required || soul.reaping_ref?.resolve() == required)
			qdel(soul)

/datum/eldritch_knowledge/base_spirit/proc/can_use(mob/living/user, allow_incapacitated = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && user && user == spirit_body && user.stat != DEAD && (allow_incapacitated || !user.incapacitated()) && isturf(user.loc) && heretic?.selected_path == PATH_SPIRIT && !heretic.role_removed && heretic.get_knowledge(type) == src

/datum/eldritch_knowledge/base_spirit/proc/tile_open(turf/tile)
	return isopenturf(tile) && !tile.is_blocked_turf(exclude_mobs = TRUE)

/datum/eldritch_knowledge/base_spirit/proc/low_obstacle(obj/thing)
	return (thing.pass_flags_self & (PASSTABLE | LETPASSTHROW)) || istype(thing, /obj/structure/railing)

/datum/eldritch_knowledge/base_spirit/proc/tile_passable(turf/tile)
	if(!isopenturf(tile))
		return FALSE
	for(var/obj/thing in tile)
		if(thing.density && !(thing.flags_1 & ON_BORDER_1) && !low_obstacle(thing))
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_spirit/proc/edge_open(turf/from_turf, turf/to_turf)
	var/direction = get_dir(from_turf, to_turf)
	for(var/obj/thing in from_turf)
		if(thing.density && (thing.flags_1 & ON_BORDER_1) && thing.dir == direction && !low_obstacle(thing))
			return FALSE
	var/reverse = REVERSE_DIR(direction)
	for(var/obj/thing in to_turf)
		if(thing.density && (thing.flags_1 & ON_BORDER_1) && thing.dir == reverse && !low_obstacle(thing))
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_spirit/proc/step_open(turf/from_turf, turf/to_turf)
	if(from_turf.x == to_turf.x || from_turf.y == to_turf.y)
		return edge_open(from_turf, to_turf)
	var/turf/corner_a = locate(from_turf.x, to_turf.y, to_turf.z)
	var/turf/corner_b = locate(to_turf.x, from_turf.y, to_turf.z)
	return tile_passable(corner_a) && tile_passable(corner_b) && edge_open(from_turf, corner_a) && edge_open(corner_a, to_turf) && edge_open(from_turf, corner_b) && edge_open(corner_b, to_turf)

/datum/eldritch_knowledge/base_spirit/proc/line_clear(atom/start, atom/target, distance = HERETIC_SPIRIT_RANGE)
	var/turf/origin = get_turf(start)
	var/turf/destination = get_turf(target)
	if(!origin || !destination || origin.z != destination.z || get_dist(origin, destination) > distance)
		return FALSE
	var/turf/previous
	for(var/turf/tile as anything in get_line(origin, destination))
		if(!tile_passable(tile) || (previous && !step_open(previous, tile)))
			return FALSE
		previous = tile
	return TRUE

/datum/eldritch_knowledge/base_spirit/proc/own_soul_at(atom/target)
	var/turf/tile = get_turf(target)
	if(!tile)
		return null
	for(var/obj/structure/heretic_spirit_soul/anchor in tile)
		var/datum/status_effect/heretic_spirit/separated/soul = anchor.effect_ref?.resolve()
		if(soul?.spirit_ref?.resolve() == src)
			return anchor
	return null

/datum/eldritch_knowledge/base_spirit/on_life(mob/user)
	if(!can_use(user) || !COOLDOWN_FINISHED(src, spirit_recovery))
		return
	if(ascension_active || combat_resource < 2)
		gain_combat_resource()
	COOLDOWN_START(src, spirit_recovery, ascension_active ? 4 SECONDS : HERETIC_SPIRIT_RECOVERY)

/datum/eldritch_knowledge/base_spirit/on_mark_detonated(mob/living/user, mob/living/target)
	if(can_use(user) && isturf(target?.loc) && heretic_can_affect(user, target, chargecost = 0))
		gain_combat_resource()

/datum/eldritch_knowledge/base_spirit/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag || !isliving(target) || !can_use(user) || !COOLDOWN_FINISHED(src, spirit_hook_income))
		return
	var/mob/living/victim = target
	var/datum/status_effect/heretic_spirit/separated/soul = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
	if(soul?.spirit_ref?.resolve() != src || !soul.validate_link())
		return
	COOLDOWN_START(src, spirit_hook_income, HERETIC_SPIRIT_HOOK_INCOME)
	gain_combat_resource()

/datum/eldritch_knowledge/base_spirit/proc/update_capacity(ignore_temper = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(spirit_body)
	var/datum/eldritch_knowledge/spirit_temper/temper = heretic?.get_knowledge(/datum/eldritch_knowledge/spirit_temper)
	combat_resource_max = ascension_active ? 8 : !ignore_temper && !QDELETED(temper) ? temper.passive_values[temper.passive_level] : initial(combat_resource_max)
	combat_resource = min(combat_resource, combat_resource_max)
	notify_resource_changed()

/datum/eldritch_knowledge/base_spirit/proc/separate(mob/living/victim, datum/eldritch_knowledge/required)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(spirit_body)
	if(!can_use(spirit_body) || QDELETED(required) || heretic.get_knowledge(required.type) != required || !isturf(victim?.loc) || !line_clear(spirit_body, victim) || !heretic_can_affect(spirit_body, victim, chargecost = 0))
		return null
	var/datum/status_effect/heretic_spirit/separated/existing = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
	if(existing)
		return existing.spirit_ref?.resolve() == src ? existing : null
	if(length(souls) >= (ascension_active ? 6 : HERETIC_SPIRIT_SOUL_LIMIT))
		qdel(souls[1])
	return victim.apply_status_effect(/datum/status_effect/heretic_spirit/separated, src, required)

/datum/eldritch_knowledge/base_spirit/proc/collect(mob/living/user, datum/status_effect/heretic_spirit/separated/soul)
	if(!can_use(user) || QDELETED(soul) || soul.spirit_ref?.resolve() != src || !soul.validate_link() || !user.Adjacent(soul.anchor))
		return FALSE
	var/mob/living/victim = soul.owner
	var/reward = victim.mind && victim.mob_size >= MOB_SIZE_HUMAN && COOLDOWN_FINISHED(src, spirit_harvest)
	var/resource_before = combat_resource
	new /obj/effect/temp_visual/heretic_spirit/burst(get_turf(soul.anchor), src)
	soul.reap_end_reason = "перевозчик собрал душу"
	qdel(soul)
	if(reward)
		gain_combat_resource()
		user.adjustStaminaLoss(-HERETIC_SPIRIT_STAMINA_RESTORE)
		COOLDOWN_START(src, spirit_harvest, HERETIC_SPIRIT_HARVEST)
		to_chat(user, span_notice("Фонарь принимает плату за переправу. Вы получаете обол."))
	user.log_message("Собрана душа [key_name(victim)]: получено [combat_resource - resource_before] оболов, запас [combat_resource]/[combat_resource_max].", LOG_ATTACK)
	playsound(user, 'modular_bluemoon/sound/heretic/spirit_impact.ogg', 40, TRUE)
	return reward

/datum/eldritch_knowledge/base_spirit/proc/sever(mob/living/user, mob/living/victim)
	if(!can_use(user) || !isturf(victim?.loc) || !line_clear(user, victim) || !heretic_can_affect(user, victim, chargecost = 0) || !spend_combat_resource())
		return FALSE
	if(!heretic_can_affect(user, victim))
		return TRUE
	var/brute_before = victim.getBruteLoss()
	var/stamina_before = victim.getStaminaLoss()
	victim.adjustBruteLoss(20)
	if(!can_use(user) || QDELETED(victim))
		return TRUE
	victim.adjustStaminaLoss(15)
	log_combat(user, victim, "поражает Разлучением", addition = "фактически [round(victim.getBruteLoss() - brute_before, 0.1)] ушибов и [round(victim.getStaminaLoss() - stamina_before, 0.1)] выносливости")
	separate(victim, src)
	new /obj/effect/temp_visual/heretic_spirit/grasp(get_turf(victim), src)
	playsound(victim, 'modular_bluemoon/sound/heretic/spirit_grasp.ogg', 60, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_spirit/proc/crossing_fail(reason)
	crossing_failure = reason
	return null

/datum/eldritch_knowledge/base_spirit/proc/crossing_destination(mob/living/user, atom/target)
	crossing_failure = null
	var/turf/origin = get_turf(user)
	var/turf/aim = get_turf(target)
	if(!origin || !aim || origin.z != aim.z)
		return crossing_fail("Выберите клетку на своём уровне.")
	var/obj/structure/heretic_spirit_soul/anchor = own_soul_at(target)
	var/datum/status_effect/heretic_spirit/separated/soul = anchor?.effect_ref?.resolve()
	var/step_range = soul?.validate_link() ? HERETIC_SPIRIT_RANGE : HERETIC_SPIRIT_STEP_RANGE
	var/distance = get_dist(origin, aim)
	if(distance > HERETIC_SPIRIT_RANGE)
		return crossing_fail("Слишком далеко: Переправа ведёт на [HERETIC_SPIRIT_STEP_RANGE] клетки, к своей душе — на [HERETIC_SPIRIT_RANGE].")
	if(distance > step_range)
		var/list/path = get_line(origin, aim)
		aim = path[step_range + 1]
	if(aim == origin)
		return crossing_fail("Выберите другую клетку, а не ту, где стоите.")
	if(!tile_open(aim))
		return crossing_fail("Место прибытия закрыто стеной или плотным предметом.")
	if(!line_clear(origin, aim, step_range))
		return crossing_fail("Путь закрыт стеной, окном или другой преградой.")
	if(!aim.is_blocked_turf())
		return aim
	var/back_dir = get_dir(aim, origin)
	for(var/turn_angle in list(0, 45, -45, 90, -90))
		var/turf/spot = get_step(aim, turn(back_dir, turn_angle))
		if(spot && spot != origin && tile_open(spot) && !spot.is_blocked_turf() && line_clear(spot, aim, 1) && line_clear(origin, spot, step_range))
			return spot
	return crossing_fail("Место занято, и рядом с ним с вашей стороны нет свободной клетки.")

/datum/eldritch_knowledge/base_spirit/proc/crossing_passenger(mob/living/user)
	var/mob/living/passenger = user.pulling
	if(!isliving(passenger) || !isturf(passenger.loc) || passenger.anchored || passenger.buckled || HAS_TRAIT(passenger, TRAIT_NO_TELEPORT))
		return null
	if(passenger.body_position != LYING_DOWN && !passenger.incapacitated())
		return null
	if(passenger.check_magic_resistance(chargecost = 0))
		return null
	return passenger

/datum/eldritch_knowledge/base_spirit/proc/carry_passenger(mob/living/user, mob/living/passenger, turf/origin, grab_state)
	if(QDELETED(passenger) || !isturf(passenger.loc) || get_dist(passenger, origin) > 1)
		return FALSE
	var/turf/landing = get_turf(user)
	var/back_dir = get_dir(landing, origin)
	for(var/turn_angle in list(0, 45, -45, 90, -90, 135, -135, 180))
		var/turf/spot = get_step(landing, turn(back_dir, turn_angle))
		if(!spot || !tile_open(spot) || spot.is_blocked_turf() || !line_clear(landing, spot, 1))
			continue
		if(!do_teleport(passenger, spot, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(passenger) != spot)
			return FALSE
		// forceMove любого из двух мобов рвёт захват, поэтому он ставится заново.
		user.start_pulling(passenger, null, user.pull_force, TRUE)
		if(user.pulling == passenger && grab_state > GRAB_PASSIVE)
			user.setGrabState(grab_state)
			passenger.update_mobility()
		new /obj/effect/temp_visual/heretic_spirit/step(spot, src)
		log_combat(user, passenger, "переносит Переправой")
		return TRUE
	return FALSE

/datum/eldritch_knowledge/base_spirit/proc/cross(mob/living/user, atom/target, preserve_soul = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/spirit_step)
	crossing_failure = null
	if(!can_use(user) || QDELETED(required))
		return FALSE
	if(combat_resource < 1)
		crossing_failure = "Нужен 1 обол."
		return FALSE
	if(user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		crossing_failure = "Вы пристёгнуты, закреплены или не можете телепортироваться."
		return FALSE
	var/turf/destination = crossing_destination(user, target)
	if(!destination)
		return FALSE
	var/obj/structure/heretic_spirit_soul/anchor = own_soul_at(target)
	var/datum/status_effect/heretic_spirit/separated/soul = anchor?.effect_ref?.resolve()
	var/mob/living/passenger = crossing_passenger(user)
	var/grab_state_before = user.grab_state
	var/turf/origin = get_turf(user)
	if(!do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != destination)
		crossing_failure = "Переход сорвался: это место закрыто для телепортации."
		return FALSE
	if(!can_use(user) || QDELETED(required))
		return TRUE
	spend_combat_resource()
	if(passenger)
		carry_passenger(user, passenger, origin, grab_state_before)
	new /obj/effect/temp_visual/heretic_spirit/step(origin, src)
	new /obj/effect/temp_visual/heretic_spirit/step(destination, src)
	if(!preserve_soul && soul?.spirit_ref?.resolve() == src)
		collect(user, soul)
	else if(preserve_soul && !QDELETED(soul) && soul.spirit_ref?.resolve() == src)
		to_chat(user, span_notice("Душа остаётся на берегу: связь, её срок и накопленное истощение сохраняются."))
	user.adjustStaminaLoss(-HERETIC_SPIRIT_STAMINA_RESTORE)
	playsound(user, 'modular_bluemoon/sound/heretic/spirit_step.ogg', 55, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_spirit/proc/can_shift_soul(mob/living/user, obj/structure/heretic_spirit_soul/anchor, turf/origin)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/status_effect/heretic_spirit/separated/soul = anchor?.effect_ref?.resolve()
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spirit_grasp)
	return can_use(user) && !QDELETED(required) && combat_resource >= 1 && !QDELETED(anchor) && (!origin || anchor.loc == origin) && soul?.spirit_ref?.resolve() == src && !soul.shifted && soul.validate_link() && get_dist(user, anchor) >= 3 && line_clear(user, anchor)

/datum/eldritch_knowledge/base_spirit/proc/shift_soul(mob/living/user, obj/structure/heretic_spirit_soul/anchor)
	if(!can_shift_soul(user, anchor))
		return FALSE
	var/datum/status_effect/heretic_spirit/separated/soul = anchor.effect_ref.resolve()
	if(soul.shifting)
		return FALSE
	var/turf/origin = get_turf(anchor)
	var/turf/destination = get_step_towards(get_step_towards(origin, user), user)
	if(!line_clear(origin, destination) || !line_clear(destination, soul.owner))
		return FALSE
	soul.shifting = TRUE
	new /obj/effect/temp_visual/heretic_spirit/step(destination, src)
	to_chat(soul.owner, span_userdanger("Перевозчик тянет вашу душу к себе! Через секунду она сместится на две клетки. Коснитесь души или разбейте её, чтобы оборвать связь."))
	var/completed = do_after(user, 1 SECONDS, target = user, extra_checks = CALLBACK(src, PROC_REF(can_shift_soul), user, anchor, origin))
	if(QDELETED(soul))
		return FALSE
	soul.shifting = FALSE
	if(!completed || !can_shift_soul(user, anchor, origin) || !line_clear(origin, destination) || !line_clear(destination, soul.owner) || !spend_combat_resource())
		return FALSE
	soul.shifted = TRUE
	anchor.forceMove(destination)
	playsound(anchor, 'modular_bluemoon/sound/heretic/spirit_step.ogg', 55, TRUE)
	log_combat(user, soul.owner, "сместил отделённую душу")
	return TRUE

/datum/eldritch_knowledge/base_spirit/proc/reap(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/spirit_reap)
	if(!can_use(user) || QDELETED(required) || !isturf(victim?.loc) || !line_clear(user, victim) || !heretic_can_affect(user, victim, chargecost = 0))
		return FALSE
	if(!heretic_can_affect(user, victim))
		return TRUE
	var/brute_before = victim.getBruteLoss()
	victim.adjustBruteLoss(22)
	if(!can_use(user) || QDELETED(victim))
		return TRUE
	log_combat(user, victim, "наносит первый удар Жатвы", addition = "фактически [round(victim.getBruteLoss() - brute_before, 0.1)] ушибов")
	var/datum/status_effect/heretic_spirit/separated/soul = separate(victim, required)
	soul?.arm(required, 25)
	new /obj/effect/temp_visual/heretic_spirit/reap(get_turf(victim), src)
	playsound(user, 'modular_bluemoon/sound/heretic/spirit_cast.ogg', 60, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_spirit/proc/ring(mob/living/user, final_cast = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/required_type = final_cast ? /datum/eldritch_knowledge/final_eldritch/spirit_final : /datum/eldritch_knowledge/spell/spirit_bell
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(required_type)
	if(!can_use(user) || QDELETED(required) || (final_cast && !ascension_active) || (!final_cast && !spend_combat_resource(2)))
		return FALSE
	var/radius = final_cast ? 4 : 3
	for(var/turf/tile in range(radius, user))
		if(!line_clear(user, tile, radius))
			continue
		new /obj/effect/temp_visual/heretic_spirit/burst(tile, src)
		for(var/mob/living/victim in tile)
			if(!heretic_can_affect(user, victim))
				continue
			victim.adjustBruteLoss(final_cast ? 30 : 20)
			if(!can_use(user))
				return TRUE
			if(QDELETED(victim))
				continue
			victim.adjustStaminaLoss(final_cast ? 25 : 20)
			var/datum/status_effect/heretic_spirit/separated/soul = separate(victim, required)
			soul?.arm(required, final_cast ? 40 : 25)
	if(final_cast)
		new /obj/effect/temp_visual/heretic_spirit/ascend(get_turf(user), src)
	playsound(user, final_cast ? 'modular_bluemoon/sound/heretic/spirit_ascend.ogg' : 'modular_bluemoon/sound/heretic/spirit_cast.ogg', 75, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_spirit/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!can_use(user) || !proximity_flag || !user.Adjacent(target) || !istype(target, /obj/structure/bed) || !isturf(target.loc))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic.advance_deed(heretic.deed_key_for(target), get_turf(target)))
		return FALSE
	new /obj/effect/temp_visual/heretic_spirit/grasp(get_turf(target), src)
	user.visible_message(span_warning("Над [target] поднимается бледная фигура и склоняет голову перед [user]."))
	playsound(target, 'modular_bluemoon/sound/heretic/spirit_grasp.ogg', 45, TRUE)
	return TRUE

/datum/heretic_deed/spirit
	next_step = "Коснитесь Хваткой Мансуса кровати в ещё не зачтённом отделе."
	name = "Места последнего сна"
	desc = "Касайтесь Хваткой Мансуса кроватей в разных отделах. Каждый отдел засчитывается один раз."
	hint = "Медбей, общежитие, каюты: перевозчик узнаёт места, где люди закрывают глаза."
	trace_name = "след переправы"
	trace_desc = "Серебристый отпечаток пустой ладьи. Из него тянет холодом."
	trace_state = "sigil_spirit"

/datum/status_effect/heretic_spirit/separated
	id = "heretic_spirit_separated"
	duration = 10 SECONDS
	tick_interval = 0.5 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_spirit
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/spirit_ref
	var/datum/weakref/knowledge_ref
	var/datum/weakref/reaping_ref
	var/obj/structure/heretic_spirit_soul/anchor
	var/mutable_appearance/spirit_overlay
	var/moved_away = FALSE
	var/shifted = FALSE
	var/shifting = FALSE
	var/drained = 0
	var/drain_limit = HERETIC_SPIRIT_DRAIN_LIMIT
	var/reap_at = 0
	var/reap_damage = 0
	var/reap_end_reason = "связь оборвана: расстояние, преграда, защита или утрата силы"

/datum/status_effect/heretic_spirit/separated/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_spirit/spirit, datum/eldritch_knowledge/required)
	spirit_ref = WEAKREF(spirit)
	knowledge_ref = WEAKREF(required)
	return ..()

/datum/status_effect/heretic_spirit/separated/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(QDELETED(spirit) || QDELETED(required) || !spirit.can_use(spirit.spirit_body) || !isturf(owner.loc))
		return FALSE
	spirit.souls += src
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_owner_moved))
	RegisterSignal(owner, COMSIG_MOB_DEATH, PROC_REF(on_owner_dead))
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(update_overlay))
	spirit_overlay = mutable_appearance('modular_bluemoon/icons/obj/heretic_spirit_effects.dmi', "spirit_tether", ABOVE_MOB_LAYER)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(spirit.spirit_body)
	var/datum/eldritch_knowledge/spirit_temper/temper = heretic?.get_knowledge(/datum/eldritch_knowledge/spirit_temper)
	if(!QDELETED(temper))
		drain_limit += temper.passive_level * 5
	anchor = new(get_turf(owner), src)
	owner.update_icon()
	to_chat(owner, span_userdanger("Ваша душа осталась на месте! Коснитесь её или вернитесь на её клетку после отхода. Пока вы стоите на душе, коснуться её можно нажатием на значок «Разлучение». Дальше одной клетки связь истощает выносливость; душу можно разбить, закрыть стеной или оставить дальше пяти клеток."))
	return TRUE

/datum/status_effect/heretic_spirit/separated/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	reap_end_reason = "знание утрачено"
	qdel(src)

/datum/status_effect/heretic_spirit/separated/proc/on_owner_dead(datum/source)
	SIGNAL_HANDLER
	reap_end_reason = "цель погибла"
	qdel(src)

/datum/status_effect/heretic_spirit/separated/proc/update_overlay(atom/source, list/overlays)
	SIGNAL_HANDLER
	if(spirit_overlay)
		overlays += spirit_overlay

/datum/status_effect/heretic_spirit/separated/proc/on_owner_moved(datum/source)
	SIGNAL_HANDLER
	if(!validate_link())
		qdel(src)
		return
	if(get_turf(owner) != get_turf(anchor))
		moved_away = TRUE
	else if(moved_away)
		reap_end_reason = "цель вернулась к своей душе"
		qdel(src)
		return
	anchor.update_click_through()

/datum/status_effect/heretic_spirit/separated/proc/validate_link()
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	return !QDELETED(src) && !QDELETED(anchor) && isturf(anchor.loc) && spirit?.can_use(spirit.spirit_body, TRUE) && isturf(owner?.loc) && owner.stat != DEAD && spirit.line_clear(spirit.spirit_body, owner) && spirit.line_clear(anchor, owner) && heretic_can_affect(spirit.spirit_body, owner, chargecost = 0)

/datum/status_effect/heretic_spirit/separated/proc/arm(datum/eldritch_knowledge/required, damage)
	if(!validate_link() || QDELETED(required) || reap_at)
		return FALSE
	reaping_ref = WEAKREF(required)
	if(required != knowledge_ref?.resolve())
		RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	reap_at = world.time + HERETIC_SPIRIT_REAP_DELAY
	reap_damage = damage
	anchor.icon_state = "spirit_reap"
	anchor.set_light(2, 1, "#b2ffe3")
	to_chat(owner, span_userdanger("Перевозчик занёс крюк! Через 2 секунды связь ударит по вам: [reap_damage] ушибов дальше одной клетки от души, [min(reap_damage, HERETIC_SPIRIT_REAP_NEAR_DAMAGE)] рядом с ней. Коснитесь души, разбейте её или вернитесь на её клетку после отхода, чтобы оборвать связь!"))
	return TRUE

/datum/status_effect/heretic_spirit/separated/tick()
	if(!validate_link())
		qdel(src)
		return
	if(get_turf(owner) != get_turf(anchor))
		moved_away = TRUE
	else if(moved_away)
		reap_end_reason = "цель вернулась к своей душе"
		qdel(src)
		return
	if(reap_at && world.time >= reap_at)
		finish_reap()
		return
	if(get_dist(owner, anchor) > 1 && drained < drain_limit)
		var/damage = min(HERETIC_SPIRIT_DRAIN_PER_TICK, drain_limit - drained)
		drained += damage
		var/stamina_before = owner.getStaminaLoss()
		owner.adjustStaminaLoss(damage)
		if(shifted && owner.getStaminaLoss() > stamina_before)
			var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
			var/datum/antagonist/heretic/heretic = IS_HERETIC(spirit?.spirit_body)
			heretic?.advance_combat_deed(owner, PATH_SPIRIT)

/datum/status_effect/heretic_spirit/separated/proc/finish_reap()
	if(!reap_at || world.time < reap_at)
		return FALSE
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	var/can_hit = validate_link() && heretic_can_affect(spirit.spirit_body, owner)
	if(can_hit)
		var/mob/living/victim = owner
		var/mob/living/user = spirit.spirit_body
		var/damage = get_dist(victim, anchor) > 1 ? reap_damage : min(reap_damage, HERETIC_SPIRIT_REAP_NEAR_DAMAGE)
		var/brute_before = victim.getBruteLoss()
		reap_at = 0
		victim.adjustBruteLoss(damage)
		if(!QDELETED(victim) && !QDELETED(user))
			var/actual_damage = round(victim.getBruteLoss() - brute_before, 0.1)
			log_combat(user, victim, "завершает Жатву", addition = "второй удар: [actual_damage] ушибов")
			to_chat(user, span_notice("Жатва настигла [victim]: [actual_damage] ушибов."))
			if(!QDELETED(spirit))
				new /obj/effect/temp_visual/heretic_spirit/reap(get_turf(victim), spirit)
				playsound(victim, 'modular_bluemoon/sound/heretic/spirit_impact.ogg', 65, TRUE)
	if(!QDELETED(src))
		qdel(src)
	return can_hit

/datum/status_effect/heretic_spirit/separated/on_remove()
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	var/mob/living/user = spirit?.spirit_body
	if(reap_at && !QDELETED(user))
		user.log_message("Жатва [key_name(owner)] отменена: [reap_end_reason].", LOG_ATTACK)
		to_chat(user, span_notice("Жатва не сработала: [reap_end_reason]."))
	reap_at = 0
	spirit?.souls.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	var/datum/eldritch_knowledge/reaping = reaping_ref?.resolve()
	if(reaping && reaping != required)
		UnregisterSignal(reaping, COMSIG_PARENT_QDELETING)
	UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_DEATH, COMSIG_ATOM_UPDATE_OVERLAYS))
	spirit_overlay = null
	if(anchor)
		anchor.effect_ref = null
	QDEL_NULL(anchor)
	owner.update_icon()
	return ..()

/atom/movable/screen/alert/status_effect/heretic_spirit
	name = "Разлучение"
	desc = "Душа осталась на месте на 10 секунд. Касание своей души или возврат на её клетку после отхода гасит связь; стоя на душе или рядом, коснитесь её нажатием на этот значок. Дальше одной клетки от неё вы теряете выносливость, но не более 25–40 за всю связь. Жатва предупреждает за 2 секунды и бьёт второй раз, пока связь цела: дальше одной клетки от души сильнее, рядом слабее. Душу можно разбить; стены, антимагия и расстояние больше пяти клеток от души или еретика разрывают связь."
	icon = 'modular_bluemoon/icons/obj/heretic_spirit_effects.dmi'
	icon_state = "spirit_soul"

/atom/movable/screen/alert/status_effect/heretic_spirit/Click(location, control, params)
	. = ..()
	var/datum/status_effect/heretic_spirit/separated/soul = attached_effect
	if(!. || !istype(soul) || QDELETED(soul.anchor))
		return
	if(!owner.Adjacent(soul.anchor))
		to_chat(owner, span_warning("Душа слишком далеко: встаньте на её клетку или рядом."))
		return
	soul.anchor.attack_hand(owner)

/obj/structure/heretic_spirit_soul
	name = "unmoored soul"
	desc = "Серебристый силуэт, привязанный к ещё живому телу. Хозяин может погасить его касанием. Разрушение не вредит телу; нулевой жезл сразу обрывает связь. Перевозчик собирает силуэт пустой рукой. Крюком нужно бить тело, а не душу; сбор души отменяет подготовленную Жатву. Пока хозяин стоит или лежит на душе, клики проходят сквозь неё к телу."
	icon = 'modular_bluemoon/icons/obj/heretic_spirit_effects.dmi'
	icon_state = "spirit_soul"
	anchored = TRUE
	density = FALSE
	max_integrity = 20
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	var/datum/weakref/effect_ref
	COOLDOWN_DECLARE(hook_warning)

/obj/structure/heretic_spirit_soul/Initialize(mapload, datum/status_effect/heretic_spirit/separated/effect)
	. = ..()
	if(QDELETED(effect) || QDELETED(effect.owner))
		return INITIALIZE_HINT_QDEL
	effect_ref = WEAKREF(effect)
	name = "unmoored soul ([effect.owner.real_name])"
	set_light(1, 0.7, "#a8f5dc")
	update_click_through()

/obj/structure/heretic_spirit_soul/proc/update_click_through()
	var/datum/status_effect/heretic_spirit/separated/effect = effect_ref?.resolve()
	mouse_opacity = effect?.owner && get_turf(effect.owner) == loc ? MOUSE_OPACITY_TRANSPARENT : MOUSE_OPACITY_OPAQUE

/obj/structure/heretic_spirit_soul/proc/shielded_body(mob/user)
	var/datum/status_effect/heretic_spirit/separated/effect = effect_ref?.resolve()
	var/datum/eldritch_knowledge/base_spirit/spirit = effect?.spirit_ref?.resolve()
	if(user && user == spirit?.spirit_body && isturf(loc) && get_turf(effect.owner) == loc)
		return effect.owner
	return null

/obj/structure/heretic_spirit_soul/attack_hand(mob/living/user, act_intent = user?.a_intent, attackchain_flags)
	var/mob/living/body = shielded_body(user)
	if(body)
		return body.attack_hand(user, act_intent, attackchain_flags)
	if(!isliving(user) || user.incapacitated() || !user.Adjacent(src))
		return
	var/datum/status_effect/heretic_spirit/separated/effect = effect_ref?.resolve()
	if(user == effect?.owner)
		to_chat(user, span_notice("Вы возвращаете себе душу."))
		effect.reap_end_reason = "цель коснулась своей души"
		qdel(effect)
		return
	var/datum/eldritch_knowledge/base_spirit/spirit = effect?.spirit_ref?.resolve()
	if(user == spirit?.spirit_body)
		spirit.collect(user, effect)
		return
	return ..()

/obj/structure/heretic_spirit_soul/attackby(obj/item/weapon, mob/living/user, params, attackchain_flags = NONE, damage_multiplier = 1)
	var/mob/living/body = shielded_body(user)
	if(body)
		weapon.melee_attack_chain(user, body, params, attackchain_flags, damage_multiplier)
		return STOP_ATTACK_PROC_CHAIN
	var/datum/status_effect/heretic_spirit/separated/effect = effect_ref?.resolve()
	var/datum/eldritch_knowledge/base_spirit/spirit = effect?.spirit_ref?.resolve()
	if(istype(weapon, /obj/item/melee/sickly_blade/spirit) && user == spirit?.spirit_body)
		if(user.Adjacent(src) && COOLDOWN_FINISHED(src, hook_warning))
			COOLDOWN_START(src, hook_warning, 5 SECONDS)
			to_chat(user, span_notice("Крюком бейте тело: удары по душе не передают урон. Соберите душу пустой рукой или фонарём, если хотите получить обол; это отменит подготовленную Жатву."))
			user.log_message("не разрушает свою отделённую душу [key_name(effect.owner)] крюком перевозчика; связь сохранена.", LOG_ATTACK)
		return STOP_ATTACK_PROC_CHAIN
	if(istype(weapon, /obj/item/nullrod) && user.Adjacent(src))
		qdel(src)
		return
	return ..()

/obj/structure/heretic_spirit_soul/Destroy()
	var/datum/status_effect/heretic_spirit/separated/effect = effect_ref?.resolve()
	effect_ref = null
	if(!QDELETED(effect))
		effect.reap_end_reason = "душа разрушена"
		if(effect.anchor == src)
			effect.anchor = null
		qdel(effect)
	return ..()

/obj/structure/heretic_spirit_soul/Moved(atom/old_location, direction, forced = FALSE)
	. = ..()
	var/datum/status_effect/heretic_spirit/separated/effect = effect_ref?.resolve()
	if(effect && !effect.validate_link())
		qdel(src)
		return
	update_click_through()

/datum/status_effect/eldritch/spirit
	id = "spirit_mark"
	mark_name = "Метка Духа"
	mark_alert_state = "sigil_spirit"
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_spirit_effects.dmi'
	effect_sprite = "spirit_mark"
	detonation_sound = 'modular_bluemoon/sound/heretic/spirit_impact.ogg'
	var/datum/weakref/spirit_ref
	var/datum/weakref/knowledge_ref

/datum/status_effect/eldritch/spirit/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_spirit/spirit)
	spirit_ref = WEAKREF(spirit)
	return ..()

/datum/status_effect/eldritch/spirit/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(spirit?.spirit_body)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spirit_mark)
	if(QDELETED(spirit) || QDELETED(required))
		return FALSE
	knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	spirit.marks += src
	return TRUE

/datum/status_effect/eldritch/spirit/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/eldritch/spirit/on_remove()
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	spirit?.marks.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	return ..()

/datum/status_effect/eldritch/spirit/on_effect()
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	if(spirit?.can_use(spirit.spirit_body) && heretic_can_affect(spirit.spirit_body, owner, chargecost = 0))
		owner.adjustBruteLoss(8)
		spirit.separate(owner, knowledge_ref?.resolve())
	return ..()

/obj/item/melee/sickly_blade/spirit
	name = "ferryman's hook"
	desc = "Серебряный ритуальный крюк с полой рукоятью. Внутри позвякивает единственная монета, которую невозможно вытряхнуть. Бейте тело противника: удар по телу с вашей душой приносит обол раз в 6 секунд, а удар по отдельно лежащей душе сохраняет её для Жатвы. Для сбора души нужна пустая рука или фонарь."
	icon = 'modular_bluemoon/icons/obj/heretic_spirit.dmi'
	icon_state = "spirit_blade"
	item_state = "spirit_blade"
	route = PATH_SPIRIT
	mark_type = /datum/status_effect/eldritch/spirit

/obj/item/heretic_path_relic/spirit
	name = "ferryman's lantern"
	desc = "Фонарь перевозчика. Подтягивает ваши отделённые души из трёх клеток на одну клетку ближе, а ближайшие собирает. Полученный при сборе обол лечит 12 ушибов и ожогов суммарно. Не перемещает тела и не действует через стены. Перезарядка 20 секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_spirit.dmi'
	icon_state = "spirit_lantern"
	item_state = "spirit_lantern"
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_relics_spirit_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_relics_spirit_righthand.dmi'

/obj/item/heretic_path_relic/spirit/attack_self(mob/living/user)
	return beckon(user)

/obj/item/heretic_path_relic/spirit/proc/beckon(mob/living/user)
	if(!isliving(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!authorized(user) || !spirit?.can_use(user) || !COOLDOWN_FINISHED(src, relic_cooldown))
		return FALSE
	var/acted = FALSE
	var/healing = 0
	for(var/datum/status_effect/heretic_spirit/separated/soul as anything in spirit.souls.Copy())
		if(!soul.validate_link() || !spirit.line_clear(user, soul.anchor, 3))
			continue
		acted = TRUE
		if(!user.Adjacent(soul.anchor))
			var/turf/destination = get_step(soul.anchor, get_dir(soul.anchor, user))
			if(spirit.line_clear(soul.anchor, destination, 1))
				soul.anchor.forceMove(destination)
		if(QDELETED(soul))
			continue
		if(user.Adjacent(soul.anchor) && spirit.collect(user, soul))
			healing = HERETIC_SPIRIT_LANTERN_HEAL
	if(!acted)
		return FALSE
	heretic_heal_pool(user, healing)
	COOLDOWN_START(src, relic_cooldown, 20 SECONDS)
	new /obj/effect/temp_visual/heretic_spirit/grasp(get_turf(user), spirit)
	playsound(user, 'modular_bluemoon/sound/heretic/spirit_cast.ogg', 50, TRUE)
	return TRUE

/obj/effect/temp_visual/heretic_spirit
	icon = 'modular_bluemoon/icons/obj/heretic_spirit_effects.dmi'
	icon_state = "spirit_burst"
	duration = 0.8 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	var/datum/weakref/spirit_ref

/obj/effect/temp_visual/heretic_spirit/Initialize(mapload, datum/eldritch_knowledge/base_spirit/spirit)
	if(!QDELETED(spirit))
		spirit_ref = WEAKREF(spirit)
		spirit.visuals += src
	return ..()

/obj/effect/temp_visual/heretic_spirit/Destroy()
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	spirit?.visuals.Remove(src)
	spirit_ref = null
	return ..()

/obj/effect/temp_visual/heretic_spirit/grasp
	icon_state = "spirit_grasp"

/obj/effect/temp_visual/heretic_spirit/burst

/obj/effect/temp_visual/heretic_spirit/step
	icon_state = "spirit_step"

/obj/effect/temp_visual/heretic_spirit/reap
	icon_state = "spirit_reap"
	duration = HERETIC_SPIRIT_REAP_DELAY

/obj/effect/temp_visual/heretic_spirit/ascend
	icon_state = "spirit_ascend"
	duration = 2 SECONDS

/datum/eldritch_knowledge/spirit_grasp
	parent_type = /datum/eldritch_knowledge/spell
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_spirit/shift
	name = "Душа на ладони"
	desc = "Хватка Мансуса отделяет душу живого врага на 10 секунд. Силуэт остаётся на месте; его можно собрать рукой для обола или использовать для Переправы и Жатвы. Даёт «Сместить душу»: за 1 обол и секунду подготовки подтяните силуэт на две клетки к себе, стоя в трёх–пяти клетках от него; если враг стоит на душе, выберите его тело. Один раз за связь; её срок и запас истощения сохраняются."
	gain_text = "Ладонь прошла сквозь грудь и вернулась тяжёлой."
	cost = 1
	route = PATH_SPIRIT

/datum/eldritch_knowledge/spirit_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!proximity_flag || !spirit?.can_use(user) || !user.Adjacent(target) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	return !!spirit.separate(target, src)

/datum/eldritch_knowledge/spirit_grasp/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	spirit?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/spell/spirit_step
	name = "Переправа"
	desc = "За обол переместитесь по открытой линии на свободную клетку в пределах трёх клеток и восстановите 15 выносливости. Клетка дальше трёх укорачивает переход до трёх клеток по той же линии. Если выбрать отделённую вами душу или тело, стоящее на ней, дальность растёт до пяти клеток, а по прибытии вы собираете душу. Если место занято телом, вы встаёте рядом с ним со своей стороны. Лежащего или обездвиженного, которого вы тащите, Переправа переносит вместе с вами и захват не теряется. В намерении «Разоружить» душа сохраняется с прежним сроком и бюджетом истощения: награды за сбор нет, зато можно продолжить охоту и Жатву. Стены и окна на пути, плотный предмет на месте прибытия, пристёгивание и запрет телепортации останавливают переход. Перезарядка 12 секунд."
	gain_text = "Река была шириной в один шаг. Только берегов у неё не было."
	cost = 1
	route = PATH_SPIRIT
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_spirit/step

/datum/eldritch_knowledge/spirit_mark
	name = "Метка Духа"
	desc = "Хватка оставляет метку на 15 секунд. Крюк взрывает её на 8 ушибов и отделяет душу, если её ещё нет. Метка не обновляет уже существующую связь."
	gain_text = "Я записал имя на монете. На обратной стороне появилось моё."
	cost = 2
	route = PATH_SPIRIT

/datum/eldritch_knowledge/spirit_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!proximity_flag || !spirit?.can_use(user) || !user.Adjacent(target) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/spirit, spirit)
	return TRUE

/datum/eldritch_knowledge/spirit_mark/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(spirit)
		QDEL_LIST(spirit.marks)
		spirit.clear_knowledge_effects(src)

/datum/eldritch_knowledge/spirit_relic
	name = "Фонарь перевозчика"
	desc = "Фонарик и лист серебра создают единственный фонарь. В руке он подтягивает ваши души в трёх клетках на клетку ближе и собирает ближайшие. Полученный обол лечит до 12 ушибов и ожогов суммарно; общая задержка сбора сохраняется. Фонарь не двигает тела и не проходит через стены. Перезарядка 20 секунд."
	gain_text = "Огонёк освещал тех, кто ещё не знал, что заблудился."
	cost = 1
	route = PATH_SPIRIT
	required_atoms = list(/obj/item/flashlight, /obj/item/stack/sheet/mineral/silver)
	result_atoms = list(/obj/item/heretic_path_relic/spirit)

/datum/eldritch_knowledge/spirit_relic/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/spirit_relic/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/spirit)

/datum/eldritch_knowledge/spirit_upgrade
	name = "Серебро режет нить"
	desc = "Удар крюком по телу с отделённой вами душой наносит ещё 6 ушибов, не чаще раза в 3 секунды. Душа остаётся; удары по самому силуэту по-прежнему не ранят тело."
	gain_text = "Лезвие зацепило нить, которую я раньше не видел."
	cost = 2
	route = PATH_SPIRIT
	COOLDOWN_DECLARE(spirit_blade)

/datum/eldritch_knowledge/spirit_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(QDELETED(src) || !proximity_flag || !spirit?.can_use(user) || !user.Adjacent(target) || !heretic_can_affect(user, target, chargecost = 0) || !COOLDOWN_FINISHED(src, spirit_blade))
		return
	var/mob/living/victim = target
	var/datum/status_effect/heretic_spirit/separated/soul = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
	if(soul?.spirit_ref?.resolve() != spirit || !soul.validate_link())
		return
	COOLDOWN_START(src, spirit_blade, 3 SECONDS)
	victim.adjustBruteLoss(HERETIC_SPIRIT_BLADE_BONUS)

/datum/eldritch_knowledge/spell/spirit_reap
	name = "Жатва неприкаянных"
	desc = "Бесплатно нанесите цели в пяти клетках 22 ушиба и отделите её душу. На душе вспыхивает предупреждение: через 2 секунды, если связь цела, враг получит второй удар — 25 ушибов дальше одной клетки от души или 15 рядом с ней. Затем душа исчезает. Касание души, её разрушение, возврат на её клетку после отхода, антимагия и разрыв связи отменяют удар. Перезарядка 18 секунд."
	gain_text = "Я позвал живого по имени, которым его назовут после смерти."
	cost = 1
	route = PATH_SPIRIT
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_spirit/reap

/datum/eldritch_knowledge/spell/spirit_reap/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	spirit?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/spirit_temper
	name = "Кошель утонувших"
	desc = "Вместимость оболов растёт до 6, а предел истощения новых связей — до 30 выносливости. Изучение не заполняет кошель и не обновляет существующие души."
	gain_text = "Ни одна монета не звенела. Каждая помнила дно."
	cost = 2
	route = PATH_SPIRIT
	passive_values = list(6, 7, 8)
	passive_desc = "Вместимость 6 / 7 / 8, предел истощения новых связей 30 / 35 / 40."
	var/datum/weakref/spirit_ref

/datum/eldritch_knowledge/spirit_temper/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(spirit)
		spirit_ref = WEAKREF(spirit)
		spirit.update_capacity()

/datum/eldritch_knowledge/spirit_temper/on_passive_upgrade(mob/living/user)
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	spirit?.update_capacity()

/datum/eldritch_knowledge/spirit_temper/on_lose(mob/user)
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	spirit?.update_capacity(ignore_temper = TRUE)
	return ..()

/datum/eldritch_knowledge/spirit_temper/Destroy()
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	spirit?.update_capacity(ignore_temper = TRUE)
	spirit_ref = null
	return ..()

/datum/eldritch_knowledge/spell/spirit_bell
	name = "Заупокойный звон"
	desc = "За два обола поразите врагов в трёх клетках на 20 ушибов и 20 выносливости и отделите до трёх душ. Каждая предупреждает о жатве через 2 секунды: пока связь цела, ещё 25 ушибов дальше одной клетки от души или 15 рядом с ней. Стены закрывают цель. Перезарядка 35 секунд."
	gain_text = "Колокол ударил под водой. На берегу все обернулись."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_SPIRIT
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_spirit/bell

/datum/eldritch_knowledge/spell/spirit_bell/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	spirit?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/final_eldritch/spirit_final
	name = "Перевозчик без берега"
	desc = "После трёх назначенных душ принесите три человеческих трупа. Обряд раскрывает место станции и длится 30 секунд. Вы не нуждаетесь в дыхании и получаете на четверть меньше ушибов и ожогов. Вместимость 8, восстановление обола каждые 4 секунды, до шести душ одновременно. «Последний рейс» бесплатно поражает врагов в четырёх клетках на 30 ушибов и 25 выносливости и готовит жатву через 2 секунды: 40 ушибов дальше одной клетки от души, 15 рядом с ней. Касание души, возврат на её клетку после отхода и остальные способы разрыва связи спасают от второго удара. Перезарядка 40 секунд."
	gain_text = "Ладья пришла пустой. Перевозчик уступил мне весло и лёг на дно."
	route = PATH_SPIRIT
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_traits = list(TRAIT_NOBREATH)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_spirit/crown)

/datum/eldritch_knowledge/final_eldritch/spirit_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	on_body_gain(user)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/spirit_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(spirit)
		spirit.ascension_active = TRUE
		spirit.update_capacity()

/datum/eldritch_knowledge/final_eldritch/spirit_final/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(spirit)
		spirit.ascension_active = FALSE
		spirit.clear_spirit()
		spirit.update_capacity()
	return ..()

/obj/effect/proc_holder/spell/pointed/heretic_spirit
	clothes_req = FALSE
	invocation_type = "none"
	range = HERETIC_SPIRIT_RANGE
	selection_type = "view"
	aim_assist = FALSE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"
	active_msg = "Укажите пассажира или место переправы."
	deactive_msg = "Вы опускаете руку перевозчика."

/obj/effect/proc_holder/spell/pointed/heretic_spirit/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	return ..() && heretic_check(user, spirit?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/pointed/heretic_spirit/proc/wrong_target_reason(atom/target, mob/user)
	if(istype(target, /obj/structure/heretic_spirit_soul))
		return "Выберите тело живого противника, а не силуэт души."
	if(target == user)
		return "Нельзя выбрать себя: укажите живого противника."
	if(isturf(target))
		return "Клик пришёлся на пол: укажите самого живого противника."
	return "Выберите живого противника, а не предмет."

/obj/effect/proc_holder/spell/pointed/heretic_spirit/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!isliving(target) || target == user)
		return heretic_check(user, FALSE, silent, wrong_target_reason(target, user))
	var/mob/living/victim = target
	if(!heretic_check(user, !IS_HERETIC(victim) && !IS_HERETIC_MONSTER(victim), silent, "Это союзник Мансуса: еретики и их слуги защищены от этой способности.", target = victim))
		return FALSE
	if(!heretic_check(user, victim.stat != DEAD && isturf(victim.loc), silent, "Нужно живое тело вне шкафа или другого контейнера."))
		return FALSE
	if(!heretic_check(user, spirit?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	if(!heretic_check(user, spirit.line_clear(user, victim, range), silent, "Цель должна быть не дальше [range] клеток по открытой линии без стен и преград."))
		return FALSE
	return heretic_check(user, heretic_can_affect(user, victim, chargecost = 0), silent, "Цель защищена от магии.", target = victim)

/obj/effect/proc_holder/spell/pointed/heretic_spirit/sever
	name = "Разлучение"
	desc = "За один обол нанесите 20 ушибов и 15 выносливости и отделите душу врага на 10 секунд."
	action_icon_state = "spirit_sever"
	charge_max = 12 SECONDS

/obj/effect/proc_holder/spell/pointed/heretic_spirit/sever/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!length(targets) || !spirit?.sever(user, targets[1]))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_spirit/step
	name = "Переправа"
	desc = "За обол переместитесь по открытой линии до трёх клеток и восстановите 15 выносливости; клетка дальше укорачивает переход до трёх. Своя душа или тело, стоящее на ней, увеличивает дальность до пяти клеток, и душа собирается по прибытии. На занятое телом место вы встаёте рядом с ним. Лежащего или обездвиженного, которого вы тащите, Переправа переносит с вами. В намерении «Разоружить» душа остаётся для дальнейшей охоты: срок и истощение не обновляются, обол за сбор не выдаётся."
	action_icon_state = "spirit_step"
	charge_max = 12 SECONDS

/obj/effect/proc_holder/spell/pointed/heretic_spirit/step/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!heretic_check(user, spirit?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	if(!heretic_check(user, target && (isturf(target) || isturf(target.loc)), silent, "Выберите клетку, тело или душу вне контейнеров."))
		return FALSE
	var/turf/destination = spirit.crossing_destination(user, target)
	return heretic_check(user, destination, silent, spirit.crossing_failure)

/obj/effect/proc_holder/spell/pointed/heretic_spirit/step/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!length(targets) || !spirit?.cross(user, targets[1], preserve_soul = user.a_intent == INTENT_DISARM))
		heretic_revert_cast(user, spirit?.crossing_failure)

/obj/effect/proc_holder/spell/pointed/heretic_spirit/shift
	name = "Сместить душу"
	desc = "За 1 обол притяните свою отделённую душу на две клетки к себе после секунды предупреждения. Встаньте в трёх–пяти клетках от неё и выберите силуэт или тело, стоящее на нём. Каждую душу можно сместить один раз; срок связи и предел истощения сохраняются. Движение прерывает подготовку. Жертва может коснуться души, разбить её или оборвать связь стеной. Перезарядка 6 секунд."
	action_icon_state = "spirit_step"
	charge_max = 6 SECONDS
	aim_assist = FALSE

/obj/effect/proc_holder/spell/pointed/heretic_spirit/shift/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/obj/structure/heretic_spirit_soul/anchor = spirit?.own_soul_at(target)
	return heretic_check(user, anchor && spirit.can_shift_soul(user, anchor), silent, "Выберите свою ещё не смещённую душу или тело, стоящее на ней, в трёх–пяти клетках без преград. Нужен 1 обол и знание «Душа на ладони».")

/obj/effect/proc_holder/spell/pointed/heretic_spirit/shift/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/obj/structure/heretic_spirit_soul/anchor = length(targets) ? spirit?.own_soul_at(targets[1]) : null
	if(!anchor || !spirit.shift_soul(user, anchor))
		heretic_revert_cast(user, "Смещение прервано или душа больше недоступна.")

/obj/effect/proc_holder/spell/pointed/heretic_spirit/reap
	name = "Жатва неприкаянных"
	desc = "Бесплатный удар на 22 ушиба. Через 2 секунды, если связь цела, второй удар: 25 ушибов дальше одной клетки от души или 15 рядом с ней."
	action_icon_state = "spirit_reap"
	charge_max = 18 SECONDS

/obj/effect/proc_holder/spell/pointed/heretic_spirit/reap/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!length(targets) || !spirit?.reap(user, targets[1]))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_spirit
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_spirit/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	return ..() && heretic_check(user, spirit?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_spirit/bell
	name = "Заупокойный звон"
	desc = "За два обола поразите врагов в трёх клетках на 20 ушибов и 20 выносливости и подготовьте жатву их душ через 2 секунды."
	action_icon_state = "spirit_bell"
	charge_max = 35 SECONDS

/obj/effect/proc_holder/spell/self/heretic_spirit/bell/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!spirit?.ring(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_spirit/crown
	name = "Последний рейс"
	desc = "Поразите врагов в четырёх клетках на 30 ушибов и 25 выносливости. До шести душ предупреждают о жатве через 2 секунды: 40 ушибов дальше одной клетки от души или 15 рядом с ней. Требует вознесения."
	action_icon_state = "spirit_crown"
	charge_max = 40 SECONDS

/obj/effect/proc_holder/spell/self/heretic_spirit/crown/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	return ..() && heretic_check(user, spirit?.ascension_active, silent, "Сначала завершите вознесение этого пути.")

/obj/effect/proc_holder/spell/self/heretic_spirit/crown/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!spirit?.ring(user, TRUE))
		heretic_revert_cast(user)

#undef HERETIC_SPIRIT_RANGE
#undef HERETIC_SPIRIT_SOUL_LIMIT
#undef HERETIC_SPIRIT_DRAIN_LIMIT
#undef HERETIC_SPIRIT_REAP_DELAY
#undef HERETIC_SPIRIT_RECOVERY
#undef HERETIC_SPIRIT_HARVEST
#undef HERETIC_SPIRIT_STEP_RANGE
#undef HERETIC_SPIRIT_DRAIN_PER_TICK
#undef HERETIC_SPIRIT_STAMINA_RESTORE
#undef HERETIC_SPIRIT_LANTERN_HEAL
#undef HERETIC_SPIRIT_BLADE_BONUS
#undef HERETIC_SPIRIT_HOOK_INCOME
#undef HERETIC_SPIRIT_REAP_NEAR_DAMAGE
