#define HERETIC_WAX_RANGE 5
#define HERETIC_WAX_RELEASE_RANGE 3
#define HERETIC_WAX_RECOVERY (10 SECONDS)
#define HERETIC_WAX_HARVEST (6 SECONDS)
#define HERETIC_WAX_SHELL_COST 2
#define HERETIC_WAX_SHELL_CAPACITY 45
#define HERETIC_WAX_HEAL_LIMIT 25
#define HERETIC_WAX_IMPRINT_DAMAGE 14
#define HERETIC_WAX_EFFIGY_CAPACITY 30
#define HERETIC_WAX_EFFIGY_SEALED_CAPACITY 45
#define HERETIC_WAX_EFFIGY_HIT_LIMIT 15
#define HERETIC_WAX_SHELL_RELEASE_LIMIT 30
#define HERETIC_WAX_SHELL_RELEASE_FRACTION (2 / 3)
#define HERETIC_WAX_COLOR "#e8ca85"
#define HERETIC_WAX_ANCHOR_FILTER "heretic_wax_anchor"
#define HERETIC_WAX_PUPPET_CRAFT "wax_puppet"
#define HERETIC_WAX_CAPTURE "wax"
#define HERETIC_WAX_PUPPET_CHECK (0.5 SECONDS)
#define HERETIC_WAX_LEAK_TRAIT "heretic_wax_leak"
#define HERETIC_WAX_LEAK_SLOWDOWN 1
#define HERETIC_WAX_PUDDLE_SPREAD 1.3
#define HERETIC_WAX_PUDDLE_SQUASH 0.25
#define HERETIC_WAX_PUDDLE_SINK 12
#define HERETIC_WAX_PUDDLE_ALPHA 220

/datum/heretic_path/wax
	id = PATH_WAX
	deed_type = /datum/heretic_deed/wax
	name = "Воск"
	tagline = "Лепит кукол по отпечаткам пальцев, усыпляет по кукле и протекает под дверью."
	craft_summary = "Хватка в «Помощи» по вещи с отпечатками, ID-карте или КПК лепит куклу; держатся 2 куклы."
	capture_summary = "Растопите куклу 5 секунд - цель охоты в 9 клетках уснёт на 8 секунд, и кукла утянет её в изнанку."
	escape_summary = "Протечь: 4 секунды вы неуязвимой лужицей ползёте под дверями и шлюзами; из изнанки выходите к своей свече."
	strength_points = list(
		"Кукла усыпляет человека в 9 клетках даже за стеной: хватит вещи, которую он держал.",
		"Спящую цель охоты кукла в руке утягивает в изнанку, не подходя к ней.",
		"Протечь уводит под закрытым шлюзом, даже на болтах, и вырывает из чужих рук.",
		"Волна ранит и замедляет врагов в 3 клетках, оттиск и двойник - в 5; выброс оболочки бьёт на 5 без замедления.",
		"Оболочка принимает удары, канделябр переплавляет принятое в лечение.",
		"Вознёсшийся раз в 5 минут встаёт из крита у одной из трёх своих свечей.",
	)
	weakness_points = list(
		"Потерянную куклу опознают по бирке, а огонь или нулевой жезл её уничтожают.",
		"Жар гаснет от воды, нулевого жезла или ухода дальше 9 клеток; спящего будит жезл, его растолкают за 2 секунды.",
		"Лужица не проходит сквозь стены, окна, гермозаслоны и неразрушимые двери и сама ничего не может.",
		"Связь с двойником рвётся за стеной или дальше 5 клеток от него или еретика; самого двойника можно разбить.",
		"Перед боем с вознёсшимся разбейте его свечи с золотым контуром ударом или огнём.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_wax,
		/datum/eldritch_knowledge/wax_grasp,
		/datum/eldritch_knowledge/spell/wax_imprint,
		/datum/eldritch_knowledge/spell/wax_puppet_sleep,
		/datum/eldritch_knowledge/spell/wax_shell,
		/datum/eldritch_knowledge/wax_mark,
		/datum/eldritch_knowledge/spell/wax_leak,
		/datum/eldritch_knowledge/wax_temper,
		/datum/eldritch_knowledge/spell/wax_procession,
		/datum/eldritch_knowledge/final_eldritch/wax_final,
	)

/datum/eldritch_knowledge/base_wax
	name = "Свеча без огня"
	summary = "Лепит кукол по чужим отпечаткам, отливает свечи из бумаги и бьёт веером воска за 1 Воск."
	details = list(
		"Хватка в «Помощи» по вещи с отпечатками живого человека с разумом, его ID-карте или КПК лепит его куклу в руку.",
		"Держатся 2 куклы, новая вытесняет старую; каждый человек идёт в дело один раз.",
		"Используйте куклу в руке, чтобы уколоть: человек на вашем уровне чувствует укол и слышит шёпот, перезарядка 30 секунд.",
		"Потерянную куклу экипаж опознает по бирке; огонь и нулевой жезл её уничтожают.",
		"Хватка по листу бумаги на полу отливает свечу за 1 Воск, куклу из бумаги не слепить; из изнанки выходите к своей свече.",
		"«Снять печать» за 1 Воск бьёт веером на 3 клетки: 18 ушибов, 20 выносливости, замедление на 2 секунды.",
		"Нож и свеча на руне дают восковой клинок.",
	)
	role = HERETIC_ROLE_CRAFT
	ritual_hint = "Нет свечи? Положите лист бумаги на пол и коснитесь его Хваткой Мансуса: лист и 1 Воск превратятся в обычную свечу. Это доступно сразу после выбора пути."
	gain_text = "Свеча не горела. Она таяла от того, что видела."
	route = PATH_WAX
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/candle)
	result_atoms = list(/obj/item/melee/sickly_blade/wax)
	combat_resource = 3
	combat_resource_max = 5
	combat_resource_name = "Воск"
	resource_rules = list(
		"Запас 3 из 5; пока воска меньше 2, единица возвращается каждые 10 секунд.",
		"Единицу даёт попадание по живому разумному врагу клинком, хваткой, волной, оттиском, процессией или взрывом метки, не чаще раза в 6 секунд.",
		"Животные и союзники воск не дают; новое дело пути даёт единицу.",
		"Волна, оттиск и отливка свечи стоят 1, оболочка и процессия - 2.",
		"Смерть и смена тела гасят свечи и обнуляют запас; куклы остаются.",
	)
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_wax/release
	grasp_visual = /obj/effect/temp_visual/heretic_wax/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/wax_grasp.ogg'
	grasp_catchphrase = "VA'SKAS TI'RPSTA"
	var/mob/living/wax_body
	var/list/datum/status_effect/heretic_wax/effects = list()
	var/list/datum/status_effect/eldritch/wax/marks = list()
	var/list/obj/effect/temp_visual/heretic_wax/visuals = list()
	var/ascension_active = FALSE
	var/datum/status_effect/heretic_wax/effigy/active_effigy
	var/list/obj/item/candle/anchor_candles = list()
	var/list/obj/item/heretic_wax_puppet/puppets = list()
	var/list/datum/status_effect/heretic_wax_melting/meltings = list()
	var/datum/status_effect/heretic_wax_leak/leak
	var/wax_failure
	COOLDOWN_DECLARE(wax_recovery)
	COOLDOWN_DECLARE(wax_harvest)

/datum/eldritch_knowledge/base_wax/on_body_gain(mob/living/user)
	if(!user?.mind || wax_body == user)
		return
	if(wax_body)
		on_body_lose(wax_body)
	wax_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	grant_combat_power(user)
	update_temper()
	COOLDOWN_START(src, wax_recovery, HERETIC_WAX_RECOVERY)

/datum/eldritch_knowledge/base_wax/on_body_lose(mob/living/user)
	if(wax_body)
		UnregisterSignal(wax_body, COMSIG_PARENT_QDELETING)
	clear_wax()
	wax_body = null
	ascension_active = FALSE
	update_anchor_marks()
	combat_resource = 0
	remove_combat_power()
	notify_resource_changed()

/datum/eldritch_knowledge/base_wax/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(wax_body)

/datum/eldritch_knowledge/base_wax/on_death(mob/user)
	clear_wax()
	combat_resource = 0
	COOLDOWN_START(src, wax_recovery, HERETIC_WAX_RECOVERY)
	notify_resource_changed()

/datum/eldritch_knowledge/base_wax/Destroy()
	on_body_lose(wax_body)
	for(var/obj/item/candle/candle as anything in anchor_candles.Copy())
		release_anchor(candle)
	for(var/obj/item/heretic_wax_puppet/puppet as anything in puppets.Copy())
		qdel(puppet)
	puppets.Cut()
	return ..()

/datum/eldritch_knowledge/base_wax/proc/clear_wax()
	QDEL_LIST(effects)
	QDEL_LIST(marks)
	QDEL_LIST(visuals)
	QDEL_LIST(meltings)
	QDEL_NULL(leak)

/datum/eldritch_knowledge/base_wax/proc/clear_knowledge_effects(datum/eldritch_knowledge/required)
	for(var/datum/status_effect/heretic_wax/effect as anything in effects.Copy())
		if(effect.knowledge_ref?.resolve() == required)
			qdel(effect)

