#define HERETIC_SPIRIT_RANGE 5
#define HERETIC_SPIRIT_SOUL_LIMIT 3
#define HERETIC_SPIRIT_DRAIN_LIMIT 25
#define HERETIC_SPIRIT_REAP_DELAY (2 SECONDS)
#define HERETIC_SPIRIT_REAP_AFTERGLOW (4 SECONDS)
#define HERETIC_SPIRIT_RECOVERY (10 SECONDS)
#define HERETIC_SPIRIT_HARVEST (6 SECONDS)
#define HERETIC_SPIRIT_STEP_RANGE 3
#define HERETIC_SPIRIT_DRAIN_PER_TICK 2.5
#define HERETIC_SPIRIT_STAMINA_RESTORE 15
#define HERETIC_SPIRIT_LANTERN_HEAL 12
#define HERETIC_SPIRIT_HOOK_INCOME (6 SECONDS)
#define HERETIC_SPIRIT_REAP_NEAR_DAMAGE 15
#define HERETIC_SPIRIT_PASSAGE_COOLDOWN (0.2 SECONDS)
#define HERETIC_SPIRIT_PASSAGE_TIME (0.5 SECONDS)
#define HERETIC_SPIRIT_PASSAGE_ALPHA 140
#define HERETIC_SPIRIT_PASSAGE_DRIFT 10
#define HERETIC_SPIRIT_TOLL_FLIGHT (0.7 SECONDS)
#define HERETIC_SPIRIT_TOLL_SEGMENTS 4
#define HERETIC_SPIRIT_TOLL_ARC 0.35
#define HERETIC_SPIRIT_TOLL_FADE_IN (0.1 SECONDS)
#define HERETIC_SPIRIT_TOLL_ABSORB 0.5
#define HERETIC_SPIRIT_TOLL_PULSE (0.5 SECONDS)
#define HERETIC_SPIRIT_TOLL_FLASH_RANGE 2
#define HERETIC_SPIRIT_TOLL_FLASH_POWER 1
#define HERETIC_SPIRIT_TOLL_FLASH_TIME (0.4 SECONDS)
#define HERETIC_SPIRIT_VOYAGE_WAVE_RADIUS 4
#define HERETIC_SPIRIT_VOYAGE_WAVE_TIME (0.9 SECONDS)
#define HERETIC_SPIRIT_VOYAGE_FLASH_RANGE 5
#define HERETIC_SPIRIT_VOYAGE_FLASH_POWER 2
#define HERETIC_SPIRIT_VOYAGE_FLASH_TIME (0.6 SECONDS)
#define HERETIC_SPIRIT_VOYAGE_QUAKE 0.15
#define HERETIC_SPIRIT_VOYAGE_QUAKE_RADIUS 7
#define HERETIC_SPIRIT_VOYAGE_QUAKE_TIME (0.4 SECONDS)
#define HERETIC_SPIRIT_VOYAGE_LANTERN_TIME (1.2 SECONDS)
#define HERETIC_SPIRIT_VOYAGE_SPIRAL_RADIUS 128
#define HERETIC_SPIRIT_VOYAGE_SPIRAL_TRAVEL (1.2 SECONDS)
#define HERETIC_SPIRIT_VOYAGE_SPIRAL_EMIT (0.8 SECONDS)
#define HERETIC_SPIRIT_VOYAGE_SPIRAL_ARMS 6
#define HERETIC_SPIRIT_VOYAGE_SPIRAL_SWIRL 1
#define HERETIC_SPIRIT_OBOL_CRAFT "spirit_obol"
#define HERETIC_SPIRIT_OBOL_CLUE "На глазах тела лежат две холодные серебряные монеты."
#define HERETIC_SPIRIT_WHISPER_LENGTH 256
#define HERETIC_SPIRIT_HOLD_CAPTURE "spirit_hold"
#define HERETIC_SPIRIT_HOLD_CHECK (0.2 SECONDS)
#define HERETIC_SPIRIT_INCORPOREAL_TRAIT "heretic_spirit_incorporeal"
#define HERETIC_SPIRIT_INCORPOREAL_HASTE -0.35
#define HERETIC_SPIRIT_INCORPOREAL_ALPHA 110
#define HERETIC_SPIRIT_INCORPOREAL_CHECK (0.5 SECONDS)
#define HERETIC_SPIRIT_ASCENDED_SOUL_LIMIT 6
#define HERETIC_SPIRIT_WHISPER_COOLDOWN (5 SECONDS)
#define HERETIC_SPIRIT_PASSMOB_TRAIT "heretic_spirit_passmob"
#define HERETIC_SPIRIT_PASSMOB_OWNED_TRAIT "heretic_spirit_passmob_owned"

/datum/heretic_path/spirit
	id = PATH_SPIRIT
	deed_type = /datum/heretic_deed/spirit
	name = "Дух"
	tagline = "Кладёт оболы на глаза мёртвым, держит чужую душу в руке, становится бесплотным."
	craft_summary = "Хватка в «Помощи» по трупу: обол открывает последний миг, а призрак 5 минут шепчет вам."
	capture_summary = "Душа в руке держит тело пустым до 12 секунд; сердце во второй руке переправляет его в изнанку."
	escape_summary = "3 секунды пули и удары проходят сквозь вас; из изнанки выходите к телам со своим оболом."
	strength_points = list(
		"Разлучение за обол сразу ранит врага в 5 клетках и оставляет его душу на месте.",
		"Жатва и Заупокойный звон бьют второй раз, пока связь с душой цела.",
		"Удержать душу держит цель до 12 секунд, а сердце во второй руке переправляет её в изнанку.",
		"Переправа переносит вас к душе и берёт с собой лежащую жертву.",
		"Бесплотность пропускает пули и удары и уводит сквозь толпу и столы.",
		"Оболы на трупах называют убийцу, а призраки шепчут вам то, что видели.",
	)
	weakness_points = list(
		"Хозяин гасит душу касанием, её можно разбить, а стены и дальность больше 5 клеток рвут связь.",
		"Душу в руке вернут удар 15+ по вам, оглушение, нулевой жезл или 2 секунды растолкать тело.",
		"Бесплотный не атакует: удар, хоть предметом по двери или стене, выстрел и заклинание возвращают плоть.",
		"Антимагия и нулевой жезл гасят связи, а наручники закрывают Бесплотность.",
		"Монеты на глазах трупов - улика, нулевой жезл их снимает.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_spirit,
		/datum/eldritch_knowledge/spirit_grasp,
		/datum/eldritch_knowledge/spell/spirit_step,
		/datum/eldritch_knowledge/spell/spirit_hold,
		/datum/eldritch_knowledge/spell/spirit_incorporeal,
		/datum/eldritch_knowledge/spirit_mark,
		/datum/eldritch_knowledge/spell/spirit_reap,
		/datum/eldritch_knowledge/spirit_relic,
		/datum/eldritch_knowledge/spell/spirit_bell,
		/datum/eldritch_knowledge/final_eldritch/spirit_final,
	)

/datum/eldritch_knowledge/base_spirit
	name = "Монета под языком"
	summary = "Разлучение отделяет душу врага, а Хватка в «Помощи» кладёт обол на глаза трупа."
	details = list(
		"Разлучение за 1 обол: 20 ушибов и 15 выносливости цели в 5 клетках, её душа 10 секунд стоит на месте.",
		"Дальше клетки от души тело теряет выносливость, до 25 за связь; касание души или возврат на неё гасят связь.",
		"Обол на глаза: Хватка в «Помощи» по трупу человека показывает, кто, чем, когда и где ранил его последним.",
		"Призрак тела с оболом 5 минут может шептать только вам. Держатся 3 обола, новый вытесняет старый.",
		"Каждый новый отдел с оболом идёт в дело. Экипаж видит монеты на глазах, нулевой жезл их снимает.",
		"Нож и лист серебра на руне дают крюк перевозчика.",
		"Из изнанки выходите к телу со своим оболом, на соседнюю с ним клетку.",
	)
	role = HERETIC_ROLE_CRAFT
	gain_text = "Я положил монету под язык. На другом берегу назвали моё имя."
	route = PATH_SPIRIT
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/mineral/silver)
	result_atoms = list(/obj/item/melee/sickly_blade/spirit)
	combat_resource = 3
	combat_resource_max = 5
	combat_resource_name = "Оболы"
	resource_rules = list(
		"Начальный запас 3 из 5; сами восстанавливаются только первые 2 обола, по одному раз в 10 секунд.",
		"Удар крюком по телу с вашей душой даёт обол раз в 6 секунд, взрыв Метки Духа - ещё один.",
		"Сбор отделённой души разумного врага рукой даёт обол и 15 выносливости раз в 6 секунд.",
		"Новый шаг дела даёт обол.",
		"Кошель утонувших из знания Фонаря поднимает вместимость до 6, улучшения - до 8.",
		"Разлучение и Переправа стоят 1 обол, Заупокойный звон - 2.",
		"Одновременно держатся 3 души; смерть и смена тела гасят их и обнуляют запас.",
	)
	combat_resource_action = /obj/effect/proc_holder/spell/pointed/heretic_spirit/sever
	grasp_visual = /obj/effect/temp_visual/heretic_spirit/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/spirit_grasp.ogg'
	grasp_catchphrase = "SIE'LA KE'LIAUJA"
	var/mob/living/spirit_body
	var/list/datum/status_effect/heretic_spirit/separated/souls = list()
	var/list/datum/status_effect/eldritch/spirit/marks = list()
	var/list/obj/effect/temp_visual/heretic_spirit/visuals = list()
	/// Трупы с оболом, старейший первым; значение - когда кончается шёпот призрака.
	var/list/obols = list()
	var/list/obol_ghosts = list()
	var/list/whisper_ready = list()
	var/datum/status_effect/heretic_spirit_hold/soul_hold
	var/ascension_active = FALSE
	var/crossing_failure
	var/shift_failure
	var/ring_failure
	var/whisper_failure
	var/hold_failure
	var/incorporeal_failure_reason
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
	for(var/mob/living/corpse as anything in obols.Copy())
		remove_obol(corpse)
	obols.Cut()
	obol_ghosts.Cut()
	whisper_ready.Cut()
	return ..()

/datum/eldritch_knowledge/base_spirit/proc/clear_spirit()
	soul_hold?.release("перевозчик потерял тело")
	QDEL_LIST(souls)
	QDEL_LIST(marks)
	QDEL_LIST(visuals)

/datum/eldritch_knowledge/base_spirit/proc/clear_knowledge_effects(datum/eldritch_knowledge/required)
	for(var/datum/status_effect/heretic_spirit/separated/soul as anything in souls.Copy())
		if(soul.knowledge_ref?.resolve() == required || soul.reaping_ref?.resolve() == required)
			qdel(soul)

