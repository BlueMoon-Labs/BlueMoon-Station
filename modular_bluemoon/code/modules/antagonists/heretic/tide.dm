#define HERETIC_TIDE_RANGE 5
#define HERETIC_TIDE_CHANNEL_MOVEMENT 2
#define HERETIC_TIDE_WAVE_RADIUS 2
#define HERETIC_TIDE_RELEASE_COST 2
#define HERETIC_TIDE_HARVEST_TIME (6 SECONDS)
#define HERETIC_TIDE_WELL_LIFETIME (12 SECONDS)
#define HERETIC_TIDE_WELL_INTERVAL (2 SECONDS)
#define HERETIC_TIDE_ASCENDED_CAPACITY 8
#define HERETIC_TIDE_PUDDLE_TIME (15 SECONDS)
#define HERETIC_TIDE_PRESSURE_INTERVAL (12 SECONDS)
#define HERETIC_TIDE_COLLISION_DAMAGE 8
#define HERETIC_TIDE_PUDDLE_RISE (0.3 SECONDS)
#define HERETIC_TIDE_PUDDLE_DRAIN (0.6 SECONDS)
#define HERETIC_TIDE_PUDDLE_DRAIN_SCALE 0.85
#define HERETIC_TIDE_STEP_SPLASH_COOLDOWN (0.3 SECONDS)
#define HERETIC_TIDE_SWELL_TIME (0.6 SECONDS)
#define HERETIC_TIDE_VOICE_WAVE_TIME (0.9 SECONDS)
#define HERETIC_TIDE_VOICE_FLASH_RANGE 5
#define HERETIC_TIDE_VOICE_FLASH_POWER 1.5
#define HERETIC_TIDE_VOICE_FLASH_TIME (0.5 SECONDS)
#define HERETIC_TIDE_VOICE_QUAKE 0.15
#define HERETIC_TIDE_VOICE_QUAKE_RADIUS 7
#define HERETIC_TIDE_VOICE_QUAKE_TIME (0.4 SECONDS)
#define HERETIC_TIDE_DELUGE_CHANNEL (1 SECONDS)
#define HERETIC_TIDE_SEA_RADIUS 4
#define HERETIC_TIDE_SEA_LIFETIME (15 SECONDS)
#define HERETIC_TIDE_SEA_PRESSURE_INTERVAL (4 SECONDS)
#define HERETIC_TIDE_BREACH_CRAFT "tide_breach"
#define HERETIC_TIDE_BREACH_CLUE "Вода не уходит в слив и темнее обычной."
#define HERETIC_TIDE_BREACH_WATER_TIME (HERETIC_TIDE_BREACH_REFRESH * 2)
#define HERETIC_TIDE_CAPTURE "tide"
#define HERETIC_TIDE_DROWN_RANGE 4
#define HERETIC_TIDE_DROWN_COST 2
#define HERETIC_TIDE_DROWN_COOLDOWN (40 SECONDS)
#define HERETIC_TIDE_DROWN_TRAIT "heretic_tide_drowning"
#define HERETIC_TIDE_CURRENT_RANGE 8
#define HERETIC_TIDE_CURRENT_INTERVAL (1 SECONDS)
#define HERETIC_TIDE_CURRENT_COOLDOWN (30 SECONDS)
#define HERETIC_TIDE_DIVE_TIME (1.5 SECONDS)
#define HERETIC_TIDE_DIVE_REACH 1

/datum/heretic_path/tide
	id = PATH_TIDE
	deed_type = /datum/heretic_deed/tide
	name = "Пучина"
	tagline = "Прорывы у раковин дают чёрную воду: в ней враги захлёбываются, а вы уходите в слив."
	craft_summary = "Хватка по раковине, душу или баку открывает прорыв на 5 минут: до 3, вокруг чёрная вода."
	capture_summary = "Сброс валит в лужу, через секунду Захлёб лишает голоса, через 5 секунд - сознания; сердце уводит в изнанку."
	escape_summary = "Уйти в слив: от своего прорыва к другому за 1,5 секунды; из изнанки выходите к своему прорыву."
	strength_points = list(
		"Прорыв 5 минут держит чёрную воду: враги в ней мокнут и замедляются, вы ходите быстрее.",
		"Захлёб лишает цель голоса и рации, через 5 секунд на мокром полу - сознания на 10 секунд.",
		"В своей изнанке весь пол - ваша вода: захлёб, начатый снаружи, кончается беспамятством внутри.",
		"Уйти в слив доступен с первой ступени, Течение делает его дешевле и чаще.",
		"Сброс валит с ног и сносит, удар о стену добавляет урон; Обрушение валит с ног всю область.",
		"Вознёсшийся заливает пол вокруг себя и оставляет мокрый след.",
	)
	weakness_points = list(
		"Прорыв виден: вода не уходит в слив; гаечный ключ или нулевой жезл по источнику его закрывают.",
		"Захлёб смыкается секунду и берёт только цель на мокром полу; сухой пол, жезл и 2 секунды растолкать его рвут.",
		"Без второго своего прорыва на уровне уйти в слив некуда.",
		"Лечения нет, а волны быстро расходуют давление.",
		"Обрушение выдаёт себя за секунду: из подсвеченной области можно выйти.",
		"Вода вознёсшегося не проходит сквозь стены, окна, двери и машины: держитесь дальше 2 клеток.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_tide,
		/datum/eldritch_knowledge/tide_grasp,
		/datum/eldritch_knowledge/spell/tide_drown,
		/datum/eldritch_knowledge/tide_mark,
		/datum/eldritch_knowledge/tide_bell,
		/datum/eldritch_knowledge/spell/tide_current,
		/datum/eldritch_knowledge/spell/tide_well,
		/datum/eldritch_knowledge/tide_depth,
		/datum/eldritch_knowledge/spell/tide_deluge,
		/datum/eldritch_knowledge/final_eldritch/tide_final,
	)

/datum/eldritch_knowledge/base_tide
	name = "Берег без солнца"
	summary = "Сброс давления валит волной; Хватка по раковине, душу или баку открывает прорыв с чёрной водой."
	details = list(
		"Нож и лист металла создают гарпунный клинок.",
		"Волны оставляют скользкий пол и на 8 секунд замедляют намокших врагов; вы на воде не скользите.",
		"Прорыв держится 5 минут: чёрная вода в 2 клетках натекает раз в 20 секунд, враги мокнут, вы быстрее.",
		"До 3 прорывов, новый вытесняет старый; смерть их не закрывает; отдел засчитывается делу один раз.",
		"Экипаж видит, что вода не уходит в слив; гаечный ключ или нулевой жезл по источнику закрывают прорыв.",
		"Уйти в слив доступен сразу: 2 давления, перезарядка 60 секунд.",
		"Из изнанки выходите к своему прорыву; весь её пол для вас - чёрная вода.",
	)
	role = HERETIC_ROLE_CRAFT
	gain_text = "Море ушло, но я всё ещё слышал, как оно дышит под моими ногами."
	route = PATH_TIDE
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/metal)
	result_atoms = list(/obj/item/melee/sickly_blade/tide)
	combat_resource = 2
	combat_resource_name = "Давление"
	resource_rules = list(
		"Начальный запас 2 из 4, единица возвращается за 12 секунд, с Тысячей саженей быстрее.",
		"Клинок даёт единицу раз в 6 секунд, Хватка глубины - 2, взрыв метки - 1.",
		"Сброс, Захлебнуться и водоворот стоят 2, Уйти в слив - 2, с Течением 1.",
		"Обрушение расходует весь запас, минимум 2.",
		"Колокол меняет направление Сброса. Смерть сбрасывает запас.",
	)
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_tide/release
	grasp_visual = /obj/effect/temp_visual/heretic_tide/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/tide_grasp.ogg'
	grasp_catchphrase = "GE'LME SA'UKIA"
	var/mob/living/tide_body
	var/obj/structure/heretic_tide_well/active_well
	var/list/datum/status_effect/heretic_drenched/drenched = list()
	var/list/datum/status_effect/eldritch/tide/marks = list()
	var/list/obj/effect/heretic_tide_puddle/sea/sea = list()
	/// Источники с ремеслом «tide_breach», старейший первым; значение - прорыв.
	var/list/atom/breaches = list()
	var/list/datum/status_effect/heretic_tide_drowning/drownings = list()
	var/list/obj/effect/heretic_tide_current/current_cells = list()
	var/obj/effect/proc_holder/spell/self/heretic_tide/dive/dive_power
	var/current_pulse_timer
	var/current_expiry_timer
	var/tide_failure
	var/inward_tide = FALSE
	var/tide_generation = 0
	var/ascension_active = FALSE
	var/static/list/water_sources = typecacheof(list(/obj/structure/sink, /obj/machinery/shower, /obj/structure/reagent_dispensers/watertank))
	COOLDOWN_DECLARE(ascended_pressure)

/datum/eldritch_knowledge/base_tide/on_body_gain(mob/living/user)
	if(!user?.mind || tide_body == user)
		return
	if(tide_body)
		on_body_lose(tide_body)
	tide_body = user
	ADD_TRAIT(user, TRAIT_NOSLIPWATER, REF(src))
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_body_moved))
	grant_combat_power(user)
	grant_dive(user)
	update_capacity()
	COOLDOWN_START(src, ascended_pressure, HERETIC_TIDE_PRESSURE_INTERVAL)

/datum/eldritch_knowledge/base_tide/on_body_lose(mob/living/user)
	if(tide_body)
		UnregisterSignal(tide_body, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
		REMOVE_TRAIT(tide_body, TRAIT_NOSLIPWATER, REF(src))
		tide_body.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_sea)
	tide_body = null
	remove_combat_power()
	QDEL_NULL(dive_power)
	clear_tide()

/datum/eldritch_knowledge/base_tide/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(tide_body)

/datum/eldritch_knowledge/base_tide/on_death(mob/user)
	clear_tide()
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_tide/Destroy()
	on_body_lose(tide_body)
	for(var/atom/source as anything in breaches.Copy())
		close_breach(source)
	return ..()

/datum/eldritch_knowledge/base_tide/proc/clear_tide()
	tide_generation++
	QDEL_NULL(active_well)
	for(var/datum/status_effect/heretic_drenched/effect as anything in drenched.Copy())
		qdel(effect)
	drenched.Cut()
	for(var/datum/status_effect/eldritch/tide/mark as anything in marks.Copy())
		qdel(mark)
	marks.Cut()
	for(var/datum/status_effect/heretic_tide_drowning/drowning as anything in drownings.Copy())
		qdel(drowning)
	drownings.Cut()
	QDEL_LIST(sea)
	clear_current()

/datum/eldritch_knowledge/base_tide/proc/can_use(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && isliving(user) && user == tide_body && !user.incapacitated() && isturf(user.loc) && heretic?.selected_path == PATH_TIDE && heretic.get_knowledge(type) == src

/datum/eldritch_knowledge/base_tide/proc/grant_dive(mob/living/user)
	if(!user.mind || !QDELETED(dive_power))
		return
	dive_power = new
	user.mind.AddSpell(dive_power)
	update_dive()

/datum/eldritch_knowledge/base_tide/proc/flowing()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(tide_body)
	var/datum/eldritch_knowledge/current = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/tide_current)
	return !QDELETED(current)