/datum/eldritch_knowledge/base_wax/proc/can_use(mob/living/user, allow_incapacitated = FALSE, ignore_grab = FALSE, ignore_leak = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && user && user == wax_body && (ignore_leak || !leak) && user.stat != DEAD && (allow_incapacitated || !user.incapacitated(ignore_grab = ignore_grab)) && isturf(user.loc) && heretic?.selected_path == PATH_WAX && !heretic.role_removed && heretic.get_knowledge(type) == src

/datum/eldritch_knowledge/base_wax/proc/line_clear(atom/start, atom/target, distance = HERETIC_WAX_RANGE)
	var/turf/origin = get_turf(start)
	var/turf/destination = get_turf(target)
	if(!origin || !destination || origin.z != destination.z || get_dist(origin, destination) > distance)
		return FALSE
	var/turf/previous
	for(var/turf/tile as anything in get_line(origin, destination))
		if(!heretic_line_tile_open(tile))
			return FALSE
		if(previous && previous.x != tile.x && previous.y != tile.y)
			if(!heretic_line_tile_open(locate(previous.x, tile.y, tile.z)) || !heretic_line_tile_open(locate(tile.x, previous.y, tile.z)))
				return FALSE
		previous = tile
	return TRUE

/datum/eldritch_knowledge/base_wax/proc/add_anchor(obj/item/candle/candle)
	if(length(anchor_candles) >= HERETIC_WAX_PHYLACTERY_ANCHORS)
		release_anchor(anchor_candles[1])
	anchor_candles += candle
	RegisterSignal(candle, COMSIG_PARENT_QDELETING, PROC_REF(on_anchor_deleted))
	RegisterSignal(candle, COMSIG_PARENT_EXAMINE, PROC_REF(on_anchor_examine))
	RegisterSignal(candle, COMSIG_PARENT_ATTACKBY, PROC_REF(on_anchor_attacked))
	mark_anchor(candle)

/datum/eldritch_knowledge/base_wax/proc/release_anchor(obj/item/candle/candle)
	anchor_candles -= candle
	UnregisterSignal(candle, list(COMSIG_PARENT_QDELETING, COMSIG_PARENT_EXAMINE, COMSIG_PARENT_ATTACKBY))
	candle.remove_filter(HERETIC_WAX_ANCHOR_FILTER)
	snuff_anchor(candle)

/datum/eldritch_knowledge/base_wax/proc/mark_anchor(obj/item/candle/candle)
	if(!ascension_active)
		candle.remove_filter(HERETIC_WAX_ANCHOR_FILTER)
		snuff_anchor(candle)
	else if(!candle.get_filter(HERETIC_WAX_ANCHOR_FILTER))
		candle.add_filter(HERETIC_WAX_ANCHOR_FILTER, 2, outline_filter(1, HERETIC_WAX_COLOR))
		light_anchor(candle, candle.get_filter(HERETIC_WAX_ANCHOR_FILTER), HERETIC_WAX_COLOR)

/datum/eldritch_knowledge/base_wax/proc/update_anchor_marks()
	for(var/obj/item/candle/candle as anything in anchor_candles)
		mark_anchor(candle)

/datum/eldritch_knowledge/base_wax/proc/on_anchor_deleted(obj/item/candle/source)
	SIGNAL_HANDLER
	release_anchor(source)

/datum/eldritch_knowledge/base_wax/proc/on_anchor_examine(obj/item/candle/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(ascension_active)
		examine_list += span_warning("Бледный воск этой свечи держит жизнь вознёсшегося еретика: упав в крит или умерев, он поднимется у неё. Свеча действует, только пока стоит на полу или столе внутри станции: в руках, в ящике, под шкафом или другим плотным предметом, на решётке, в космосе или снаружи под открытым небом она ничего не держит. Разбейте её любым ударом, зажигалкой или нулевым жезлом, прежде чем его валить.")

/datum/eldritch_knowledge/base_wax/proc/on_anchor_attacked(obj/item/candle/source, obj/item/weapon, mob/living/user, params)
	SIGNAL_HANDLER
	if(!ascension_active || user == wax_body || (weapon.force <= 0 && !weapon.get_temperature() && !istype(weapon, /obj/item/nullrod)))
		return NONE
	source.visible_message(span_warning("[user] разбивает восковую свечу, и бледный воск рассыпается крошкой."))
	playsound(source, 'modular_bluemoon/sound/heretic/wax_impact.ogg', 40, TRUE)
	qdel(source)
	return COMPONENT_NO_AFTERATTACK

/datum/eldritch_knowledge/base_wax/proc/anchor_spot_valid(turf/place)
	var/area/place_area = get_area(place)
	if(!isopenturf(place) || place.density || isgroundlessturf(place) || !is_station_level(place.z) || !place_area || place_area.considered_hull_exterior || place_area.outdoors)
		return FALSE
	for(var/obj/thing in place)
		if(thing.density && !(thing.flags_1 & ON_BORDER_1) && !istype(thing, /obj/structure/table))
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_wax/proc/anchor_holds(obj/item/candle/candle, turf/center)
	return center && isturf(candle.loc) && candle.z == center.z && anchor_spot_valid(candle.loc)

/datum/eldritch_knowledge/base_wax/proc/nearest_anchor(atom/origin)
	var/turf/center = get_turf(origin)
	var/best_distance = INFINITY
	for(var/obj/item/candle/candle as anything in anchor_candles)
		if(!anchor_holds(candle, center) || get_dist(center, candle) >= best_distance)
			continue
		best_distance = get_dist(center, candle)
		. = candle

/datum/eldritch_knowledge/base_wax/proc/count_anchors(atom/origin)
	. = 0
	var/turf/center = get_turf(origin)
	for(var/obj/item/candle/candle as anything in anchor_candles)
		if(anchor_holds(candle, center))
			.++

/datum/eldritch_knowledge/base_wax/proc/tile_open(turf/tile)
	return isopenturf(tile) && !tile.is_blocked_turf(exclude_mobs = TRUE)

/datum/eldritch_knowledge/base_wax/get_combat_resource_data()
	var/list/data = ..()
	data["name"] = wax_body?.a_intent == INTENT_DISARM ? "Воск: выброс оболочки" : "Воск: волна"
	return data

/datum/eldritch_knowledge/base_wax/combat_resource_state()
	var/datum/status_effect/heretic_wax/shell/shell = wax_body?.has_status_effect(/datum/status_effect/heretic_wax/shell)
	. = "Кукол: [length(puppets)] из [HERETIC_WAX_PUPPET_LIMIT]. "
	. += wax_body?.a_intent == INTENT_DISARM ? "Сейчас «Снять печать» расходует оставшуюся оболочку и её лечение, создавая веер в пяти клетках. Чтобы выпустить обычную волну за 1 воск, смените намерение «Разоружить»." : "Сейчас «Снять печать» выпускает волну за 1 воск в трёх клетках перед вами. В намерении «Разоружить» вместо неё расходуется оболочка."
	. += " Оболочка: [shell?.capacity || 0] защиты."
	if(!QDELETED(active_effigy) && !QDELETED(active_effigy.effigy))
		. += " Двойник: [active_effigy.owner.real_name], осталось [active_effigy.effigy.obj_integrity] переносимого урона и [round(max(0, active_effigy.duration - world.time) / (1 SECONDS), 0.1)] с. Бейте его своим восковым клинком."
	var/datum/antagonist/heretic/heretic = IS_HERETIC(wax_body)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	if(ascension_active && final_knowledge)
		var/cooldown_left = COOLDOWN_TIMELEFT(final_knowledge, phylactery_cooldown)
		. += " Филактерия: свечей на этом уровне [count_anchors(wax_body)] из [HERETIC_WAX_PHYLACTERY_ANCHORS], [cooldown_left ? "остынет через [DisplayTimeText(cooldown_left)]" : "готова"]."

/datum/eldritch_knowledge/base_wax/on_life(mob/user)
	if(user && user == wax_body)
		var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
		heretic?.update_combat_resource_alert(FALSE, user)
	if(!can_use(user) || !COOLDOWN_FINISHED(src, wax_recovery))
		return
	if(ascension_active || combat_resource < HERETIC_WAX_SHELL_COST)
		gain_combat_resource()
	COOLDOWN_START(src, wax_recovery, ascension_active ? 4 SECONDS : HERETIC_WAX_RECOVERY)

/datum/eldritch_knowledge/base_wax/proc/harvest(mob/living/user, mob/living/target, ignore_leak = FALSE)
	if(!can_use(user, ignore_leak = ignore_leak) || !target?.mind || target.mob_size < MOB_SIZE_HUMAN || !heretic_can_affect(user, target, chargecost = 0) || !COOLDOWN_FINISHED(src, wax_harvest))
		return FALSE
	gain_combat_resource()
	COOLDOWN_START(src, wax_harvest, HERETIC_WAX_HARVEST)
	return TRUE

/datum/eldritch_knowledge/base_wax/on_mark_detonated(mob/living/user, mob/living/target)
	harvest(user, target)

/datum/eldritch_knowledge/base_wax/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(proximity_flag && isliving(target) && isturf(target.loc))
		harvest(user, target)

/datum/eldritch_knowledge/base_wax/proc/update_temper(ignore_temper = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(wax_body)
	var/datum/eldritch_knowledge/wax_temper/temper = heretic?.get_knowledge(/datum/eldritch_knowledge/wax_temper)
	combat_resource_max = ascension_active ? 8 : !ignore_temper && !QDELETED(temper) ? temper.passive_values[temper.passive_level] : initial(combat_resource_max)
	combat_resource = min(combat_resource, combat_resource_max)
	notify_resource_changed()

/datum/eldritch_knowledge/base_wax/proc/seal(mob/living/victim, ignore_leak = FALSE)
	if(!can_use(wax_body, ignore_leak = ignore_leak) || !isturf(victim?.loc) || !heretic_can_affect(wax_body, victim, chargecost = 0))
		return null
	return victim.apply_status_effect(/datum/status_effect/heretic_wax/seal, src, src)

/datum/eldritch_knowledge/base_wax/proc/hinder(mob/living/victim, datum/eldritch_knowledge/required, ignore_leak = FALSE)
	if(!can_use(wax_body, ignore_leak = ignore_leak) || !isturf(victim?.loc) || !heretic_can_affect(wax_body, victim, chargecost = 0))
		return null
	return victim.apply_status_effect(/datum/status_effect/heretic_wax/clinging, src, required || src)

/datum/eldritch_knowledge/base_wax/proc/release(mob/living/user, consume_shell = FALSE)
	if(!can_use(user))
		return FALSE
	var/release_range = HERETIC_WAX_RELEASE_RANGE
	var/damage = 18
	if(consume_shell)
		var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
		if(QDELETED(shell) || shell.wax_ref?.resolve() != src || shell.capacity <= 0)
			to_chat(user, span_warning("Для выброса нужна неповреждённая часть погребальной оболочки."))
			return FALSE
		damage = min(HERETIC_WAX_SHELL_RELEASE_LIMIT, shell.capacity * HERETIC_WAX_SHELL_RELEASE_FRACTION)
		release_range = HERETIC_WAX_RANGE
		qdel(shell)
		user.visible_message(span_danger("[user] срывает погребальную оболочку и выбрасывает её осколки перед собой!"))
	else if(!spend_combat_resource())
		return FALSE
	var/list/directions = list(user.dir, turn(user.dir, 45), turn(user.dir, -45))
	for(var/turf/tile in range(release_range, user))
		if(tile == get_turf(user) || !(get_dir(user, tile) in directions) || !line_clear(user, tile, release_range))
			continue
		new /obj/effect/temp_visual/heretic_wax/burst(tile, src)
		for(var/mob/living/victim in tile)
			if(!heretic_can_affect(user, victim))
				continue
			victim.adjustBruteLoss(damage)
			if(!can_use(user))
				return TRUE
			if(QDELETED(victim) || consume_shell)
				continue
			victim.adjustStaminaLoss(20)
			seal(victim)
			hinder(victim)
			harvest(user, victim)
	playsound(user, 'modular_bluemoon/sound/heretic/wax_cast.ogg', 60, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_wax/proc/raise_shell(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	var/datum/status_effect/heretic_wax/shell/old_shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	if(!can_use(user) || QDELETED(required) || !spend_combat_resource(HERETIC_WAX_SHELL_COST))
		return FALSE
	QDEL_NULL(old_shell)
	user.apply_status_effect(/datum/status_effect/heretic_wax/shell, src, required)
	playsound(user, 'modular_bluemoon/sound/heretic/wax_cast.ogg', 55, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_wax/proc/imprint(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/wax_imprint)
	if(!can_use(user) || QDELETED(required) || !isturf(victim?.loc) || !line_clear(user, victim) || !heretic_can_affect(user, victim, chargecost = 0) || combat_resource < 1)
		return FALSE
	spend_combat_resource()
	if(!heretic_can_affect(user, victim))
		return TRUE
	var/datum/status_effect/heretic_wax/seal/sealed = victim.has_status_effect(/datum/status_effect/heretic_wax/seal)
	var/damage = HERETIC_WAX_IMPRINT_DAMAGE
	var/effigy_capacity = HERETIC_WAX_EFFIGY_CAPACITY
	if(sealed?.wax_ref?.resolve() == src)
		damage += 12
		effigy_capacity = HERETIC_WAX_EFFIGY_SEALED_CAPACITY
		victim.adjustStaminaLoss(25)
		qdel(sealed)
	victim.adjustBruteLoss(damage)
	if(!can_use(user) || QDELETED(victim))
		return TRUE
	harvest(user, victim)
	hinder(victim, required)
	QDEL_NULL(active_effigy)
	if(heretic_can_affect(user, victim, chargecost = 0))
		active_effigy = victim.apply_status_effect(/datum/status_effect/heretic_wax/effigy, src, required, effigy_capacity)
	notify_resource_changed()
	new /obj/effect/temp_visual/heretic_wax/burst(get_turf(victim), src)
	playsound(victim, 'modular_bluemoon/sound/heretic/wax_impact.ogg', 55, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_wax/proc/procession(mob/living/user, crown = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = crown ? heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final) : heretic?.get_knowledge(/datum/eldritch_knowledge/spell/wax_procession)
	if(!can_use(user) || QDELETED(required) || (crown && !ascension_active) || user.has_status_effect(/datum/status_effect/heretic_wax/procession) || (!crown && !spend_combat_resource(2)))
		return FALSE
	var/datum/status_effect/heretic_wax/procession/procession = user.apply_status_effect(/datum/status_effect/heretic_wax/procession, src, required, crown)
	procession?.tick()
	playsound(user, crown ? 'modular_bluemoon/sound/heretic/wax_ascend.ogg' : 'modular_bluemoon/sound/heretic/wax_cast.ogg', 65, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_wax/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_failure_reason = null
	if(!can_use(user) || QDELETED(target) || !proximity_flag)
		return FALSE
	if(istype(target, /obj/item/paper))
		return isturf(target.loc) && user.Adjacent(target) && cast_candle(user, target)
	if(user.a_intent != INTENT_HELP || !isitem(target) || istype(target, /obj/item/melee/touch_attack))
		return FALSE
	if(target.loc != user && (!isturf(target.loc) || !user.Adjacent(target)))
		return FALSE
	return make_puppet(user, target)

/datum/eldritch_knowledge/base_wax/proc/cast_candle(mob/living/user, obj/item/paper/paper)
	if(GLOB.heretic_ritual_reservations[paper])
		to_chat(user, span_warning("Этот лист уже используется в обряде."))
		return FALSE
	if(!spend_combat_resource(1))
		to_chat(user, span_warning("Для отливки свечи нужен 1 Воск. Запас постепенно восстановится сам."))
		return FALSE
	add_anchor(new /obj/item/candle(get_turf(paper)))
	new /obj/effect/temp_visual/heretic_wax/grasp(get_turf(paper), src)
	user.visible_message(span_warning("[user] сворачивает бумагу в фитиль и покрывает его бледным воском."), span_notice("Вы отливаете свечу, расходуя лист бумаги и 1 Воск."))
	if(ascension_active)
		to_chat(user, span_eldritch("Свеча держит вашу жизнь, пока стоит на полу или столе внутри станции. В счёт идут [HERETIC_WAX_PHYLACTERY_ANCHORS] последние отлитые свечи."))
	qdel(paper)
	return TRUE

/datum/eldritch_knowledge/base_wax/proc/puppet_models(atom/source, mob/living/user)
	. = list()
	var/owner_name = heretic_wax_item_owner(source)
	if(!length(source.fingerprints) && !owner_name)
		return
	for(var/mob/living/carbon/human/candidate as anything in GLOB.human_list)
		if(QDELETED(candidate) || candidate == user || candidate.stat == DEAD || !candidate.mind || !candidate.dna || IS_HERETIC(candidate) || IS_HERETIC_MONSTER(candidate))
			continue
		var/print = md5(candidate.dna.uni_identity)
		if(LAZYACCESS(source.fingerprints, print) || (owner_name && candidate.real_name == owner_name))
			.[print] = candidate

/// Имя владельца на личной вещи: кукла по ней лепится так же, как по отпечаткам.
/proc/heretic_wax_item_owner(atom/item)
	if(istype(item, /obj/item/card/id))
		var/obj/item/card/id/card = item
		return card.registered_name
	if(istype(item, /obj/item/modular_computer))
		var/obj/item/modular_computer/computer = item
		return computer.saved_identification
	return null

/datum/eldritch_knowledge/base_wax/proc/puppet_of(mob/living/model)
	for(var/obj/item/heretic_wax_puppet/puppet as anything in puppets)
		if(puppet.model_ref?.resolve() == model)
			return puppet
	return null

/datum/eldritch_knowledge/base_wax/proc/make_puppet(mob/living/user, obj/item/source)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || istype(source, /obj/item/heretic_wax_puppet))
		return FALSE
	var/list/models = puppet_models(source, user)
	if(!length(models))
		grasp_failure_reason = "На [source] нет отпечатков или имени живого человека с разумом: свои отпечатки и имя не годятся."
		return FALSE
	var/fresh_print
	var/counted_print
	for(var/candidate_print in models)
		if(puppet_of(models[candidate_print]))
			continue
		if(heretic.deed && !(candidate_print in heretic.deed.counted_keys))
			fresh_print ||= candidate_print
		else
			counted_print ||= candidate_print
	if(!fresh_print && !counted_print)
		grasp_failure_reason = "Куклы всех, чьи отпечатки есть на [source], уже у вас."
		return FALSE
	var/print = fresh_print || counted_print
	if(fresh_print)
		var/wait_reason = heretic.deed_wait_reason(fresh_print)
		if(wait_reason)
			if(!counted_print)
				grasp_failure_reason = wait_reason
				return FALSE
			print = counted_print
	var/fresh = print == fresh_print
	var/mob/living/carbon/human/model = models[print]
	while(length(puppets) >= HERETIC_WAX_PUPPET_LIMIT)
		var/obj/item/heretic_wax_puppet/oldest = puppets[1]
		puppets -= oldest
		log_game("[key_name(user)] теряет восковую куклу [oldest.model_name]: её вытеснила новая.")
		qdel(oldest)
	var/turf/place = get_turf(source)
	var/obj/item/heretic_wax_puppet/puppet = new(place, model)
	var/by_prints = LAZYACCESS(source.fingerprints, print)
	puppet.AddComponent(/datum/component/heretic_craft, src, HERETIC_WAX_PUPPET_CRAFT, "Восковая кукла с биркой «[model.real_name]»: её слепили [by_prints ? "по чужим отпечаткам пальцев" : "по чужой вещи с именем"].")
	puppets += puppet
	user.put_in_hands(puppet)
	new /obj/effect/temp_visual/heretic_wax/grasp(place, src)
	user.visible_message(span_warning("[user] сминает в ладони комок бледного воска, и тот принимает форму маленькой фигурки."), span_eldritch("Воск запомнил отпечатки [model.real_name]: кукла у вас в руках. Кукол: [length(puppets)] из [HERETIC_WAX_PUPPET_LIMIT]."))
	log_game("[key_name(user)] лепит восковую куклу [key_name(model)] по [by_prints ? "отпечаткам" : "имени"] на [source] ([source.type]) в [AREACOORD(place)].")
	if(fresh)
		heretic.advance_deed(print, place)
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_wax/on_craft_removed(atom/crafted, craft_id)
	if(craft_id != HERETIC_WAX_PUPPET_CRAFT)
		return
	puppets -= crafted
	if(!QDELETED(crafted))
		qdel(crafted)
	notify_resource_changed()

/datum/eldritch_knowledge/base_wax/proc/prick(mob/living/user, obj/item/heretic_wax_puppet/puppet)
	wax_failure = null
	if(!can_use(user) || !(puppet in puppets) || !user.is_holding(puppet))
		wax_failure = "Держите свою куклу в руке и оставайтесь в своём теле еретика."
		return FALSE
	if(!COOLDOWN_FINISHED(puppet, prick_cooldown))
		wax_failure = "Воск ещё не остыл: ещё [heretic_capture_seconds_left(puppet.prick_cooldown)] с."
		return FALSE
	var/mob/living/carbon/human/model = puppet.model_ref?.resolve()
	if(QDELETED(model) || model.stat == DEAD)
		wax_failure = "Кукла молчит: того, чьи отпечатки в воске, нет среди живых."
		return FALSE
	var/turf/here = get_turf(user)
	var/turf/there = get_turf(model)
	if(!here || !there || here.z != there.z)
		wax_failure = "Кукла не дотягивается: [model.real_name] не на вашем уровне."
		return FALSE
	if(!heretic_can_affect(user, model, chargecost = 0))
		wax_failure = "Кукла холодна: [model.real_name] под защитой от магии."
		return FALSE
	COOLDOWN_START(puppet, prick_cooldown, HERETIC_WAX_PUPPET_PRICK_COOLDOWN)
	to_chat(model, span_warning("Кожу колет тонкой иглой, и у самого уха кто-то шепчет: «Ты у меня в ладонях»."))
	to_chat(user, span_eldritch("Вы колете куклу, и [model.real_name] вздрагивает от укола."))
	log_game("[key_name(user)] колет восковую куклу [key_name(model)].")
	return TRUE

/datum/eldritch_knowledge/base_wax/proc/held_puppet(mob/living/user)
	var/obj/item/heretic_wax_puppet/active = user.get_active_held_item()
	if(istype(active) && (active in puppets))
		return active
	for(var/obj/item/heretic_wax_puppet/puppet in user.held_items)
		if(puppet in puppets)
			return puppet
	return null

/datum/eldritch_knowledge/base_wax/proc/puppet_sleep_block_reason(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/wax_puppet_sleep)
	if(!can_use(user) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/obj/item/heretic_wax_puppet/puppet = held_puppet(user)
	if(!puppet)
		return "Возьмите в руку свою восковую куклу."
	var/mob/living/carbon/human/model = puppet.model_ref?.resolve()
	var/reason = heretic_capture_block_reason(user, model, HERETIC_WAX_CAPTURE)
	if(reason)
		return reason
	var/turf/here = get_turf(user)
	var/turf/there = get_turf(model)
	if(!here || !there || here.z != there.z || get_dist(here, there) > HERETIC_WAX_PUPPET_SLEEP_RANGE)
		return "[model.real_name] должен быть на вашем уровне не дальше [HERETIC_WAX_PUPPET_SLEEP_RANGE] клеток."
	if(model.has_status_effect(/datum/status_effect/heretic_wax_melting))
		return "Кукла [model.real_name] уже тает."
	if(heretic_wax_doused(model))
		return "Вода на коже или в крови [model.real_name] не даёт воску растаять."
	return null

/datum/eldritch_knowledge/base_wax/proc/melt_puppet(mob/living/user)
	wax_failure = puppet_sleep_block_reason(user)
	if(wax_failure)
		return FALSE
	var/obj/item/heretic_wax_puppet/puppet = held_puppet(user)
	var/mob/living/carbon/human/model = puppet.model_ref.resolve()
	if(!model.apply_status_effect(/datum/status_effect/heretic_wax_melting, src, puppet))
		wax_failure = "Кукла не поддалась жару."
		return FALSE
	user.visible_message(span_warning("[user] сжимает в ладони восковую куклу, и та начинает оплывать."), span_eldritch("Кукла [model.real_name] тает: держите её [HERETIC_WAX_PUPPET_SLEEP_CHANNEL / (1 SECONDS)] секунд."))
	log_combat(user, model, "растапливает восковую куклу")
	return TRUE

/datum/eldritch_knowledge/base_wax/proc/dollhouse_block_reason(mob/living/user, obj/item/heretic_wax_puppet/puppet)
	if(!can_use(user) || QDELETED(puppet) || !(puppet in puppets) || !user.is_holding(puppet))
		return "Держите свою куклу в руке и оставайтесь в своём теле еретика."
	var/mob/living/carbon/human/model = puppet.model_ref?.resolve()
	var/datum/status_effect/heretic_capture_knockout/knockout = puppet.doll_sleep
	if(QDELETED(model) || QDELETED(knockout) || knockout.owner != model || !model.IsSleeping())
		return "Кукольный дом закрыт: [puppet.model_name] уже не спит от этой куклы."
	var/turf/here = get_turf(user)
	var/turf/there = get_turf(model)
	if(!here || !there || here.z != there.z || get_dist(here, there) > HERETIC_WAX_PUPPET_SLEEP_RANGE)
		return "[model.real_name] должен быть на вашем уровне не дальше [HERETIC_WAX_PUPPET_SLEEP_RANGE] клеток."
	return null

/datum/eldritch_knowledge/base_wax/proc/dollhouse_holds(mob/living/user, obj/item/heretic_wax_puppet/puppet)
	return !dollhouse_block_reason(user, puppet)

/// Полный сон - только цели охоты, остальных кукла валит в короткую дрёму.
/datum/eldritch_knowledge/base_wax/proc/doll_sleep_time(mob/living/user, mob/living/sleeper)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return (sleeper.mind && sleeper.mind == heretic?.hunt_target) ? HERETIC_WAX_PUPPET_SLEEP_TIME : HERETIC_WAX_PUPPET_DOZE_TIME

/datum/eldritch_knowledge/base_wax/proc/doll_sleep_notice(mob/living/user, mob/living/sleeper)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(sleeper.mind && sleeper.mind == heretic?.hunt_target)
		return "[sleeper.real_name] спит. Используйте куклу в руке: пока длится сон, за [replacetext("[HERETIC_WAX_DOLLHOUSE_TIME / (1 SECONDS)]", ".", ",")] секунды она утянет цель охоты в изнанку. К пробуждению кукла треснет."
	return "[sleeper.real_name] задремал на [HERETIC_WAX_PUPPET_DOZE_TIME / (1 SECONDS)] секунды: полный сон кукла даёт только над целью охоты. К пробуждению кукла треснет."

/// Кукла, пока её человек спит, утягивает спящую цель охоты в изнанку и рассыпается.
/datum/eldritch_knowledge/base_wax/proc/pull_into_dollhouse(mob/living/user, obj/item/heretic_wax_puppet/puppet)
	wax_failure = dollhouse_block_reason(user, puppet)
	if(wax_failure)
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/mob/living/carbon/human/model = puppet.model_ref.resolve()
	if(!heretic?.pocket_pull(user, model, get_turf(model), HERETIC_WAX_DOLLHOUSE_TIME, CALLBACK(src, PROC_REF(dollhouse_holds), user, puppet), "Воск на коже [model] оплывает, и спящего утягивает в крошечную дверцу."))
		return FALSE
	log_combat(user, model, "утягивает в кукольный дом")
	puppet.crack()
	return TRUE

/datum/eldritch_knowledge/base_wax/pocket_exits(mob/living/user)
	. = list()
	for(var/obj/item/candle/candle as anything in anchor_candles)
		if(isturf(candle.loc))
			heretic_add_pocket_exit(., "Свеча - [get_area_name(candle, TRUE)]", heretic_pocket_landing(get_turf(candle)))

/datum/eldritch_knowledge/base_wax/proc/start_leak(mob/living/user)
	wax_failure = heretic_containment_reason(user)
	if(wax_failure)
		return FALSE
	if(leak)
		wax_failure = "Вы уже растеклись воском."
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/wax_leak)
	if(!can_use(user, ignore_grab = TRUE) || QDELETED(required))
		wax_failure = "Протечь недоступна: нужно изучить её, быть в сознании, на полу и в своём теле еретика."
		return FALSE
	if(!user.apply_status_effect(/datum/status_effect/heretic_wax_leak, src))
		wax_failure = "Воск не растёкся."
		return FALSE
	log_game("[key_name(user)] растекается лужицей воска в [AREACOORD(user)].")
	return TRUE

/proc/heretic_wax_doused(mob/living/victim)
	return victim.fire_stacks < 0 || victim.reagents?.has_reagent(/datum/reagent/water) || victim.reagents?.has_reagent(/datum/reagent/water/holywater)

/datum/heretic_deed/wax
	next_step = "В намерении «Помощь» коснитесь Хваткой Мансуса предмета с отпечатками, ID-карты или КПК человека, которого ещё нет в деле."
	name = "Восковые куклы"
	desc = "Лепите Хваткой Мансуса в намерении «Помощь» кукол по чужим отпечаткам пальцев на предметах или по ID-карте и КПК с именем владельца. Каждый человек засчитывается один раз."
	craft_wait_place = "куклу нового человека"
	craft_wait = "не слепить"
	hint = "Кружки, инструменты, ручки и оружие хранят отпечатки тех, кто их держал, а ID-карта и КПК - имя владельца; бумага идёт на свечи. Держатся 2 куклы, новая вытесняет самую старую. Потерянную куклу экипаж узнает по бирке, огонь или нулевой жезл её уничтожают."
	trace_name = "wax seal"
	trace_desc = "Бледный воск застыл в форме ладони с шестью пальцами."
	trace_state = "sigil_wax"

/datum/status_effect/heretic_wax
	id = "heretic_wax"
	duration = 12 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/wax_ref
	var/datum/weakref/knowledge_ref
	var/mutable_appearance/wax_overlay
	var/overlay_state = "wax_mark"

/datum/status_effect/heretic_wax/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_wax/wax, datum/eldritch_knowledge/required)
	wax_ref = WEAKREF(wax)
	knowledge_ref = WEAKREF(required)
	return ..()

/datum/status_effect/heretic_wax/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(QDELETED(wax) || QDELETED(required) || !wax.can_use(wax.wax_body, ignore_leak = TRUE))
		return FALSE
	wax.effects += src
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(update_overlay))
	wax_overlay = mutable_appearance('modular_bluemoon/icons/obj/heretic_wax_effects.dmi', overlay_state, ABOVE_MOB_LAYER)
	wax_overlay.pixel_x = -16
	wax_overlay.pixel_y = -16
	owner.update_icon()
	return TRUE

/datum/status_effect/heretic_wax/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_wax/proc/update_overlay(atom/source, list/overlays)
	SIGNAL_HANDLER
	if(wax_overlay)
		overlays += wax_overlay

/datum/status_effect/heretic_wax/on_remove()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	wax?.effects.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	UnregisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS)
	wax_overlay = null
	owner.update_icon()
	return ..()

/datum/status_effect/heretic_wax/be_replaced()
	on_remove()
	return ..()

/datum/status_effect/heretic_wax/seal
	id = "heretic_wax_seal"
	alert_type = /atom/movable/screen/alert/status_effect/heretic_wax_seal

/datum/status_effect/heretic_wax/clinging
	id = "heretic_wax_clinging"
	duration = 2 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/heretic_wax_clinging

/datum/status_effect/heretic_wax/clinging/on_apply()
	if(!..())
		return FALSE
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_clinging)
	return TRUE

/datum/status_effect/heretic_wax/clinging/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_clinging)
	return ..()

/datum/movespeed_modifier/heretic_wax_clinging
	multiplicative_slowdown = 0.6

/atom/movable/screen/alert/status_effect/heretic_wax_clinging
	name = "Липкий воск"
	desc = "Воск сковывает ваши движения на 2 секунды. Новое попадание волной, оттиском, двойником или процессией обновляет замедление."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "wax_clinging"

/datum/status_effect/heretic_wax/effigy
	id = "heretic_wax_effigy"
	duration = 8 SECONDS
	tick_interval = 0.5 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/heretic_wax_effigy
	var/obj/structure/heretic_wax_effigy/effigy
	var/effigy_capacity

/datum/status_effect/heretic_wax/effigy/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_wax/wax, datum/eldritch_knowledge/required, capacity)
	effigy_capacity = capacity
	return ..(new_owner, wax, required)

/datum/status_effect/heretic_wax/effigy/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref.resolve()
	var/turf/position = get_step(wax.wax_body, get_dir(wax.wax_body, owner))
	if(!wax.tile_open(position))
		position = get_turf(wax.wax_body)
	effigy = new(position, src, effigy_capacity)
	to_chat(wax.wax_body, span_eldritch("Рядом с вами появился золотистый двойник [owner.real_name]. Бейте его своим восковым клинком: до [HERETIC_WAX_EFFIGY_HIT_LIMIT] урона за удар, всего [effigy_capacity], в течение 8 секунд. Сохраняйте открытую линию к цели в пяти клетках."))
	to_chat(owner, span_userdanger("Рядом с еретиком застыл ваш восковой двойник! Его клинок может ранить и замедлить вас через оттиск. Разбейте двойника, скройтесь за преградой или отойдите дальше пяти клеток от него или еретика!"))
	return TRUE

/datum/status_effect/heretic_wax/effigy/proc/validate_link()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	return !QDELETED(src) && !QDELETED(effigy) && wax?.can_use(wax.wax_body) && isturf(owner?.loc) && owner.stat != DEAD && wax.line_clear(wax.wax_body, owner) && wax.line_clear(effigy, owner)

/datum/status_effect/heretic_wax/effigy/tick()
	if(!validate_link())
		qdel(src)

/datum/status_effect/heretic_wax/effigy/on_remove()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	if(wax?.active_effigy == src)
		wax.active_effigy = null
	if(effigy)
		effigy.effect_ref = null
	QDEL_NULL(effigy)
	wax?.notify_resource_changed()
	return ..()

/atom/movable/screen/alert/status_effect/heretic_wax_effigy
	name = "Восковой двойник"
	desc = "Еретик может ранить вас клинком через восковой оттиск в течение 8 секунд. Попадание замедляет на 2 секунды. Разбейте двойника, перекройте связь стеной или отойдите дальше пяти клеток от него или еретика. Оттиск переносит ограниченный урон и расходуется при ударах; антимагия разрывает связь при попадании."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "wax_effigy"

/obj/structure/heretic_wax_effigy
	name = "wax effigy"
	desc = "Холодный воск повторяет чужую фигуру. Ритуальный клинок создателя переносит раны на оригинал и ненадолго замедляет его. Остальные могут разбить оттиск без вреда жертве; нулевой жезл гасит связь сразу."
	anchored = TRUE
	density = FALSE
	max_integrity = HERETIC_WAX_EFFIGY_CAPACITY
	var/datum/weakref/effect_ref

/obj/structure/heretic_wax_effigy/Initialize(mapload, datum/status_effect/heretic_wax/effigy/effect, capacity)
	. = ..()
	if(QDELETED(effect) || QDELETED(effect.owner))
		return INITIALIZE_HINT_QDEL
	effect_ref = WEAKREF(effect)
	appearance = effect.owner.appearance
	name = "wax effigy of [effect.owner.name]"
	desc = "Восковая копия [effect.owner.name], а не живой человек. [initial(desc)]"
	color = HERETIC_WAX_COLOR
	alpha = 200
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	set_light(1, 0.5, HERETIC_WAX_COLOR)
	max_integrity = capacity
	obj_integrity = capacity

/obj/structure/heretic_wax_effigy/examine(mob/user)
	. = ..()
	var/datum/status_effect/heretic_wax/effigy/effect = effect_ref?.resolve()
	if(effect?.owner)
		. += span_notice("Оттиск [effect.owner.real_name]: осталось [obj_integrity] переносимого урона и [round(max(0, effect.duration - world.time) / (1 SECONDS), 0.1)] с. Один удар воскового клинка переносит не больше [HERETIC_WAX_EFFIGY_HIT_LIMIT] урона.")

/obj/structure/heretic_wax_effigy/attackby(obj/item/weapon, mob/living/user, params, attackchain_flags = NONE, damage_multiplier = 1)
	if(istype(weapon, /obj/item/nullrod))
		qdel(src)
		return
	var/datum/status_effect/heretic_wax/effigy/effect = effect_ref?.resolve()
	var/datum/eldritch_knowledge/base_wax/wax = effect?.wax_ref?.resolve()
	if(!istype(weapon, /obj/item/melee/sickly_blade/wax) || user != wax?.wax_body)
		return ..()
	if(!user.Adjacent(src) || !effect.validate_link())
		qdel(effect)
		return
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		return STOP_ATTACK_PROC_CHAIN
	weapon.ApplyAttackCooldown(user, src, attackchain_flags)
	var/mob/living/victim = effect.owner
	if(!heretic_can_affect(user, victim))
		qdel(effect)
		return
	var/damage = min(weapon.force, HERETIC_WAX_EFFIGY_HIT_LIMIT, obj_integrity)
	if(damage <= 0)
		return
	var/damage_before = victim.getBruteLoss()
	victim.adjustBruteLoss(damage)
	if(QDELETED(src) || QDELETED(effect) || QDELETED(victim))
		return
	if(victim.getBruteLoss() > damage_before)
		var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
		heretic?.advance_combat_deed(victim, PATH_WAX)
	wax.harvest(user, victim)
	wax.hinder(victim, effect.knowledge_ref?.resolve())
	log_combat(user, victim, "attacked through a wax effigy with", weapon)
	user.do_attack_animation(src)
	new /obj/effect/temp_visual/heretic_wax/burst(get_turf(victim), wax)
	playsound(src, 'modular_bluemoon/sound/heretic/wax_impact.ogg', 55, TRUE)
	take_damage(damage, BRUTE, MELEE)
	wax.notify_resource_changed()
	return STOP_ATTACK_PROC_CHAIN

/obj/structure/heretic_wax_effigy/Destroy()
	var/datum/status_effect/heretic_wax/effigy/effect = effect_ref?.resolve()
	if(effect)
		effect.effigy = null
		qdel(effect)
	effect_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_wax_seal
	name = "Восковая печать"
	desc = "На вас застыл воск. Снятие оттиска усилится на 12 ушибов и 25 выносливости, а двойник сможет перенести 45 урона вместо 30. Печать исчезнет через 12 секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "wax_sealed"

/datum/status_effect/heretic_wax/attended
	var/list/obj/structure/heretic_wax_candle/candles = list()

/datum/status_effect/heretic_wax/attended/on_apply()
	if(!..())
		return FALSE
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(follow_owner))
	return TRUE