/datum/eldritch_knowledge/base_spirit/proc/can_use(mob/living/user, allow_incapacitated = FALSE, ignore_grab = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && user && user == spirit_body && user.stat != DEAD && (allow_incapacitated || !user.incapacitated(ignore_grab = ignore_grab)) && isturf(user.loc) && heretic?.selected_path == PATH_SPIRIT && !heretic.role_removed && heretic.get_knowledge(type) == src

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

/// Своя душа по клику на силуэт, на тело, чья это душа, или на тело, стоящее на ней.
/datum/eldritch_knowledge/base_spirit/proc/soul_anchor_of(atom/target)
	if(isliving(target))
		var/mob/living/victim = target
		var/datum/status_effect/heretic_spirit/separated/soul = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
		if(soul?.spirit_ref?.resolve() == src && !QDELETED(soul.anchor))
			return soul.anchor
	return own_soul_at(target)

/datum/eldritch_knowledge/base_spirit/combat_resource_state()
	return "Душ: [length(souls)] из [ascension_active ? HERETIC_SPIRIT_ASCENDED_SOUL_LIMIT : HERETIC_SPIRIT_SOUL_LIMIT]. Оболов на глазах: [length(obols)] из [HERETIC_SPIRIT_OBOL_LIMIT]."

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

/datum/eldritch_knowledge/base_spirit/proc/update_capacity(ignore_purse = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(spirit_body)
	var/datum/eldritch_knowledge/spirit_relic/purse = heretic?.get_knowledge(/datum/eldritch_knowledge/spirit_relic)
	combat_resource_max = ascension_active ? 8 : !ignore_purse && !QDELETED(purse) ? purse.passive_values[purse.passive_level] : initial(combat_resource_max)
	combat_resource = min(combat_resource, combat_resource_max)
	notify_resource_changed()

/datum/eldritch_knowledge/base_spirit/proc/separate(mob/living/victim, datum/eldritch_knowledge/required)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(spirit_body)
	if(!can_use(spirit_body) || QDELETED(required) || heretic.get_knowledge(required.type) != required || !isturf(victim?.loc) || !line_clear(spirit_body, victim) || !heretic_can_affect(spirit_body, victim, chargecost = 0))
		return null
	var/datum/status_effect/heretic_spirit/separated/existing = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
	if(existing)
		return existing.spirit_ref?.resolve() == src ? existing : null
	if(length(souls) >= (ascension_active ? HERETIC_SPIRIT_ASCENDED_SOUL_LIMIT : HERETIC_SPIRIT_SOUL_LIMIT))
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
	shift_failure = null
	if(!can_use(user) || QDELETED(required))
		shift_failure = "Для смещения изучите «Душа на ладони» и используйте своё тело еретика."
	else if(QDELETED(anchor) || soul?.spirit_ref?.resolve() != src)
		shift_failure = "Здесь нет отделённой вами души. Сначала примените Разлучение, затем укажите силуэт или само тело."
	else if(soul.shifted)
		shift_failure = "Эта душа уже смещена. Отделите новую: каждую душу можно сместить только один раз."
	else if(origin && anchor.loc != origin)
		shift_failure = "Душа переместилась во время подготовки. Выберите её снова."
	else if(get_dist(user, anchor) < 3)
		shift_failure = "Вы слишком близко к душе. Отойдите на 3–5 клеток, чтобы притянуть её от тела."
	else if(get_dist(user, anchor) > HERETIC_SPIRIT_RANGE)
		shift_failure = "Душа слишком далеко. Подойдите на 3–5 клеток."
	else if(!line_clear(user, anchor))
		shift_failure = "Путь к душе закрыт преградой. Встаньте на открытую линию."
	else if(!soul.validate_link())
		shift_failure = "Связь с телом оборвана. Снова отделите душу Разлучением."
	return !shift_failure

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
	if(!completed || !can_shift_soul(user, anchor, origin) || !line_clear(origin, destination) || !line_clear(destination, soul.owner))
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
	ring_failure = null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/required_type = final_cast ? /datum/eldritch_knowledge/final_eldritch/spirit_final : /datum/eldritch_knowledge/spell/spirit_bell
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(required_type)
	if(!can_use(user) || QDELETED(required) || (final_cast && !ascension_active))
		ring_failure = "Звон недоступен вашему знанию, вознесению или текущему телу."
		return FALSE
	if(!final_cast && !spend_combat_resource(2))
		ring_failure = "Для Заупокойного звона нужны 2 обола; сейчас [combat_resource]."
		return FALSE
	var/radius = final_cast ? 4 : 3
	if(final_cast)
		last_voyage_fx(user)
	for(var/turf/tile in range(radius, user))
		if(!line_clear(user, tile, radius))
			continue
		if(!final_cast)
			new /obj/effect/temp_visual/heretic_spirit/burst(tile, src)
		for(var/mob/living/victim in tile)
			if(!heretic_can_affect(user, victim))
				continue
			if(final_cast)
				new /obj/effect/temp_visual/heretic_spirit/burst(tile, src)
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

/// Последний рейс: звон колокола переправы и свет фонаря, бледная волна, души по спирали стягиваются к перевозчику, земля дрожит.
/datum/eldritch_knowledge/base_spirit/proc/last_voyage_fx(mob/living/user)
	var/ink = heretic_path_ink(PATH_SPIRIT)
	var/turf/center = get_turf(user)
	playsound(center, 'sound/hallucinations/psychosis/bell_creepy.ogg', 50, FALSE)
	heretic_vfx_rays(user, ink, HERETIC_SPIRIT_VOYAGE_LANTERN_TIME)
	heretic_vfx_pulse(user, ink, 2, HERETIC_SPIRIT_VOYAGE_LANTERN_TIME / 2)
	heretic_vfx_flash(center, ink, HERETIC_SPIRIT_VOYAGE_FLASH_RANGE, HERETIC_SPIRIT_VOYAGE_FLASH_POWER, HERETIC_SPIRIT_VOYAGE_FLASH_TIME)
	heretic_vfx_shockwave(center, ink, HERETIC_SPIRIT_VOYAGE_WAVE_RADIUS, HERETIC_SPIRIT_VOYAGE_WAVE_TIME)
	heretic_vfx_burst(center, /particles/heretic_ascension/spirit)
	heretic_vfx_converge(center, /particles/heretic_ascension/spirit/spiral, HERETIC_SPIRIT_VOYAGE_SPIRAL_RADIUS, HERETIC_SPIRIT_VOYAGE_SPIRAL_TRAVEL, HERETIC_SPIRIT_VOYAGE_SPIRAL_EMIT, HERETIC_SPIRIT_VOYAGE_SPIRAL_ARMS, HERETIC_SPIRIT_VOYAGE_SPIRAL_SWIRL)
	heretic_vfx_quake(center, HERETIC_SPIRIT_VOYAGE_QUAKE_RADIUS, HERETIC_SPIRIT_VOYAGE_QUAKE, HERETIC_SPIRIT_VOYAGE_QUAKE_TIME)

/datum/eldritch_knowledge/base_spirit/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_failure_reason = null
	if(!proximity_flag || !ishuman(target))
		return FALSE
	var/mob/living/carbon/human/corpse = target
	if(corpse.stat != DEAD)
		return FALSE
	if(user.a_intent != INTENT_HELP)
		grasp_failure_reason = "Обол на глаза кладут в намерении «Помощь»."
		return FALSE
	return place_obol(user, corpse)

/datum/eldritch_knowledge/base_spirit/proc/place_obol(mob/living/user, mob/living/carbon/human/corpse)
	grasp_failure_reason = null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !can_use(user) || !istype(corpse) || corpse.stat != DEAD || !isturf(corpse.loc))
		return FALSE
	if(corpse.GetComponent(/datum/component/heretic_craft))
		grasp_failure_reason = (corpse in obols) ? "На глазах этого тела уже лежит ваш обол." : "На этом теле уже лежит чужое ремесло."
		return FALSE
	grasp_failure_reason = heretic.deed_wait_reason(heretic.deed_key_for(corpse))
	if(grasp_failure_reason)
		return FALSE
	while(length(obols) >= HERETIC_SPIRIT_OBOL_LIMIT)
		var/mob/living/oldest = obols[1]
		log_game("[key_name(user)] теряет обол Духа на [key_name(oldest)] в [AREACOORD(oldest)]: его вытеснил новый.")
		remove_obol(oldest)
	corpse.AddComponent(/datum/component/heretic_craft, src, HERETIC_SPIRIT_OBOL_CRAFT, HERETIC_SPIRIT_OBOL_CLUE)
	obols[corpse] = 0
	to_chat(user, span_eldritch(last_moment(corpse)))
	var/mob/dead/observer/ghost = corpse.get_ghost(TRUE)
	if(ghost?.client)
		open_whisper(corpse, ghost)
		to_chat(user, span_notice("Призрак [corpse.real_name] может шептать вам [HERETIC_SPIRIT_WHISPER_TIME / (1 MINUTES)] минут. Держится оболов: [length(obols)] из [HERETIC_SPIRIT_OBOL_LIMIT]."))
	else
		to_chat(user, span_notice("Призрака у этого тела нет: шептать вам некому. Держится оболов: [length(obols)] из [HERETIC_SPIRIT_OBOL_LIMIT]."))
	playsound(corpse, 'modular_bluemoon/sound/heretic/spirit_grasp.ogg', 40, TRUE)
	log_game("[key_name(user)] кладёт обол Духа на глаза [key_name(corpse)] в [AREACOORD(corpse)].")
	heretic.advance_deed(heretic.deed_key_for(corpse), get_turf(corpse))
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_spirit/proc/remove_obol(mob/living/corpse)
	qdel(heretic_craft_on(corpse, HERETIC_SPIRIT_OBOL_CRAFT))
	close_whisper(corpse)
	obols -= corpse

/datum/eldritch_knowledge/base_spirit/on_craft_removed(atom/crafted, craft_id)
	if(craft_id != HERETIC_SPIRIT_OBOL_CRAFT)
		return
	close_whisper(crafted)
	obols -= crafted
	notify_resource_changed()

/datum/eldritch_knowledge/base_spirit/pocket_exits(mob/living/user)
	. = list()
	for(var/mob/living/corpse as anything in obols)
		if(isturf(corpse.loc))
			heretic_add_pocket_exit(., "Обол - [get_area_name(corpse, TRUE)]", heretic_pocket_beside(corpse))

/datum/eldritch_knowledge/base_spirit/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	return list("name" = "за реку", "text" = "Пустое тело [victim] уходит вслед за своей душой, как в тёмную воду.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))

/// Душа этой цели в руке еретика, во второй руке живое сердце, тело рядом.
/datum/eldritch_knowledge/base_spirit/proc/door_holds(mob/living/user, mob/living/victim)
	var/datum/status_effect/heretic_spirit_hold/hold = soul_hold
	if(QDELETED(hold) || hold.owner != victim || hold.holder != user || !user.is_holding(hold.soul_item))
		return FALSE
	if(!can_use(user) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > 1)
		return FALSE
	return !ferry_hands_reason(user) && !isnull(locate(/obj/item/living_heart) in user.held_items)

/// Душа занимает одну руку, а переправе в изнанку нужна вторая: пустая или с живым сердцем.
/datum/eldritch_knowledge/base_spirit/proc/ferry_hands_reason(mob/living/user)
	for(var/obj/item/held in user.held_items)
		if(held == soul_hold?.soul_item || istype(held, /obj/item/living_heart))
			continue
		return "Вторая рука занята ([held]): чтобы переправить тело в изнанку, держите в ней живое сердце."
	return null

/// Запись лога атак, после которой здоровье тела упало; схватить или обыскать - не ранить.
/datum/eldritch_knowledge/base_spirit/proc/last_blow(mob/living/corpse)
	var/list/entries = corpse.logging[num2text(LOG_VICTIM)]
	if(!length(entries))
		return null
	for(var/index in length(entries) to 1 step -1)
		var/list/entry = entries[index]
		var/health_before = corpse.maxHealth
		if(index > 1)
			var/list/previous = entries[index - 1]
			health_before = text2num(previous["health"])
		var/health_after = text2num(entry["health"])
		if(entry["target_name"] && !isnull(health_after) && !isnull(health_before) && health_after < health_before)
			return entry
	return null

/datum/eldritch_knowledge/base_spirit/proc/last_moment(mob/living/corpse)
	var/list/entry = last_blow(corpse)
	if(!entry)
		return "Последний миг [corpse.name]: смерть пришла тихо."
	var/list/parts = list("ранил «[entry["target_name"]]»")
	var/weapon = log_weapon(entry["what"])
	if(weapon)
		parts += "чем: [weapon]"
	var/elapsed = world.time - entry["timestamp"]
	parts += elapsed < 1 SECONDS ? "только что" : "[DisplayTimeText(elapsed, 1)] назад"
	var/where = entry["where"]
	var/coords_at = findlasttext(where, " (")
	if(length(where) > 2 && coords_at > 2)
		parts += "где: [copytext(where, 2, coords_at)]"
	return "Последний миг [corpse.name]: [jointext(parts, "; ")]."

/// Оружие из строки log_combat: предмет пишется как «[имя]», а имя строкой - как «имя[DC]».
/datum/eldritch_knowledge/base_spirit/proc/log_weapon(what)
	var/marker = "при помощи "
	var/start = findtext(what, marker)
	if(!start)
		return null
	start += length(marker)
	if(copytext(what, start, start + 1) == "\[")
		var/close = findtext(what, "\]", start + 1)
		return close ? copytext(what, start + 1, close) : null
	var/stop = length(what) + 1
	for(var/ending in list("\[DC\]", " (", "/(", "<"))
		var/found = findtext(what, ending, start)
		if(found)
			stop = min(stop, found)
	var/weapon = trim(copytext(what, start, stop))
	return length(weapon) ? weapon : null

/datum/eldritch_knowledge/base_spirit/proc/open_whisper(mob/living/corpse, mob/dead/observer/ghost)
	if(!(corpse in obols) || QDELETED(ghost))
		return FALSE
	obols[corpse] = world.time + HERETIC_SPIRIT_WHISPER_TIME
	obol_ghosts[corpse] = WEAKREF(ghost)
	add_verb(ghost, /mob/dead/observer/proc/heretic_spirit_whisper)
	to_chat(ghost, span_deadsay("На ваши глаза положили обол. [HERETIC_SPIRIT_WHISPER_TIME / (1 MINUTES)] минут вы можете шептать тому, кто его положил: команда «Шепнуть перевозчику»."))
	addtimer(CALLBACK(src, PROC_REF(expire_whisper), WEAKREF(corpse)), HERETIC_SPIRIT_WHISPER_TIME)
	return TRUE

/datum/eldritch_knowledge/base_spirit/proc/expire_whisper(datum/weakref/corpse_ref)
	var/mob/living/corpse = corpse_ref?.resolve()
	if(corpse && (corpse in obols) && world.time >= obols[corpse])
		close_whisper(corpse)

/datum/eldritch_knowledge/base_spirit/proc/close_whisper(mob/living/corpse)
	var/datum/weakref/ghost_ref = obol_ghosts[corpse]
	obol_ghosts -= corpse
	whisper_ready -= corpse
	var/mob/dead/observer/ghost = ghost_ref?.resolve()
	if(ghost)
		remove_verb(ghost, /mob/dead/observer/proc/heretic_spirit_whisper)

/datum/eldritch_knowledge/base_spirit/proc/deliver_whisper(mob/dead/observer/ghost, message)
	whisper_failure = null
	var/mob/living/corpse = ghost?.mind?.current
	var/datum/weakref/ghost_ref = corpse ? obol_ghosts[corpse] : null
	message = sanitize(trim(copytext_char(message, 1, HERETIC_SPIRIT_WHISPER_LENGTH)))
	if(!length(message))
		whisper_failure = "Пустой шёпот никто не услышит."
	else if(!corpse || !(corpse in obols) || ghost_ref?.resolve() != ghost)
		whisper_failure = "На глазах вашего тела больше нет обола."
	else if(world.time >= obols[corpse])
		whisper_failure = "Время шёпота вышло."
	else if(world.time < whisper_ready[corpse])
		whisper_failure = "Слишком часто: следующий шёпот через [heretic_capture_seconds_left(whisper_ready[corpse])] с."
	else if(QDELETED(spirit_body))
		whisper_failure = "Перевозчик вас не слышит."
	if(whisper_failure)
		return FALSE
	whisper_ready[corpse] = world.time + HERETIC_SPIRIT_WHISPER_COOLDOWN
	to_chat(spirit_body, span_eldritch("Шёпот [corpse.real_name]: «[message]»"))
	to_chat(ghost, span_deadsay("Вы шепчете перевозчику: «[message]»"))
	log_directed_talk(ghost, spirit_body, message, LOG_SAY, "шёпот перевозчику")
	return TRUE

/mob/dead/observer/proc/heretic_spirit_whisper()
	set name = "Шепнуть перевозчику"
	set category = "Ghost"
	set desc = "Шепните еретику, положившему обол на глаза вашего тела. Услышит только он."
	var/datum/component/heretic_craft/craft = heretic_craft_on(mind?.current, HERETIC_SPIRIT_OBOL_CRAFT)
	var/datum/eldritch_knowledge/base_spirit/spirit = craft?.owner_ref?.resolve()
	if(!istype(spirit))
		to_chat(src, span_warning("На глазах вашего тела больше нет обола."))
		remove_verb(src, /mob/dead/observer/proc/heretic_spirit_whisper)
		return
	var/message = tgui_input_text(src, "Что прошептать перевозчику? Услышит только он.", "Шёпот перевозчику", max_length = HERETIC_SPIRIT_WHISPER_LENGTH)
	if(!message || QDELETED(spirit))
		return
	if(!spirit.deliver_whisper(src, message))
		to_chat(src, span_warning(spirit.whisper_failure))

/datum/heretic_deed/spirit
	next_step = "В намерении «Помощь» коснитесь Хваткой Мансуса трупа человека в ещё не зачтённом отделе."
	name = "Оболы на глазах"
	desc = "Кладите Хваткой Мансуса в намерении «Помощь» обол на глаза трупов людей в разных отделах. Каждый отдел засчитывается один раз."
	craft_wait = "обол не кладётся"
	hint = "Морг, лазарет и места недавних драк. Обол называет, кто последним ранил умершего, а его призрак 5 минут может шептать вам. Держатся три обола, новый вытесняет самый старый; экипаж может заметить монеты на глазах тела, а нулевой жезл снимает обол."
	trace_name = "ferry trail"
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
	var/datum/eldritch_knowledge/spirit_relic/purse = heretic?.get_knowledge(/datum/eldritch_knowledge/spirit_relic)
	if(!QDELETED(purse))
		drain_limit += purse.passive_level * 5
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
	var/datum/eldritch_knowledge/previous = reaping_ref?.resolve()
	if(previous && previous != knowledge_ref?.resolve())
		UnregisterSignal(previous, COMSIG_PARENT_QDELETING)
	reaping_ref = WEAKREF(required)
	if(required != knowledge_ref?.resolve())
		RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	reap_at = world.time + HERETIC_SPIRIT_REAP_DELAY
	duration = max(duration, reap_at + tick_interval)
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
	if(QDELETED(src))
		return can_hit
	if(!can_hit || !validate_link())
		qdel(src)
		return can_hit
	duration = max(duration, world.time + HERETIC_SPIRIT_REAP_AFTERGLOW)
	anchor.icon_state = "spirit_soul"
	anchor.set_light(1, 0.7, "#a8f5dc")
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
	desc = "Душа осталась на месте на 10 секунд; Жатва продлевает короткую связь до удара, а при попадании оставляет минимум 4 секунды. Касание своей души или возврат на её клетку после отхода гасит связь; стоя на душе или рядом, коснитесь её нажатием на этот значок. Дальше одной клетки от неё вы теряете выносливость, но не более 25–40 за всю связь. Жатва предупреждает за 2 секунды и бьёт второй раз, пока связь цела: дальше одной клетки от души сильнее, рядом слабее. Душу можно разбить; стены, антимагия и расстояние больше пяти клеток от души или еретика разрывают связь. Стоя рядом с душой, перевозчик может взять её в руку: тогда тело застынет до 12 секунд."
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
	desc = "Серебристый силуэт, привязанный к ещё живому телу. Хозяин может погасить его касанием. Разрушение не вредит телу; нулевой жезл сразу обрывает связь. Перевозчик собирает силуэт пустой рукой. Крюком нужно бить тело, а не душу; сбор души отменяет подготовленную Жатву. Пока хозяин стоит или лежит на душе, клики проходят сквозь неё к телу. Стоящий рядом перевозчик может взять душу в руку, и тело застынет."
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
	summary = "Хватка отделяет душу живого врага, а «Сместить душу» оттаскивает её от тела."
	details = list(
		"Хватка по живому врагу бесплатно отделяет его душу на 10 секунд.",
		"Сместить душу: встаньте в 3-5 клетках от души и выберите её силуэт или само тело.",
		"Через секунду душа сдвинется на 2 клетки к вам; ваш шаг прерывает подготовку.",
		"Каждую душу можно сместить один раз, срок связи и предел истощения не меняются.",
		"Смещение бесплатно, перезарядка 6 секунд.",
	)
	role = HERETIC_ROLE_GRASP
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
	summary = "За обол переход по открытой линии на 3 клетки, к своей душе - на 5."
	details = list(
		"Дальняя клетка укорачивает переход до 3 клеток; на занятое телом место вы встаёте рядом.",
		"У своей души вы собираете её по прибытии; в намерении «Разоружить» душа остаётся для Жатвы.",
		"Лежащего или обездвиженного, которого вы тащите, Переправа берёт с собой, захват не теряется.",
		"Переход восстанавливает 15 выносливости. Стены, окна и запрет телепортации не пускают.",
		"Перезарядка 12 секунд.",
	)
	role = HERETIC_ROLE_SUPPORT
	gain_text = "Река была шириной в один шаг. Только берегов у неё не было."
	cost = 1
	route = PATH_SPIRIT
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_spirit/step

/datum/eldritch_knowledge/spirit_mark
	name = "Метка Духа"
	summary = "Хватка ставит метку на 15 секунд, крюк её взрывает, а серебро крюка режет нить души."
	details = list(
		"Взрыв метки наносит 8 ушибов и отделяет душу, если её ещё нет; взрыв даёт обол.",
		"Серебро режет нить: удар крюком по телу с вашей душой наносит ещё 6 ушибов, раз в 3 секунды.",
		"Метка не обновляет существующую связь, удары по самому силуэту тело не ранят.",
	)
	role = HERETIC_ROLE_MARK
	gain_text = "Я записал имя на монете. На обратной стороне появилось моё."
	cost = 2
	route = PATH_SPIRIT
	COOLDOWN_DECLARE(spirit_blade)

/datum/eldritch_knowledge/spirit_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!proximity_flag || !spirit?.can_use(user) || !user.Adjacent(target) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/spirit, spirit)
	return TRUE

/datum/eldritch_knowledge/spirit_mark/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(QDELETED(src) || !proximity_flag || !spirit?.can_use(user) || !user.Adjacent(target) || !heretic_can_affect(user, target, chargecost = 0) || !COOLDOWN_FINISHED(src, spirit_blade))
		return
	var/mob/living/victim = target
	var/datum/status_effect/heretic_spirit/separated/soul = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
	if(soul?.spirit_ref?.resolve() != spirit || !soul.validate_link())
		return
	COOLDOWN_START(src, spirit_blade, HERETIC_SPIRIT_BLADE_COOLDOWN)
	victim.adjustBruteLoss(HERETIC_SPIRIT_BLADE_BONUS)

/datum/eldritch_knowledge/spirit_mark/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(spirit)
		QDEL_LIST(spirit.marks)
		spirit.clear_knowledge_effects(src)

/datum/eldritch_knowledge/spirit_relic
	name = "Фонарь перевозчика"
	summary = "Фонарик и лист серебра дают фонарь, а Кошель утонувших поднимает запас оболов до 6."
	details = list(
		"Фонарь в руке подтягивает ваши души в 3 клетках на клетку ближе и собирает соседние.",
		"Обол за сбор фонарём лечит 12 ушибов и ожогов; тела и души за стеной фонарь не тянет.",
		"Перезарядка фонаря 20 секунд, фонарь может быть только один.",
		"Кошель утонувших: вместимость 6 оболов, предел истощения новых связей 30.",
		"Кошель можно улучшить до 7 и 8 оболов, предел истощения растёт до 35 и 40.",
	)
	role = HERETIC_ROLE_RELIC
	gain_text = "Огонёк освещал тех, кто ещё не знал, что заблудился. Ни одна монета в кошеле не звенела: каждая помнила дно."
	cost = 1
	route = PATH_SPIRIT
	required_atoms = list(/obj/item/flashlight, /obj/item/stack/sheet/mineral/silver)
	result_atoms = list(/obj/item/heretic_path_relic/spirit)
	passive_values = list(6, 7, 8)
	passive_desc = "Кошель утонувших: вместимость оболов 6 / 7 / 8, предел истощения новых связей 30 / 35 / 40. Изучение не заполняет кошель и не меняет уже отделённые души."
	var/datum/weakref/spirit_ref

/datum/eldritch_knowledge/spirit_relic/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/spirit_relic/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/spirit)

