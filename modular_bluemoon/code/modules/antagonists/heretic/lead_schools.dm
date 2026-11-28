#define LEAD_CROWD_HASTE 0.1
#define LEAD_SIGHT_TIME (2 SECONDS)
#define LEAD_TRAP_SEEN_TIME (3 SECONDS)
#define LEAD_TRAP_EXAMINE_RANGE 3
#define LEAD_STANDOFF_CLICKS 3
#define TRAIT_HERETIC_LEAD_SLOWED "heretic_lead_slowed_bullet"

/// Школы стрельбы по id в порядке радиального меню.
GLOBAL_LIST_INIT(heretic_lead_schools, list(
	HERETIC_LEAD_SCHOOL_GUNSLINGER = new /datum/heretic_lead_school/gunslinger,
	HERETIC_LEAD_SCHOOL_HUNTER = new /datum/heretic_lead_school/hunter,
	HERETIC_LEAD_SCHOOL_CANNONEER = new /datum/heretic_lead_school/cannoneer,
))

/// Школа стрельбы: смещает упор пути, даёт свой приём и цвет трассеров и дыма.
/datum/heretic_lead_school
	var/id
	var/name
	/// Подпись варианта в радиальном меню выбора.
	var/choice_text
	var/choice_state
	var/tracer_state
	var/smoke_color
	var/spell_type
	var/chosen_text
	var/scent_line
	var/lesson_text

/datum/heretic_lead_school/gunslinger
	id = HERETIC_LEAD_SCHOOL_GUNSLINGER
	name = "Стрелок"
	choice_text = "Стрелок: каждый вооружённый враг на виду ускоряет шаг и выстрелы; против трёх стволов - Мгновение: чужие пули вязнут, а летящие в вас вы ловите"
	choice_state = "lead_school_gunslinger"
	tracer_state = "lead_tracer_gunslinger"
	smoke_color = "#ffb4a6"
	spell_type = /obj/effect/proc_holder/spell/self/heretic_lead/standoff
	chosen_text = "Вы выбираете Школу Стрелка. Чем больше стволов на вас смотрит, тем вы быстрее; когда стреляют трое разом, время для вас замедляется - Мгновение, и летящие в вас пули вы ловите на лету. Ваши трассеры теперь красные."
	scent_line = "Вокруг него то и дело щёлкает, будто рядом взводят курки."
	lesson_text = "Стрелок: каждый вооружённый враг на виду ускоряет шаг и выстрелы, а три стрелка за 3 секунды включают Мгновение: пули рядом вязнут, летящие в вас ловятся. Экипаж слышит щелчки курков и видит красное кольцо под ногами: лучше разойтись или перестать стрелять."

/datum/heretic_lead_school/hunter
	id = HERETIC_LEAD_SCHOOL_HUNTER
	name = "Охотник"
	choice_text = "Охотник: прицельный выстрел быстрее и дальше, Мишень дольше и видна сквозь стены, Растяжки на проходах"
	choice_state = "lead_school_hunter"
	tracer_state = "lead_tracer_hunter"
	smoke_color = "#e6ebf4"
	spell_type = /obj/effect/proc_holder/spell/pointed/heretic_lead/tripwire
	chosen_text = "Вы выбираете Школу Охотника. Прицел сходится быстрее и бьёт дальше, меченых вы видите сквозь стены, а на проходах ждут ваши Растяжки. Ваши трассеры теперь бледные."
	scent_line = "От него тянет холодной оружейной смазкой, на рукаве блестит обрывок тонкой проволоки."
	lesson_text = "Охотник: кнопка «Растяжка» натягивает проволоку на соседней клетке. Экипаж находит её осмотром клетки или Т-сканером и режет кусачками."

/datum/heretic_lead_school/cannoneer
	id = HERETIC_LEAD_SCHOOL_CANNONEER
	name = "Канонир"
	choice_text = "Канонир: Свинцовый дождь сразу, шире и за единицу; веер длиннее, Пороховая пуля хлопает, Пороховые закладки"
	choice_state = "lead_school_cannoneer"
	tracer_state = "lead_tracer_cannoneer"
	smoke_color = "#ffcd94"
	spell_type = /obj/effect/proc_holder/spell/pointed/heretic_lead/powder_charge
	chosen_text = "Вы выбираете Школу Канонира. Свинцовый дождь ваш уже сейчас, шире и дешевле, веер длиннее, Пороховая пуля хлопает, а под ногами врагов ждут ваши закладки. Ваши трассеры теперь огненные."
	scent_line = "Резко пахнет рассыпанным порохом, в складках одежды скрипят чёрные крупинки."
	lesson_text = "Канонир: Свинцовый дождь у вас с выбора Школы, круг шире и стоит единицу. Кнопка «Пороховая закладка» кладёт горсть гильз с дорожкой пороха на соседнюю клетку. Экипаж заливает её водой или пеной, собирает руками за 2 секунды или подрывает выстрелом издали."

/datum/eldritch_knowledge/base_lead
	var/school
	/// Вооружённые враги на виду у Стрелка, до HERETIC_LEAD_CROWD_CAP.
	var/crowd = 0
	/// Стрелки Мексиканской дуэли: REF(стрелка) => когда стрелял.
	var/list/duel_shooters = list()
	/// Серия Стрелка: REF(цели) => когда попал.
	var/list/spree_hits = list()
	var/standoff_shots = 0
	var/standoff_shots_until = 0
	var/list/obj/structure/heretic_lead_tripwire/tripwires = list()
	var/list/obj/structure/heretic_lead_charge/charges = list()
	var/list/atom/movable/screen/heretic_lead_sight/sights = list()
	COOLDOWN_DECLARE(standoff_cooldown)

/datum/eldritch_knowledge/base_lead/proc/school_datum()
	return school ? GLOB.heretic_lead_schools[school] : null

/datum/eldritch_knowledge/base_lead/proc/school_block_reason(mob/living/user)
	if(!can_use(user, TRUE))
		return "Способность недоступна вашему пути или текущему телу."
	if(!knows(/datum/eldritch_knowledge/lead_mark))
		return "Школа стрельбы открывается на четвёртой ступени пути, вместе с Мишенью."
	var/datum/heretic_lead_school/chosen = school_datum()
	if(chosen)
		return "Школа «[chosen.name]» уже выбрана: сменить её можно только сбросом пути."
	return null