/datum/status_effect/heretic_wax/attended/proc/add_candle(offset = 0)
	var/obj/structure/heretic_wax_candle/candle = new(get_turf(owner), src)
	candle.pixel_x = offset
	candles += candle
	candle.rise_from_floor()
	return candle

/datum/status_effect/heretic_wax/attended/proc/follow_owner(atom/movable/source, atom/old_location, direction, forced)
	SIGNAL_HANDLER
	if(!isturf(owner.loc) || !isturf(old_location) || old_location.z != owner.z || get_dist(old_location, owner) > 1)
		qdel(src)
		return
	for(var/obj/structure/heretic_wax_candle/candle as anything in candles.Copy())
		candle.forceMove(get_turf(owner))

/datum/status_effect/heretic_wax/attended/proc/candle_lost(obj/structure/heretic_wax_candle/candle)
	candles -= candle
	if(!length(candles))
		qdel(src)

/datum/status_effect/heretic_wax/attended/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	for(var/obj/structure/heretic_wax_candle/candle as anything in candles)
		candle.effect_ref = null
	QDEL_LIST(candles)
	return ..()

/datum/status_effect/heretic_wax/shell
	parent_type = /datum/status_effect/heretic_wax/attended
	id = "heretic_wax_shell"
	duration = 20 SECONDS
	overlay_state = "wax_shell"
	var/capacity = HERETIC_WAX_SHELL_CAPACITY
	var/absorbed_hostile = 0