/datum/eldritch_knowledge/spirit_relic/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(spirit)
		spirit_ref = WEAKREF(spirit)
		spirit.update_capacity()

/datum/eldritch_knowledge/spirit_relic/on_passive_upgrade(mob/living/user)
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	spirit?.update_capacity()

/datum/eldritch_knowledge/spirit_relic/on_lose(mob/user)
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	spirit?.update_capacity(ignore_purse = TRUE)
	return ..()

/datum/eldritch_knowledge/spirit_relic/Destroy()
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	spirit?.update_capacity(ignore_purse = TRUE)
	spirit_ref = null
	return ..()

/datum/eldritch_knowledge/spell/spirit_hold
	name = "Удержать душу"
	summary = "Возьмите в руку отделённую душу рядом с собой: её тело стоит пустым до 12 секунд."
	details = list(
		"Выберите свою отделённую душу в соседней клетке или её тело; нужна свободная рука.",
		"1 секунду душа тянется к руке: хозяин может коснуться её или вернуться на её клетку.",
		"Пока душа у вас в руке, тело не двигается и готово к обряду, до 12 секунд.",
		"Цель охоты рядом: живое сердце во второй руке за 1 секунду переправляет пустое тело в изнанку.",
		"Душу вернут удар 15+ урона по вам, оглушение, выпущенная душа, нулевой жезл или 2 секунды растолкать тело.",
		"Потом цель минуту невосприимчива к Удержанию и 15 секунд - к любому захвату. Перезарядка 40 секунд.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Душа оказалась лёгкой, как монета. Тело без неё стояло и ждало, когда я верну сдачу."
	cost = 2
	route = PATH_SPIRIT
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_spirit/hold

/datum/eldritch_knowledge/spell/spirit_hold/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	spirit?.soul_hold?.release("знание утрачено")
	return ..()

/datum/eldritch_knowledge/spell/spirit_reap
	name = "Жатва неприкаянных"
	summary = "Бесплатно 22 ушиба цели в 5 клетках, её душа отделяется, а через 2 секунды бьёт второй раз."
	details = list(
		"Второй удар, пока связь цела: 25 ушибов дальше клетки от души или 15 рядом с ней.",
		"После попадания душа остаётся минимум на 4 секунды для крюка, Переправы, Удержания или сбора.",
		"Если связь истекает во время предупреждения, она дожидается второго удара.",
		"Касание души, её разрушение, возврат на её клетку, антимагия и разрыв связи отменяют второй удар.",
		"Перезарядка 18 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Я позвал живого по имени, которым его назовут после смерти."
	cost = 1
	route = PATH_SPIRIT
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_spirit/reap

/datum/eldritch_knowledge/spell/spirit_reap/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	spirit?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/spell/spirit_incorporeal
	name = "Бесплотность"
	summary = "3 секунды пули и удары проходят сквозь вас, а вы проходите сквозь людей и столы."
	details = list(
		"Работает в чужом захвате и вырывает из него: бесплотного не удержать и не схватить заново.",
		"Вы двигаетесь быстрее и становитесь полупрозрачным.",
		"Удар, даже предметом по двери, машине или стене, выстрел, бросок и заклинание пропадают и сразу возвращают плоть.",
		"Пока вы держите чужую душу, стать бесплотным нельзя.",
		"Наручники и щит разума закрывают Бесплотность. Перезарядка 60 секунд.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "Я вспомнил, что тело - только лодка. Лодку можно оставить у берега."
	cost = 2
	route = PATH_SPIRIT
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_spirit/incorporeal

/datum/eldritch_knowledge/spell/spirit_incorporeal/on_body_lose(mob/living/user)
	var/datum/status_effect/heretic_spirit_incorporeal/effect = user?.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal)
	effect?.end("знание утрачено")
	return ..()

/datum/eldritch_knowledge/spell/spirit_bell
	name = "Заупокойный звон"
	summary = "За 2 обола 20 ушибов и 20 выносливости врагам в 3 клетках и жатва их душ."
	details = list(
		"Звон отделяет до трёх душ и готовит второй удар каждой через 2 секунды.",
		"Второй удар, пока связь цела: 25 ушибов дальше клетки от души или 15 рядом с ней.",
		"После попадания души остаются минимум на 4 секунды для крюка, Переправы или сбора.",
		"Стены закрывают цель. Перезарядка 35 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
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
	summary = "Люди и столы вас не держат, смерть экипажа рядом платит оболами, открывается Последний рейс."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; обряд длится 30 секунд.",
		"Вы получаете общую стойкость вознесения и проходите сквозь людей и столы.",
		"Смерть члена экипажа в 7 клетках даёт 2 обола и лечит 20 урона, если он не был защищён от магии.",
		"Вместимость 8 оболов, обол каждые 4 секунды, до 6 душ одновременно.",
		"Последний рейс бесплатно: 30 ушибов и 25 выносливости врагам в 4 клетках.",
		"Второй удар рейса через 2 секунды: 40 ушибов дальше клетки от души, 15 рядом. Перезарядка 40 секунд.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Ладья пришла пустой. Перевозчик уступил мне весло и лёг на дно. Теперь каждый, кто умирает рядом, платит за переправу мне."
	route = PATH_SPIRIT
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_spirit/crown)
	var/datum/weakref/spirit_knowledge_ref

/datum/eldritch_knowledge/final_eldritch/spirit_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!spirit)
		return
	spirit_knowledge_ref = WEAKREF(spirit)
	spirit.ascension_active = TRUE
	spirit.update_capacity()
	user.AddComponent(/datum/component/heretic_spirit_ferryman, spirit)

/datum/eldritch_knowledge/final_eldritch/spirit_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_spirit_ferryman))
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_knowledge_ref?.resolve()
	spirit_knowledge_ref = null
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
	desc = "За один обол нанесите 20 ушибов и 15 выносливости цели в пяти клетках и отделите её душу на 10 секунд."
	summary = "За обол 20 ушибов и 15 выносливости цели в 5 клетках, её душа 10 секунд стоит на месте."
	action_icon_state = "spirit_sever"
	charge_max = 12 SECONDS