/datum/eldritch_knowledge/base_tide/proc/dive_cost()
	return flowing() ? HERETIC_TIDE_DIVE_FLOW_COST : HERETIC_TIDE_DIVE_COST

/// Течение удешевляет уход в слив; готовая способность остаётся готовой при смене перезарядки.
/datum/eldritch_knowledge/base_tide/proc/update_dive()
	if(QDELETED(dive_power))
		return
	var/ready = dive_power.charge_counter >= dive_power.charge_max
	dive_power.charge_max = flowing() ? HERETIC_TIDE_DIVE_FLOW_COOLDOWN : HERETIC_TIDE_DIVE_COOLDOWN
	if(ready)
		dive_power.charge_counter = dive_power.charge_max

/datum/eldritch_knowledge/base_tide/proc/update_capacity()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(tide_body)
	var/datum/eldritch_knowledge/tide_depth/depth = heretic?.get_knowledge(/datum/eldritch_knowledge/tide_depth)
	combat_resource_max = ascension_active ? HERETIC_TIDE_ASCENDED_CAPACITY : depth ? depth.passive_values[depth.passive_level] : initial(combat_resource_max)
	combat_resource = min(combat_resource, combat_resource_max)
	notify_resource_changed()

/datum/eldritch_knowledge/base_tide/combat_resource_state()
	return "Сброс сейчас [inward_tide ? "притягивает" : "отталкивает"]. Прорывов: [length(breaches)] из [HERETIC_TIDE_BREACH_LIMIT]."

/datum/eldritch_knowledge/base_tide/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(!can_use(user) || !proximity_flag || !COOLDOWN_FINISHED(src, resource_harvest) || !heretic_can_affect(user, target, chargecost = 0))
		return
	gain_combat_resource()
	COOLDOWN_START(src, resource_harvest, HERETIC_TIDE_HARVEST_TIME)

/datum/eldritch_knowledge/base_tide/on_life(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user))
		return
	for(var/obj/effect/heretic_tide_puddle/sea/puddle as anything in sea)
		for(var/mob/living/victim in puddle.loc)
			if(victim != user)
				keep_soaked(victim)
	for(var/atom/source as anything in breaches)
		var/datum/heretic_tide_breach/breach = breaches[source]
		for(var/obj/effect/heretic_tide_puddle/breach/puddle as anything in breach.puddles)
			for(var/mob/living/victim in puddle.loc)
				if(victim != user)
					keep_soaked(victim)
	var/in_own_sea = in_sea(user)
	if(in_own_sea && COOLDOWN_TIMELEFT(src, ascended_pressure) > HERETIC_TIDE_SEA_PRESSURE_INTERVAL)
		COOLDOWN_START(src, ascended_pressure, HERETIC_TIDE_SEA_PRESSURE_INTERVAL)
	if(!COOLDOWN_FINISHED(src, ascended_pressure))
		return
	gain_combat_resource()
	var/datum/eldritch_knowledge/tide_depth/depth = heretic?.get_knowledge(/datum/eldritch_knowledge/tide_depth)
	var/interval = HERETIC_TIDE_PRESSURE_INTERVAL - (depth ? 2 SECONDS * depth.passive_level : 0)
	if(ascension_active || in_own_sea)
		interval = min(interval, HERETIC_TIDE_SEA_PRESSURE_INTERVAL)
	COOLDOWN_START(src, ascended_pressure, interval)

/datum/eldritch_knowledge/base_tide/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag || !is_type_in_typecache(target, water_sources))
		return FALSE
	return open_breach(target, user)

/datum/eldritch_knowledge/base_tide/proc/open_breach(atom/source, mob/living/user)
	grasp_failure_reason = null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !can_use(user) || QDELETED(source) || !isturf(source.loc) || !is_type_in_typecache(source, water_sources))
		return FALSE
	if(source.GetComponent(/datum/component/heretic_craft))
		grasp_failure_reason = (source in breaches) ? "Здесь прорыв уже открыт: выберите другую раковину, душ или бак с водой." : "На этом источнике уже лежит чужое ремесло."
		return FALSE
	grasp_failure_reason = heretic.deed_wait_reason(heretic.deed_key_for(source))
	if(grasp_failure_reason)
		return FALSE
	while(length(breaches) >= HERETIC_TIDE_BREACH_LIMIT)
		var/atom/oldest = breaches[1]
		log_game("[key_name(user)] теряет прорыв Пучины у [oldest] ([oldest.type]) в [AREACOORD(oldest)]: его вытеснил новый.")
		close_breach(oldest)
	source.AddComponent(/datum/component/heretic_craft, src, HERETIC_TIDE_BREACH_CRAFT, HERETIC_TIDE_BREACH_CLUE)
	breaches[source] = new /datum/heretic_tide_breach(source, src)
	playsound(source, 'sound/effects/slosh.ogg', 50, TRUE)
	to_chat(user, span_eldritch("Вода в [source] больше не уходит в слив: прорыв открыт на [DisplayTimeText(HERETIC_TIDE_BREACH_LIFETIME)]. Прорывов: [length(breaches)] из [HERETIC_TIDE_BREACH_LIMIT]."))
	log_game("[key_name(user)] открывает прорыв Пучины у [source] ([source.type]) в [AREACOORD(source)].")
	heretic.advance_deed(heretic.deed_key_for(source), source)
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/close_breach(atom/source)
	if(!(source in breaches))
		return
	var/datum/heretic_tide_breach/breach = breaches[source]
	breaches -= source
	qdel(breach)
	qdel(heretic_craft_on(source, HERETIC_TIDE_BREACH_CRAFT))
	notify_resource_changed()

/datum/eldritch_knowledge/base_tide/on_craft_removed(atom/crafted, craft_id)
	if(craft_id == HERETIC_TIDE_BREACH_CRAFT)
		close_breach(crafted)

/datum/eldritch_knowledge/base_tide/pocket_exits(mob/living/user)
	. = list()
	for(var/atom/source as anything in breaches)
		heretic_add_pocket_exit(., "Прорыв - [get_area_name(source, TRUE)]", heretic_pocket_landing(get_turf(source)))