/datum/status_effect/heretic_wax/shell/on_apply()
	if(!..())
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(owner)
	var/datum/eldritch_knowledge/wax_temper/temper = heretic?.get_knowledge(/datum/eldritch_knowledge/wax_temper)
	if(temper)
		capacity += 10 * temper.passive_level
	add_candle()
	RegisterSignal(owner, COMSIG_LIVING_RUN_BLOCK, PROC_REF(absorb_attack))
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_shell)
	to_chat(owner, span_notice("Оболочка примет [capacity] урона. Свечу у ваших ног можно разбить; телепортация гасит её."))
	return TRUE

/datum/status_effect/heretic_wax/shell/proc/absorb_attack(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	if(!real_attack || capacity <= 0 || !length(candles) || !wax?.can_use(source, allow_incapacitated = TRUE) || !(attack_type & (ATTACK_TYPE_MELEE | ATTACK_TYPE_UNARMED | ATTACK_TYPE_PROJECTILE | ATTACK_TYPE_THROWN)))
		return BLOCK_NONE
	if(istype(object, /obj/item/nullrod))
		qdel(src)
		return BLOCK_NONE
	var/damage_type = BRUTE
	if(istype(object, /obj/item/projectile))
		var/obj/item/projectile/projectile = object
		damage_type = projectile.damage_type
	else if(damage == 0 && (attack_type & ATTACK_TYPE_MELEE))
		damage = return_list?[BLOCK_CONTEXT_DAMAGE]
		damage_type = return_list?[BLOCK_CONTEXT_DAMAGE_TYPE]
	else if(isitem(object))
		var/obj/item/weapon = object
		damage_type = weapon.damtype
	if(!damage || damage <= 0)
		return BLOCK_NONE
	var/remaining_damage = max(0, block_calculate_resultant_damage(damage, return_list))
	var/absorbed = min(capacity, remaining_damage)
	if(absorbed <= 0)
		return BLOCK_NONE
	capacity -= absorbed
	if((damage_type == BRUTE || damage_type == BURN) && isliving(attacker) && attacker.mind && attacker.mob_size >= MOB_SIZE_HUMAN && heretic_can_affect(source, attacker, chargecost = 0))
		absorbed_hostile += absorbed
	var/final_damage = remaining_damage - absorbed
	return_list[BLOCK_RETURN_SET_DAMAGE_TO] = final_damage
	return_list[BLOCK_RETURN_MITIGATION_PERCENT] = 100 * (1 - final_damage / damage)
	if(capacity <= 0)
		source.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_shell)
		wax_overlay.alpha = 90
		source.update_icon()
	playsound(source, 'modular_bluemoon/sound/heretic/wax_impact.ogg', 35, TRUE)
	return BLOCK_SHOULD_CHANGE_DAMAGE | (final_damage <= 0 ? BLOCK_SUCCESS : BLOCK_NONE)