/obj/effect/proc_holder/spell/pointed/heretic_spirit/sever/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!length(targets) || !spirit?.sever(user, targets[1]))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_spirit/step
	name = "Переправа"
	active_msg = "Выберите место по открытой линии: до трёх клеток, к своей душе — до пяти. Стены и окна не пропускают. На разоружении душа сохраняется для Жатвы; в остальных намерениях собирается."
	desc = "За обол переместитесь по открытой линии до трёх клеток и восстановите 15 выносливости; клетка дальше укорачивает переход до трёх. Своя душа или тело, стоящее на ней, увеличивает дальность до пяти клеток, и душа собирается по прибытии. На занятое телом место вы встаёте рядом с ним. Лежащего или обездвиженного, которого вы тащите, Переправа переносит с вами. В намерении «Разоружить» душа остаётся для дальнейшей охоты: срок и истощение не обновляются, обол за сбор не выдаётся."
	summary = "За обол переход на 3 клетки, к своей душе на 5; тащимую лежащую жертву берёт с собой."
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
	active_msg = "Отойдите от души на 3–5 клеток, выберите её силуэт или само тело и стойте секунду. После смещения атакуйте тело; сбор души отменит Жатву."
	desc = "Бесплатно притяните свою отделённую душу на две клетки к себе после секунды предупреждения. Встаньте в трёх–пяти клетках от неё и выберите силуэт или само тело. Каждую душу можно сместить один раз; срок связи и предел истощения сохраняются. Движение прерывает подготовку. Жертва может коснуться души, разбить её или оборвать связь стеной. Перезарядка 6 секунд."
	summary = "Бесплатно тянет вашу душу на 2 клетки к вам, если вы стоите в 3-5 клетках от неё."
	action_icon_state = "spirit_shift"
	charge_max = 6 SECONDS
	aim_assist = FALSE