/datum/eldritch_knowledge/base_lead/proc/open_school_menu(mob/living/user)
	lead_failure = school_block_reason(user)
	if(lead_failure)
		return FALSE
	var/list/choices = list()
	var/list/ids = list()
	for(var/school_id in GLOB.heretic_lead_schools)
		var/datum/heretic_lead_school/option = GLOB.heretic_lead_schools[school_id]
		choices[option.choice_text] = image(icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi', icon_state = option.choice_state)
		ids[option.choice_text] = school_id
	var/choice = show_radial_menu(user, user, choices, tooltips = TRUE)
	var/datum/heretic_lead_school/picked = choice ? GLOB.heretic_lead_schools[ids[choice]] : null
	if(!picked || tgui_alert(user, "Школа «[picked.name]» выбирается один раз: сменить её можно только сбросом пути. Выбрать?", "Школа стрельбы", list("Выбрать", "Подумать")) != "Выбрать")
		lead_failure = "Школа не выбрана: кнопка «Школа стрельбы» подождёт."
		return FALSE
	return choose_school(user, picked.id)

/// Школа выбирается один раз и держится до сброса пути.
/datum/eldritch_knowledge/base_lead/proc/choose_school(mob/living/user, school_id)
	lead_failure = school_block_reason(user)
	if(lead_failure)
		return FALSE
	var/datum/heretic_lead_school/chosen = GLOB.heretic_lead_schools[school_id]
	if(!chosen)
		lead_failure = "Такой Школы нет."
		return FALSE
	school = school_id
	var/datum/antagonist/heretic/heretic = owner_heretic()
	var/datum/eldritch_knowledge/lead_mark/mark_knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/lead_mark)
	mark_knowledge?.refresh_school_powers(user)
	new /obj/effect/temp_visual/heretic_lead/ricochet(get_turf(user))
	heretic_lead_sound(user, "school_[school]", 55)
	user.visible_message(span_warning("[user] проворачивает в пальцах невидимый барабан, и в воздухе пахнет порохом."), span_eldritch(chosen.chosen_text))
	log_game("[key_name(user)] выбирает Школу стрельбы Свинца «[chosen.name]» в [AREACOORD(user)].")
	school_tick()
	notify_resource_changed()
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "school", user, school)
	return TRUE

/datum/eldritch_knowledge/base_lead/proc/school_state()
	var/datum/heretic_lead_school/chosen = school_datum()
	if(!chosen)
		return knows(/datum/eldritch_knowledge/lead_mark) ? " Школа стрельбы ещё не выбрана." : ""
	. = " Школа: [chosen.name]."
	switch(school)
		if(HERETIC_LEAD_SCHOOL_GUNSLINGER)
			. += " Вооружённых врагов на виду: [crowd]."
			if(standoff_shot_ready())
				. += " Мгновенных выстрелов: [standoff_shots]."
			else if(!COOLDOWN_FINISHED(src, standoff_cooldown))
				. += " Мгновение отдыхает [CEILING(COOLDOWN_TIMELEFT(src, standoff_cooldown) / (1 SECONDS), 1)] с."
		if(HERETIC_LEAD_SCHOOL_HUNTER)
			. += " Растяжек: [length(tripwires)] из [HERETIC_LEAD_TRIPWIRE_LIMIT]."
		if(HERETIC_LEAD_SCHOOL_CANNONEER)
			. += " Закладок: [length(charges)] из [HERETIC_LEAD_CHARGE_LIMIT]."

/// Раз в жизненный такт: Стрелок пересчитывает стволы вокруг, Охотник видит меченых сквозь стены.
/datum/eldritch_knowledge/base_lead/proc/school_tick()
	switch(school)
		if(HERETIC_LEAD_SCHOOL_GUNSLINGER)
			set_crowd(count_crowd())
		if(HERETIC_LEAD_SCHOOL_HUNTER)
			show_sights()

/datum/eldritch_knowledge/base_lead/proc/clear_school_effects()
	set_crowd(0)
	QDEL_LIST(sights)
	standoff_shots = 0
	duel_shooters.Cut()
	spree_hits.Cut()
	lead_body?.remove_status_effect(/datum/status_effect/heretic_lead_standoff)

/datum/eldritch_knowledge/base_lead/proc/clear_traps()
	QDEL_LIST(tripwires)
	QDEL_LIST(charges)

/datum/eldritch_knowledge/base_lead/proc/school_tracer(obj/item/projectile/projectile)
	var/datum/heretic_lead_school/chosen = school_datum()
	if(!chosen || QDELETED(projectile))
		return null
	var/mutable_appearance/tracer = mutable_appearance(HERETIC_LEAD_SCHOOLS_FX_ICON, chosen.tracer_state)
	tracer.appearance_flags = RESET_COLOR | KEEP_APART
	projectile.add_overlay(tracer)
	return tracer

/datum/eldritch_knowledge/base_lead/proc/smoke_tint()
	var/datum/heretic_lead_school/chosen = school_datum()
	return chosen?.smoke_color

/proc/heretic_lead_armed(mob/living/someone)
	return locate(/obj/item/gun) in someone.held_items

/datum/eldritch_knowledge/base_lead/proc/count_crowd()
	. = 0
	if(school != HERETIC_LEAD_SCHOOL_GUNSLINGER || QDELETED(lead_body) || lead_body.stat == DEAD || !isturf(lead_body.loc))
		return
	for(var/mob/living/enemy in range(HERETIC_LEAD_CROWD_RANGE, lead_body))
		if(enemy == lead_body || enemy.stat == DEAD || IS_HERETIC(enemy) || IS_HERETIC_MONSTER(enemy) || !heretic_lead_armed(enemy))
			continue
		if(!can_see(lead_body, enemy, HERETIC_LEAD_CROWD_RANGE))
			continue
		.++
		if(. >= HERETIC_LEAD_CROWD_CAP)
			return

/// Толпа злит Стрелка: каждый ствол на виду ускоряет шаг и выстрелы.
/datum/eldritch_knowledge/base_lead/proc/set_crowd(count)
	if(crowd == count)
		return
	crowd = count
	if(!QDELETED(lead_body))
		if(crowd)
			lead_body.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/heretic_lead_crowd, multiplicative_slowdown = -LEAD_CROWD_HASTE * crowd)
		else
			lead_body.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_lead_crowd)
	notify_resource_changed()

/datum/eldritch_knowledge/base_lead/proc/shot_delay()
	return CLICK_CD_RANGE * (100 - crowd * HERETIC_LEAD_CROWD_RATE) / 100

/datum/eldritch_knowledge/base_lead/proc/aim_time()
	return school == HERETIC_LEAD_SCHOOL_HUNTER ? HERETIC_LEAD_HUNTER_AIM_TIME : HERETIC_LEAD_AIM_TIME

/datum/eldritch_knowledge/base_lead/proc/aim_range()
	return school == HERETIC_LEAD_SCHOOL_HUNTER ? HERETIC_LEAD_HUNTER_AIM_RANGE : HERETIC_LEAD_AIM_RANGE

/datum/eldritch_knowledge/base_lead/proc/rain_radius()
	return school == HERETIC_LEAD_SCHOOL_CANNONEER ? HERETIC_LEAD_CANNON_RAIN_RADIUS : HERETIC_LEAD_RAIN_RADIUS