/datum/eldritch_knowledge/base_tide/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	return list("name" = "под воду", "text" = "Вода под [victim] темнеет и расступается.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))

/// Цель захлёбывается от своего «Захлебнуться» или готова к обряду на мокром полу, еретик рядом с ней.
/datum/eldritch_knowledge/base_tide/proc/door_holds(mob/living/user, mob/living/victim)
	if(!can_use(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > 1)
		return FALSE
	for(var/datum/status_effect/heretic_tide_drowning/drowning as anything in drownings)
		if(drowning.owner == victim)
			return TRUE
	if(knocked_out_by_capture(victim))
		return TRUE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic.hunt_target_ready(victim) && on_wet_floor(victim)

/// Своя вода - лужи прорывов и моря Обрушения этого знания и весь пол своей изнанки; прилив вознесения сюда не входит.
/datum/eldritch_knowledge/base_tide/proc/on_own_water(atom/movable/thing)
	if(!isturf(thing?.loc))
		return FALSE
	if(in_own_pocket(thing))
		return TRUE
	for(var/obj/effect/heretic_tide_puddle/puddle in thing.loc)
		if(!QDELETED(puddle) && puddle.tide_ref?.resolve() == src)
			return TRUE
	return FALSE

/datum/eldritch_knowledge/base_tide/proc/in_own_pocket(atom/movable/thing)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(tide_body)
	return heretic?.pocket?.active && heretic.pocket.contains(thing)

/datum/eldritch_knowledge/base_tide/proc/on_own_current(atom/movable/thing)
	if(!length(current_cells) || !isturf(thing?.loc))
		return FALSE
	for(var/obj/effect/heretic_tide_current/cell in thing.loc)
		if(!QDELETED(cell) && cell.tide_ref?.resolve() == src)
			return TRUE
	return FALSE

/// Мокрый пол для захлёба: своя вода Пучины или водяная лужа от любого источника, в том числе от Сброса.
/datum/eldritch_knowledge/base_tide/proc/on_wet_floor(atom/movable/thing)
	var/turf/open/place = thing?.loc
	if(!istype(place))
		return FALSE
	if(on_own_water(thing))
		return TRUE
	var/datum/component/wet_floor/wet = place.GetComponent(/datum/component/wet_floor)
	return wet && (wet.is_wet() & TURF_WET_WATER)

/datum/eldritch_knowledge/base_tide/proc/drown_block_reason(mob/living/user, atom/target, check_cost = TRUE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/tide_drown)
	if(!can_use(user) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_capture_block_reason(user, target, HERETIC_TIDE_CAPTURE)
	if(reason)
		return reason
	var/mob/living/victim = target
	if(!isturf(victim.loc) || !line_clear(user, victim, HERETIC_TIDE_DROWN_RANGE))
		return "Цель должна стоять не дальше четырёх клеток по открытой линии."
	if(victim.has_status_effect(/datum/status_effect/heretic_tide_drowning))
		return "Цель уже захлёбывается."
	if(!on_wet_floor(victim))
		return "Захлебнуться может только цель на мокром полу: в вашей воде или в водяной луже."
	if(check_cost && combat_resource < HERETIC_TIDE_DROWN_COST)
		return "Нужно [HERETIC_TIDE_DROWN_COST] давления."
	return null

/datum/eldritch_knowledge/base_tide/proc/drown(mob/living/user, mob/living/victim)
	tide_failure = drown_block_reason(user, victim)
	if(tide_failure || !spend_combat_resource(HERETIC_TIDE_DROWN_COST))
		return FALSE
	var/turf/place = get_turf(victim)
	new /obj/effect/temp_visual/heretic_tide/warning/drown(place)
	addtimer(CALLBACK(src, PROC_REF(seal_drown), user, victim, place, tide_generation), HERETIC_TIDE_DROWN_TELEGRAPH)
	user.visible_message(span_danger("Вода под [victim] темнеет и тянется вверх!"), span_notice("Вода смыкается вокруг [victim]."))
	playsound(place, 'modular_bluemoon/sound/heretic/tide_grasp.ogg', 30, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/seal_drown(mob/living/user, mob/living/victim, turf/place, generation)
	if(QDELETED(src) || generation != tide_generation || QDELETED(user))
		return FALSE
	if(QDELETED(victim) || victim.loc != place)
		to_chat(user, span_warning("Цель ушла из воды, и захлёб не случился."))
		return FALSE
	var/reason = drown_block_reason(user, victim, check_cost = FALSE)
	if(reason)
		to_chat(user, span_warning("Захлёб сорвался: [reason]"))
		return FALSE
	if(!victim.apply_status_effect(/datum/status_effect/heretic_tide_drowning, src))
		return FALSE
	new /obj/effect/temp_visual/heretic_tide/grasp(place)
	playsound(victim, 'modular_bluemoon/sound/heretic/tide_grasp.ogg', 45, TRUE)
	log_combat(user, victim, "заставляет захлебнуться водой Пучины")
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/create_current(mob/living/user, atom/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/tide_current)
	var/turf/origin = get_turf(user)
	var/turf/destination = get_turf(target)
	if(!can_use(user) || QDELETED(required))
		tide_failure = "Способность недоступна вашему пути или текущему телу."
		return FALSE
	if(!destination || destination == origin || destination.z != origin.z || get_dist(origin, destination) > HERETIC_TIDE_CURRENT_RANGE)
		tide_failure = "Укажите другую клетку не дальше восьми клеток от себя."
		return FALSE
	var/list/turf/path = current_path(origin, destination)
	if(length(path) < 2)
		tide_failure = "Течению некуда идти: соседнюю клетку перекрывает преграда."
		return FALSE
	clear_current()
	for(var/index in 1 to length(path))
		var/turf/tile = path[index]
		var/direction = index < length(path) ? get_dir(tile, path[index + 1]) : get_dir(path[index - 1], tile)
		current_cells += new /obj/effect/heretic_tide_current(tile, src, direction, index == length(path))
	current_expiry_timer = addtimer(CALLBACK(src, PROC_REF(clear_current)), HERETIC_TIDE_CURRENT_LIFETIME, TIMER_STOPPABLE)
	current_pulse_timer = addtimer(CALLBACK(src, PROC_REF(current_pulse)), HERETIC_TIDE_CURRENT_INTERVAL, TIMER_STOPPABLE)
	playsound(origin, 'sound/effects/watersplash.ogg', 45, TRUE)
	update_water_haste()
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/current_path(turf/origin, turf/destination)
	. = list()
	var/turf/previous
	for(var/turf/tile as anything in get_line(origin, destination))
		if(isgroundlessturf(tile) || (previous && (!heretic_tile_passable(tile) || !heretic_step_open(previous, tile))))
			break
		. += tile
		previous = tile

/datum/eldritch_knowledge/base_tide/proc/current_carries(atom/movable/thing)
	if(thing.anchored || thing.throwing)
		return FALSE
	if(isitem(thing))
		return TRUE
	if(!isliving(thing))
		return FALSE
	var/mob/living/body = thing
	return !body.buckled && !(body.mobility_flags & MOBILITY_STAND) && !body.check_magic_resistance(tinfoil = TRUE, chargecost = 0)

/datum/eldritch_knowledge/base_tide/proc/current_pulse()
	deltimer(current_pulse_timer)
	current_pulse_timer = addtimer(CALLBACK(src, PROC_REF(current_pulse)), HERETIC_TIDE_CURRENT_INTERVAL, TIMER_STOPPABLE)
	var/list/carried = list()
	for(var/obj/effect/heretic_tide_current/cell as anything in current_cells)
		if(cell.terminal || !isturf(cell.loc))
			continue
		for(var/atom/movable/thing in cell.loc)
			if(current_carries(thing))
				carried[thing] = cell.dir
	for(var/atom/movable/thing as anything in carried)
		if(!QDELETED(thing))
			step(thing, carried[thing])
	update_water_haste()

/datum/eldritch_knowledge/base_tide/proc/clear_current()
	deltimer(current_pulse_timer)
	deltimer(current_expiry_timer)
	current_pulse_timer = null
	current_expiry_timer = null
	QDEL_LIST(current_cells)
	update_water_haste()

/datum/eldritch_knowledge/base_tide/proc/adjacent_breach(mob/living/user)
	for(var/atom/source as anything in breaches)
		var/turf/place = get_turf(source)
		if(place?.z == user.z && get_dist(user, place) <= HERETIC_TIDE_DIVE_REACH)
			return source
	return null

/datum/eldritch_knowledge/base_tide/proc/dive_exit(atom/to_breach)
	var/turf/center = get_turf(to_breach)
	if(!center || isgroundlessturf(center))
		return null
	if(!center.is_blocked_turf(exclude_mobs = TRUE))
		return center
	for(var/turf/open/tile in RANGE_TURFS(HERETIC_TIDE_DIVE_REACH, center))
		if(tile != center && !isgroundlessturf(tile) && !tile.is_blocked_turf(exclude_mobs = TRUE) && heretic_step_open(center, tile))
			return tile
	return null

/datum/eldritch_knowledge/base_tide/proc/dive_failure(mob/living/user, atom/from_breach, atom/to_breach)
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	if(!can_use(user))
		return "Способность недоступна вашему пути или текущему телу."
	var/turf/entry = get_turf(from_breach)
	if(!(from_breach in breaches) || entry?.z != user.z || get_dist(user, entry) > HERETIC_TIDE_DIVE_REACH)
		return "Встаньте вплотную к своему прорыву."
	if(!(to_breach in breaches) || to_breach == from_breach)
		return "Выйти можно только у другого своего прорыва."
	var/turf/exit_place = get_turf(to_breach)
	if(exit_place?.z != user.z)
		return "Этот прорыв на другом уровне: слив ведёт только к прорывам на вашем уровне."
	if(user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return "Вас что-то держит на месте: уйти в воду не выйдет."
	var/turf/exit = dive_exit(to_breach)
	if(!exit)
		return "У того прорыва некуда выйти: все клетки рядом заняты."
	var/area/origin_area = get_area(user)
	var/area/exit_area = get_area(exit)
	if((origin_area.area_flags & NOTELEPORT) || (exit_area.area_flags & NOTELEPORT))
		return "Здесь вода не пропустит: вход или выход в зоне, закрытой для телепортации."
	if(combat_resource < dive_cost())
		return "Нужно [dive_cost()] давления."
	return null

/datum/eldritch_knowledge/base_tide/proc/dive_ready(mob/living/user, atom/from_breach, atom/to_breach)
	return !dive_failure(user, from_breach, to_breach)

/datum/eldritch_knowledge/base_tide/proc/dive(mob/living/user, atom/from_breach, atom/to_breach)
	tide_failure = dive_failure(user, from_breach, to_breach)
	if(tide_failure)
		return FALSE
	user.visible_message(span_warning("[user] шагает в чёрную воду у [from_breach] и уходит в неё с головой."), span_notice("Вы уходите в воду."))
	new /obj/effect/temp_visual/heretic_tide/wave(get_turf(user))
	playsound(from_breach, 'sound/effects/slosh.ogg', 50, TRUE)
	if(!do_after(user, HERETIC_TIDE_DIVE_TIME, target = from_breach, extra_checks = CALLBACK(src, PROC_REF(dive_ready), user, from_breach, to_breach)))
		tide_failure = dive_failure(user, from_breach, to_breach) || "Погружение прервано: полторы секунды стойте у прорыва неподвижно."
		return FALSE
	tide_failure = dive_failure(user, from_breach, to_breach)
	var/cost = dive_cost()
	if(tide_failure || !spend_combat_resource(cost))
		return FALSE
	var/turf/origin = get_turf(user)
	var/turf/exit = dive_exit(to_breach)
	if(!do_teleport(user, exit, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != exit)
		gain_combat_resource(cost)
		tide_failure = "Вода не вынесла вас: у выхода что-то мешает."
		return FALSE
	new /obj/effect/temp_visual/heretic_tide/burst(exit)
	playsound(exit, 'sound/effects/watersplash.ogg', 50, TRUE)
	log_game("[key_name(user)] уходит в слив Пучины из [AREACOORD(origin)] к [to_breach] в [AREACOORD(exit)].")
	update_water_haste()
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/line_clear(atom/start, atom/end, max_distance = HERETIC_TIDE_RANGE)
	return !line_failure(start, end, max_distance)

/datum/eldritch_knowledge/base_tide/proc/line_failure(atom/start, atom/end, max_distance = HERETIC_TIDE_RANGE)
	var/turf/origin = get_turf(start)
	var/turf/destination = get_turf(end)
	if(!origin || !destination || origin.z != destination.z || get_dist(origin, destination) > max_distance)
		return "Цель вне досягаемости: выберите её не дальше [max_distance] клеток на этом же уровне."
	if(!heretic_edge_line_clear(origin, destination))
		return "Линию перекрывает преграда: стена, закрытая дверь, окно или машина. Столы и перила течению не мешают, направленное окно держит воду только со своей стороны."
	return null

/datum/eldritch_knowledge/base_tide/proc/soak(mob/living/victim)
	return victim.apply_status_effect(/datum/status_effect/heretic_drenched, src)

/// Стоящего в своей воде не перемачивает заново, а продлевает намокание.
/datum/eldritch_knowledge/base_tide/proc/keep_soaked(mob/living/victim)
	if(QDELETED(tide_body) || !heretic_can_affect(tide_body, victim, chargecost = 0))
		return
	var/datum/status_effect/heretic_drenched/water = victim.has_status_effect(/datum/status_effect/heretic_drenched)
	if(water?.tide_ref?.resolve() == src)
		water.refresh()
	else
		soak(victim)

/datum/eldritch_knowledge/base_tide/proc/in_sea(atom/movable/thing)
	if(!length(sea) || !isturf(thing?.loc))
		return FALSE
	for(var/obj/effect/heretic_tide_puddle/sea/puddle in thing.loc)
		if(puddle.tide_ref?.resolve() == src)
			return TRUE
	return FALSE

/datum/eldritch_knowledge/base_tide/proc/update_water_haste()
	if(!tide_body)
		return
	if(tide_body.stat != DEAD && !ascension_active && (on_own_water(tide_body) || on_own_current(tide_body)))
		tide_body.add_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_sea)
	else
		tide_body.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_sea)

/datum/eldritch_knowledge/base_tide/proc/on_body_moved(datum/source)
	SIGNAL_HANDLER
	update_water_haste()

/datum/eldritch_knowledge/base_tide/proc/raise_sea(turf/center)
	for(var/turf/open/tile in RANGE_TURFS(HERETIC_TIDE_SEA_RADIUS, center))
		if(isgroundlessturf(tile) || istype(tile, /turf/open/lava) || !line_clear(center, tile, HERETIC_TIDE_SEA_RADIUS))
			continue
		var/obj/effect/heretic_tide_puddle/sea/puddle
		for(var/obj/effect/heretic_tide_puddle/sea/existing in tile)
			if(existing.tide_ref?.resolve() == src)
				puddle = existing
				break
		if(puddle)
			puddle.refresh()
		else
			new /obj/effect/heretic_tide_puddle/sea(tile, src)
		for(var/mob/living/victim in tile)
			if(victim != tide_body)
				keep_soaked(victim)
	update_water_haste()

/datum/eldritch_knowledge/base_tide/proc/wet_floor(turf/open/place)
	if(!istype(place) || isspaceturf(place) || istype(place, /turf/open/lava))
		return
	place.MakeSlippery(TURF_WET_WATER, min_wet_time = HERETIC_TIDE_PUDDLE_TIME, wet_time_to_add = 0)

/datum/eldritch_knowledge/base_tide/proc/move_with_tide(mob/living/victim, atom/center, inward, steps = 1, reach_center = FALSE, collide = TRUE)
	if(victim.anchored || victim.buckled || !isturf(victim.loc))
		return
	for(var/step_index in 1 to steps)
		if(inward && get_dist(victim, center) <= (reach_center ? 0 : 1))
			break
		var/direction = inward ? get_dir(victim, center) : get_dir(center, victim)
		if(!direction)
			break
		var/turf/destination = get_step(victim, direction)
		if(!destination || !isopenturf(destination) || destination.is_blocked_turf(exclude_mobs = TRUE))
			if(!collide)
				break
			victim.adjustBruteLoss(HERETIC_TIDE_COLLISION_DAMAGE)
			victim.Knockdown(1.5 SECONDS)
			new /obj/effect/temp_visual/heretic_tide/burst(get_turf(victim))
			break
		if(!step(victim, direction))
			break

/datum/eldritch_knowledge/base_tide/proc/release(mob/living/user, ascended_wave = FALSE)
	if(!can_use(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(ascended_wave)
		if(!ascension_active)
			return FALSE
	else if(!spend_combat_resource(HERETIC_TIDE_RELEASE_COST))
		return FALSE
	var/wave_radius = ascended_wave ? 3 : HERETIC_TIDE_WAVE_RADIUS
	var/turf/center = get_turf(user)
	if(ascended_wave)
		voice_fx(center, wave_radius)
	for(var/mob/living/victim in range(wave_radius, center))
		if(!isturf(victim.loc) || !line_clear(center, victim, wave_radius) || !heretic_can_affect(user, victim))
			continue
		var/damage_before = victim.getBruteLoss()
		victim.adjustBruteLoss(ascended_wave ? 30 : 18)
		if(victim.getBruteLoss() > damage_before)
			heretic.advance_combat_deed(victim, PATH_TIDE)
		victim.adjustStaminaLoss(ascended_wave ? 40 : 24)
		soak(victim)
		move_with_tide(victim, center, inward_tide, ascended_wave ? 3 : 2)
		victim.Knockdown(ascended_wave ? 3 SECONDS : 2.5 SECONDS)
		log_combat(user, victim, "поражает приливной волной")
	for(var/turf/tile in range(wave_radius, center))
		if(line_clear(center, tile, wave_radius))
			wet_floor(tile)
			new /obj/effect/temp_visual/heretic_tide/wave(tile)
	new /obj/effect/temp_visual/heretic_tide/wave(center)
	playsound(center, 'sound/effects/watersplash.ogg', 65, TRUE)
	return TRUE

/// Голос Пучины: вода встаёт короной вокруг героя, от него расходятся волна и пена, пол дрожит.
/datum/eldritch_knowledge/base_tide/proc/voice_fx(turf/center, radius)
	var/ink = heretic_path_ink(PATH_TIDE)
	new /obj/effect/temp_visual/heretic_tide_swell(center)
	new /obj/effect/temp_visual/heretic_tide_swell/front(center)
	heretic_vfx_shockwave(center, ink, radius, HERETIC_TIDE_VOICE_WAVE_TIME)
	heretic_vfx_burst(center, /particles/heretic_ascension/tide/foam)
	heretic_vfx_flash(center, ink, HERETIC_TIDE_VOICE_FLASH_RANGE, HERETIC_TIDE_VOICE_FLASH_POWER, HERETIC_TIDE_VOICE_FLASH_TIME)
	heretic_vfx_quake(center, HERETIC_TIDE_VOICE_QUAKE_RADIUS, HERETIC_TIDE_VOICE_QUAKE, HERETIC_TIDE_VOICE_QUAKE_TIME)

/datum/eldritch_knowledge/base_tide/proc/create_well(mob/living/user, turf/place)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user) || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/tide_well) || !isopenturf(place) || isspaceturf(place) || istype(place, /turf/open/lava) || !line_clear(user, place) || !spend_combat_resource(HERETIC_TIDE_RELEASE_COST))
		return FALSE
	QDEL_NULL(active_well)
	active_well = new(place, src)
	active_well.pulse(erupting = TRUE)
	playsound(place, 'sound/effects/watersplash.ogg', 45, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/can_prepare_deluge(mob/living/user, turf/origin, turf/center, expected_generation)
	return can_use(user) && tide_generation == expected_generation && origin && user.z == origin.z && get_dist(user, origin) <= HERETIC_TIDE_CHANNEL_MOVEMENT && combat_resource >= HERETIC_TIDE_RELEASE_COST && line_clear(user, center)

/datum/eldritch_knowledge/base_tide/proc/deluge_turfs(mob/living/user, turf/center)
	var/list/affected = list()
	if(!can_use(user) || !line_clear(user, center))
		return affected
	for(var/turf/tile in range(HERETIC_TIDE_WAVE_RADIUS, center))
		if(line_clear(center, tile, HERETIC_TIDE_WAVE_RADIUS))
			affected += tile
	return affected

/// Обрушение поражает только предупреждённые клетки, оставшиеся доступными после подготовки.
/datum/eldritch_knowledge/base_tide/proc/deluge(mob/living/user, turf/center, list/telegraphed_turfs, expected_generation)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user) || tide_generation != expected_generation || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/tide_deluge) || !length(telegraphed_turfs) || !line_clear(user, center) || combat_resource < HERETIC_TIDE_RELEASE_COST)
		return FALSE
	var/pressure = combat_resource
	spend_combat_resource(pressure)
	for(var/mob/living/victim in range(HERETIC_TIDE_WAVE_RADIUS, center))
		if(!isturf(victim.loc) || !(get_turf(victim) in telegraphed_turfs) || !line_clear(center, victim, HERETIC_TIDE_WAVE_RADIUS) || !heretic_can_affect(user, victim))
			continue
		victim.adjustBruteLoss(20 + pressure * 6)
		victim.adjustStaminaLoss(20 + pressure * 3)
		victim.Knockdown(2 SECONDS)
		soak(victim)
		new /obj/effect/temp_visual/heretic_tide/burst(get_turf(victim))
		log_combat(user, victim, "обрушивает толщу Пучины на")
	for(var/turf/tile as anything in telegraphed_turfs)
		if(line_clear(center, tile, HERETIC_TIDE_WAVE_RADIUS))
			wet_floor(tile)
	raise_sea(center)
	new /obj/effect/temp_visual/heretic_tide/burst(center)
	playsound(center, 'modular_bluemoon/sound/heretic/tide_deluge.ogg', 80, TRUE)
	return TRUE

/datum/status_effect/heretic_drenched
	id = "heretic_drenched"
	duration = 8 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_drenched
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/tide_ref
	/// Капли с намокшего; снятие воды отпускает их догореть на полу.
	var/obj/effect/abstract/heretic_particle_holder/drips

/datum/status_effect/heretic_drenched/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_tide/tide)
	if(QDELETED(tide))
		qdel(src)
		return
	tide_ref = WEAKREF(tide)
	return ..()