/obj/effect/proc_holder/spell/pointed/heretic_spirit/shift/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/obj/structure/heretic_spirit_soul/anchor = spirit?.soul_anchor_of(target)
	return heretic_check(user, spirit?.can_shift_soul(user, anchor), silent, spirit?.shift_failure || "Сначала выберите путь Духа.")

/obj/effect/proc_holder/spell/pointed/heretic_spirit/shift/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/obj/structure/heretic_spirit_soul/anchor = length(targets) ? spirit?.soul_anchor_of(targets[1]) : null
	if(!anchor || !spirit.shift_soul(user, anchor))
		heretic_revert_cast(user, "Смещение прервано или душа больше недоступна.")

/obj/effect/proc_holder/spell/pointed/heretic_spirit/hold
	name = "Удержать душу"
	active_msg = "Выберите свою отделённую душу рядом с собой или её тело. Нужна свободная рука."
	desc = "Возьмите в руку свою отделённую душу в соседней клетке или выберите её тело; нужна свободная рука. Через 1 секунду тело стоит пустым до 12 секунд и готово к обряду. Живое сердце во второй руке переправит пустое тело цели охоты в изнанку за 1 секунду. Удар 15+ урона по вам, оглушение, выпущенная из руки душа, нулевой жезл по телу или по вам и 2 секунды растолкать тело возвращают её. Перезарядка 40 секунд."
	summary = "Душа рядом с вами - в руку: тело стоит пустым до 12 секунд и готово к обряду."
	action_icon_state = "spirit_hold"
	charge_max = HERETIC_SPIRIT_HOLD_COOLDOWN

/obj/effect/proc_holder/spell/pointed/heretic_spirit/hold/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/reason = spirit ? spirit.hold_block_reason(user, target) : "Сначала выберите путь Духа."
	return heretic_check(user, !reason, silent, reason, target = isliving(target) ? target : null)

/obj/effect/proc_holder/spell/pointed/heretic_spirit/hold/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!length(targets) || !spirit?.grab_soul(user, targets[1]))
		heretic_revert_cast(user, spirit?.hold_failure)

/obj/effect/proc_holder/spell/pointed/heretic_spirit/reap
	name = "Жатва неприкаянных"
	desc = "Бесплатный удар на 22 ушиба. Через 2 секунды, если связь цела, второй удар: 25 ушибов дальше одной клетки от души или 15 рядом с ней. После попадания душа остаётся минимум на 4 секунды для крюка, Переправы или сбора."
	summary = "Бесплатно 22 ушиба и отделённая душа, через 2 секунды второй удар на 25 или 15."
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
	return ..() && heretic_check(user, spirit?.can_use(user, FALSE, usable_while_grabbed), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_spirit/bell
	name = "Заупокойный звон"
	desc = "За два обола поразите врагов в трёх клетках на 20 ушибов и 20 выносливости и подготовьте жатву их душ через 2 секунды. После попадания души остаются минимум на 4 секунды."
	summary = "За 2 обола 20 ушибов и 20 выносливости врагам в 3 клетках, их души ждёт жатва."
	action_icon_state = "spirit_bell"
	charge_max = 35 SECONDS

/obj/effect/proc_holder/spell/self/heretic_spirit/bell/can_cast(mob/user, skipcharge, silent)
	return ..() && heretic_require_knowledge(user, silent, /datum/eldritch_knowledge/base_spirit, 2)

/obj/effect/proc_holder/spell/self/heretic_spirit/bell/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!spirit?.ring(user))
		heretic_revert_cast(user, spirit?.ring_failure || "Сначала выберите путь Духа.")

/obj/effect/proc_holder/spell/self/heretic_spirit/incorporeal
	name = "Бесплотность"
	desc = "3 секунды пули, лазеры, броски и удары проходят сквозь вас, вы проходите сквозь людей и столы и двигаетесь быстрее. Работает в чужом захвате и вырывает из него. Атаковать, даже предметом по двери, машине или стене, стрелять, бросать и колдовать нельзя: попытка пропадает и сразу возвращает плоть; открыть дверь рукой можно. Недоступна в наручниках, под щитом разума и пока вы держите чужую душу. Перезарядка 60 секунд."
	summary = "3 секунды сквозь вас проходят пули и удары, а вы - сквозь людей и столы."
	action_icon_state = "spirit_incorporeal"
	charge_max = HERETIC_SPIRIT_INCORPOREAL_COOLDOWN
	usable_while_grabbed = TRUE

/obj/effect/proc_holder/spell/self/heretic_spirit/incorporeal/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/reason = spirit ? spirit.incorporeal_failure(user) : "Сначала выберите путь Духа."
	return heretic_check(user, !reason, silent, reason) && ..()

/obj/effect/proc_holder/spell/self/heretic_spirit/incorporeal/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic?.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	if(!spirit?.become_incorporeal(user))
		heretic_revert_cast(user, spirit?.incorporeal_failure_reason || "Сначала выберите путь Духа.")

/obj/effect/proc_holder/spell/self/heretic_spirit/crown
	name = "Последний рейс"
	desc = "Поразите врагов в четырёх клетках на 30 ушибов и 25 выносливости. До шести душ предупреждают о жатве через 2 секунды: 40 ушибов дальше одной клетки от души или 15 рядом с ней. После попадания души остаются минимум на 4 секунды. Требует вознесения."
	summary = "Бесплатно 30 ушибов и 25 выносливости врагам в 4 клетках, жатва их душ на 40 или 15."
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
		heretic_revert_cast(user, spirit?.ring_failure || "Сначала выберите путь Духа.")

/datum/eldritch_knowledge/base_spirit/proc/hold_block_reason(mob/living/user, atom/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!isliving(user) || heretic?.get_knowledge(type) != src || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_hold))
		return "Способность недоступна вашему пути или текущему телу."
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	if(!can_use(user))
		return "Сейчас вы не можете действовать: нужно быть в сознании, на полу и в своём теле еретика."
	if(!QDELETED(soul_hold))
		return "Вы уже держите душу."
	var/obj/structure/heretic_spirit_soul/anchor = soul_anchor_of(target)
	var/datum/status_effect/heretic_spirit/separated/soul = anchor?.effect_ref?.resolve()
	if(!soul)
		return "Выберите отделённую вами душу или тело, чью душу вы отделили."
	var/reason = heretic_capture_block_reason(user, soul.owner, HERETIC_SPIRIT_HOLD_CAPTURE)
	if(reason)
		return reason
	if(anchor.z != user.z || get_dist(user, anchor) > HERETIC_SPIRIT_HOLD_REACH)
		return "Душу берут рукой: встаньте рядом с её силуэтом."
	if(!soul.validate_link())
		return "Связь с телом оборвана: снова отделите душу."
	if(!length(user.get_empty_held_indexes()))
		return "Освободите руку: душу держат в руке."
	return null

/datum/eldritch_knowledge/base_spirit/proc/grab_soul(mob/living/user, atom/target)
	hold_failure = hold_block_reason(user, target)
	if(hold_failure)
		return FALSE
	var/obj/structure/heretic_spirit_soul/anchor = soul_anchor_of(target)
	var/datum/status_effect/heretic_spirit/separated/soul = anchor.effect_ref.resolve()
	var/mob/living/victim = soul.owner
	new /obj/effect/temp_visual/heretic_spirit/grasp(get_turf(anchor), src)
	user.visible_message(span_danger("[user] тянется к бледному силуэту [victim]!"), span_notice("Вы тянетесь к душе [victim]."))
	to_chat(victim, span_userdanger("Перевозчик тянется к вашей душе! Через секунду он возьмёт её в руку. Коснитесь души или вернитесь на её клетку."))
	playsound(anchor, 'modular_bluemoon/sound/heretic/spirit_cast.ogg', 50, TRUE)
	addtimer(CALLBACK(src, PROC_REF(seize_soul), user, victim), HERETIC_SPIRIT_HOLD_TELEGRAPH)
	return TRUE

/datum/eldritch_knowledge/base_spirit/proc/seize_soul(mob/living/user, mob/living/victim)
	if(QDELETED(user) || QDELETED(victim))
		return FALSE
	var/datum/status_effect/heretic_spirit/separated/soul = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
	var/reason = soul ? hold_block_reason(user, soul.anchor) : "душа вернулась к телу."
	if(reason)
		to_chat(user, span_warning("Душа ускользнула: [reason]"))
		return FALSE
	var/datum/status_effect/heretic_spirit_hold/hold = victim.apply_status_effect(/datum/status_effect/heretic_spirit_hold, user, src)
	if(!hold || QDELETED(hold))
		to_chat(user, span_warning("Душа ускользнула: её не во что взять."))
		return FALSE
	soul_hold = hold
	soul.reap_end_reason = "душа в руке перевозчика"
	qdel(soul)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/refusal = ferry_hands_reason(user)
	if(refusal && victim.mind && victim.mind == heretic?.hunt_target)
		to_chat(user, span_warning(refusal))
	return TRUE

/datum/status_effect/heretic_spirit_hold
	id = "heretic_spirit_hold"
	duration = HERETIC_SPIRIT_HOLD_DURATION
	tick_interval = HERETIC_SPIRIT_HOLD_CHECK
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_spirit_hold
	examine_text = span_warning("SUBJECTPRONOUN стоит пустым: глаза стеклянные, а душу держит в руке перевозчик. Удар нулевым жезлом по телу или по перевозчику или 2 секунды растолкать тело вернут её.")
	var/mob/living/holder
	var/datum/weakref/spirit_ref
	var/obj/item/heretic_spirit_soul/soul_item
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint
	var/holder_damage
	var/hit_at = -1
	var/hit_damage = 0
	var/release_reason
	var/held = FALSE