/datum/status_effect/heretic_wax/shell/on_remove()
	UnregisterSignal(owner, COMSIG_LIVING_RUN_BLOCK)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_shell)
	return ..()

/datum/movespeed_modifier/heretic_wax_shell
	multiplicative_slowdown = 0.2

/datum/status_effect/heretic_wax/procession
	parent_type = /datum/status_effect/heretic_wax/attended
	id = "heretic_wax_procession"
	duration = 7 SECONDS
	tick_interval = 2 SECONDS
	overlay_state = "wax_procession"
	var/crown = FALSE
	var/pulses = 0

/datum/status_effect/heretic_wax/procession/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_wax/wax, datum/eldritch_knowledge/required, ascended = FALSE)
	crown = ascended
	duration = crown ? 11 SECONDS : 7 SECONDS
	return ..(new_owner, wax, required)

/datum/status_effect/heretic_wax/procession/on_apply()
	if(!..())
		return FALSE
	for(var/index in 1 to (crown ? 5 : 3))
		add_candle((index - (crown ? 3 : 2)) * 7)
	return TRUE

/datum/status_effect/heretic_wax/procession/tick()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	if(!wax?.can_use(owner, ignore_leak = crown) || !length(candles) || (crown && !wax.ascension_active))
		qdel(src)
		return
	for(var/turf/tile in range(2, owner))
		if(!wax.line_clear(owner, tile, 2))
			continue
		new /obj/effect/temp_visual/heretic_wax/burst(tile, wax)
		for(var/mob/living/victim in tile)
			if(!heretic_can_affect(owner, victim))
				continue
			victim.adjustBruteLoss(crown ? 18 : 14)
			if(QDELETED(src) || !wax.can_use(owner, ignore_leak = crown))
				return
			if(QDELETED(victim))
				continue
			victim.adjustStaminaLoss(crown ? 15 : 10)
			wax.seal(victim, crown)
			wax.hinder(victim, knowledge_ref?.resolve(), crown)
			wax.harvest(owner, victim, crown)
	playsound(owner, 'modular_bluemoon/sound/heretic/wax_impact.ogg', 50, TRUE)
	var/mob/living/bearer = owner
	var/crowned = crown
	pulses++
	var/first = pulses == 1
	qdel(candles[1])
	if(crowned)
		heretic_wax_crown_pulse(bearer, first)

/obj/structure/heretic_wax_candle
	name = "funeral candle"
	desc = "Бледная свеча движется за своим хозяином. Разбейте её, чтобы оборвать восковую защиту или сократить процессию. Нулевой жезл гасит её сразу."
	icon = 'modular_bluemoon/icons/obj/heretic_wax.dmi'
	icon_state = "wax_candle"
	anchored = TRUE
	density = FALSE
	max_integrity = 25
	layer = ABOVE_MOB_LAYER
	var/datum/weakref/effect_ref

/obj/structure/heretic_wax_candle/Initialize(mapload, datum/status_effect/heretic_wax/attended/effect)
	. = ..()
	if(!effect)
		return INITIALIZE_HINT_QDEL
	effect_ref = WEAKREF(effect)
	set_light(2, 1, "#eacfa1")

/obj/structure/heretic_wax_candle/attackby(obj/item/weapon, mob/living/user, params)
	if(istype(weapon, /obj/item/nullrod))
		qdel(src)
		return TRUE
	return ..()

/obj/structure/heretic_wax_candle/Moved(atom/old_location, direction, forced = FALSE)
	. = ..()
	var/datum/status_effect/heretic_wax/attended/effect = effect_ref?.resolve()
	if(effect && loc != get_turf(effect.owner))
		qdel(src)

/obj/structure/heretic_wax_candle/Destroy()
	var/datum/status_effect/heretic_wax/attended/effect = effect_ref?.resolve()
	effect_ref = null
	if(!QDELETED(effect))
		effect.candle_lost(src)
	if(isturf(loc))
		new /obj/effect/temp_visual/heretic_wax_melt(loc, appearance)
	return ..()

/datum/status_effect/eldritch/wax
	id = "wax_mark"
	mark_name = "Метка Воска"
	mark_alert_state = "sigil_wax"
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_wax_effects.dmi'
	effect_sprite = "wax_mark"
	detonation_sound = 'modular_bluemoon/sound/heretic/wax_impact.ogg'
	var/datum/weakref/wax_ref
	var/datum/weakref/knowledge_ref

/datum/status_effect/eldritch/wax/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_wax/wax)
	wax_ref = WEAKREF(wax)
	return ..()

/datum/status_effect/eldritch/wax/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(wax?.wax_body)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/wax_mark)
	if(QDELETED(wax) || QDELETED(required))
		return FALSE
	knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	wax.marks += src
	return TRUE

/datum/status_effect/eldritch/wax/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/eldritch/wax/on_remove()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	wax?.marks.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	return ..()

/datum/status_effect/eldritch/wax/on_effect()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	if(wax?.can_use(wax.wax_body) && heretic_can_affect(wax.wax_body, owner, chargecost = 0))
		owner.adjustBruteLoss(8)
		wax.seal(owner)
	return ..()

/obj/item/melee/sickly_blade/wax
	name = "votive snuffer"
	desc = "Ритуальные щипцы с двумя заточенными створками. Между ними дрожит холодный огонь; каждый щелчок шарнира выдавливает из пустоты новую каплю воска."
	icon = 'modular_bluemoon/icons/obj/heretic_wax.dmi'
	icon_state = "wax_blade"
	item_state = "wax_blade"
	route = PATH_WAX
	mark_type = /datum/status_effect/eldritch/wax

/obj/item/heretic_path_relic/wax
	name = "mourner's candelabrum"
	desc = "Канделябр с холодными фитилями. Поглощает вашу оболочку без расхода воска и лечит до 25 ушибов и ожогов суммарно: половину урона, который оболочка действительно приняла от разумного врага. Перезарядка 20 секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_wax.dmi'
	icon_state = "wax_relic"
	item_state = "wax_relic"
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_relics_wax_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_relics_wax_righthand.dmi'

/obj/item/heretic_path_relic/wax/attack_self(mob/living/user)
	return melt(user)

/obj/item/heretic_path_relic/wax/proc/melt(mob/living/user)
	if(!isliving(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	if(!authorized(user) || !wax?.can_use(user) || !COOLDOWN_FINISHED(src, relic_cooldown) || !shell || shell.wax_ref?.resolve() != wax || shell.absorbed_hostile <= 0 || user.getBruteLoss() + user.getFireLoss() <= 0)
		return FALSE
	var/healing = min(HERETIC_WAX_HEAL_LIMIT, shell.absorbed_hostile / 2)
	heretic_heal_pool(user, healing)
	qdel(shell)
	COOLDOWN_START(src, relic_cooldown, 20 SECONDS)
	new /obj/effect/temp_visual/heretic_wax/grasp(get_turf(user), wax)
	playsound(user, 'modular_bluemoon/sound/heretic/wax_cast.ogg', 45, TRUE)
	return TRUE

/obj/effect/temp_visual/heretic_wax
	icon = 'modular_bluemoon/icons/obj/heretic_wax_effects.dmi'
	icon_state = "wax_burst"
	duration = 0.6 SECONDS
	pixel_x = -16
	pixel_y = -16
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	var/datum/weakref/wax_ref

/obj/effect/temp_visual/heretic_wax/Initialize(mapload, datum/eldritch_knowledge/base_wax/wax)
	if(!QDELETED(wax))
		wax_ref = WEAKREF(wax)
		wax.visuals += src
	return ..()

/obj/effect/temp_visual/heretic_wax/Destroy()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	wax?.visuals.Remove(src)
	wax_ref = null
	return ..()

/obj/effect/temp_visual/heretic_wax/grasp
	icon_state = "wax_grasp"

/obj/effect/temp_visual/heretic_wax/burst

/obj/item/heretic_wax_puppet
	name = "wax puppet"
	desc = "Маленькая фигурка из бледного воска с бумажной биркой на шее."
	icon = 'modular_bluemoon/icons/obj/heretic_wax.dmi'
	icon_state = "wax_puppet"
	item_state = "wax_puppet"
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_relics_wax_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_relics_wax_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	var/datum/weakref/model_ref
	var/model_name
	/// Сон, который держит эта кукла: пока он идёт, кукла цела и открывает кукольный дом.
	var/datum/status_effect/heretic_capture_knockout/doll_sleep
	COOLDOWN_DECLARE(prick_cooldown)

/obj/item/heretic_wax_puppet/Initialize(mapload, mob/living/carbon/human/model)
	. = ..()
	if(!istype(model))
		return
	model_ref = WEAKREF(model)
	model_name = model.real_name
	name = "wax puppet ([model_name])"

/obj/item/heretic_wax_puppet/examine(mob/user)
	. = ..()
	if(model_name)
		. += span_notice("На бирке выведено: «[model_name]».")

/obj/item/heretic_wax_puppet/attack_self(mob/living/user)
	var/datum/component/heretic_craft/craft = heretic_craft_on(src, HERETIC_WAX_PUPPET_CRAFT)
	var/datum/eldritch_knowledge/base_wax/wax = craft?.owner_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!wax || heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax) != wax)
		to_chat(user, span_notice("Вы вертите в руках восковую куклу, но ничего не происходит."))
		return FALSE
	if(doll_sleep)
		if(!wax.pull_into_dollhouse(user, src) && wax.wax_failure)
			to_chat(user, span_warning(wax.wax_failure))
		return TRUE
	if(!wax.prick(user, src))
		to_chat(user, span_warning(wax.wax_failure))
		return FALSE
	return TRUE

/obj/item/heretic_wax_puppet/attackby(obj/item/weapon, mob/living/user, params)
	if(weapon.get_temperature())
		melt_away(user)
		return TRUE
	return ..()

/obj/item/heretic_wax_puppet/fire_act(exposed_temperature, exposed_volume)
	melt_away()

/obj/item/heretic_wax_puppet/proc/melt_away(mob/living/user)
	if(QDELETED(src))
		return
	visible_message(span_warning("[src] оплывает от жара и растекается бесформенной каплей воска."))
	log_game("[user ? key_name(user) : "Огонь"] растапливает восковую куклу [model_name || "без бирки"] в [AREACOORD(src)].")
	qdel(src)

/obj/item/heretic_wax_puppet/proc/bind_sleep(datum/status_effect/heretic_capture_knockout/knockout)
	if(QDELETED(knockout))
		crack()
		return
	doll_sleep = knockout
	RegisterSignal(knockout, COMSIG_PARENT_QDELETING, PROC_REF(on_sleep_ended))

/obj/item/heretic_wax_puppet/proc/on_sleep_ended(datum/source)
	SIGNAL_HANDLER
	doll_sleep = null
	crack()

/obj/item/heretic_wax_puppet/proc/crack()
	if(QDELETED(src))
		return
	visible_message(span_warning("[src] трескается и осыпается восковой крошкой."))
	qdel(src)

/obj/item/heretic_wax_puppet/Destroy()
	if(doll_sleep)
		UnregisterSignal(doll_sleep, COMSIG_PARENT_QDELETING)
		doll_sleep = null
	model_ref = null
	return ..()

/datum/status_effect/heretic_wax_melting
	var/held_since = 0
	id = "heretic_wax_melting"
	duration = HERETIC_WAX_PUPPET_SLEEP_CHANNEL
	tick_interval = HERETIC_WAX_PUPPET_CHECK
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_wax_melting
	examine_text = span_warning("SUBJECTPRONOUN обливается потом, от кожи поднимается пар. Вода или нулевой жезл остудят этот жар.")
	var/datum/weakref/wax_ref
	var/mob/living/caster
	var/obj/item/heretic_wax_puppet/puppet
	var/obj/effect/abstract/heretic_particle_holder/steam
	var/applied = FALSE
	var/interrupted = FALSE

/datum/status_effect/heretic_wax_melting/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_wax/wax, obj/item/heretic_wax_puppet/puppet)
	wax_ref = WEAKREF(wax)
	caster = wax?.wax_body
	src.puppet = puppet
	return ..()