/datum/eldritch_knowledge/base_lead/proc/rain_cost()
	return school == HERETIC_LEAD_SCHOOL_CANNONEER ? HERETIC_LEAD_CANNON_RAIN_COST : HERETIC_LEAD_RAIN_COST

/datum/eldritch_knowledge/base_lead/proc/fan_extra()
	return school == HERETIC_LEAD_SCHOOL_CANNONEER ? HERETIC_LEAD_CANNON_FAN_EXTRA : 0

/proc/heretic_lead_harmful_shot(fired)
	var/obj/item/projectile/shot = fired
	if(istype(shot))
		return !shot.nodamage && shot.damage > 0
	if(ispath(fired, /obj/item/projectile))
		return !initial(shot.nodamage) && initial(shot.damage) > 0
	return TRUE

/// Чужая пуля пролетает рядом со Стрелком или попадает в него.
/datum/eldritch_knowledge/base_lead/proc/note_duel_shot(obj/item/projectile/projectile)
	if(!projectile.fired || !heretic_lead_harmful_shot(projectile))
		return FALSE
	return note_duel_shooter(projectile.firer)

/// Выстрел в Стрелка или в его сторону в 7 клеток, долетела пуля или нет: три разных стрелка за 3 секунды начинают Мгновение.
/datum/eldritch_knowledge/base_lead/proc/note_duel_shooter(mob/living/shooter)
	if(school != HERETIC_LEAD_SCHOOL_GUNSLINGER || QDELETED(lead_body) || lead_body.stat == DEAD)
		return FALSE
	if(!isliving(shooter) || shooter == lead_body || IS_HERETIC(shooter) || IS_HERETIC_MONSTER(shooter))
		return FALSE
	var/list/fresh = list()
	for(var/key in duel_shooters)
		if(world.time - duel_shooters[key] <= HERETIC_LEAD_STANDOFF_WINDOW)
			fresh[key] = duel_shooters[key]
	fresh[REF(shooter)] = world.time
	duel_shooters = fresh
	if(length(duel_shooters) < HERETIC_LEAD_STANDOFF_SHOOTERS || !COOLDOWN_FINISHED(src, standoff_cooldown))
		return FALSE
	return !!start_standoff(lead_body, FALSE)

/datum/eldritch_knowledge/base_lead/proc/on_body_projectile(mob/living/source, obj/item/projectile/projectile, def_zone)
	SIGNAL_HANDLER
	note_duel_shot(projectile)

/datum/eldritch_knowledge/base_lead/proc/standoff_block_reason(mob/living/user, manual = TRUE)
	if(school != HERETIC_LEAD_SCHOOL_GUNSLINGER)
		return "Мгновение - приём Школы Стрелка."
	if(!can_use(user, TRUE))
		return "Способность недоступна вашему пути или текущему телу."
	if(!COOLDOWN_FINISHED(src, standoff_cooldown))
		return "Мгновение отдыхает ещё [CEILING(COOLDOWN_TIMELEFT(src, standoff_cooldown) / (1 SECONDS), 1)] с."
	if(user.has_status_effect(/datum/status_effect/heretic_lead_standoff))
		return "Мгновение уже идёт."
	if(manual && count_crowd() < HERETIC_LEAD_STANDOFF_SHOOTERS)
		return "Мексиканской дуэли нет: на вас должны смотреть стволы хотя бы [HERETIC_LEAD_STANDOFF_SHOOTERS] вооружённых врагов. Само Мгновение начнётся, когда за [HERETIC_LEAD_STANDOFF_WINDOW / (1 SECONDS)] секунды в вас выстрелят [HERETIC_LEAD_STANDOFF_SHOOTERS] разных стрелка в [HERETIC_LEAD_UNDER_FIRE_RANGE] клетках."
	return null

/// Мгновение: щелчки курков и кольцо под ногами, чужие пули рядом вязнут, следующие выстрелы Шестизарядника мгновенные и прицельные.
/datum/eldritch_knowledge/base_lead/proc/start_standoff(mob/living/user, manual = TRUE)
	lead_failure = standoff_block_reason(user, manual)
	if(lead_failure)
		return null
	var/datum/status_effect/heretic_lead_standoff/standoff = user.apply_status_effect(/datum/status_effect/heretic_lead_standoff, src)
	if(QDELETED(standoff))
		lead_failure = "Мгновение не началось."
		return null
	COOLDOWN_START(src, standoff_cooldown, HERETIC_LEAD_STANDOFF_COOLDOWN)
	standoff_shots = HERETIC_LEAD_STANDOFF_SHOTS
	standoff_shots_until = world.time + HERETIC_LEAD_STANDOFF_SHOTS_TIME
	duel_shooters.Cut()
	var/datum/antagonist/heretic/heretic = owner_heretic()
	var/datum/eldritch_knowledge/lead_mark/mark_knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/lead_mark)
	var/obj/effect/proc_holder/spell/button = mark_knowledge?.school_power
	if(!manual && istype(button, /obj/effect/proc_holder/spell/self/heretic_lead/standoff))
		button.charge_counter = 0
		button.start_recharge()
		button.action?.UpdateButtons()
	log_game("[key_name(user)] входит в Мгновение Стрелка ([manual ? "кнопкой" : "три стрелка за [HERETIC_LEAD_STANDOFF_WINDOW / (1 SECONDS)] секунды"]) в [AREACOORD(user)].")
	notify_resource_changed()
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "standoff", user)
	return standoff

/datum/eldritch_knowledge/base_lead/proc/standoff_shot_ready()
	return standoff_shots > 0 && world.time < standoff_shots_until

/// Серия Стрелка: попадания по трём разным людям за 6 секунд дают ещё 2 Свинца.
/datum/eldritch_knowledge/base_lead/proc/note_spree(mob/living/victim)
	if(school != HERETIC_LEAD_SCHOOL_GUNSLINGER || !ishuman(victim) || victim.stat == DEAD || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || QDELETED(lead_body) || lead_body.stat == DEAD)
		return FALSE
	var/list/fresh = list()
	for(var/key in spree_hits)
		if(world.time - spree_hits[key] <= HERETIC_LEAD_SPREE_WINDOW)
			fresh[key] = spree_hits[key]
	fresh[REF(victim)] = world.time
	spree_hits = fresh
	if(length(spree_hits) < HERETIC_LEAD_SPREE_TARGETS)
		return FALSE
	spree_hits = list()
	gain_combat_resource(HERETIC_LEAD_SPREE_LEAD)
	to_chat(lead_body, span_eldritch("Серия: [HERETIC_LEAD_SPREE_TARGETS] разные цели за [HERETIC_LEAD_SPREE_WINDOW / (1 SECONDS)] секунд - ещё [HERETIC_LEAD_SPREE_LEAD] Свинца."))
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "spree", victim)
	return TRUE