/datum/status_effect/heretic_spirit_hold/on_creation(mob/living/new_owner, mob/living/new_holder, datum/eldritch_knowledge/base_spirit/spirit)
	holder = new_holder
	spirit_ref = WEAKREF(spirit)
	return ..()

/datum/status_effect/heretic_spirit_hold/on_apply()
	. = ..()
	if(!.)
		return
	if(QDELETED(holder))
		return FALSE
	soul_item = new(get_turf(holder), src)
	if(!holder.put_in_hands(soul_item))
		soul_item.hold = null
		QDEL_NULL(soul_item)
		return FALSE
	restraint = new(list(owner, HERETIC_SPIRIT_HOLD_DURATION, TRUE))
	held = TRUE
	holder_damage = heretic_blade_damage_total(holder)
	heretic_capture_hold(owner, HERETIC_SPIRIT_HOLD_CAPTURE)
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(on_shaken))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, PROC_REF(on_sacrifice))
	RegisterSignal(owner, COMSIG_MOB_DEATH, PROC_REF(on_owner_death))
	RegisterSignal(holder, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(holder, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(on_holder_health))
	RegisterSignal(holder, COMSIG_PARENT_QDELETING, PROC_REF(on_holder_deleted))
	owner.visible_message(span_danger("[holder] вынимает из [owner] бледную душу и сжимает её в кулаке. Тело застывает пустым."), span_userdanger("Ваша душа в руке перевозчика: тело не слушается!"))
	log_combat(holder, owner, "берёт в руку душу")

/datum/status_effect/heretic_spirit_hold/tick()
	var/reason = break_reason()
	if(reason)
		release(reason)

/datum/status_effect/heretic_spirit_hold/proc/break_reason()
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	if(QDELETED(holder) || !spirit)
		return "перевозчик исчез"
	if(holder.stat != CONSCIOUS || holder.incapacitated(ignore_grab = TRUE) || heretic_capture_downed(holder))
		return "перевозчика оглушили или сбили"
	if(QDELETED(soul_item) || !(soul_item in holder.held_items))
		return "душу выпустили из руки"
	return null

/datum/status_effect/heretic_spirit_hold/proc/release(reason)
	if(QDELETED(src))
		return
	release_reason = reason
	qdel(src)

/datum/status_effect/heretic_spirit_hold/proc/on_holder_health(mob/living/carbon/source)
	SIGNAL_HANDLER
	var/damage = heretic_blade_damage_total(holder)
	var/delta = damage - holder_damage
	holder_damage = damage
	if(delta <= 0)
		return
	// Один удар доходит несколькими пересчётами здоровья за тик, поэтому урон тика складывается.
	if(hit_at != world.time)
		hit_at = world.time
		hit_damage = 0
	hit_damage += delta
	if(round(hit_damage, DAMAGE_PRECISION) >= HERETIC_SPIRIT_HOLD_BREAK_DAMAGE)
		release("перевозчик получил сильный удар")

/datum/status_effect/heretic_spirit_hold/proc/on_attackby(atom/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	user.visible_message(span_warning("[user] касается [source] нулевым жезлом, и душа возвращается в тело [owner]."), span_notice("Вы касаетесь [source] нулевым жезлом и возвращаете душу [owner]."))
	log_game("[key_name(user)] возвращает душу [key_name(owner)] нулевым жезлом в [AREACOORD(source)].")
	release("нулевой жезл")
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_spirit_hold/proc/on_shaken(datum/source, mob/living/helper)
	SIGNAL_HANDLER
	release("тело растолкали")

/datum/status_effect/heretic_spirit_hold/proc/on_sacrifice(datum/source)
	SIGNAL_HANDLER
	release("начался обряд")

/datum/status_effect/heretic_spirit_hold/proc/on_owner_death(datum/source)
	SIGNAL_HANDLER
	release("тело погибло")

/datum/status_effect/heretic_spirit_hold/proc/on_holder_deleted(datum/source)
	SIGNAL_HANDLER
	release("перевозчик исчез")

/datum/status_effect/heretic_spirit_hold/on_remove()
	UnregisterSignal(owner, list(COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_PARENT_ATTACKBY, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_MOB_DEATH))
	if(held)
		heretic_capture_unhold(owner, HERETIC_SPIRIT_HOLD_CAPTURE)
	if(holder)
		UnregisterSignal(holder, list(COMSIG_PARENT_ATTACKBY, COMSIG_CARBON_UPDATEHEALTH, COMSIG_PARENT_QDELETING))
	// Чужой Paralyze мог продлить этот экземпляр: тогда он остаётся.
	if(!QDELETED(restraint) && !QDELETED(owner) && restraint.duration <= duration)
		qdel(restraint)
	restraint = null
	var/obj/item/heretic_spirit_soul/item = soul_item
	soul_item = null
	if(item)
		item.hold = null
		if(!QDELETED(item))
			qdel(item)
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	if(spirit?.soul_hold == src)
		spirit.soul_hold = null
	if(held)
		owner.visible_message(span_notice("Бледная душа возвращается в тело [owner]."), span_notice("Душа вернулась: [release_reason || "время вышло"]."))
		if(holder)
			to_chat(holder, span_warning("Душа [owner] вернулась к телу: [release_reason || "время вышло"]."))
		log_combat(holder, owner, "отпускает душу", addition = release_reason || "время вышло")
		heretic_capture_release(owner, HERETIC_SPIRIT_HOLD_CAPTURE)
	holder = null
	spirit_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_spirit_hold
	name = "Душа в чужой руке"
	desc = "Перевозчик держит вашу душу в руке, тело пусто и не двигается до 12 секунд. Душу вернут удар 15+ урона по нему, его оглушение, выпущенная из руки душа, нулевой жезл по вам или по нему и тот, кто растолкает вас 2 секунды."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "spirit_held"

/obj/item/heretic_spirit_soul
	name = "captured soul"
	desc = "Бледный силуэт размером с ладонь. Пока душу держат, её тело стоит пустым; выпущенная из руки, она вернётся к хозяину. Живое сердце во второй руке переправит тело цели охоты в изнанку."
	icon = 'modular_bluemoon/icons/obj/heretic_spirit_effects.dmi'
	icon_state = "spirit_soul"
	item_flags = DROPDEL
	w_class = WEIGHT_CLASS_HUGE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/datum/status_effect/heretic_spirit_hold/hold

/obj/item/heretic_spirit_soul/Initialize(mapload, datum/status_effect/heretic_spirit_hold/new_hold)
	. = ..()
	hold = new_hold

/obj/item/heretic_spirit_soul/attack_self(mob/user)
	hold?.release("перевозчик отпустил душу")

/obj/item/heretic_spirit_soul/Destroy()
	var/datum/status_effect/heretic_spirit_hold/current = hold
	hold = null
	current?.release("душу выпустили из руки")
	return ..()

/datum/eldritch_knowledge/base_spirit/proc/incorporeal_failure(mob/living/user)
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user, FALSE, TRUE) || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_incorporeal))
		return "Бесплотность недоступна: нужно изучить её, быть в сознании и в своём теле еретика."
	if(user.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal))
		return "Вы уже бесплотны."
	if(!QDELETED(soul_hold))
		return "Пока вы держите чужую душу, стать бесплотным нельзя."
	return null

/datum/eldritch_knowledge/base_spirit/proc/become_incorporeal(mob/living/user)
	incorporeal_failure_reason = incorporeal_failure(user)
	if(incorporeal_failure_reason)
		return FALSE
	var/datum/status_effect/heretic_spirit_incorporeal/effect = user.apply_status_effect(/datum/status_effect/heretic_spirit_incorporeal, src)
	if(!effect || QDELETED(effect))
		incorporeal_failure_reason = "Бесплотность сорвалась."
		return FALSE
	playsound(user, 'modular_bluemoon/sound/heretic/spirit_step.ogg', 55, TRUE)
	log_game("[key_name(user)] становится бесплотным (Дух) в [AREACOORD(user)].")
	return TRUE

/datum/status_effect/heretic_spirit_incorporeal
	id = "heretic_spirit_incorporeal"
	duration = HERETIC_SPIRIT_INCORPOREAL_DURATION
	tick_interval = HERETIC_SPIRIT_INCORPOREAL_CHECK
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_spirit_incorporeal
	var/datum/weakref/spirit_ref
	var/applied = FALSE
	var/previous_alpha
	var/end_reason
	var/datum/weakref/watched_item_ref

/// Флаг снимается, только если его ставили эти источники: чужой PASSMOB (форма слизи) остаётся.
/proc/heretic_spirit_passmob_on(mob/living/target, source)
	if(!HAS_TRAIT(target, HERETIC_SPIRIT_PASSMOB_TRAIT) && !(target.pass_flags & PASSMOB))
		ADD_TRAIT(target, HERETIC_SPIRIT_PASSMOB_OWNED_TRAIT, HERETIC_SPIRIT_PASSMOB_TRAIT)
	ADD_TRAIT(target, HERETIC_SPIRIT_PASSMOB_TRAIT, source)
	target.pass_flags |= PASSMOB

/proc/heretic_spirit_passmob_off(mob/living/target, source)
	REMOVE_TRAIT(target, HERETIC_SPIRIT_PASSMOB_TRAIT, source)
	if(HAS_TRAIT(target, HERETIC_SPIRIT_PASSMOB_TRAIT) || !HAS_TRAIT(target, HERETIC_SPIRIT_PASSMOB_OWNED_TRAIT))
		return
	REMOVE_TRAIT(target, HERETIC_SPIRIT_PASSMOB_OWNED_TRAIT, HERETIC_SPIRIT_PASSMOB_TRAIT)
	target.pass_flags &= ~PASSMOB

/datum/status_effect/heretic_spirit_incorporeal/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_spirit/spirit)
	spirit_ref = WEAKREF(spirit)
	return ..()