/datum/status_effect/heretic_wax_melting/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	if(!. || !wax || QDELETED(caster) || QDELETED(puppet))
		return FALSE
	applied = TRUE
	held_since = world.time
	wax.meltings += src
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(check_hold))
	RegisterSignal(caster, COMSIG_MOVABLE_MOVED, PROC_REF(check_hold))
	RegisterSignal(puppet, COMSIG_MOVABLE_MOVED, PROC_REF(check_hold))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, PROC_REF(interrupt))
	RegisterSignal(caster, COMSIG_PARENT_QDELETING, PROC_REF(interrupt))
	RegisterSignal(puppet, COMSIG_PARENT_QDELETING, PROC_REF(interrupt))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(caster, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))
	steam = heretic_vfx_attach_particles(owner, /particles/heretic_ascension/steam)
	heretic_wax_melt_fx(owner, caster)
	owner.visible_message(span_warning("[owner] вдруг покрывается испариной, от кожи поднимается пар."), span_userdanger("Вас бросает в жар, словно вы тающий воск! Выпейте воды или облейтесь ею, уходите подальше - или через [HERETIC_WAX_PUPPET_SLEEP_CHANNEL / (1 SECONDS)] секунд вы уснёте."))
	return TRUE

/datum/status_effect/heretic_wax_melting/tick()
	check_hold()

/datum/status_effect/heretic_wax_melting/proc/holds()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	if(!wax?.can_use(caster) || QDELETED(puppet) || !caster.is_holding(puppet) || owner.stat == DEAD || heretic_wax_doused(owner))
		return FALSE
	var/turf/here = get_turf(caster)
	var/turf/there = get_turf(owner)
	return here && there && here.z == there.z && get_dist(here, there) <= HERETIC_WAX_PUPPET_SLEEP_RANGE && heretic_can_affect(caster, owner, chargecost = 0)

/datum/status_effect/heretic_wax_melting/proc/check_hold(datum/source)
	SIGNAL_HANDLER
	if(!holds())
		interrupt()

/datum/status_effect/heretic_wax_melting/proc/interrupt(datum/source)
	SIGNAL_HANDLER
	if(QDELETED(src))
		return
	interrupted = TRUE
	owner.visible_message(span_notice("Пар над [owner] рассеивается."), span_notice("Жар отступает."))
	qdel(src)

/datum/status_effect/heretic_wax_melting/proc/on_attackby(atom/source, obj/item/weapon, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(weapon, /obj/item/nullrod))
		return NONE
	log_game("[key_name(user)] обрывает Сон по кукле у [key_name(owner)] нулевым жезлом в [AREACOORD(source)].")
	var/touched_target = source == owner
	interrupt()
	return touched_target ? COMPONENT_NO_AFTERATTACK : NONE

/datum/status_effect/heretic_wax_melting/proc/on_exposed(datum/source, list/exposed, datum/reagents/holder, method)
	SIGNAL_HANDLER
	for(var/datum/reagent/reagent as anything in exposed)
		if(istype(reagent, /datum/reagent/water))
			interrupt()
			return

/datum/status_effect/heretic_wax_melting/on_remove()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_PARENT_ATTACKBY, COMSIG_ATOM_EXPOSE_REAGENTS))
		if(caster)
			UnregisterSignal(caster, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING, COMSIG_PARENT_ATTACKBY))
		if(puppet)
			UnregisterSignal(puppet, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
		heretic_vfx_release_particles(owner, steam)
		wax?.meltings -= src
		// Истёкший срок без срыва отличает досмотренный жар от оборванного.
		var/fell_asleep = !interrupted && wax && world.time >= duration && holds()
		var/sleep_time = fell_asleep ? wax.doll_sleep_time(caster, owner) : 0
		if(fell_asleep)
			owner.Sleeping(sleep_time)
			owner.visible_message(span_warning("[owner] обмякает и засыпает, от кожи поднимается последний пар."), span_userdanger("Жар накрывает с головой, и вы проваливаетесь в сон."))
			log_combat(caster, owner, "усыпляет восковой куклой")
			to_chat(caster, span_eldritch(wax.doll_sleep_notice(caster, owner)))
			puppet.bind_sleep(owner.apply_status_effect(/datum/status_effect/heretic_capture_knockout/wax_doll, wax, HERETIC_WAX_CAPTURE, sleep_time))
		heretic_capture_release(owner, HERETIC_WAX_CAPTURE, sleep_time, fell_asleep ? INFINITY : heretic_capture_held_for(held_since))
	steam = null
	caster = null
	puppet = null
	wax_ref = null
	return ..()

/// Сон по кукле: нулевой жезл по спящему и его смерть обрывают сон, а с ним трескается кукла.
/datum/status_effect/heretic_capture_knockout/wax_doll
	examine_text = span_warning("SUBJECTPRONOUN крепко спит, от кожи тянет тёплым воском. Разбудить можно нулевым жезлом или растолкать за 2 секунды.")

/datum/status_effect/heretic_capture_knockout/wax_doll/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/status_effect/heretic_capture_knockout/wax_doll/on_remove()
	UnregisterSignal(owner, list(COMSIG_PARENT_ATTACKBY, COMSIG_LIVING_DEATH))
	return ..()

/datum/status_effect/heretic_capture_knockout/wax_doll/proc/on_attackby(datum/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	log_game("[key_name(user)] будит спящего по кукле [key_name(owner)] нулевым жезлом в [AREACOORD(owner)].")
	owner.visible_message(span_notice("[user] касается [owner] нулевым жезлом, и восковой сон рассыпается."), span_notice("Вы вздрагиваете и просыпаетесь."))
	owner.SetSleeping(0)
	qdel(src)
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_capture_knockout/wax_doll/proc/on_death(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/atom/movable/screen/alert/status_effect/heretic_wax_melting
	name = "Жар"
	desc = "Вас бросает в жар, словно вы тающий воск: через 5 секунд вы уснёте. Выпейте воды или облейтесь ею, уйдите подальше или пусть вас коснутся нулевым жезлом."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "wax_fever"

/datum/status_effect/heretic_wax_leak
	id = "heretic_wax_leak"
	duration = HERETIC_WAX_LEAK_DURATION
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_wax_leak
	examine_text = span_warning("SUBJECTPRONOUN растёкся лужицей тёплого воска и медленно ползёт по полу.")
	var/datum/weakref/wax_ref
	var/obj/effect/abstract/heretic_wax_puddle/puddle
	var/saved_alpha
	var/granted_godmode = FALSE
	var/applied = FALSE

/datum/status_effect/heretic_wax_leak/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_wax/wax)
	wax_ref = WEAKREF(wax)
	return ..()

/datum/status_effect/heretic_wax_leak/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	if(!. || !wax)
		return FALSE
	applied = TRUE
	wax.leak = src
	if(!(owner.status_flags & GODMODE))
		owner.status_flags |= GODMODE
		granted_godmode = TRUE
	for(var/trait in list(TRAIT_UNPULLABLE, TRAIT_MOBILITY_NOUSE, TRAIT_MOBILITY_NOPICKUP, HERETIC_WAX_LEAK_TRAIT))
		ADD_TRAIT(owner, trait, HERETIC_WAX_LEAK_TRAIT)
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_leak)
	slip_free()
	owner.update_mobility()
	RegisterSignal(owner, COMSIG_MOB_CLICKON, PROC_REF(block_click))
	if(isturf(owner.loc))
		new /obj/effect/temp_visual/heretic_wax_melt(owner.loc, owner.appearance)
	puddle = new(null, owner)
	saved_alpha = owner.alpha
	owner.alpha = 0
	owner.visible_message(span_danger("[owner] оплывает и растекается по полу лужицей тёплого воска!"), span_eldritch("Вы растекаетесь воском: [HERETIC_WAX_LEAK_DURATION / (1 SECONDS)] секунды вас не ранить и не удержать, а двери вам не помеха."))
	playsound(owner, 'modular_bluemoon/sound/heretic/wax_cast.ogg', 50, TRUE)
	return TRUE

/datum/status_effect/heretic_wax_leak/proc/slip_free()
	var/atom/movable/grabber = owner.pulledby
	if(grabber)
		grabber.stop_pulling()
		log_combat(owner, grabber, "вытекает лужицей воска из захвата")
	owner.buckled?.unbuckle_mob(owner, TRUE)
	owner.unbuckle_all_mobs(TRUE)
	owner.stop_pulling()

/datum/status_effect/heretic_wax_leak/proc/block_click(datum/source, atom/target, params)
	SIGNAL_HANDLER
	return COMSIG_MOB_CANCEL_CLICKON

/datum/status_effect/heretic_wax_leak/proc/leave_door()
	var/turf/here = owner.loc
	if(!isturf(here))
		return
	var/inside_door = FALSE
	for(var/obj/machinery/door/door in here)
		if(door.density && !(door.flags_1 & ON_BORDER_1))
			inside_door = TRUE
			break
	if(!inside_door)
		return
	for(var/direction in list(owner.dir, turn(owner.dir, 180), turn(owner.dir, 90), turn(owner.dir, -90)))
		var/turf/exit = get_step(here, direction)
		if(exit && !exit.is_blocked_turf(exclude_mobs = TRUE))
			owner.forceMove(exit)
			return

/datum/status_effect/heretic_wax_leak/on_remove()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	if(wax?.leak == src)
		wax.leak = null
	if(applied)
		UnregisterSignal(owner, COMSIG_MOB_CLICKON)
		for(var/trait in list(TRAIT_UNPULLABLE, TRAIT_MOBILITY_NOUSE, TRAIT_MOBILITY_NOPICKUP, HERETIC_WAX_LEAK_TRAIT))
			REMOVE_TRAIT(owner, trait, HERETIC_WAX_LEAK_TRAIT)
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_leak)
		if(granted_godmode)
			owner.status_flags &= ~GODMODE
		owner.alpha = saved_alpha
		QDEL_NULL(puddle)
		if(!QDELETED(owner))
			owner.update_mobility()
			leave_door()
			owner.visible_message(span_warning("Лужица воска вздымается и снова становится [owner]."), span_notice("Воск собирается обратно в тело."))
	wax_ref = null
	return ..()

/datum/movespeed_modifier/heretic_wax_leak
	multiplicative_slowdown = HERETIC_WAX_LEAK_SLOWDOWN

/atom/movable/screen/alert/status_effect/heretic_wax_leak
	name = "Лужица воска"
	desc = "Вы растеклись воском на 4 секунды: неуязвимы и медленнее, проползаете под дверями и шлюзами, но ничего не можете делать."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "wax_puddle"

/obj/effect/abstract/heretic_wax_puddle
	vis_flags = VIS_INHERIT_ID | VIS_INHERIT_PLANE
	var/datum/weakref/host_ref

/obj/effect/abstract/heretic_wax_puddle/Initialize(mapload, atom/movable/host)
	. = ..()
	if(QDELETED(host))
		return INITIALIZE_HINT_QDEL
	host_ref = WEAKREF(host)
	appearance = host.appearance
	appearance_flags = RESET_ALPHA | RESET_COLOR | RESET_TRANSFORM | KEEP_TOGETHER | PIXEL_SCALE
	vis_flags = initial(vis_flags)
	mouse_opacity = MOUSE_OPACITY_ICON
	layer = FLOAT_LAYER
	plane = FLOAT_PLANE
	pixel_x = 0
	pixel_y = 0
	color = HERETIC_WAX_COLOR
	alpha = HERETIC_WAX_PUDDLE_ALPHA
	var/matrix/melted = matrix()
	melted.Scale(HERETIC_WAX_PUDDLE_SPREAD, HERETIC_WAX_PUDDLE_SQUASH)
	melted.Translate(0, -HERETIC_WAX_PUDDLE_SINK)
	transform = melted
	host.vis_contents += src

/obj/effect/abstract/heretic_wax_puddle/Destroy()
	var/atom/movable/host = host_ref?.resolve()
	if(host)
		host.vis_contents -= src
	host_ref = null
	return ..()

/obj/machinery/door/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(!. && mover && !poddoor && !(resistance_flags & INDESTRUCTIBLE) && !istype(src, /obj/machinery/door/password) && HAS_TRAIT(mover, HERETIC_WAX_LEAK_TRAIT))
		return TRUE

/obj/machinery/door/window/CheckExit(atom/movable/mover, turf/target)
	return ..() || HAS_TRAIT(mover, HERETIC_WAX_LEAK_TRAIT)

/obj/machinery/door/firedoor/border_only/CheckExit(atom/movable/mover, turf/target)
	return ..() || HAS_TRAIT(mover, HERETIC_WAX_LEAK_TRAIT)

/obj/effect/proc_holder/spell/can_cast(mob/user = usr, skipcharge = FALSE, silent = FALSE)
	if(user && HAS_TRAIT(user, HERETIC_WAX_LEAK_TRAIT))
		return heretic_check(user, FALSE, silent, "Лужица воска не колдует: дождитесь, пока тело соберётся.")
	return ..()

/mob/living/execute_mode(obj/item/expected_item, expected_active_hand_index, force = FALSE)
	if(HAS_TRAIT(src, HERETIC_WAX_LEAK_TRAIT))
		return FALSE
	return ..()

/datum/eldritch_knowledge/wax_grasp
	name = "Тёплый оттиск"
	summary = "Хватка оставляет на враге восковую печать на 12 секунд."
	details = list(
		"Печать усиливает Снятие оттиска: +12 ушибов, +25 выносливости и двойник на 45 урона вместо 30.",
		"Хватка по живому разумному врагу даёт единицу воска, общая задержка с боевыми попаданиями 6 секунд.",
	)
	role = HERETIC_ROLE_GRASP
	gain_text = "Ладонь запомнила лицо лучше, чем глаза."
	cost = 1
	route = PATH_WAX