/datum/status_effect/heretic_drenched/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide || owner.stat == DEAD || IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner))
		return FALSE
	tide.drenched += src
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_drenched)
	drips = heretic_vfx_attach_particles(owner, /particles/heretic_ascension/tide/drip, FALSE)
	return TRUE

/datum/status_effect/heretic_drenched/on_remove()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	tide?.drenched.Remove(src)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_drenched)
	heretic_vfx_release_particles(owner, drips)
	drips = null
	return ..()

/datum/status_effect/heretic_drenched/be_replaced()
	on_remove()
	return ..()

/datum/status_effect/heretic_drenched/Destroy()
	. = ..()
	tide_ref = null
	return .

/datum/movespeed_modifier/heretic_drenched
	multiplicative_slowdown = 0.7
	blacklisted_movetypes = FLYING | FLOATING

/atom/movable/screen/alert/status_effect/heretic_drenched
	name = "Вода Пучины"
	desc = "Вода Пучины замедляет ваши шаги даже в нескользящей обуви. Полёт позволяет двигаться без этого замедления. Вода исчезнет через 8 секунд после последнего попадания магии или шага по чёрной воде Пучины."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "tide_drenched"

/datum/status_effect/eldritch/tide
	id = "tide_mark"
	mark_name = "Метка Пучины"
	mark_alert_state = "sigil_tide"
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_tide_effects.dmi'
	effect_sprite = "tide_mark"
	detonation_sound = 'sound/effects/watersplash.ogg'
	detonation_visual = /obj/effect/temp_visual/heretic_tide/burst
	var/datum/weakref/tide_ref

/datum/status_effect/eldritch/tide/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_tide/tide)
	if(tide)
		tide_ref = WEAKREF(tide)
	return ..()

/datum/status_effect/eldritch/tide/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide)
		return FALSE
	tide.marks += src
	return TRUE

/datum/status_effect/eldritch/tide/on_remove()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	tide?.marks.Remove(src)
	return ..()

/datum/status_effect/eldritch/tide/on_effect()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide?.can_use(tide.tide_body) && heretic_can_affect(tide.tide_body, owner, chargecost = 0))
		owner.adjustBruteLoss(8)
		owner.adjustStaminaLoss(12)
	return ..()

/obj/structure/heretic_tide_well
	name = "abyssal whirlpool"
	desc = "Вода вращается над сухим полом и тянет всё живое к чёрной воронке. Разбейте её или коснитесь нулевым жезлом, чтобы оборвать течение."
	icon = 'modular_bluemoon/icons/obj/heretic_tide_well.dmi'
	icon_state = "tide_whirlpool"
	pixel_x = -32
	pixel_y = -32
	anchored = TRUE
	density = FALSE
	max_integrity = 60
	layer = BELOW_MOB_LAYER
	var/datum/weakref/tide_ref
	var/expires_at
	var/outward = FALSE
	COOLDOWN_DECLARE(well_pulse)

/obj/structure/heretic_tide_well/Initialize(mapload, datum/eldritch_knowledge/base_tide/tide)
	. = ..()
	if(QDELETED(tide))
		return INITIALIZE_HINT_QDEL
	tide_ref = WEAKREF(tide)
	expires_at = world.time + HERETIC_TIDE_WELL_LIFETIME
	COOLDOWN_START(src, well_pulse, HERETIC_TIDE_WELL_INTERVAL)
	START_PROCESSING(SSobj, src)

/obj/structure/heretic_tide_well/Destroy()
	STOP_PROCESSING(SSobj, src)
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide?.active_well == src)
		tide.active_well = null
	tide_ref = null
	return ..()

/obj/structure/heretic_tide_well/process()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide || QDELETED(tide.tide_body) || tide.tide_body.stat == DEAD || !IS_HERETIC(tide.tide_body) || world.time >= expires_at)
		qdel(src)
		return PROCESS_KILL
	if(!COOLDOWN_FINISHED(src, well_pulse))
		return
	COOLDOWN_START(src, well_pulse, HERETIC_TIDE_WELL_INTERVAL)
	pulse()

/obj/structure/heretic_tide_well/proc/pulse(erupting = FALSE)
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	var/mob/living/user = tide?.tide_body
	if(!tide || QDELETED(user) || user.stat == DEAD || !IS_HERETIC(user) || !tide.line_clear(user, src, 7) || world.time >= expires_at)
		return FALSE
	for(var/mob/living/victim in range(HERETIC_TIDE_WAVE_RADIUS, src))
		if(!isturf(victim.loc) || !tide.line_clear(src, victim, HERETIC_TIDE_WAVE_RADIUS) || !heretic_can_affect(user, victim))
			continue
		var/in_core = !outward && get_dist(victim, src) <= 1
		victim.adjustBruteLoss(erupting ? 12 : in_core ? 12 : 6)
		victim.adjustStaminaLoss(erupting ? 18 : in_core ? 12 : 8)
		tide.soak(victim)
		tide.move_with_tide(victim, src, !outward, reach_center = TRUE, collide = !outward)
		if(erupting || in_core)
			victim.Knockdown(erupting ? 1.5 SECONDS : 0.6 SECONDS)
		log_combat(user, victim, outward ? "оттесняет водоворотом" : "затягивает водоворотом")
	for(var/turf/tile in range(HERETIC_TIDE_WAVE_RADIUS, src))
		if(tide.line_clear(src, tile, HERETIC_TIDE_WAVE_RADIUS))
			tide.wet_floor(tile)
	new /obj/effect/temp_visual/heretic_tide/wave(get_turf(src))
	return TRUE