/datum/status_effect/heretic_spirit_incorporeal/on_apply()
	if(!..() || !spirit_ref?.resolve())
		return FALSE
	applied = TRUE
	heretic_spirit_passmob_on(owner, HERETIC_SPIRIT_INCORPOREAL_TRAIT)
	passtable_on(owner, HERETIC_SPIRIT_INCORPOREAL_TRAIT)
	ADD_TRAIT(owner, TRAIT_UNPULLABLE, HERETIC_SPIRIT_INCORPOREAL_TRAIT)
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_spirit_incorporeal)
	previous_alpha = owner.alpha
	owner.alpha = HERETIC_SPIRIT_INCORPOREAL_ALPHA
	var/atom/movable/grabber = owner.pulledby
	if(grabber)
		grabber.stop_pulling()
		log_combat(owner, grabber, "выходит бесплотным из захвата")
	if(ismob(owner.buckled))
		var/mob/living/carrier = owner.buckled
		carrier.unbuckle_mob(owner, TRUE)
	RegisterSignal(owner, COMSIG_LIVING_RUN_BLOCK, PROC_REF(pass_through))
	RegisterSignal(owner, COMSIG_MOB_CLICKON, PROC_REF(on_click))
	RegisterSignal(owner, COMSIG_MOB_SPELL_CAN_CAST, PROC_REF(on_spell_check))
	RegisterSignal(owner, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_GUN_PROCESS_FIRE, COMSIG_MOB_CAST_SPELL, COMSIG_MOB_THROW, COMSIG_MOB_ATTACK_RANGED, COMSIG_LIVING_SET_AS_ATTACKER), PROC_REF(on_attack_attempt))
	RegisterSignal(owner, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(on_unarmed))
	owner.visible_message(span_warning("[owner] бледнеет и становится прозрачным, как туман над рекой."), span_notice("Вы бесплотны [HERETIC_SPIRIT_INCORPOREAL_DURATION / (1 SECONDS)] секунды: пули и удары проходят сквозь вас. Атака или заклинание вернут плоть."))
	return TRUE

/datum/status_effect/heretic_spirit_incorporeal/tick()
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	if(!spirit?.can_use(owner, FALSE, TRUE) || heretic_containment_reason(owner))
		end("вы больше не можете держать бесплотность")

/datum/status_effect/heretic_spirit_incorporeal/proc/pass_through(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, list/return_list)
	SIGNAL_HANDLER
	if(!(attack_type & (ATTACK_TYPE_PROJECTILE | ATTACK_TYPE_MELEE | ATTACK_TYPE_UNARMED | ATTACK_TYPE_THROWN)))
		return BLOCK_NONE
	return_list[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_PASSTHROUGH
	return BLOCK_SUCCESS | BLOCK_SHOULD_REDIRECT | BLOCK_TARGET_DODGED

/// Клик-атака, выстрел, бросок или цель заклинания пропадают и возвращают плоть; осмотр и ходьба - нет.
/datum/status_effect/heretic_spirit_incorporeal/proc/on_click(mob/living/source, atom/target, params)
	SIGNAL_HANDLER
	var/list/modifiers = params2list(params)
	if(modifiers["shift"] || modifiers["ctrl"] || modifiers["alt"] || modifiers["middle"])
		return NONE
	if(!attack_click(target))
		watch_item(owner.get_active_held_item())
		return NONE
	end("атака прошла сквозь цель и пропала")
	return COMSIG_MOB_CANCEL_CLICKON

/datum/status_effect/heretic_spirit_incorporeal/proc/attack_click(atom/target)
	if(!target || target == owner || target.loc == owner)
		return FALSE
	if(owner.ranged_ability || owner.throw_mode || istype(owner.get_active_held_item(), /obj/item/gun))
		return TRUE
	if(isliving(target))
		return owner.get_active_held_item() || owner.a_intent != INTENT_HELP
	return isclosedturf(target) && owner.a_intent == INTENT_HARM && owner.get_active_held_item() && owner.Adjacent(target)

/// Удар предметом по двери или машине в любом намерении доходит до attack_obj; инструменты и пустая рука туда не попадают.
/datum/status_effect/heretic_spirit_incorporeal/proc/watch_item(obj/item/held)
	var/obj/item/watched = watched_item_ref?.resolve()
	if(watched == held)
		return
	if(watched)
		UnregisterSignal(watched, COMSIG_ITEM_ATTACK_OBJ)
	watched_item_ref = held ? WEAKREF(held) : null
	if(held)
		RegisterSignal(held, COMSIG_ITEM_ATTACK_OBJ, PROC_REF(on_item_strike))

/datum/status_effect/heretic_spirit_incorporeal/proc/on_item_strike(obj/item/source, obj/target, mob/living/user)
	SIGNAL_HANDLER
	if(user != owner || (source.item_flags & NOBLUDGEON) || source.get_damage_to_obj(target, user) <= 0)
		return NONE
	end("удар прошёл сквозь предмет и пропал")
	return COMPONENT_NO_ATTACK_OBJ

/datum/status_effect/heretic_spirit_incorporeal/proc/on_spell_check(mob/living/source, obj/effect/proc_holder/spell/spell, silent)
	SIGNAL_HANDLER
	if(istype(spell, /obj/effect/proc_holder/spell/self/heretic_spirit/incorporeal))
		return NONE
	if(!silent)
		end("заклинание не далось бесплотной руке")
	return SPELL_CANCEL_CAST

/datum/status_effect/heretic_spirit_incorporeal/proc/on_attack_attempt(datum/source)
	SIGNAL_HANDLER
	end("атака возвращает плоть")

/datum/status_effect/heretic_spirit_incorporeal/proc/on_unarmed(datum/source, atom/target)
	SIGNAL_HANDLER
	if(isliving(target) && target != owner && owner.a_intent != INTENT_HELP)
		end("атака возвращает плоть")

/datum/status_effect/heretic_spirit_incorporeal/proc/end(reason)
	if(QDELETED(src))
		return
	end_reason = reason
	qdel(src)

/datum/status_effect/heretic_spirit_incorporeal/on_remove()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_LIVING_RUN_BLOCK, COMSIG_MOB_CLICKON, COMSIG_MOB_SPELL_CAN_CAST, COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_GUN_PROCESS_FIRE, COMSIG_MOB_CAST_SPELL, COMSIG_MOB_THROW, COMSIG_MOB_ATTACK_RANGED, COMSIG_LIVING_SET_AS_ATTACKER, COMSIG_HUMAN_MELEE_UNARMED_ATTACK))
		watch_item(null)
		heretic_spirit_passmob_off(owner, HERETIC_SPIRIT_INCORPOREAL_TRAIT)
		passtable_off(owner, HERETIC_SPIRIT_INCORPOREAL_TRAIT)
		REMOVE_TRAIT(owner, TRAIT_UNPULLABLE, HERETIC_SPIRIT_INCORPOREAL_TRAIT)
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_spirit_incorporeal)
		// Прозрачность, изменённая кем-то другим за эти секунды, остаётся как есть.
		if(owner.alpha == HERETIC_SPIRIT_INCORPOREAL_ALPHA)
			owner.alpha = previous_alpha
		to_chat(owner, span_notice("Вы снова во плоти[end_reason ? ": [end_reason]" : ""]."))
	spirit_ref = null
	return ..()

/datum/movespeed_modifier/heretic_spirit_incorporeal
	multiplicative_slowdown = HERETIC_SPIRIT_INCORPOREAL_HASTE

/atom/movable/screen/alert/status_effect/heretic_spirit_incorporeal
	name = "Бесплотность"
	desc = "3 секунды пули и удары проходят сквозь вас, вы проходите сквозь людей и столы и двигаетесь быстрее, вас не схватить. Атаковать, даже предметом по двери или стене, и колдовать нельзя: попытка пропадёт и сразу вернёт плоть."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "spirit_phased"

/// Перевозчик: проход сквозь существ и столы, смерть экипажа рядом платит оболами и лечит.
/datum/component/heretic_spirit_ferryman
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/spirit_ref
	var/ferry_range = HERETIC_SPIRIT_FERRY_RANGE
	COOLDOWN_DECLARE(passage_trail)

/datum/component/heretic_spirit_ferryman/Initialize(datum/eldritch_knowledge/base_spirit/spirit)
	if(!isliving(parent) || QDELETED(spirit))
		return COMPONENT_INCOMPATIBLE
	spirit_ref = WEAKREF(spirit)

/datum/component/heretic_spirit_ferryman/RegisterWithParent()
	var/mob/living/owner = parent
	heretic_spirit_passmob_on(owner, REF(src))
	passtable_on(owner, REF(src))
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_mob_death))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/component/heretic_spirit_ferryman/UnregisterFromParent()
	var/mob/living/owner = parent
	heretic_spirit_passmob_off(owner, REF(src))
	passtable_off(owner, REF(src))
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	UnregisterSignal(parent, list(COMSIG_PARENT_EXAMINE, COMSIG_MOVABLE_MOVED))