/// Охотник видит своих меченых сквозь стены и свои растяжки рядом.
/datum/eldritch_knowledge/base_lead/proc/show_sights()
	QDEL_LIST(sights)
	if(school != HERETIC_LEAD_SCHOOL_HUNTER || QDELETED(lead_body) || lead_body.stat == DEAD)
		return 0
	var/turf/here = get_turf(lead_body)
	if(!here)
		return 0
	for(var/datum/status_effect/eldritch/lead/mark as anything in marks)
		var/mob/living/victim = mark.owner
		var/turf/there = get_turf(victim)
		if(!there || there.z != here.z || get_dist(here, there) > HERETIC_LEAD_HUNTER_SIGHT_RANGE)
			continue
		if(isturf(victim.loc) && can_see(lead_body, victim, HERETIC_LEAD_HUNTER_SIGHT_RANGE))
			continue
		var/atom/movable/screen/heretic_lead_sight/sight = new(null, src, victim)
		sights += sight
		lead_body.client?.screen += sight
	for(var/obj/structure/heretic_lead_tripwire/wire as anything in tripwires)
		if(wire.z == here.z && get_dist(wire, here) <= HERETIC_LEAD_CROWD_RANGE)
			wire.reveal_to(lead_body, LEAD_SIGHT_TIME)
	return length(sights)

/datum/eldritch_knowledge/base_lead/proc/trap_block_reason(mob/living/user, atom/target)
	if(!can_use(user))
		return "Способность недоступна вашему пути или текущему телу."
	var/turf/spot = get_turf(target)
	if(!isopenturf(spot) || isgroundlessturf(spot) || spot.density || spot.z != user.z || get_dist(user, spot) > 1)
		return "Выберите свободный пол под собой или на соседней клетке."
	if(locate(/obj/structure/heretic_lead_tripwire) in spot)
		return "Здесь уже натянута растяжка."
	if(locate(/obj/structure/heretic_lead_charge) in spot)
		return "Здесь уже лежит закладка."
	if(lead_total() < HERETIC_LEAD_TRAP_COST)
		return "Нужна единица Свинца."
	return null

/datum/eldritch_knowledge/base_lead/proc/tripwire_block_reason(mob/living/user, atom/target)
	if(school != HERETIC_LEAD_SCHOOL_HUNTER)
		return "Растяжка - приём Школы Охотника."
	return trap_block_reason(user, target)

/datum/eldritch_knowledge/base_lead/proc/charge_block_reason(mob/living/user, atom/target)
	if(school != HERETIC_LEAD_SCHOOL_CANNONEER)
		return "Пороховая закладка - приём Школы Канонира."
	return trap_block_reason(user, target)

/datum/eldritch_knowledge/base_lead/proc/place_tripwire(mob/living/user, atom/target)
	lead_failure = tripwire_block_reason(user, target)
	if(lead_failure || !spend_combat_resource(HERETIC_LEAD_TRAP_COST))
		return null
	while(length(tripwires) >= HERETIC_LEAD_TRIPWIRE_LIMIT)
		qdel(tripwires[1])
	var/obj/structure/heretic_lead_tripwire/wire = new(get_turf(target), src)
	if(QDELETED(wire))
		return null
	heretic_lead_sound(wire, "tripwire_set", 35, TRUE, SILENCED_SOUND_EXTRARANGE)
	wire.reveal_to(user, LEAD_TRAP_SEEN_TIME)
	to_chat(user, span_eldritch("Проволока натянута над полом. Растяжек: [length(tripwires)] из [HERETIC_LEAD_TRIPWIRE_LIMIT]; самая старая уступит место новой."))
	log_game("[key_name(user)] ставит Растяжку Свинца в [AREACOORD(wire)].")
	notify_resource_changed()
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "tripwire", wire)
	return wire

/datum/eldritch_knowledge/base_lead/proc/place_charge(mob/living/user, atom/target)
	lead_failure = charge_block_reason(user, target)
	if(lead_failure || !spend_combat_resource(HERETIC_LEAD_TRAP_COST))
		return null
	while(length(charges) >= HERETIC_LEAD_CHARGE_LIMIT)
		qdel(charges[1])
	var/obj/structure/heretic_lead_charge/charge = new(get_turf(target), src)
	if(QDELETED(charge))
		return null
	heretic_lead_sound(charge, "charge_set", 40, TRUE, SILENCED_SOUND_EXTRARANGE)
	to_chat(user, span_eldritch("Горсть гильз и дорожка пороха легли на пол. Закладок: [length(charges)] из [HERETIC_LEAD_CHARGE_LIMIT]; самая старая уступит место новой."))
	log_game("[key_name(user)] кладёт Пороховую закладку Свинца в [AREACOORD(charge)].")
	notify_resource_changed()
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "charge", charge)
	return charge

/// Растяжка сработала: пуля из ближайшей стены в задевшего, попадание вешает Мишень.
/datum/eldritch_knowledge/base_lead/proc/tripwire_shot(mob/living/victim)
	var/turf/target_turf = get_turf(victim)
	var/turf/start = target_turf
	var/turf/wall
	var/best_distance
	for(var/turf/closed/candidate in range(HERETIC_LEAD_TRIPWIRE_WALL_RANGE, target_turf))
		var/list/line = get_line(candidate, target_turf)
		if(length(line) < 2)
			continue
		var/turf/muzzle = line[2]
		if(!heretic_tile_passable(muzzle) || !heretic_edge_line_clear(muzzle, target_turf))
			continue
		var/distance = get_dist_euclidian(candidate, target_turf)
		if(wall && distance >= best_distance)
			continue
		wall = candidate
		start = muzzle
		best_distance = distance
	var/obj/item/projectile/bullet/heretic_lead/tripwire/bullet = new(start)
	bullet.firer = lead_body
	bullet.fired_from = wall || start
	bullet.lead_ref = WEAKREF(src)
	bullet.def_zone = BODY_ZONE_CHEST
	bullet.preparePixelProjectile(victim, start)
	if(QDELETED(bullet))
		return null
	school_tracer(bullet)
	bullet.fire(null, start == target_turf ? victim : null)
	var/obj/effect/temp_visual/heretic_lead/muzzle/flash = new(start)
	flash.setDir(get_dir(start, victim))
	heretic_lead_sound(start, "shot", 50, TRUE)
	log_combat(lead_body, victim, "стреляет Растяжкой Свинца в", null, "пуля из [AREACOORD(start)]")
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "tripwire_shot", victim)
	return bullet