/datum/eldritch_knowledge/wax_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(!proximity_flag || !wax?.can_use(user) || !user.Adjacent(target) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	wax.seal(target)
	wax.harvest(user, target)
	return TRUE

/datum/eldritch_knowledge/spell/wax_shell
	name = "Погребальная оболочка"
	summary = "За 2 воска оболочка на 20 секунд принимает 45 урона; свеча и серебро дают канделябр."
	details = list(
		"Оболочка принимает удары, пули, броски и дубинки, лишний урон проходит; в ней вы чуть медленнее.",
		"У ног горит свеча на 25 прочности: её разрушение или телепортация снимают оболочку.",
		"Нулевой жезл проходит насквозь и гасит оболочку. Повтор за 2 воска даёт свежую, перезарядка 18 секунд.",
		"«Снять печать» в «Разоружении» тратит оболочку на веер в 5 клеток: 2/3 её остатка, но не больше 30 ушибов.",
		"Свеча и лист серебра на руне дают канделябр, он один на путь.",
		"Канделябр в руке съедает оболочку и лечит половину урона, принятого ею от разумных врагов, до 25.",
		"Перезарядка канделябра 20 секунд; неизрасходованная защита не лечит.",
	)
	role = HERETIC_ROLE_DEFENSE
	ritual_hint = "Свечу можно отлить из листа бумаги на полу Хваткой Мансуса за 1 Воск."
	gain_text = "Я отлил себе вторую кожу. Она знала, каково это — умереть."
	cost = 1
	route = PATH_WAX
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_wax/shell
	required_atoms = list(/obj/item/candle, /obj/item/stack/sheet/mineral/silver)
	result_atoms = list(/obj/item/heretic_path_relic/wax)

/datum/eldritch_knowledge/spell/wax_shell/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/spell/wax_shell/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/wax)

/datum/eldritch_knowledge/spell/wax_shell/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	wax?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/wax_mark
	name = "Метка Воска"
	summary = "Хватка ставит метку на 15 секунд, удар восковым клинком её взрывает."
	details = list(
		"Взрыв наносит 8 ушибов и оставляет восковую печать.",
		"Взрыв по живому разумному врагу даёт единицу воска, общая задержка с боевыми попаданиями 6 секунд.",
	)
	role = HERETIC_ROLE_MARK
	gain_text = "Воск закрыл имя, но сохранил его очертания."
	cost = 2
	route = PATH_WAX

/datum/eldritch_knowledge/wax_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(!proximity_flag || !wax?.can_use(user) || !user.Adjacent(target) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/wax, wax)
	return TRUE

/datum/eldritch_knowledge/wax_mark/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(wax)
		QDEL_LIST(wax.marks)