/obj/structure/heretic_tide_well/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	return ..()

/obj/item/melee/sickly_blade/tide
	name = "abyssal harpoon"
	desc = "Изогнутый гарпун с бронзовой рукоятью. Внутри лезвия колышется чёрная вода, которой неведомы берега."
	icon = 'modular_bluemoon/icons/obj/heretic_tide.dmi'
	icon_state = "tide_blade"
	item_state = "tide_blade"
	route = PATH_TIDE
	mark_type = /datum/status_effect/eldritch/tide

/obj/item/heretic_path_relic/tide_bell
	name = "drowned bell"
	desc = "Водолазный колокол, умещающийся в ладони. Применение в руке меняет притяжение и отталкивание Сброса давления. Щелчок по своей воронке в пяти клетках обращает её наружу или обратно. Наружное течение отталкивает на клетку с 6 ушибами и 8 урона выносливости, без падения и удара о стену. Срок жизни воронки сохраняется. Общая перезарядка — 10 секунд."
	icon_state = "tide_bell"

/obj/item/heretic_path_relic/tide_bell/attack_self(mob/living/user)
	ring(user)

/obj/item/heretic_path_relic/tide_bell/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	if(istype(target, /obj/structure/heretic_tide_well))
		return redirect_well(user, target)
	return ..()

/obj/item/heretic_path_relic/tide_bell/proc/redirect_well(mob/living/user, obj/structure/heretic_tide_well/well)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!authorized(user) || !tide?.can_use(user) || !COOLDOWN_FINISHED(src, relic_cooldown) || QDELETED(well) || well.tide_ref?.resolve() != tide || world.time >= well.expires_at || !tide.line_clear(user, well))
		return FALSE
	well.outward = !well.outward
	well.color = well.outward ? "#7fb9c8" : initial(well.color)
	well.desc = well.outward ? "Вода расходится от центра. Раз в две секунды течение отталкивает на клетку, нанося 6 ушибов и 8 урона выносливости без падения. Разбейте воронку или коснитесь нулевым жезлом, чтобы оборвать течение." : initial(well.desc)
	COOLDOWN_START(src, relic_cooldown, 10 SECONDS)
	well.visible_message(span_warning("[well] меняет течение: вода теперь [well.outward ? "расходится от центра" : "стягивается в воронку"]!"))
	playsound(well, 'modular_bluemoon/sound/heretic/tide_bell.ogg', 45, FALSE)
	return TRUE

/obj/item/heretic_path_relic/tide_bell/proc/ring(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!authorized(user) || !tide?.can_use(user) || !COOLDOWN_FINISHED(src, relic_cooldown))
		return FALSE
	tide.inward_tide = !tide.inward_tide
	tide.notify_resource_changed()
	COOLDOWN_START(src, relic_cooldown, 10 SECONDS)
	to_chat(user, span_eldritch("Колокол зовёт [tide.inward_tide ? "прилив: Сброс притягивает противников" : "отлив: Сброс отталкивает противников"]."))
	new /obj/effect/temp_visual/heretic_tide/wave(get_turf(user))
	flick("tide_bell_ring", src)
	playsound(user, 'modular_bluemoon/sound/heretic/tide_bell.ogg', 45, FALSE)
	return TRUE

/obj/effect/temp_visual/heretic_tide
	icon = 'modular_bluemoon/icons/obj/heretic_tide_effects.dmi'
	icon_state = "tide_wave"
	duration = 0.8 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_tide/grasp
	icon_state = "tide_grasp"

/obj/effect/temp_visual/heretic_tide/wave

/obj/effect/temp_visual/heretic_tide/burst
	icon_state = "tide_burst"
	duration = 1.9 SECONDS

/obj/effect/temp_visual/heretic_tide/warning
	icon_state = "tide_warning"
	duration = HERETIC_TIDE_DELUGE_CHANNEL

/obj/effect/temp_visual/heretic_tide/warning/drown
	duration = HERETIC_TIDE_DROWN_TELEGRAPH

/// Корона воды вокруг вознёсшегося: задняя половина уходит под героя, передняя встаёт перед ним.
/obj/effect/temp_visual/heretic_tide_swell
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "tide_swell_back"
	layer = BELOW_MOB_LAYER
	randomdir = FALSE
	duration = HERETIC_TIDE_SWELL_TIME

/obj/effect/temp_visual/heretic_tide_swell/front
	icon_state = "tide_swell_front"
	layer = ABOVE_MOB_LAYER

/// Пучина: капли стекают с намокшего и падают к ногам.
/particles/heretic_ascension/tide/drip
	icon_state = list("water_drop" = 1)
	count = 8
	spawning = 0.35
	position = generator("box", list(-8, -4, 0), list(8, 10, 0))
	velocity = list(0, -0.3, 0)
	gravity = list(0, -0.25)
	friction = 0
	lifespan = 0.9 SECONDS
	fade = 0.3 SECONDS
	fadein = 0.1 SECONDS

/// Пучина: брызги из-под шага по своей воде.
/particles/heretic_ascension/tide/step
	count = 8
	spawning = 8
	position = generator("box", list(-6, -13, 0), list(6, -9, 0))
	velocity = generator("box", list(-1.5, 1.5, 0), list(1.5, 3, 0))
	gravity = list(0, -0.45)
	friction = 0.02
	lifespan = 0.5 SECONDS
	fade = 0.2 SECONDS

/// Пучина: пена разлетается кольцом от Голоса Пучины.
/particles/heretic_ascension/tide/foam
	velocity = generator("circle", 4, 7)
	gravity = list(0, -0.2)
	friction = 0.12
	lifespan = 1 SECONDS
	fade = 0.4 SECONDS

/obj/effect/proc_holder/spell/self/heretic_tide
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "tide_release"
	action_background_icon_state = "bg_ecult"
	charge_max = 20 SECONDS