/// Хлопок пороха: сбивает с ног в 1 клетке, не дальше стен; закладка ещё и поджигает.
/proc/heretic_lead_pop(turf/center, datum/eldritch_knowledge/base_lead/lead, ignite = FALSE)
	. = list()
	if(!isturf(center))
		return
	new /obj/effect/temp_visual/heretic_lead/pop(center)
	heretic_lead_sound(center, "pop", 60, TRUE)
	var/mob/living/shooter = lead?.lead_body
	for(var/mob/living/victim in range(1, center))
		if(victim.stat == DEAD || victim == shooter || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || !heretic_edge_line_clear(center, victim))
			continue
		if(!victim.has_status_effect(/datum/status_effect/heretic_lead_staggered))
			victim.apply_status_effect(/datum/status_effect/heretic_lead_staggered)
			victim.Knockdown(HERETIC_LEAD_POP_KNOCKDOWN)
			lead?.note_knocked(victim)
		if(ignite)
			victim.adjust_fire_stacks(HERETIC_LEAD_CHARGE_STACKS)
			victim.IgniteMob()
		. += victim
		if(shooter)
			log_combat(shooter, victim, ignite ? "подрывает Пороховой закладкой Свинца" : "сбивает хлопком Пороховой пули")
		else
			victim.log_message("попадает под хлопок пороха Свинца в [AREACOORD(center)]", LOG_ATTACK, color = "red")

/// Свинцовый дождь знают с девятой ступени, а Канонир - с выбора Школы.
/datum/eldritch_knowledge/base_lead/proc/rain_known()
	return knows(/datum/eldritch_knowledge/spell/lead_rain) || (school == HERETIC_LEAD_SCHOOL_CANNONEER && knows(/datum/eldritch_knowledge/lead_mark))

/datum/eldritch_knowledge/lead_mark
	var/obj/effect/proc_holder/spell/self/heretic_lead/school/choice_power
	var/obj/effect/proc_holder/spell/school_power
	/// Дождь Канонира до девятой ступени; потом его сменяет кнопка самого знания.
	var/obj/effect/proc_holder/spell/pointed/heretic_lead/rain/school_rain

/datum/eldritch_knowledge/lead_mark/on_body_gain(mob/living/user)
	. = ..()
	refresh_school_powers(user)

/// До выбора - кнопка «Школа стрельбы», после - приём выбранной Школы на её горячей клавише.
/datum/eldritch_knowledge/lead_mark/proc/refresh_school_powers(mob/living/user)
	if(!user?.mind)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lead/lead = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/datum/heretic_lead_school/chosen = lead?.school_datum()
	if(!chosen)
		if(QDELETED(choice_power))
			choice_power = new
			user.mind.AddSpell(choice_power)
		return
	if(choice_power)
		heretic.swap_ability_hotkey(choice_power.type, chosen.spell_type)
	QDEL_NULL(choice_power)
	refresh_school_rain(user, lead)
	if(!QDELETED(school_power) && school_power.type == chosen.spell_type)
		return
	QDEL_NULL(school_power)
	school_power = new chosen.spell_type
	user.mind.AddSpell(school_power)

/datum/eldritch_knowledge/lead_mark/proc/refresh_school_rain(mob/living/user, datum/eldritch_knowledge/base_lead/lead)
	if(lead.school != HERETIC_LEAD_SCHOOL_CANNONEER || lead.knows(/datum/eldritch_knowledge/spell/lead_rain))
		QDEL_NULL(school_rain)
		return
	if(QDELETED(school_rain))
		school_rain = new
		user.mind.AddSpell(school_rain)

/datum/eldritch_knowledge/lead_mark/proc/drop_school_powers()
	QDEL_NULL(choice_power)
	QDEL_NULL(school_power)
	QDEL_NULL(school_rain)

/datum/eldritch_knowledge/spell/lead_rain/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/lead_mark/mark_knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/lead_mark)
	var/obj/effect/proc_holder/spell/early = mark_knowledge?.school_rain
	var/early_left = !QDELETED(early) && early.charge_counter < early.charge_max ? early.charge_max - early.charge_counter : 0
	if(early_left)
		spell_ready_at = max(spell_ready_at, world.time + early_left)
	mark_knowledge?.refresh_school_powers(user)
	return ..()

/datum/eldritch_knowledge/lead_mark/Destroy()
	drop_school_powers()
	return ..()

/obj/effect/proc_holder/spell/self/heretic_lead/school
	name = "Школа стрельбы"
	desc = "Выберите одну из трёх Школ стрельбы. Выбор один: сменить Школу можно только сбросом пути. Приём Школы работает сразу, без Шестизарядника. Стрелок: каждый вооружённый враг на виду в 7 клетках, до 4, ускоряет шаг и на 10% выстрелы; когда за 3 секунды в вас выстрелят 3 разных стрелка в 7 клетках, даже если пули не долетят, начинается Мгновение: 2 секунды чужие пули рядом летят вдвое медленнее, летящие в вас вы ловите, как Ловлей пули, а 3 следующих выстрела мгновенные и прицельные, раз в 60 секунд; попадания по 3 разным людям за 6 секунд дают ещё 2 Свинца. Охотник: прицельный выстрел за 0,6 секунды и в 12 клетках, Мишень держится на 10 секунд дольше и видна вам сквозь стены, Растяжка за единицу Свинца - до 3 проволок, задевший получает пулю из стены и Мишень. Канонир: Свинцовый дождь сразу, а не с девятой ступени, - радиусом 3 за единицу, веер на 2 пули длиннее, Пороховая пуля хлопает и сбивает с ног в 1 клетке, Пороховая закладка за единицу - до 2 горстей пороха, хлопок на 1,5 секунды и огонь."
	summary = "Один раз и до сброса пути: Стрелок - против толпы, Охотник - издали и ловушками, Канонир - дождём сразу."
	charge_max = 1 SECONDS
	usable_while_grabbed = TRUE
	action_icon_state = "lead_school"

/obj/effect/proc_holder/spell/self/heretic_lead/school/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	var/reason = lead.school_block_reason(user)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/self/heretic_lead/school/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(!lead?.open_school_menu(user))
		heretic_revert_cast(user, lead?.lead_failure)

/obj/effect/proc_holder/spell/self/heretic_lead/standoff
	name = "Мгновение"
	desc = "Приём Стрелка. Когда на вас смотрят стволы хотя бы 3 вооружённых врагов, кнопка начинает Мгновение; само оно начинается, когда за 3 секунды в вас выстрелят 3 разных стрелка в 7 клетках, даже если пули лягут в чужие спины или в укрытие. Вокруг щёлкают взводимые курки, под ногами горит красное кольцо: 2 секунды чужие пули в 3 клетках от вас летят вдвое медленнее, летящие в вас пули и дробь вы ловите, как Ловлей пули, а 3 следующих выстрела Шестизарядника за 10 секунд уходят сразу и бьют как прицельные. Перезарядка 60 секунд."
	summary = "Против трёх стволов: 2 секунды чужие пули вязнут и ловятся, а 3 ваших выстрела мгновенные и прицельные."
	charge_max = HERETIC_LEAD_STANDOFF_COOLDOWN
	usable_while_grabbed = TRUE
	action_icon_state = "lead_standoff"