/datum/eldritch_knowledge/spell/wax_puppet_sleep
	name = "Сон по кукле"
	summary = "Со своей куклой в руке растопите её 5 секунд: цель охоты в 9 клетках уснёт на 8 секунд."
	details = list(
		"Человек должен быть на вашем уровне не дальше 9 клеток; стены не мешают. Кто не цель охоты, лишь задремлет на 3 секунды.",
		"Он сразу чувствует жар, над ним поднимается пар; кукла всё это время должна быть у вас в руке.",
		"Жар срывается, если человек уйдёт дальше 9 клеток, намокнет, выпьет воды или его либо вас тронут нулевым жезлом.",
		"Уснувший готов к обряду. Его можно разбудить нулевым жезлом или растолкать за 2 секунды; вода сон уже не рвёт.",
		"Спящую цель охоты кукла в руке за 1,5 секунды утягивает в изнанку из 9 клеток; когда спящий проснётся, кукла треснет.",
		"После попытки человек до 60 секунд невосприимчив к Сну и 15 секунд к любому захвату; если уснул - считая с пробуждения.",
		"Защита от магии спасает. Перезарядка 60 секунд.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Воск помнил тепло чужих пальцев. Стоило его согреть, и хозяин пальцев засыпал."
	cost = 2
	route = PATH_WAX
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_wax/puppet_sleep

/datum/eldritch_knowledge/spell/wax_puppet_sleep/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(wax)
		QDEL_LIST(wax.meltings)
	return ..()

/datum/eldritch_knowledge/spell/wax_leak
	name = "Протечь"
	summary = "На 4 секунды вы становитесь лужицей воска и проползаете под закрытыми дверями."
	details = list(
		"Лужица неуязвима, но медленнее вас и ничего не может: ни бить, ни колдовать, ни трогать вещи в руках.",
		"Проходит под дверями, шлюзами даже на болтах, пожарными заслонками и стеклянными дверцами.",
		"Стены, окна, гермозаслоны, ставни, неразрушимые и кодовые двери лужицу не пускают.",
		"Работает и в чужом захвате: лужица выскальзывает из рук, её не схватить.",
		"Если лужица застыла в проёме двери, вы выходите на соседнюю свободную клетку.",
		"Обычная процессия под лужицей гаснет, Бессмертная процессия горит дальше.",
		"Наручники и щит разума не дают растечься. Перезарядка 60 секунд.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "Дверь заперли на засов. Воску не нужна дверь, ему хватит щели."
	cost = 1
	route = PATH_WAX
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_wax/leak

/datum/eldritch_knowledge/spell/wax_leak/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(wax)
		QDEL_NULL(wax.leak)
	return ..()

/datum/eldritch_knowledge/spell/wax_imprint
	name = "Снятие оттиска"
	summary = "За 1 Воск бьёт цель в 5 клетках на 14 ушибов и ставит рядом с вами её двойника на 8 секунд."
	details = list(
		"Цель замедляется на 2 секунды; удар вашего клинка по двойнику переносит на неё до 15 ушибов.",
		"Двойник переносит всего 30 урона; если на цели ваша печать - 45, а оттиск бьёт ещё на 12 ушибов и 25 выносливости.",
		"Двойник один: новый оттиск заменяет старый.",
		"Связь рвётся за стеной, от антимагии или если цель отойдёт дальше 5 клеток от вас или двойника.",
		"Двойника может разбить кто угодно, нулевой жезл гасит его сразу. Перезарядка 14 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Достаточно потянуть за край, чтобы форма рассталась с содержимым."
	cost = 1
	route = PATH_WAX
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_wax/imprint

/datum/eldritch_knowledge/spell/wax_imprint/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	wax?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/wax_temper
	name = "Тройной фитиль"
	summary = "Запас воска растёт до 6, новые оболочки принимают 55 урона."
	details = list(
		"Улучшение не заполняет запас и не чинит уже созданную оболочку.",
		"Уровни: вместимость 6 / 7 / 8, оболочка 55 / 65 / 75.",
	)
	role = HERETIC_ROLE_PASSIVE
	gain_text = "Я сплёл фитили так, чтобы ни один не мог догореть в одиночестве."
	cost = 2
	route = PATH_WAX
	passive_values = list(6, 7, 8)
	passive_desc = "Вместимость 6 / 7 / 8, поглощение новых оболочек 55 / 65 / 75. Уже созданная защита не восстанавливается."
	var/datum/weakref/wax_ref

/datum/eldritch_knowledge/wax_temper/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(wax)
		wax_ref = WEAKREF(wax)
		wax.update_temper()

/datum/eldritch_knowledge/wax_temper/on_passive_upgrade(mob/living/user)
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	wax?.update_temper()

/datum/eldritch_knowledge/wax_temper/on_lose(mob/user)
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	wax?.update_temper(ignore_temper = TRUE)
	return ..()

/datum/eldritch_knowledge/wax_temper/Destroy()
	var/datum/eldritch_knowledge/base_wax/wax = wax_ref?.resolve()
	wax?.update_temper(ignore_temper = TRUE)
	wax_ref = null
	return ..()

/datum/eldritch_knowledge/spell/wax_procession
	name = "Погребальная процессия"
	summary = "За 2 воска три свечи идут за вами и бьют врагов в 2 клетках."
	details = list(
		"Первая свеча гаснет сразу, остальные - через 2 и 4 секунды.",
		"Каждый импульс: 14 ушибов, 10 выносливости, замедление на 2 секунды и восковая печать.",
		"Если свечу разбить, импульсов будет на один меньше.",
		"Стены закрывают цели, телепортация обрывает процессию. Перезарядка 35 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Процессия шла за пустым гробом. Я понял, для кого оставили место."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_WAX
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_wax/procession

/datum/eldritch_knowledge/spell/wax_procession/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	wax?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/final_eldritch/wax_final
	name = "Последний плакальщик"
	summary = "Стойкость вознесения, запас воска 8, Бессмертная процессия, а свечи держат вашу жизнь."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; обряд длится 30 секунд.",
		"Запас вмещает 8 и возвращается по единице каждые 4 секунды.",
		"Бессмертная процессия бесплатна: 5 свечей по 18 ушибов и 15 выносливости в 2 клетках, перезарядка 45 секунд.",
		"Раз в 5 минут в крите или при смерти вы встаёте у ближайшей из 3 последних бумажных свечей с половиной здоровья.",
		"Свеча держит жизнь, только если стоит на полу или столе внутри станции на вашем уровне; тело должно лежать на полу.",
		"Разорванное, обращённое в прах или лишённое мозга, сердца или лёгких тело не встаёт.",
		"Свечи обведены золотом: экипаж разбивает их ударом, огнём или нулевым жезлом.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Погребальная песня закончилась. Я остался, чтобы встретить тех, кто ещё не родился. Пока горят мои свечи, в гроб ложится только воск."
	route = PATH_WAX
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_wax/crown)
	var/datum/weakref/wax_knowledge_ref
	var/phylactery_timer
	COOLDOWN_DECLARE(phylactery_cooldown)

/datum/eldritch_knowledge/final_eldritch/wax_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(!wax)
		return
	wax_knowledge_ref = WEAKREF(wax)
	wax.ascension_active = TRUE
	wax.update_temper()
	wax.update_anchor_marks()
	RegisterSignal(user, COMSIG_LIVING_DEATH, PROC_REF(on_phylactery_death), override = TRUE)
	RegisterSignal(user, COMSIG_MOB_STATCHANGE, PROC_REF(on_phylactery_stat), override = TRUE)

/datum/eldritch_knowledge/final_eldritch/wax_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	if(body)
		UnregisterSignal(body, list(COMSIG_LIVING_DEATH, COMSIG_MOB_STATCHANGE))
	var/datum/eldritch_knowledge/base_wax/wax = wax_knowledge_ref?.resolve()
	if(wax)
		wax.ascension_active = FALSE
		wax.clear_wax()
		wax.update_temper()
		wax.update_anchor_marks()
	return ..()

/datum/eldritch_knowledge/final_eldritch/wax_final/on_ascended_examine(datum/source, mob/examiner, list/examine_list)
	. = ..()
	var/datum/eldritch_knowledge/base_wax/wax = wax_knowledge_ref?.resolve()
	if(!wax)
		return
	var/anchors = wax.count_anchors(source)
	if(!anchors)
		examine_list += span_notice("Ни одна восковая свеча на этом уровне не держит жизнь этого тела: сейчас оно падёт насовсем.")
	else if(!COOLDOWN_FINISHED(src, phylactery_cooldown))
		examine_list += span_notice("Восковые свечи ещё не остыли после прошлого возвращения: сейчас это тело падёт насовсем.")
	else
		examine_list += span_warning("Жизнь этого тела держат восковые свечи (свечей на этом уровне: [anchors]). Упав в крит или умерев, оно оплывёт восковой куклой и поднимется у ближайшей. Сначала найдите и разбейте свечи.")

/datum/eldritch_knowledge/final_eldritch/wax_final/proc/on_phylactery_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	if(!gibbed)
		schedule_phylactery(source)
		return
	deltimer(phylactery_timer)
	phylactery_timer = null

/datum/eldritch_knowledge/final_eldritch/wax_final/proc/on_phylactery_stat(mob/living/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(source.InFullCritical())
		schedule_phylactery(source)

/datum/eldritch_knowledge/final_eldritch/wax_final/proc/schedule_phylactery(mob/living/body)
	var/datum/eldritch_knowledge/base_wax/wax = wax_knowledge_ref?.resolve()
	if(phylactery_timer || !COOLDOWN_FINISHED(src, phylactery_cooldown) || !wax?.nearest_anchor(body))
		return
	// Смерть ещё не завершила death(): возвращение идёт следующим тиком.
	phylactery_timer = addtimer(CALLBACK(src, PROC_REF(rise_at_anchor), WEAKREF(body)), world.tick_lag, TIMER_STOPPABLE)

/datum/eldritch_knowledge/final_eldritch/wax_final/proc/rise_at_anchor(datum/weakref/body_ref)
	phylactery_timer = null
	var/mob/living/carbon/body = body_ref.resolve()
	var/datum/eldritch_knowledge/base_wax/wax = wax_knowledge_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(body)
	if(!istype(body) || !wax || !finished || !heretic || heretic.role_removed || heretic.get_knowledge(type) != src || !COOLDOWN_FINISHED(src, phylactery_cooldown))
		return FALSE
	if(!isturf(body.loc) || body.suiciding || !has_vital_organs(body) || (body.stat != DEAD && !body.InFullCritical()))
		return FALSE
	var/obj/item/candle/anchor = wax.nearest_anchor(body)
	if(!anchor)
		return FALSE
	var/turf/fall_spot = get_turf(body)
	var/fallen_look = body.appearance
	var/fallen_name = body.name
	mend_phylactery_body(body)
	if(body.stat == DEAD && !body.revive())
		return FALSE
	COOLDOWN_START(src, phylactery_cooldown, HERETIC_WAX_PHYLACTERY_COOLDOWN)
	var/turf/destination = get_turf(anchor)
	var/anchor_look = anchor.appearance
	qdel(anchor)
	var/obj/effect/temp_visual/heretic_wax_doll/doll = new(fall_spot, fallen_look, fallen_name, get_area_name(destination))
	doll.visible_message(span_danger("[fallen_name] оплывает воском: на полу остаётся пустая восковая кукла!"))
	playsound(doll, 'modular_bluemoon/sound/heretic/wax_cast.ogg', 60, TRUE)
	body.buckled?.unbuckle_mob(body, force = TRUE)
	body.unbuckle_all_mobs(force = TRUE)
	body.pulledby?.stop_pulling()
	body.stop_pulling()
	body.forceMove(destination)
	if(applied_body != body)
		on_body_gain(body)
	body.grab_ghost()
	body.visible_message(span_danger("Восковая свеча оплывает, и из её воска поднимается [body]!"), span_eldritch("Воск свечи принимает вас обратно. Следующее возвращение возможно не раньше чем через [DisplayTimeText(HERETIC_WAX_PHYLACTERY_COOLDOWN)]."))
	playsound(body, 'modular_bluemoon/sound/heretic/wax_ascend.ogg', 60, TRUE)
	log_game("[key_name(body)] returned to a wax candle at [AREACOORD(destination)].")
	heretic_wax_rise_fx(body, fall_spot, destination, anchor_look)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/wax_final/proc/has_vital_organs(mob/living/carbon/body)
	if(!body.getorganslot(ORGAN_SLOT_BRAIN) || (body.needs_heart() && !body.getorganslot(ORGAN_SLOT_HEART)))
		return FALSE
	return HAS_TRAIT_FROM(body, TRAIT_NOBREATH, SPECIES_TRAIT) || body.getorganslot(ORGAN_SLOT_LUNGS)

/datum/eldritch_knowledge/final_eldritch/wax_final/proc/mend_phylactery_body(mob/living/carbon/body)
	body.setOxyLoss(0, FALSE)
	body.setToxLoss(0, FALSE, TRUE)
	body.setCloneLoss(0, FALSE)
	body.updatehealth()
	// Предел считается от здоровья вознесения: при смерти база уже снята и вернётся после оживления.
	var/kept = max(body.maxHealth, HERETIC_ASCENDED_MAX_HEALTH) * (1 - HERETIC_WAX_PHYLACTERY_HEALTH)
	var/wounds = body.maxHealth - body.health
	if(wounds > kept)
		var/healed_share = 1 - kept / wounds
		for(var/obj/item/bodypart/part as anything in body.bodyparts)
			part.heal_damage(part.brute_dam * healed_share, part.burn_dam * healed_share, only_organic = FALSE, updating_health = FALSE, forced = TRUE)
		body.update_damage_overlays()
	// updatehealth() выше снова делает хаском мёртвое тело с тяжёлыми ожогами, лечим после снижения урона.
	body.cure_husk()
	for(var/obj/item/organ/organ as anything in body.internal_organs)
		organ.setOrganDamage(min(organ.damage, organ.maxHealth * HERETIC_WAX_PHYLACTERY_HEALTH))
	body.set_heartattack(FALSE)
	body.blood_volume = max(body.blood_volume, BLOOD_VOLUME_SAFE)
	body.ExtinguishMob()
	body.bodytemperature = BODYTEMP_NORMAL
	body.SetSleeping(0, FALSE)
	body.remove_CC(FALSE)
	body.set_resting(FALSE, TRUE, FALSE)
	body.updatehealth()
	body.update_mobility()

/obj/effect/temp_visual/heretic_wax_doll
	name = "wax doll"
	desc = "Оплывшая восковая кукла в человеческий рост. Тот, кого она повторяет, ушёл к одной из своих свечей; кукла скоро растает."
	duration = HERETIC_WAX_PHYLACTERY_DOLL_TIME
	randomdir = FALSE
	var/destination_name

/obj/effect/temp_visual/heretic_wax_doll/Initialize(mapload, fallen_look, fallen_name, destination_name)
	. = ..()
	src.destination_name = destination_name
	if(!fallen_look)
		return
	appearance = fallen_look
	name = "wax doll of [fallen_name]"
	desc = initial(desc)
	color = HERETIC_WAX_COLOR
	alpha = 200
	filters = null
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	melt_down()

/obj/effect/temp_visual/heretic_wax_doll/examine(mob/user)
	. = ..()
	if(destination_name)
		. += span_warning("Восковые капли ещё тёплые: тот, кого она повторяет, поднялся у своей свечи в секторе «[destination_name]».")

/obj/effect/proc_holder/spell/self/heretic_wax
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_wax/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	return ..() && heretic_check(user, wax?.can_use(user, ignore_grab = usable_while_grabbed), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_wax/release
	name = "Снять печать"
	desc = "За единицу воска немедленно поразите веер в трёх клетках перед собой: 18 ушибов, 20 выносливости, замедление на 2 секунды и восковая печать. В намерении «Разоружить» вместо заряда расходует всю погребальную оболочку: веер достигает пяти клеток и наносит две трети оставшейся прочности, до 30 ушибов, без печати и замедления. Запас лечения оболочки также теряется."
	summary = "За 1 Воск бьёт веером на 3 клетки: 18 ушибов, замедление и печать; в «Разоружении» тратит оболочку."
	action_icon_state = "wax_release"
	charge_max = 10 SECONDS

/obj/effect/proc_holder/spell/self/heretic_wax/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(!wax?.release(user, consume_shell = user.a_intent == INTENT_DISARM))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_wax/shell
	name = "Погребальная оболочка"
	desc = "За два воска создайте конечную защиту на 20 секунд. Повторное применение восстанавливает её до полной прочности. Свеча принимает удары; её разрушение или телепортация гасят защиту. «Снять печать» в намерении «Разоружить» превращает оставшуюся оболочку в атакующий веер, расходуя защиту и запас лечения."
	summary = "За 2 воска оболочка на 20 секунд принимает 45 урона."
	action_icon_state = "wax_shell"
	charge_max = 18 SECONDS

/obj/effect/proc_holder/spell/self/heretic_wax/shell/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(!wax?.raise_shell(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_wax/puppet_sleep
	name = "Растопить куклу"
	desc = "Держите в руке свою восковую куклу: человек в 9 клетках на вашем уровне 5 секунд чувствует жар и затем спит 8 секунд, если это цель охоты, иначе дремлет 3 секунды. Жар обрывается, если человек намокнет, выпьет воды, уйдёт дальше 9 клеток или его либо вас тронут нулевым жезлом. Спящего можно разбудить нулевым жезлом или растолкать за 2 секунды, вода сон уже не рвёт. Пока человек спит, кукла цела: спящую цель охоты она в руке за 1,5 секунды утянет в изнанку и рассыплется, а иначе треснет, когда он проснётся. Перезарядка 60 секунд."
	summary = "Кукла в руке: через 5 секунд жара цель охоты в 9 клетках спит 8 секунд, другие дремлют 3."
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "wax_puppet"
	charge_max = HERETIC_WAX_PUPPET_SLEEP_COOLDOWN

/obj/effect/proc_holder/spell/self/heretic_wax/puppet_sleep/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(!wax?.melt_puppet(user))
		heretic_revert_cast(user, wax?.wax_failure)

/obj/effect/proc_holder/spell/self/heretic_wax/leak
	name = "Протечь"
	desc = "На 4 секунды станьте лужицей воска: вы неуязвимы и медленнее, проходите под закрытыми дверями и шлюзами, но не сквозь стены, окна, гермозаслоны и неразрушимые двери, и ничего не можете делать. Работает в чужом захвате, но не в наручниках и не под щитом разума. Перезарядка 60 секунд."
	summary = "4 секунды вы неуязвимая лужица воска и проползаете под дверями и шлюзами."
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "wax_leak"
	charge_max = HERETIC_WAX_LEAK_COOLDOWN
	usable_while_grabbed = TRUE

/obj/effect/proc_holder/spell/self/heretic_wax/leak/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(!wax?.start_leak(user))
		heretic_revert_cast(user, wax?.wax_failure)

/obj/effect/proc_holder/spell/self/heretic_wax/procession
	name = "Погребальная процессия"
	desc = "За два воска три разрушаемые свечи поражают врагов рядом: первая сразу, остальные следуют за вами и гаснут с интервалом две секунды."
	summary = "За 2 воска три свечи бьют врагов в 2 клетках по 14 ушибов."
	action_icon_state = "wax_procession"
	charge_max = 35 SECONDS

/obj/effect/proc_holder/spell/self/heretic_wax/procession/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(!wax?.procession(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_wax/crown
	name = "Бессмертная процессия"
	desc = "Пять разрушаемых свечей наносят по 18 ушибов и 15 выносливости в двух клетках: первая сразу, остальные следуют за вами и гаснут с интервалом две секунды."
	summary = "Бесплатно пять свечей бьют врагов в 2 клетках по 18 ушибов."
	action_icon_state = "wax_ascend"
	charge_max = 45 SECONDS

/obj/effect/proc_holder/spell/self/heretic_wax/crown/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	return ..() && heretic_check(user, wax?.ascension_active, silent, "Сначала завершите вознесение этого пути.")

/obj/effect/proc_holder/spell/self/heretic_wax/crown/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(!wax?.procession(user, TRUE))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_wax/imprint
	name = "Снятие оттиска"
	desc = "За единицу воска нанесите 14 ушибов и создайте двойника на 8 секунд. Цель замедляется на 2 секунды. Удары вашего воскового клинка по двойнику переносят до 15 ушибов за удар, до 30 суммарно, и обновляют замедление. Печать добавляет 12 ушибов и 25 выносливости сразу и укрепляет двойника до 45. Двойника можно разбить; стены, антимагия и расстояние больше пяти клеток рвут связь."
	summary = "За 1 Воск бьёт цель в 5 клетках на 14 ушибов и ставит её двойника рядом с вами на 8 секунд."
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "wax_imprint"
	action_background_icon_state = "bg_ecult"
	range = HERETIC_WAX_RANGE
	selection_type = "view"
	aim_assist = FALSE
	charge_max = 14 SECONDS
	active_msg = "Укажите живую цель для снятия оттиска."
	deactive_msg = "Воск снова застывает."

/obj/effect/proc_holder/spell/pointed/heretic_wax/imprint/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	return heretic_check(user, wax?.can_use(user) && wax.combat_resource >= 1 && wax.line_clear(user, target) && heretic_can_affect(user, target, chargecost = 0), silent, "Нужны 1 Воск и видимый противник без защиты от магии; стены перекрывают путь.", target = target)

/obj/effect/proc_holder/spell/pointed/heretic_wax/imprint/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_wax/wax = heretic?.get_knowledge(/datum/eldritch_knowledge/base_wax)
	if(!length(targets) || !isliving(targets[1]) || !wax?.imprint(user, targets[1]))
		heretic_revert_cast(user)

#undef HERETIC_WAX_RANGE
#undef HERETIC_WAX_RELEASE_RANGE
#undef HERETIC_WAX_RECOVERY
#undef HERETIC_WAX_HARVEST
#undef HERETIC_WAX_SHELL_COST
#undef HERETIC_WAX_SHELL_CAPACITY
#undef HERETIC_WAX_HEAL_LIMIT
#undef HERETIC_WAX_IMPRINT_DAMAGE
#undef HERETIC_WAX_EFFIGY_CAPACITY
#undef HERETIC_WAX_EFFIGY_SEALED_CAPACITY
#undef HERETIC_WAX_EFFIGY_HIT_LIMIT
#undef HERETIC_WAX_SHELL_RELEASE_LIMIT
#undef HERETIC_WAX_SHELL_RELEASE_FRACTION
#undef HERETIC_WAX_COLOR
#undef HERETIC_WAX_ANCHOR_FILTER
#undef HERETIC_WAX_PUPPET_CRAFT
#undef HERETIC_WAX_CAPTURE
#undef HERETIC_WAX_PUPPET_CHECK
#undef HERETIC_WAX_LEAK_TRAIT
#undef HERETIC_WAX_LEAK_SLOWDOWN
#undef HERETIC_WAX_PUDDLE_SPREAD
#undef HERETIC_WAX_PUDDLE_SQUASH
#undef HERETIC_WAX_PUDDLE_SINK
#undef HERETIC_WAX_PUDDLE_ALPHA