/obj/effect/proc_holder/spell/self/heretic_tide/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	return ..() && heretic_check(user, tide?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_tide/release
	name = "Сброс давления"
	desc = "За 2 давления волна в двух клетках: 18 ушибов, 24 урона выносливости, падение на 2,5 секунды и снос на две клетки, упор в стену добавляет 8 ушибов. Колокол меняет отталкивание на притяжение."
	summary = "Волна в 2 клетках: 18 ушибов, 24 выносливости, падение на 2,5 секунды и снос; 2 давления."
	charge_max = 15 SECONDS

/obj/effect/proc_holder/spell/self/heretic_tide/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!tide?.release(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_tide/leviathan
	name = "Голос Пучины"
	desc = "Бесплатная волна в трёх клетках после вознесения: 30 ушибов, 40 урона выносливости, падение на 3 секунды и снос на три клетки. Упор в стену добавляет 8 ушибов, пристёгнутых и закреплённых волна не сносит."
	summary = "Бесплатная волна в 3 клетках: 30 ушибов, 40 выносливости и падение на 3 секунды."
	charge_max = 30 SECONDS
	action_icon_state = "tide_ascend"

/obj/effect/proc_holder/spell/self/heretic_tide/leviathan/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!tide?.release(user, ascended_wave = TRUE))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_tide
	clothes_req = FALSE
	invocation_type = "none"
	range = HERETIC_TIDE_RANGE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "tide_undertow"
	action_background_icon_state = "bg_ecult"
	charge_max = 20 SECONDS
	active_msg = "Укажите цель для магии Пучины."
	deactive_msg = "Вы отпускаете течение."

/obj/effect/proc_holder/spell/pointed/heretic_tide/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	return ..() && heretic_check(user, tide?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/pointed/heretic_tide/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!heretic_check(user, tide, silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	var/reason = tide.line_failure(user, target)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_tide/well
	name = "Чёрный водоворот"
	desc = "За 2 давления воронка на 12 секунд в 5 клетках: первый удар в 2 клетках сбивает и притягивает, затем каждые 2 секунды тянет и бьёт. У неё 60 прочности, она работает, пока вы в 7 клетках без преград."
	summary = "Воронка на 12 секунд тянет и бьёт врагов в 2 клетках; 2 давления."
	charge_max = 30 SECONDS
	action_icon_state = "tide_well"

/obj/effect/proc_holder/spell/pointed/heretic_tide/well/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!length(targets) || !tide?.create_well(user, get_turf(targets[1])))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_tide/deluge
	name = "Обрушение толщи"
	desc = "Через секунду подготовки весь запас давления, не меньше 2, бьёт по области радиусом 2 в 5 клетках: 20 ушибов + 6 за давление и падение на 2 секунды. Затем 15 секунд море радиусом 4 мочит и замедляет врагов, а вам даёт давление раз в 4 секунды."
	summary = "Весь запас давления - удар по области и море на 15 секунд."
	charge_max = 25 SECONDS
	action_icon_state = "tide_deluge"

/obj/effect/proc_holder/spell/pointed/heretic_tide/deluge/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/turf/center = length(targets) ? get_turf(targets[1]) : null
	if(!tide?.can_use(user) || tide.combat_resource < HERETIC_TIDE_RELEASE_COST || !tide.line_clear(user, center))
		heretic_revert_cast(user)
		return
	var/list/telegraphed_turfs = tide.deluge_turfs(user, center)
	var/expected_generation = tide.tide_generation
	var/turf/origin = get_turf(user)
	for(var/turf/tile as anything in telegraphed_turfs)
		new /obj/effect/temp_visual/heretic_tide/warning(tile)
	user.visible_message(span_danger("[user] поднимает руки. Над полом проступает чёрная вода — сейчас обрушится прилив!"))
	playsound(center, 'modular_bluemoon/sound/heretic/tide_charge.ogg', 50, FALSE)
	if(!do_after(user, HERETIC_TIDE_DELUGE_CHANNEL, target = center, timed_action_flags = IGNORE_USER_LOC_CHANGE, extra_checks = CALLBACK(tide, TYPE_PROC_REF(/datum/eldritch_knowledge/base_tide, can_prepare_deluge), user, origin, center, expected_generation)) || QDELETED(src) || QDELETED(tide) || !tide.deluge(user, center, telegraphed_turfs, expected_generation))
		if(!QDELETED(src))
			heretic_revert_cast(user, "Подготовка сорвана: можно сместиться не дальше двух клеток от её начала. Сохраняйте видимость выбранной области в пяти клетках и возможность действовать; давление сохранено.")

/obj/effect/proc_holder/spell/pointed/heretic_tide/drown
	name = "Захлебнуться"
	desc = "За 2 давления вода секунду смыкается вокруг цели на мокром полу в 4 клетках; не сошедшая с клетки цель 5 секунд захлёбывается: ни голоса, ни рации, 6 удушья в секунду, за захлёб до 30. Если к концу она на мокром полу - без сознания 10 секунд; сухой пол, нулевой жезл и 2 секунды растолкать рвут захват."
	summary = "Через секунду цель на мокром полу 5 секунд захлёбывается, затем без сознания 10 секунд; 2 давления."
	range = HERETIC_TIDE_DROWN_RANGE
	charge_max = HERETIC_TIDE_DROWN_COOLDOWN
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "tide_drown"
	active_msg = "Укажите цель на мокром полу."

/obj/effect/proc_holder/spell/pointed/heretic_tide/drown/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!heretic_check(user, tide, silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	var/reason = tide.drown_block_reason(user, target)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_tide/drown/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!length(targets) || !tide?.drown(user, targets[1]))
		heretic_revert_cast(user, tide?.tide_failure)

/obj/effect/proc_holder/spell/pointed/heretic_tide/current
	name = "Течение"
	desc = "Полоса течения от вас к клетке в 8 клетках на 20 секунд: раз в секунду сносит лежащих и брошенные вещи, а вас ускоряет. Без давления, перезарядка 30 секунд."
	summary = "Полоса течения на 20 секунд сносит лежащих и вещи и ускоряет вас."
	range = HERETIC_TIDE_CURRENT_RANGE
	charge_max = HERETIC_TIDE_CURRENT_COOLDOWN
	active_msg = "Укажите, куда потечёт вода."

/obj/effect/proc_holder/spell/pointed/heretic_tide/current/can_target(atom/target, mob/user, silent)
	var/turf/origin = get_turf(user)
	var/turf/destination = get_turf(target)
	return heretic_check(user, origin && destination && destination != origin && destination.z == origin.z && get_dist(origin, destination) <= HERETIC_TIDE_CURRENT_RANGE, silent, "Укажите другую клетку не дальше восьми клеток от себя.")

/obj/effect/proc_holder/spell/pointed/heretic_tide/current/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!length(targets) || !tide?.create_current(user, targets[1]))
		heretic_revert_cast(user, tide?.tide_failure)

/obj/effect/proc_holder/spell/self/heretic_tide/dive
	name = "Уйти в слив"
	desc = "Вплотную к своему прорыву выберите другой свой прорыв на этом уровне: через полторы секунды вы выходите у него. Стоит 2 давления, перезарядка 60 секунд; со знанием «Течение» - 1 давление и 30 секунд."
	summary = "От своего прорыва к другому за 1,5 секунды; 2 давления, с Течением 1."
	charge_max = HERETIC_TIDE_DIVE_COOLDOWN
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "tide_dive"

/obj/effect/proc_holder/spell/self/heretic_tide/dive/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/atom/from_breach = tide?.adjacent_breach(user)
	if(!from_breach)
		heretic_revert_cast(user, "Встаньте вплотную к своему прорыву.")
		return
	var/list/exits = list()
	for(var/atom/source as anything in tide.breaches)
		var/turf/place = get_turf(source)
		if(source != from_breach && place?.z == user.z)
			exits["[length(exits) + 1]. [source.name]: [get_area_name(source, TRUE)]"] = source
	if(!length(exits))
		heretic_revert_cast(user, "Нужен второй прорыв на этом же уровне: выйти можно только у другого своего прорыва.")
		return
	var/choice = length(exits) == 1 ? exits[1] : tgui_input_list(user, "У какого прорыва выйти?", name, exits)
	if(QDELETED(src))
		return
	if(!(choice in exits))
		heretic_revert_cast(user, "Уход отменён: прорыв не выбран.")
		return
	if(QDELETED(tide) || !tide.dive(user, from_breach, exits[choice]))
		heretic_revert_cast(user, tide?.tide_failure)

/datum/eldritch_knowledge/tide_grasp
	name = "Хватка глубины"
	summary = "Хватка даёт 2 давления и мочит врага водой Пучины на 8 секунд."
	details = list(
		"Намокший враг замедлен даже в нескользящей обуви.",
		"Антимагия и союзники давления не дают.",
	)
	role = HERETIC_ROLE_GRASP
	gain_text = "На дне нет воздуха, но ладонь помнит вес каждого вдоха."
	cost = 1
	route = PATH_TIDE

/datum/eldritch_knowledge/tide_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!proximity_flag || !tide?.can_use(user) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	tide.gain_combat_resource(2)
	tide.soak(target)
	return TRUE

/datum/eldritch_knowledge/spell/tide_drown
	name = "Захлебнуться"
	summary = "За 2 давления цель на мокром полу 5 секунд захлёбывается, затем теряет сознание на 10 секунд."
	details = list(
		"Цель в 4 клетках по открытой линии, в вашей воде или водяной луже, в том числе от Сброса; мокрой одежды мало.",
		"Вода смыкается секунду: если цель сошла с клетки, захлёба нет, давление потрачено.",
		"Цель немеет: ни голоса, ни рации; 6 удушья в секунду, за захлёб до 30, выше 50 не поднимает и не убивает.",
		"Если к концу цель на мокром полу, она без сознания 10 секунд и готова к обряду.",
		"Сердце уводит цель с первой секунды захлёба: пол изнанки - ваша вода, захлёб кончается внутри.",
		"Срывают шаг на сухой пол, нулевой жезл, 2 секунды растолкать и ваша смерть; антимагия защищает.",
		"Потом цель минуту невосприимчива к захлёбу, к любому захвату - 15 секунд. Перезарядка 40 секунд.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Я держал его под водой не руками. Вода сама помнила, как держать."
	cost = 1
	route = PATH_TIDE
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_tide/drown

/datum/eldritch_knowledge/tide_mark
	name = "Метка Пучины"
	summary = "Хватка ставит метку на 15 секунд, удар гарпуном её взрывает."
	details = list(
		"Взрыв: 8 ушибов и 12 выносливости.",
		"Владелец клинка получает единицу давления.",
	)
	role = HERETIC_ROLE_MARK
	gain_text = "Вода отступила, оставив на коже очертания невозможного берега."
	cost = 2
	route = PATH_TIDE

/datum/eldritch_knowledge/tide_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!proximity_flag || !tide?.can_use(user) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/tide, tide)
	return TRUE

/datum/eldritch_knowledge/tide_bell
	name = "Звон затонувшего храма"
	summary = "Лист золота и прут дают колокол: он меняет направление Сброса и воронки."
	details = list(
		"Применение в руке переключает Сброс между отталкиванием и притяжением.",
		"Щелчок по своей воронке в 5 клетках обращает её наружу или обратно.",
		"Наружное течение раз в 2 секунды отталкивает на клетку: 6 ушибов, 8 выносливости, без падения.",
		"Переключение не даёт лишнего пульса и не продлевает воронку.",
		"Давление не тратится, общая перезарядка 10 секунд; колокол один и слушается только создателя.",
	)
	role = HERETIC_ROLE_RELIC
	gain_text = "В затонувшем храме всё ещё звонят к утренней службе."
	cost = 1
	route = PATH_TIDE
	required_atoms = list(/obj/item/stack/sheet/mineral/gold, /obj/item/stack/rods)
	result_atoms = list(/obj/item/heretic_path_relic/tide_bell)

/datum/eldritch_knowledge/tide_bell/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/tide_bell/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/tide_bell)

/datum/eldritch_knowledge/spell/tide_current
	name = "Течение"
	summary = "Полоса течения на 20 секунд сносит лежащих и вещи, ускоряет вас и удешевляет уход в слив."
	details = list(
		"Укажите клетку не дальше 8 клеток: полоса ложится от вас к ней.",
		"Раз в секунду сносит лежащих и брошенные вещи на клетку; стоящих, пристёгнутых и антимагию не трогает.",
		"Стены, закрытые двери, окна и машины обрывают полосу; новое течение заменяет прежнее.",
		"Без давления, перезарядка 30 секунд.",
		"С этим знанием Уйти в слив стоит 1 давление и перезаряжается 30 секунд вместо 60.",
	)
	role = HERETIC_ROLE_CONTROL
	gain_text = "Течения не спорят с берегом. Они просто уносят всё, что лежит у них на пути."
	cost = 2
	route = PATH_TIDE
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_tide/current

/datum/eldritch_knowledge/spell/tide_current/on_body_gain(mob/living/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	tide?.update_dive()

/datum/eldritch_knowledge/spell/tide_well
	name = "Чёрный водоворот"
	summary = "За 2 давления воронка на 12 секунд в 5 клетках тянет и бьёт врагов."
	details = list(
		"Первый удар в 2 клетках: 12 ушибов, 18 выносливости, падение на 1,5 секунды и притяжение.",
		"Каждые 2 секунды тянет на клетку: на краю 6 ушибов и 8 выносливости, у центра 12 и 12 с падением.",
		"60 прочности, нулевой жезл её разрушает; работает, пока вы в 7 клетках без преград.",
		"Одновременно одна, перезарядка 30 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Воронка ведёт не вниз. Она ведёт домой."
	cost = 1
	route = PATH_TIDE
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_tide/well

/datum/eldritch_knowledge/tide_depth
	name = "Тысяча саженей"
	summary = "Запас давления растёт до 5, единица возвращается за 10 секунд."
	details = list(
		"Улучшения: запас 6 и 7, восстановление за 8 и 6 секунд.",
		"Вознесение даёт запас 8 и восстановление за 4 секунды.",
	)
	role = HERETIC_ROLE_PASSIVE
	gain_text = "У глубины нет дна. Есть лишь предел того, что я готов вместить."
	cost = 2
	route = PATH_TIDE
	passive_values = list(5, 6, 7)
	passive_desc = "Запас давления: 5 / 6 / 7. Восстановление единицы: 10 / 8 / 6 секунд. Вознесение даёт запас 8 и восстановление за 4 секунды."

/datum/eldritch_knowledge/tide_depth/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	tide?.update_capacity()

/datum/eldritch_knowledge/tide_depth/on_passive_upgrade(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	tide?.update_capacity()

/datum/eldritch_knowledge/spell/tide_deluge
	name = "Обрушение толщи"
	summary = "Весь запас давления обрушивается на область, затем разливается море на 15 секунд."
	details = list(
		"Через секунду подготовки область радиусом 2 в 5 клетках: 20 ушибов + 6 за давление, падение на 2 секунды.",
		"Выносливость: 20 + 3 за давление; при полном начальном запасе это 44 ушиба и 32 выносливости.",
		"Море радиусом 4: враги мокнут и замедляются, вы быстрее и получаете давление раз в 4 секунды.",
		"Вода не проходит сквозь стены, окна, закрытые двери и машины.",
		"Нужно не меньше 2 давления; в подготовке можно сместиться на 2 клетки, область стоит на месте.",
		"Потеря видимости, дальность или оглушение срывают удар без расхода. Перезарядка 25 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Я услышал треск стекла. Между нами и морем никогда не было ничего прочнее."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_TIDE
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_tide/deluge

/datum/eldritch_knowledge/final_eldritch/tide_final
	parallax_scene = ANTAG_SCENE_HERETIC_TIDE
	name = "Владыка Пучины"
	summary = "Пол вокруг вас заливает чёрная вода, давление растёт, открывается Голос Пучины."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; станция узнаёт место обряда, он длится 30 секунд.",
		"Общая стойкость вознесения, запас давления 8, единица за 4 секунды.",
		"Каждые 2 секунды вода заливает пол в 2 клетках, шаги оставляют лужи; без обновления вода уходит за 4 секунды.",
		"Стены, закрытые двери, окна и машины воду держат, столы и перила пропускают.",
		"Враги в воде мокнут на 8 секунд и замедляются, пока стоят в ней; вы по ней быстрее, пол не скользкий.",
		"Голос Пучины раз в 30 секунд: 30 ушибов, 40 выносливости, падение на 3 секунды и снос на 3 клетки.",
		"Пристёгнутых и закреплённых волна не сносит. Смерть снимает усиления, оживление возвращает.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Берег исчез. Осталось только моё дыхание, и море дышало вместе со мной. Теперь оно разливалось у моих ног, куда бы я ни шёл."
	route = PATH_TIDE
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_tide/leviathan)
	var/datum/weakref/tide_knowledge_ref

/datum/eldritch_knowledge/final_eldritch/tide_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!tide)
		return
	tide_knowledge_ref = WEAKREF(tide)
	tide.ascension_active = TRUE
	tide.update_capacity()
	user.AddComponent(/datum/component/heretic_tide_flood, tide)

/datum/eldritch_knowledge/final_eldritch/tide_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_tide_flood))
	var/datum/eldritch_knowledge/base_tide/tide = tide_knowledge_ref?.resolve()
	tide_knowledge_ref = null
	if(tide)
		tide.ascension_active = FALSE
		tide.update_capacity()
	return ..()