/obj/effect/proc_holder/spell/self/heretic_lead/standoff/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	var/reason = lead.standoff_block_reason(user)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/self/heretic_lead/standoff/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(!lead?.start_standoff(user))
		heretic_revert_cast(user, lead?.lead_failure)

/obj/effect/proc_holder/spell/pointed/heretic_lead/tripwire
	name = "Растяжка"
	desc = "Приём Охотника. За единицу Свинца натяните почти невидимую проволоку на полу под собой или на соседней клетке; держатся до 3 растяжек, новая снимает самую старую. Враг, задевший проволоку, слышит щелчок, а через 0,3 секунды получает пулю на 20 ушибов из ближайшей стены в 4 клетках и Мишень. Экипаж видит растяжку осмотром клетки или Т-сканером и режет её кусачками за секунду. Перезарядка 10 секунд."
	summary = "За единицу Свинца проволока на соседней клетке: задевший получает пулю из стены и Мишень."
	charge_max = HERETIC_LEAD_TRAP_COOLDOWN
	range = 1
	aim_assist = TRUE
	aim_assist_turf = TRUE
	action_icon_state = "lead_tripwire"

/obj/effect/proc_holder/spell/pointed/heretic_lead/tripwire/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	var/reason = lead ? lead.tripwire_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_lead/tripwire/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(!length(targets) || !lead?.place_tripwire(user, targets[1]))
		heretic_revert_cast(user, lead?.lead_failure)

/obj/effect/proc_holder/spell/pointed/heretic_lead/powder_charge
	name = "Пороховая закладка"
	desc = "Приём Канонира. За единицу Свинца положите на пол под собой или на соседнюю клетку горсть гильз с дорожкой пороха; держатся до 2 закладок, новая снимает самую старую. Наступивший враг слышит щелчок, и через 0,5 секунды хлопок сбивает с ног всех в 1 клетке на 1,5 секунды и поджигает их; выстрел в закладку, ваш или чужой, подрывает её сразу. Стены хлопок не ломает. Экипаж заливает закладку водой или пеной из огнетушителя или собирает руками за 2 секунды. Перезарядка 10 секунд."
	summary = "За единицу Свинца порох на соседней клетке: хлопок валит с ног и поджигает всех в 1 клетке."
	charge_max = HERETIC_LEAD_TRAP_COOLDOWN
	range = 1
	aim_assist = TRUE
	aim_assist_turf = TRUE
	action_icon_state = "lead_powder_charge"

/obj/effect/proc_holder/spell/pointed/heretic_lead/powder_charge/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	var/reason = lead ? lead.charge_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_lead/powder_charge/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(!length(targets) || !lead?.place_charge(user, targets[1]))
		heretic_revert_cast(user, lead?.lead_failure)

/datum/movespeed_modifier/heretic_lead_crowd
	variable = TRUE

/// Мгновение Стрелка: кольцо под ногами, чужие пули рядом летят вдвое медленнее.
/datum/status_effect/heretic_lead_standoff
	id = "heretic_lead_standoff"
	duration = HERETIC_LEAD_STANDOFF_TIME
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_lead_standoff
	var/datum/weakref/lead_ref
	var/mutable_appearance/ring
	var/mutable_appearance/slow_mark
	var/list/datum/weakref/slowed = list()
	var/static/list/slow_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)

/datum/status_effect/heretic_lead_standoff/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_lead/lead)
	lead_ref = WEAKREF(lead)
	return ..()

/datum/status_effect/heretic_lead_standoff/on_apply()
	. = ..()
	if(!. || !lead_ref?.resolve())
		return FALSE
	ring = mutable_appearance(HERETIC_LEAD_SCHOOLS_FX_ICON, "lead_standoff_ring", BELOW_MOB_LAYER)
	ring.appearance_flags = RESET_COLOR | KEEP_APART
	slow_mark = mutable_appearance(HERETIC_LEAD_SCHOOLS_FX_ICON, "lead_slow_bullet")
	slow_mark.appearance_flags = RESET_COLOR | KEEP_APART
	owner.add_overlay(ring)
	AddComponent(/datum/component/connect_range, owner, slow_connections, HERETIC_LEAD_STANDOFF_RANGE, FALSE)
	heretic_lead_sound(owner, "standoff_in", 60)
	var/list/turf/around = list()
	for(var/turf/open/spot in orange(HERETIC_LEAD_STANDOFF_RANGE, owner))
		around += spot
	for(var/click in 1 to min(LEAD_STANDOFF_CLICKS, length(around)))
		heretic_lead_sound(pick_n_take(around), "cock", 45, TRUE)
	var/datum/status_effect/heretic_lead_catch/catching = owner.has_status_effect(/datum/status_effect/heretic_lead_catch)
	if(catching)
		catching.duration = max(catching.duration, world.time + HERETIC_LEAD_STANDOFF_TIME)
	else
		owner.apply_status_effect(/datum/status_effect/heretic_lead_catch, lead_ref.resolve(), HERETIC_LEAD_STANDOFF_TIME)
	owner.visible_message(span_danger("Вокруг [owner] разом щёлкают взводимые курки, под ногами вспыхивает красное кольцо: пули рядом с ним вязнут в воздухе!"), span_userdanger("Мгновение: [HERETIC_LEAD_STANDOFF_TIME / (1 SECONDS)] секунды чужие пули рядом летят вдвое медленнее, летящие в вас вы ловите, а [HERETIC_LEAD_STANDOFF_SHOTS] следующих выстрела Шестизарядника - мгновенные и прицельные."))
	return TRUE

/datum/status_effect/heretic_lead_standoff/proc/on_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/obj/item/projectile/projectile = arrived
	if(!istype(projectile) || !projectile.fired || HAS_TRAIT(projectile, TRAIT_HERETIC_LEAD_SLOWED))
		return
	var/mob/firer = projectile.firer
	if(firer == owner || (ismob(firer) && (IS_HERETIC(firer) || IS_HERETIC_MONSTER(firer))))
		return
	ADD_TRAIT(projectile, TRAIT_HERETIC_LEAD_SLOWED, REF(src))
	projectile.pixels_per_second *= HERETIC_LEAD_STANDOFF_SLOW / 100
	projectile.add_overlay(slow_mark)
	slowed += WEAKREF(projectile)