/// Шаг сквозь человека или стол оставляет шлейф; без зрителей рядом он не рисуется.
/datum/component/heretic_spirit_ferryman/proc/on_moved(mob/living/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	if(!COOLDOWN_FINISHED(src, passage_trail) || !stepped_through(source, old_loc))
		return
	if(!heretic_vfx_watched(source))
		return
	COOLDOWN_START(src, passage_trail, HERETIC_SPIRIT_PASSAGE_COOLDOWN)
	show_passage(old_loc, movement_dir || get_dir(old_loc, source.loc))

/// Шаг на соседнюю клетку сквозь живое существо или стол; телепорт и перенос шлейфа не оставляют.
/datum/component/heretic_spirit_ferryman/proc/stepped_through(mob/living/owner, atom/old_loc)
	return isturf(old_loc) && isturf(owner.loc) && get_dist(old_loc, owner.loc) <= 1 && passing_through(owner)

/// Герой стоит в одной клетке с живым существом или столом, то есть прошёл сквозь них.
/datum/component/heretic_spirit_ferryman/proc/passing_through(mob/living/owner)
	for(var/atom/movable/thing as anything in owner.loc)
		if(thing == owner || !thing.density)
			continue
		if(isliving(thing) || (thing.pass_flags_self & PASSTABLE))
			return TRUE
	return FALSE

/// Полупрозрачный отпечаток героя тянется за ним и тает, сквозь пройденное поднимаются огоньки.
/datum/component/heretic_spirit_ferryman/proc/show_passage(turf/from, direction)
	var/mob/living/owner = parent
	var/obj/effect/temp_visual/heretic_vfx/ghost/trail = heretic_vfx_ghost(owner, from, heretic_vfx_ink_tint(heretic_path_ink(PATH_SPIRIT)), HERETIC_SPIRIT_PASSAGE_TIME, TRUE)
	if(trail)
		trail.alpha = trail.model_share(HERETIC_SPIRIT_PASSAGE_ALPHA)
		var/drift_x = ((direction & EAST) ? 1 : (direction & WEST) ? -1 : 0) * HERETIC_SPIRIT_PASSAGE_DRIFT
		var/drift_y = ((direction & NORTH) ? 1 : (direction & SOUTH) ? -1 : 0) * HERETIC_SPIRIT_PASSAGE_DRIFT
		animate(trail, pixel_x = trail.pixel_x + drift_x, pixel_y = trail.pixel_y + drift_y, alpha = 0, time = HERETIC_SPIRIT_PASSAGE_TIME, easing = SINE_EASING | EASE_IN)
	heretic_vfx_burst(owner, /particles/heretic_ascension/spirit/passage, HERETIC_VFX_BURST_TIME / 2)

/datum/component/heretic_spirit_ferryman/proc/on_mob_death(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER
	var/mob/living/owner = parent
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	if(!spirit?.ascension_active || owner.stat == DEAD || died == owner || !ishuman(died) || !died.mind || IS_HERETIC(died) || IS_HERETIC_MONSTER(died))
		return
	var/turf/owner_turf = get_turf(owner)
	var/turf/death_turf = get_turf(died)
	if(!owner_turf || !death_turf || owner_turf.z != death_turf.z || get_dist(owner_turf, death_turf) > ferry_range)
		return
	if(died.check_magic_resistance(chargecost = 0))
		return
	spirit.gain_combat_resource(HERETIC_SPIRIT_FERRY_OBOLS)
	heretic_heal_pool(owner, HERETIC_SPIRIT_FERRY_HEAL)
	new /obj/effect/temp_visual/heretic_spirit/burst(death_turf, spirit)
	heretic_vfx_pulse(owner, heretic_path_ink(PATH_SPIRIT), 2, HERETIC_SPIRIT_TOLL_PULSE)
	new /obj/effect/abstract/heretic_spirit_toll_soul(null, owner, death_turf)
	to_chat(owner, span_notice("Душа [died] платит за переправу: [HERETIC_SPIRIT_FERRY_OBOLS] обола, раны затягиваются."))

/datum/component/heretic_spirit_ferryman/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Люди и столы не задерживают его, словно он туман. Каждая смерть в семи клетках от него платит ему оболами и лечит его: уносите раненых подальше. Смерть под защитой от магии ему не достаётся, антимагия гасит его чары, а нулевой жезл рвёт нить души.")

/// Душа-плата летит из тела к перевозчику по дуге; она висит в его vis_contents и потому догоняет его, куда бы он ни шёл.
/obj/effect/abstract/heretic_spirit_toll_soul
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "soul_wisp"
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	vis_flags = VIS_INHERIT_PLANE
	var/datum/weakref/host_ref
	var/from_x = 0
	var/from_y = 0

/obj/effect/abstract/heretic_spirit_toll_soul/Initialize(mapload, mob/living/host, turf/from)
	. = ..()
	var/turf/host_turf = get_turf(host)
	if(QDELETED(host) || !isturf(from) || !host_turf || host_turf.z != from.z)
		return INITIALIZE_HINT_QDEL
	host_ref = WEAKREF(host)
	add_overlay(emissive_appearance(icon, icon_state))
	from_x = (from.x - host_turf.x) * world.icon_size
	from_y = (from.y - host_turf.y) * world.icon_size
	host.vis_contents += src
	fly()
	addtimer(CALLBACK(src, PROC_REF(arrive)), HERETIC_SPIRIT_TOLL_FLIGHT)

/// Отрезки квадратичной дуги с изгибом вбок; на каждом душа разворачивается по касательной.
/obj/effect/abstract/heretic_spirit_toll_soul/proc/fly()
	var/bend_x = from_x / 2 - from_y * HERETIC_SPIRIT_TOLL_ARC
	var/bend_y = from_y / 2 + from_x * HERETIC_SPIRIT_TOLL_ARC
	pixel_x = from_x
	pixel_y = from_y
	transform = heading_at(0, bend_x, bend_y)
	alpha = 0
	var/step_time = HERETIC_SPIRIT_TOLL_FLIGHT / HERETIC_SPIRIT_TOLL_SEGMENTS
	for(var/index in 1 to HERETIC_SPIRIT_TOLL_SEGMENTS)
		var/share = index / HERETIC_SPIRIT_TOLL_SEGMENTS
		var/rest = 1 - share
		var/matrix/facing = heading_at(share, bend_x, bend_y)
		if(index == HERETIC_SPIRIT_TOLL_SEGMENTS)
			facing.Scale(HERETIC_SPIRIT_TOLL_ABSORB)
		var/point_x = rest * rest * from_x + 2 * rest * share * bend_x
		var/point_y = rest * rest * from_y + 2 * rest * share * bend_y
		if(index == 1)
			animate(src, pixel_x = point_x, pixel_y = point_y, transform = facing, time = step_time)
		else
			animate(pixel_x = point_x, pixel_y = point_y, transform = facing, time = step_time, easing = index == HERETIC_SPIRIT_TOLL_SEGMENTS ? QUAD_EASING | EASE_IN : LINEAR_EASING)
	animate(src, alpha = 255, time = HERETIC_SPIRIT_TOLL_FADE_IN, flags = ANIMATION_PARALLEL)

/// Поворот спрайта головой по касательной дуги в доле пути share.
/obj/effect/abstract/heretic_spirit_toll_soul/proc/heading_at(share, bend_x, bend_y)
	var/tangent_x = 2 * (1 - share) * (bend_x - from_x) - 2 * share * bend_x
	var/tangent_y = 2 * (1 - share) * (bend_y - from_y) - 2 * share * bend_y
	var/matrix/facing = matrix()
	if(tangent_x || tangent_y)
		facing.Turn(90 - arctan(tangent_x, tangent_y))
	return facing

/// Долетевшая душа гаснет в перевозчике бледной вспышкой.
/obj/effect/abstract/heretic_spirit_toll_soul/proc/arrive()
	var/mob/living/host = host_ref?.resolve()
	if(host)
		heretic_vfx_flash(host, heretic_path_ink(PATH_SPIRIT), HERETIC_SPIRIT_TOLL_FLASH_RANGE, HERETIC_SPIRIT_TOLL_FLASH_POWER, HERETIC_SPIRIT_TOLL_FLASH_TIME)
		heretic_vfx_burst(host, /particles/heretic_ascension/spirit/passage, HERETIC_VFX_BURST_TIME / 2)
	qdel(src)

/obj/effect/abstract/heretic_spirit_toll_soul/Destroy()
	var/atom/movable/host = host_ref?.resolve()
	if(host)
		host.vis_contents -= src
	host_ref = null
	return ..()

/// Дух: редкие огоньки там, где перевозчик прошёл сквозь живое или сквозь стол.
/particles/heretic_ascension/spirit/passage
	count = 6
	spawning = 6
	position = generator("box", list(-8, -10, 0), list(8, 8, 0))
	velocity = generator("circle", 0.4, 1.2)
	gravity = list(0, 0.08)
	lifespan = 0.9 SECONDS
	fade = 0.5 SECONDS
	fadein = 0.1 SECONDS

/// Дух: души по спирали тянутся к перевозчику.
/particles/heretic_ascension/spirit/spiral
	count = 12
	spawning = 1
	grow = -0.01

#undef HERETIC_SPIRIT_RANGE
#undef HERETIC_SPIRIT_SOUL_LIMIT
#undef HERETIC_SPIRIT_DRAIN_LIMIT
#undef HERETIC_SPIRIT_REAP_DELAY
#undef HERETIC_SPIRIT_REAP_AFTERGLOW
#undef HERETIC_SPIRIT_RECOVERY
#undef HERETIC_SPIRIT_HARVEST
#undef HERETIC_SPIRIT_STEP_RANGE
#undef HERETIC_SPIRIT_DRAIN_PER_TICK
#undef HERETIC_SPIRIT_STAMINA_RESTORE
#undef HERETIC_SPIRIT_LANTERN_HEAL
#undef HERETIC_SPIRIT_HOOK_INCOME
#undef HERETIC_SPIRIT_REAP_NEAR_DAMAGE
#undef HERETIC_SPIRIT_PASSAGE_COOLDOWN
#undef HERETIC_SPIRIT_PASSAGE_TIME
#undef HERETIC_SPIRIT_PASSAGE_ALPHA
#undef HERETIC_SPIRIT_PASSAGE_DRIFT
#undef HERETIC_SPIRIT_TOLL_FLIGHT
#undef HERETIC_SPIRIT_TOLL_SEGMENTS
#undef HERETIC_SPIRIT_TOLL_ARC
#undef HERETIC_SPIRIT_TOLL_FADE_IN
#undef HERETIC_SPIRIT_TOLL_ABSORB
#undef HERETIC_SPIRIT_TOLL_PULSE
#undef HERETIC_SPIRIT_TOLL_FLASH_RANGE
#undef HERETIC_SPIRIT_TOLL_FLASH_POWER
#undef HERETIC_SPIRIT_TOLL_FLASH_TIME
#undef HERETIC_SPIRIT_VOYAGE_WAVE_RADIUS
#undef HERETIC_SPIRIT_VOYAGE_WAVE_TIME
#undef HERETIC_SPIRIT_VOYAGE_FLASH_RANGE
#undef HERETIC_SPIRIT_VOYAGE_FLASH_POWER
#undef HERETIC_SPIRIT_VOYAGE_FLASH_TIME
#undef HERETIC_SPIRIT_VOYAGE_QUAKE
#undef HERETIC_SPIRIT_VOYAGE_QUAKE_RADIUS
#undef HERETIC_SPIRIT_VOYAGE_QUAKE_TIME
#undef HERETIC_SPIRIT_VOYAGE_LANTERN_TIME
#undef HERETIC_SPIRIT_VOYAGE_SPIRAL_RADIUS
#undef HERETIC_SPIRIT_VOYAGE_SPIRAL_TRAVEL
#undef HERETIC_SPIRIT_VOYAGE_SPIRAL_EMIT
#undef HERETIC_SPIRIT_VOYAGE_SPIRAL_ARMS
#undef HERETIC_SPIRIT_VOYAGE_SPIRAL_SWIRL
#undef HERETIC_SPIRIT_OBOL_CRAFT
#undef HERETIC_SPIRIT_OBOL_CLUE
#undef HERETIC_SPIRIT_WHISPER_LENGTH
#undef HERETIC_SPIRIT_HOLD_CAPTURE
#undef HERETIC_SPIRIT_HOLD_CHECK
#undef HERETIC_SPIRIT_INCORPOREAL_TRAIT
#undef HERETIC_SPIRIT_INCORPOREAL_HASTE
#undef HERETIC_SPIRIT_INCORPOREAL_ALPHA
#undef HERETIC_SPIRIT_INCORPOREAL_CHECK
#undef HERETIC_SPIRIT_ASCENDED_SOUL_LIMIT
#undef HERETIC_SPIRIT_WHISPER_COOLDOWN
#undef HERETIC_SPIRIT_PASSMOB_TRAIT
#undef HERETIC_SPIRIT_PASSMOB_OWNED_TRAIT