/// Прилив: пол вокруг вознёсшегося залит его водой, враги в ней мокнут, а сам он по ней ходит быстрее.
/datum/component/heretic_tide_flood
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/tide_ref
	var/list/obj/effect/heretic_tide_puddle/puddles = list()
	var/flood_timer
	COOLDOWN_DECLARE(step_splash)

/datum/component/heretic_tide_flood/Initialize(datum/eldritch_knowledge/base_tide/tide)
	if(!isliving(parent) || QDELETED(tide))
		return COMPONENT_INCOMPATIBLE
	tide_ref = WEAKREF(tide)

/datum/component/heretic_tide_flood/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	flood()

/datum/component/heretic_tide_flood/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_EXAMINE))
	var/mob/living/owner = parent
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_flow)

/datum/component/heretic_tide_flood/Destroy()
	deltimer(flood_timer)
	flood_timer = null
	var/list/old_puddles = puddles
	puddles = list()
	QDEL_LIST(old_puddles)
	tide_ref = null
	return ..()

/datum/component/heretic_tide_flood/proc/flood()
	deltimer(flood_timer)
	flood_timer = addtimer(CALLBACK(src, PROC_REF(flood)), HERETIC_TIDE_FLOOD_INTERVAL, TIMER_STOPPABLE)
	var/mob/living/owner = parent
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide?.ascension_active || owner.stat == DEAD || !isturf(owner.loc))
		return
	var/turf/center = owner.loc
	for(var/turf/open/tile in RANGE_TURFS(HERETIC_TIDE_FLOOD_RADIUS, center))
		if(!tide.line_clear(center, tile, HERETIC_TIDE_FLOOD_RADIUS) || !wet_tile(tile))
			continue
		for(var/mob/living/victim in tile)
			soak(victim)
	update_haste()

/datum/component/heretic_tide_flood/proc/wet_tile(turf/open/tile)
	if(!istype(tile) || isgroundlessturf(tile) || istype(tile, /turf/open/lava))
		return FALSE
	var/obj/effect/heretic_tide_puddle/puddle = own_puddle(tile)
	if(puddle)
		puddle.refresh()
	else
		new /obj/effect/heretic_tide_puddle(tile, src)
	return TRUE

/datum/component/heretic_tide_flood/proc/own_puddle(atom/place)
	if(!isturf(place))
		return null
	for(var/obj/effect/heretic_tide_puddle/puddle in place)
		if(!QDELETED(puddle) && puddle.flood_ref?.resolve() == src)
			return puddle
	return null

/datum/component/heretic_tide_flood/proc/soak(mob/living/victim)
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide?.ascension_active)
		tide.keep_soaked(victim)

/datum/component/heretic_tide_flood/proc/update_haste()
	var/mob/living/owner = parent
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide?.ascension_active && owner.stat != DEAD && own_puddle(owner.loc))
		owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_flow)
	else
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_flow)

/datum/component/heretic_tide_flood/proc/puddle_gone(obj/effect/heretic_tide_puddle/puddle)
	puddles -= puddle
	var/mob/living/owner = parent
	if(owner.loc == puddle.loc)
		update_haste()

/datum/component/heretic_tide_flood/proc/on_moved(mob/living/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide?.ascension_active && source.stat != DEAD)
		if(wet_tile(source.loc) && COOLDOWN_FINISHED(src, step_splash) && heretic_vfx_watched(source))
			splash_step(source.loc)
	update_haste()

/// Брызги из-под шага по своей воде.
/datum/component/heretic_tide_flood/proc/splash_step(turf/place)
	COOLDOWN_START(src, step_splash, HERETIC_TIDE_STEP_SPLASH_COOLDOWN)
	heretic_vfx_burst(place, /particles/heretic_ascension/tide/step, HERETIC_VFX_BURST_TIME / 3, FALSE)

/datum/component/heretic_tide_flood/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("У его ног разливается чёрная вода, за ним тянется мокрый след: пол в двух клетках от него залит, вошедшие в воду мокнут и замедляются, а по своей воде он ходит быстрее. Держитесь дальше двух клеток, не идите по следу и стреляйте издалека; стены, окна, закрытые двери и машины воду не пропускают, пристёгнутых и закреплённых его волна не сносит.")

/obj/effect/heretic_tide_puddle
	name = "abyssal water"
	desc = "Чёрная вода Пучины стоит на сухом полу. Вошедший в неё намокает и замедляется. Без хозяина рядом вода уходит за несколько секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_tide_effects.dmi'
	icon_state = "tide_puddle"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FLOOR_PLANE
	layer = ABOVE_NORMAL_TURF_LAYER
	var/datum/weakref/flood_ref
	var/datum/weakref/tide_ref
	var/expires_at
	var/expiry_timer
	var/lifetime = HERETIC_TIDE_FLOOD_LIFETIME

/obj/effect/heretic_tide_puddle/Initialize(mapload, datum/source)
	. = ..()
	if(QDELETED(source) || !attach(source))
		return INITIALIZE_HINT_QDEL
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	alpha = 0
	flick("tide_puddle_spread", src)
	animate(src, alpha = 255, time = HERETIC_TIDE_PUDDLE_RISE, easing = SINE_EASING | EASE_OUT)
	refresh()

/obj/effect/heretic_tide_puddle/Destroy()
	if(isturf(loc))
		drain_away()
	deltimer(expiry_timer)
	expiry_timer = null
	detach()
	return ..()

/obj/effect/heretic_tide_puddle/proc/attach(datum/component/heretic_tide_flood/flood)
	flood_ref = WEAKREF(flood)
	flood.puddles += src
	return TRUE

/obj/effect/heretic_tide_puddle/proc/detach()
	var/datum/component/heretic_tide_flood/flood = flood_ref?.resolve()
	flood?.puddle_gone(src)
	flood_ref = null
	tide_ref = null

/obj/effect/heretic_tide_puddle/proc/soak_arrival(mob/living/arrived)
	var/datum/component/heretic_tide_flood/flood = flood_ref?.resolve()
	flood?.soak(arrived)

/// Обновлённая вода держится ещё полный срок.
/obj/effect/heretic_tide_puddle/proc/refresh()
	deltimer(expiry_timer)
	expires_at = world.time + lifetime
	expiry_timer = QDEL_IN_STOPPABLE(src, lifetime)

/// Ушедшая вода, в срок или раньше, не пропадает рывком: её отпечаток стекает на месте.
/obj/effect/heretic_tide_puddle/proc/drain_away()
	var/obj/effect/temp_visual/heretic_vfx/ghost/drain = new(loc, src, null, HERETIC_TIDE_PUDDLE_DRAIN)
	if(QDELETED(drain))
		return
	drain.alpha = drain.model_share(255)
	drain.transform = matrix()
	animate(drain, alpha = 0, transform = matrix(HERETIC_TIDE_PUDDLE_DRAIN_SCALE, 0, 0, 0, HERETIC_TIDE_PUDDLE_DRAIN_SCALE, 0), time = HERETIC_TIDE_PUDDLE_DRAIN, easing = SINE_EASING | EASE_IN)

/obj/effect/heretic_tide_puddle/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(isliving(arrived))
		soak_arrival(arrived)

/// Море после Обрушения: держится без хозяина рядом и принадлежит знанию, а не телу.
/obj/effect/heretic_tide_puddle/sea
	desc = "Чёрная вода Пучины разлилась после обрушения толщи. Вошедший в неё намокает и замедляется, а еретик в ней быстрее ходит и быстрее копит давление. Вода уходит через 15 секунд."
	lifetime = HERETIC_TIDE_SEA_LIFETIME

/obj/effect/heretic_tide_puddle/sea/attach(datum/eldritch_knowledge/base_tide/tide)
	tide_ref = WEAKREF(tide)
	tide.sea += src
	return TRUE

/obj/effect/heretic_tide_puddle/sea/detach()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	tide_ref = null
	if(!tide)
		return
	tide.sea -= src
	if(tide.tide_body?.loc == loc)
		tide.update_water_haste()

/obj/effect/heretic_tide_puddle/sea/soak_arrival(mob/living/arrived)
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide && arrived != tide.tide_body)
		tide.keep_soaked(arrived)

/// Вода прорыва держится, пока источник открыт: прорыв обновляет её раньше, чем она уйдёт.
/obj/effect/heretic_tide_puddle/breach
	desc = "Чёрная вода натекла из прорыва и не уходит в слив. Вошедший в неё намокает и замедляется. Прорыв закрывают гаечным ключом или нулевым жезлом по источнику воды."
	lifetime = HERETIC_TIDE_BREACH_WATER_TIME
	var/datum/weakref/breach_ref

/obj/effect/heretic_tide_puddle/breach/attach(datum/heretic_tide_breach/breach)
	breach_ref = WEAKREF(breach)
	tide_ref = WEAKREF(breach.tide)
	breach.puddles += src
	return TRUE

/obj/effect/heretic_tide_puddle/breach/detach()
	var/datum/heretic_tide_breach/breach = breach_ref?.resolve()
	breach?.puddles -= src
	breach_ref = null
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	tide_ref = null
	if(tide?.tide_body?.loc == loc)
		tide.update_water_haste()

/obj/effect/heretic_tide_puddle/breach/soak_arrival(mob/living/arrived)
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide && arrived != tide.tide_body)
		tide.keep_soaked(arrived)

/// Прорыв: вода из источника стоит вокруг него, пока его не закроют или не выйдет срок.
/datum/heretic_tide_breach
	var/atom/source
	var/datum/eldritch_knowledge/base_tide/tide
	var/list/obj/effect/heretic_tide_puddle/breach/puddles = list()
	var/refresh_timer
	var/expiry_timer

/datum/heretic_tide_breach/New(atom/source, datum/eldritch_knowledge/base_tide/tide)
	src.source = source
	src.tide = tide
	expiry_timer = addtimer(CALLBACK(src, PROC_REF(expire)), HERETIC_TIDE_BREACH_LIFETIME, TIMER_STOPPABLE)
	RegisterSignal(source, COMSIG_ATOM_TOOL_ACT(TOOL_WRENCH), PROC_REF(on_wrench))
	RegisterSignal(source, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(on_item_interaction))
	flood()