/datum/status_effect/heretic_lead_standoff/on_remove()
	qdel(GetComponent(/datum/component/connect_range))
	if(ring)
		owner.cut_overlay(ring)
	for(var/datum/weakref/projectile_ref as anything in slowed)
		var/obj/item/projectile/projectile = projectile_ref.resolve()
		if(!projectile || !HAS_TRAIT_FROM(projectile, TRAIT_HERETIC_LEAD_SLOWED, REF(src)))
			continue
		REMOVE_TRAIT(projectile, TRAIT_HERETIC_LEAD_SLOWED, REF(src))
		projectile.pixels_per_second /= HERETIC_LEAD_STANDOFF_SLOW / 100
		projectile.cut_overlay(slow_mark)
	slowed.Cut()
	if(!QDELETED(owner))
		heretic_lead_sound(owner, "standoff_out", 50)
	ring = null
	slow_mark = null
	lead_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_lead_standoff
	name = "Мгновение"
	desc = "Время для вас замедлилось: чужие пули рядом летят вдвое медленнее, летящие в вас пули и дробь вы ловите, а следующие выстрелы Шестизарядника мгновенные и прицельные."
	icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	icon_state = "lead_standoff"

/// Метка Охотника сквозь стены: перекрестие в той клетке экрана, где стоит меченый, гаснет до следующего такта.
/atom/movable/screen/heretic_lead_sight
	name = "crosshair"
	icon = HERETIC_LEAD_FX_ICON
	icon_state = "lead_crosshair"
	plane = ABOVE_LIGHTING_PLANE
	layer = ABOVE_LIGHTING_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART | TILE_BOUND
	var/datum/eldritch_knowledge/base_lead/lead
	var/datum/weakref/target_ref

/atom/movable/screen/heretic_lead_sight/Initialize(mapload, datum/eldritch_knowledge/base_lead/lead, mob/living/target)
	. = ..(mapload)
	src.lead = lead
	target_ref = WEAKREF(target)
	var/mob/living/viewer = lead?.lead_body
	var/dx = target && viewer ? target.x - viewer.x : 0
	var/dy = target && viewer ? target.y - viewer.y : 0
	screen_loc = "CENTER[dx >= 0 ? "+[dx]" : "[dx]"],CENTER[dy >= 0 ? "+[dy]" : "[dy]"]"
	animate(src, alpha = 0, time = LEAD_SIGHT_TIME, easing = SINE_EASING | EASE_IN)
	QDEL_IN(src, LEAD_SIGHT_TIME)

/atom/movable/screen/heretic_lead_sight/Destroy()
	if(lead)
		lead.lead_body?.client?.screen -= src
		lead.sights -= src
		lead = null
	target_ref = null
	return ..()

/// Растяжка Охотника: невидима глазу, кроме едва заметного блика; её показывают Т-сканер и осмотр клетки.
/obj/structure/heretic_lead_tripwire
	name = "tripwire"
	desc = "Тонкая свинцовая проволока натянута над самым полом между двумя латунными скобами. Задевший её получит пулю из ближайшей стены; кусачки по этой клетке её перережут."
	icon = HERETIC_LEAD_SCHOOLS_FX_ICON
	icon_state = "lead_tripwire_seen"
	anchored = TRUE
	density = FALSE
	level = 1
	invisibility = INVISIBILITY_MAXIMUM
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE
	var/datum/weakref/lead_ref
	var/obj/effect/heretic_lead_tripwire_glint/glint
	var/turf/watched
	var/armed = TRUE
	var/fire_timer
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)

/obj/structure/heretic_lead_tripwire/Initialize(mapload, datum/eldritch_knowledge/base_lead/lead)
	. = ..()
	if(!istype(lead) || !isturf(loc))
		return INITIALIZE_HINT_QDEL
	lead_ref = WEAKREF(lead)
	lead.tripwires += src
	glint = new(loc)
	watched = loc
	RegisterSignal(watched, COMSIG_PARENT_EXAMINE, PROC_REF(on_turf_examine))
	RegisterSignal(watched, COMSIG_PARENT_ATTACKBY, PROC_REF(on_turf_attackby))
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/structure/heretic_lead_tripwire/Destroy()
	deltimer(fire_timer)
	fire_timer = null
	if(watched)
		UnregisterSignal(watched, list(COMSIG_PARENT_EXAMINE, COMSIG_PARENT_ATTACKBY))
		watched = null
	QDEL_NULL(glint)
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(lead)
		lead.tripwires -= src
		lead.notify_resource_changed()
	lead_ref = null
	return ..()

/obj/structure/heretic_lead_tripwire/proc/owner_lead()
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(!lead?.owner_heretic() || QDELETED(lead.lead_body) || lead.lead_body.stat == DEAD)
		return null
	return lead

/obj/structure/heretic_lead_tripwire/proc/reveal_to(mob/viewer, duration)
	if(!viewer?.client || !watched)
		return FALSE
	var/image/seen = image(icon, watched, "lead_tripwire_seen", ABOVE_OPEN_TURF_LAYER)
	flick_overlay(seen, list(viewer.client), duration)
	return TRUE

/obj/structure/heretic_lead_tripwire/proc/on_turf_examine(turf/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(!armed || get_dist(user, source) > LEAD_TRAP_EXAMINE_RANGE)
		return
	examine_list += span_warning("Над самым полом блестит тонкая натянутая проволока между двумя латунными скобами: это растяжка. Задевший её получит пулю из ближайшей стены; кусачки по этой клетке её перережут.")
	reveal_to(user, LEAD_TRAP_SEEN_TIME)

/obj/structure/heretic_lead_tripwire/proc/on_turf_attackby(turf/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!armed || item?.tool_behaviour != TOOL_WIRECUTTER || !isliving(user))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(cut), user, item)
	return COMPONENT_NO_AFTERATTACK

/obj/structure/heretic_lead_tripwire/proc/cut(mob/living/user, obj/item/tool)
	user.visible_message(span_notice("[user] нащупывает кусачками проволоку над полом."), span_notice("Вы подводите кусачки под натянутую проволоку..."))
	if(!tool.use_tool(src, user, HERETIC_LEAD_TRIPWIRE_CUT_TIME, volume = 50) || QDELETED(src) || !armed)
		return FALSE
	user.visible_message(span_notice("[user] перерезает растяжку, и проволока со звоном опадает."), span_notice("Растяжка перерезана."))
	log_game("[key_name(user)] перерезает Растяжку Свинца в [AREACOORD(src)].")
	qdel(src)
	return TRUE

/obj/structure/heretic_lead_tripwire/proc/on_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/mob/living/victim = arrived
	if(!armed || !isliving(victim) || victim.stat == DEAD || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || (victim.movement_type & (FLYING | FLOATING)))
		return
	if(!owner_lead())
		return
	armed = FALSE
	heretic_lead_sound(src, "tripwire_click", 55, TRUE)
	glint.icon_state = "lead_tripwire_seen"
	to_chat(victim, span_userdanger("Под ногой щёлкает натянутая проволока!"))
	fire_timer = addtimer(CALLBACK(src, PROC_REF(spring), WEAKREF(victim)), HERETIC_LEAD_TRIPWIRE_DELAY, TIMER_STOPPABLE)

/obj/structure/heretic_lead_tripwire/proc/spring(datum/weakref/victim_ref)
	fire_timer = null
	var/mob/living/victim = victim_ref?.resolve()
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead()
	. = null
	if(lead && victim && victim.stat != DEAD && victim.z == z)
		. = lead.tripwire_shot(victim)
	qdel(src)