/datum/heretic_tide_breach/Destroy()
	deltimer(refresh_timer)
	deltimer(expiry_timer)
	refresh_timer = null
	expiry_timer = null
	UnregisterSignal(source, list(COMSIG_ATOM_TOOL_ACT(TOOL_WRENCH), COMSIG_ATOM_ITEM_INTERACTION))
	var/list/old_puddles = puddles
	puddles = list()
	QDEL_LIST(old_puddles)
	source = null
	tide = null
	return ..()

/datum/heretic_tide_breach/proc/flood()
	deltimer(refresh_timer)
	refresh_timer = addtimer(CALLBACK(src, PROC_REF(flood)), HERETIC_TIDE_BREACH_REFRESH, TIMER_STOPPABLE)
	var/turf/center = get_turf(source)
	if(!center)
		return
	for(var/turf/open/tile in RANGE_TURFS(HERETIC_TIDE_BREACH_RADIUS, center))
		if(isgroundlessturf(tile) || istype(tile, /turf/open/lava) || !tide.line_clear(center, tile, HERETIC_TIDE_BREACH_RADIUS))
			continue
		var/obj/effect/heretic_tide_puddle/breach/puddle = puddle_at(tile)
		if(puddle)
			puddle.refresh()
		else
			new /obj/effect/heretic_tide_puddle/breach(tile, src)
		for(var/mob/living/victim in tile)
			if(victim != tide.tide_body)
				tide.keep_soaked(victim)
	tide.update_water_haste()

/datum/heretic_tide_breach/proc/puddle_at(turf/tile)
	for(var/obj/effect/heretic_tide_puddle/breach/puddle in tile)
		if(!QDELETED(puddle) && puddle.breach_ref?.resolve() == src)
			return puddle
	return null

/datum/heretic_tide_breach/proc/expire()
	tide.close_breach(source)

/datum/heretic_tide_breach/proc/on_wrench(atom/target, mob/living/user, obj/item/tool)
	SIGNAL_HANDLER
	close_by_wrench(user, tool)
	return TOOL_ACT_MELEE_CHAIN_BLOCKING

/// Раковина разбирается ключом и моет предметы прямо в attackby, поэтому ключ и жезл перехватываются до него.
/datum/heretic_tide_breach/proc/on_item_interaction(atom/target, mob/living/user, obj/item/tool, params)
	SIGNAL_HANDLER
	if(tool.tool_behaviour == TOOL_WRENCH)
		close_by_wrench(user, tool)
		return TOOL_ACT_MELEE_CHAIN_BLOCKING
	if(!istype(tool, /obj/item/nullrod))
		return NONE
	var/datum/component/heretic_craft/craft = heretic_craft_on(source, HERETIC_TIDE_BREACH_CRAFT)
	craft?.on_attackby(source, tool, user, params)
	return TOOL_ACT_MELEE_CHAIN_BLOCKING

/datum/heretic_tide_breach/proc/close_by_wrench(mob/living/user, obj/item/tool)
	tool.play_tool_sound(source)
	user.visible_message(span_warning("[user] перекрывает [source] гаечным ключом, и чёрная вода уходит в слив."), span_notice("Вы перекрываете [source], и чёрная вода уходит в слив."))
	log_game("[key_name(user)] закрывает прорыв Пучины у [source] ([source.type]) гаечным ключом в [AREACOORD(source)].")
	tide.close_breach(source)

/obj/effect/heretic_tide_current
	name = "abyssal current"
	desc = "По полу тянется тёмная полоса воды и течёт в одну сторону. Лежащих и брошенные вещи она раз в секунду сносит на клетку к своему концу; стоящим не мешает. Течение держится 20 секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_tide_effects.dmi'
	icon_state = "tide_current"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FLOOR_PLANE
	layer = ABOVE_NORMAL_TURF_LAYER
	var/datum/weakref/tide_ref
	var/terminal = FALSE

/obj/effect/heretic_tide_current/Initialize(mapload, datum/eldritch_knowledge/base_tide/tide, direction, terminal = FALSE)
	. = ..()
	if(QDELETED(tide))
		return INITIALIZE_HINT_QDEL
	tide_ref = WEAKREF(tide)
	setDir(direction)
	src.terminal = terminal
	RegisterSignal(loc, COMSIG_PARENT_EXAMINE, PROC_REF(on_floor_examine))

/obj/effect/heretic_tide_current/proc/on_floor_examine(turf/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning(desc)

/datum/status_effect/heretic_tide_drowning
	id = "heretic_tide_drowning"
	duration = HERETIC_TIDE_DROWN_DURATION
	tick_interval = 1 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_tide_drowning
	examine_text = span_warning("SUBJECTPRONOUN захлёбывается: изо рта льётся чёрная вода, позвать на помощь не выходит. Вытащите на сухой пол, коснитесь нулевым жезлом или растолкайте 2 секунды.")
	var/datum/weakref/tide_ref
	var/applied = FALSE
	var/interrupted = FALSE

/datum/status_effect/heretic_tide_drowning/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_tide/tide)
	tide_ref = WEAKREF(tide)
	return ..()

/datum/status_effect/heretic_tide_drowning/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!. || !tide)
		return FALSE
	applied = TRUE
	tide.drownings += src
	ADD_TRAIT(owner, TRAIT_MUTE, HERETIC_TIDE_DROWN_TRAIT)
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignals(owner, list(COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN), PROC_REF(on_sacrifice_starting))
	heretic_capture_hold(owner, HERETIC_TIDE_CAPTURE)
	owner.visible_message(span_danger("[owner] захлёбывается: изо рта хлещет чёрная вода!"), span_userdanger("Горло заливает чёрная вода: ни крикнуть, ни позвать по рации!"))
	return TRUE

/datum/status_effect/heretic_tide_drowning/tick()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide || owner.stat == DEAD || !tide.on_wet_floor(owner))
		qdel(src)
		return
	var/room = HERETIC_TIDE_DROWN_OXY_CAP - owner.getOxyLoss()
	if(room > 0)
		owner.adjustOxyLoss(min(HERETIC_TIDE_DROWN_OXY_PER_TICK, room))

/datum/status_effect/heretic_tide_drowning/proc/on_moved(datum/source)
	SIGNAL_HANDLER
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide?.on_wet_floor(owner))
		qdel(src)

/datum/status_effect/heretic_tide_drowning/proc/on_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	user.visible_message(span_warning("[user] касается [source] нулевым жезлом, и чёрная вода выплёскивается из горла."), span_notice("Вы касаетесь [source] нулевым жезлом, и вода отпускает."))
	log_game("[key_name(user)] развеивает захлёб Пучины у [key_name(source)] нулевым жезлом в [AREACOORD(source)].")
	qdel(src)
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_tide_drowning/proc/on_sacrifice_starting(datum/source)
	SIGNAL_HANDLER
	interrupted = TRUE
	qdel(src)

/datum/status_effect/heretic_tide_drowning/on_remove()
	if(!applied)
		return ..()
	UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_ATTACKBY, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN))
	heretic_capture_unhold(owner, HERETIC_TIDE_CAPTURE)
	REMOVE_TRAIT(owner, TRAIT_MUTE, HERETIC_TIDE_DROWN_TRAIT)
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	tide_ref = null
	tide?.drownings -= src
	// Истёкший срок отличает естественный конец от срыва и снятия.
	var/knocked_out = !interrupted && tide && world.time > duration && owner.stat != DEAD && tide.on_wet_floor(owner)
	if(knocked_out)
		owner.Unconscious(HERETIC_TIDE_DROWN_SLEEP)
		heretic_capture_knock_out(owner, tide, HERETIC_TIDE_CAPTURE, HERETIC_TIDE_DROWN_SLEEP)
		owner.visible_message(span_danger("[owner] обмякает, захлебнувшись чёрной водой."), span_userdanger("Вода заполняет лёгкие, и всё темнеет."))
	heretic_capture_release(owner, HERETIC_TIDE_CAPTURE, knocked_out ? HERETIC_TIDE_DROWN_SLEEP : 0)
	return ..()

/atom/movable/screen/alert/status_effect/heretic_tide_drowning
	name = "Захлёб"
	desc = "Горло залито чёрной водой: вы не можете говорить ни вслух, ни в рацию, удушье растёт. Выйдите на сухой пол или попросите коснуться вас нулевым жезлом или растолкать 2 секунды - захлёб прервётся. Иначе через 5 секунд вы потеряете сознание на 10 секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "tide_drowning"

/datum/movespeed_modifier/heretic_tide_flow
	multiplicative_slowdown = -HERETIC_TIDE_FLOOD_HASTE

/datum/movespeed_modifier/heretic_tide_sea
	multiplicative_slowdown = -HERETIC_TIDE_FLOOD_HASTE

#undef HERETIC_TIDE_RANGE
#undef HERETIC_TIDE_CHANNEL_MOVEMENT
#undef HERETIC_TIDE_WAVE_RADIUS
#undef HERETIC_TIDE_RELEASE_COST
#undef HERETIC_TIDE_HARVEST_TIME
#undef HERETIC_TIDE_WELL_LIFETIME
#undef HERETIC_TIDE_WELL_INTERVAL
#undef HERETIC_TIDE_ASCENDED_CAPACITY
#undef HERETIC_TIDE_PUDDLE_TIME
#undef HERETIC_TIDE_PRESSURE_INTERVAL
#undef HERETIC_TIDE_COLLISION_DAMAGE
#undef HERETIC_TIDE_PUDDLE_RISE
#undef HERETIC_TIDE_PUDDLE_DRAIN
#undef HERETIC_TIDE_PUDDLE_DRAIN_SCALE
#undef HERETIC_TIDE_STEP_SPLASH_COOLDOWN
#undef HERETIC_TIDE_SWELL_TIME
#undef HERETIC_TIDE_VOICE_WAVE_TIME
#undef HERETIC_TIDE_VOICE_FLASH_RANGE
#undef HERETIC_TIDE_VOICE_FLASH_POWER
#undef HERETIC_TIDE_VOICE_FLASH_TIME
#undef HERETIC_TIDE_VOICE_QUAKE
#undef HERETIC_TIDE_VOICE_QUAKE_RADIUS
#undef HERETIC_TIDE_VOICE_QUAKE_TIME
#undef HERETIC_TIDE_DELUGE_CHANNEL
#undef HERETIC_TIDE_SEA_RADIUS
#undef HERETIC_TIDE_SEA_LIFETIME
#undef HERETIC_TIDE_SEA_PRESSURE_INTERVAL
#undef HERETIC_TIDE_BREACH_CRAFT
#undef HERETIC_TIDE_BREACH_CLUE
#undef HERETIC_TIDE_BREACH_WATER_TIME
#undef HERETIC_TIDE_CAPTURE
#undef HERETIC_TIDE_DROWN_RANGE
#undef HERETIC_TIDE_DROWN_COST
#undef HERETIC_TIDE_DROWN_COOLDOWN
#undef HERETIC_TIDE_DROWN_TRAIT
#undef HERETIC_TIDE_CURRENT_RANGE
#undef HERETIC_TIDE_CURRENT_INTERVAL
#undef HERETIC_TIDE_CURRENT_COOLDOWN
#undef HERETIC_TIDE_DIVE_TIME
#undef HERETIC_TIDE_DIVE_REACH