/obj/effect/heretic_lead_tripwire_glint
	name = "glint"
	icon = HERETIC_LEAD_SCHOOLS_FX_ICON
	icon_state = "lead_tripwire"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_OPEN_TURF_LAYER

/// Пуля Растяжки: из стены в задевшего, попадание вешает Мишень.
/obj/item/projectile/bullet/heretic_lead/tripwire
	name = "tripwire bullet"
	damage = HERETIC_LEAD_TRIPWIRE_DAMAGE
	armour_penetration = BULLET_BR4
	round_name = "Растяжка"
	refunds = FALSE

/obj/item/projectile/bullet/heretic_lead/tripwire/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	var/mob/living/victim = target
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(!istype(victim) || blocked >= 100 || !lead || QDELETED(lead.lead_body) || !isturf(victim.loc) || !heretic_can_affect(lead.lead_body, victim, chargecost = 0, notify = FALSE))
		return
	victim.apply_status_effect(/datum/status_effect/eldritch/lead, lead)

/// Пороховая закладка Канонира: наступивший враг или выстрел в неё - хлопок, огонь и падение рядом.
/obj/structure/heretic_lead_charge
	name = "powder charge"
	desc = "Горсть стреляных гильз, от неё по полу тянется дорожка чёрного пороха, в которой иногда тлеет искра. Если на неё наступить, через полсекунды хлопнет: собьёт с ног и подожжёт всех рядом; выстрел в неё подрывает сразу. Залейте её водой или пеной из огнетушителя или осторожно соберите руками за 2 секунды."
	icon = HERETIC_LEAD_SCHOOLS_FX_ICON
	icon_state = "lead_powder_charge"
	anchored = TRUE
	density = FALSE
	layer = OBJ_LAYER
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	resistance_flags = INDESTRUCTIBLE
	var/datum/weakref/lead_ref
	var/arm_timer
	var/spent = FALSE
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)

/obj/structure/heretic_lead_charge/Initialize(mapload, datum/eldritch_knowledge/base_lead/lead)
	. = ..()
	if(!istype(lead) || !isturf(loc))
		return INITIALIZE_HINT_QDEL
	lead_ref = WEAKREF(lead)
	lead.charges += src
	RegisterSignal(src, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/structure/heretic_lead_charge/Destroy()
	deltimer(arm_timer)
	arm_timer = null
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(lead)
		lead.charges -= src
		lead.notify_resource_changed()
	lead_ref = null
	return ..()

/obj/structure/heretic_lead_charge/proc/owner_lead()
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(!lead?.owner_heretic() || QDELETED(lead.lead_body) || lead.lead_body.stat == DEAD)
		return null
	return lead

/obj/structure/heretic_lead_charge/proc/on_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/mob/living/victim = arrived
	if(spent || arm_timer || !isliving(victim) || victim.stat == DEAD || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || (victim.movement_type & (FLYING | FLOATING)))
		return
	if(!owner_lead())
		return
	icon_state = "lead_powder_charge_armed"
	heretic_lead_sound(src, "charge_arm", 55, TRUE)
	to_chat(victim, span_userdanger("Под ногой хрустят гильзы, и по дорожке пороха бежит искра!"))
	arm_timer = addtimer(CALLBACK(src, PROC_REF(detonate), "наступили"), HERETIC_LEAD_CHARGE_DELAY, TIMER_STOPPABLE)

/// Хлопок закладки; how - для лога.
/obj/structure/heretic_lead_charge/proc/detonate(how)
	arm_timer = null
	if(spent)
		return list()
	spent = TRUE
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead()
	var/turf/place = get_turf(src)
	. = list()
	if(lead)
		. = heretic_lead_pop(place, lead, TRUE)
		log_game("Пороховая закладка Свинца ([key_name(lead.lead_body)]) хлопает в [AREACOORD(place)]: [how], задето [length(.)].")
		SEND_SIGNAL(lead, COMSIG_HERETIC_LEAD_EVENT, "charge_pop", place, length(.))
	qdel(src)

/obj/structure/heretic_lead_charge/proc/defuse(mob/living/user, message, how)
	if(spent)
		return FALSE
	spent = TRUE
	visible_message(span_notice(message))
	log_game("[user ? key_name(user) : "Вода или пена"] обезвреживает Пороховую закладку Свинца ([how]) в [AREACOORD(src)].")
	qdel(src)
	return TRUE

/obj/structure/heretic_lead_charge/bullet_act(obj/item/projectile/projectile, def_zone, piercing_hit = FALSE)
	. = ..()
	if(!projectile.nodamage && projectile.damage > 0)
		INVOKE_ASYNC(src, PROC_REF(detonate), "выстрел [key_name(projectile.firer)]")

/obj/structure/heretic_lead_charge/fire_act(exposed_temperature, exposed_volume)
	INVOKE_ASYNC(src, PROC_REF(detonate), "огонь")

/obj/structure/heretic_lead_charge/ex_act(severity, target, origin)
	INVOKE_ASYNC(src, PROC_REF(detonate), "взрыв")
	return TRUE

/obj/structure/heretic_lead_charge/proc/on_exposed(atom/source, list/reagents, datum/reagents/holder, method)
	SIGNAL_HANDLER
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water) || istype(reagent, /datum/reagent/firefighting_foam))
			INVOKE_ASYNC(src, PROC_REF(defuse), null, "Порох закладки шипит и намокает, искра гаснет.", "залита")
			return

/obj/structure/heretic_lead_charge/attack_hand(mob/living/user, act_intent = user?.a_intent, attackchain_flags)
	if(!isliving(user) || spent)
		return ..()
	if(IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return defuse(user, "[user] сгребает свою закладку в ладонь.", "собрана хозяином")
	user.visible_message(span_warning("[user] осторожно собирает рассыпанный порох и гильзы."), span_notice("Вы осторожно сгребаете порох, не задевая искру..."))
	if(!do_after(user, HERETIC_LEAD_CHARGE_DEFUSE_TIME, target = src) || QDELETED(src))
		return TRUE
	return defuse(user, "[user] сгребает порох и гильзы: закладка больше не опасна.", "собрана руками")

/obj/effect/temp_visual/heretic_lead/pop
	name = "powder pop"
	icon = HERETIC_LEAD_SCHOOLS_FX_ICON
	icon_state = "lead_pop"
	duration = 1 SECONDS
	layer = FLY_LAYER

#undef LEAD_CROWD_HASTE
#undef LEAD_SIGHT_TIME
#undef LEAD_TRAP_SEEN_TIME
#undef LEAD_TRAP_EXAMINE_RANGE
#undef LEAD_STANDOFF_CLICKS
#undef TRAIT_HERETIC_LEAD_SLOWED
