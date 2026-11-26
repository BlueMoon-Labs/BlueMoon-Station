/datum/unit_test/proc/heretic_lead_comfort_told(mob/listener, fragment)
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		var/target = entry[1]
		if((target == listener || (islist(target) && (listener in target))) && findtext(entry[2], fragment))
			return TRUE
	return FALSE

/// Канонир получает Свинцовый дождь сразу с выбором Школы, дождь стоит единицу; девятая ступень не даёт второй кнопки. Другие Школы раннего дождя не получают.
/datum/unit_test/heretic_lead_cannoneer_early_rain/Run()
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(null, heretic_lead_test_spot(0, 2))
	var/mob/living/carbon/human/user = lead.lead_body
	var/datum/antagonist/heretic/heretic = lead.owner_heretic()
	var/datum/eldritch_knowledge/lead_mark/mark = heretic.get_knowledge(/datum/eldritch_knowledge/lead_mark)
	TEST_ASSERT(!lead.rain_known(), "До выбора Школы дождя нет.")
	TEST_ASSERT(lead.choose_school(user, HERETIC_LEAD_SCHOOL_CANNONEER), "Школа Канонира: [lead.lead_failure]")
	TEST_ASSERT(!QDELETED(mark.school_rain) && (mark.school_rain in user.mind.spell_list), "Канонир получает кнопку Свинцового дождя сразу.")
	var/list/spells = list()
	heretic.collect_combat_spells(spells)
	TEST_ASSERT(mark.school_rain in spells, "Ранний дождь среди способностей и на клавише.")
	lead.combat_resource = HERETIC_LEAD_CANNON_RAIN_COST
	TEST_ASSERT(lead.rain(user, heretic_lead_test_spot(3, 2)) && lead.combat_resource == 0, "Ранний дождь Канонира за [HERETIC_LEAD_CANNON_RAIN_COST]: [lead.lead_failure]")
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_rain)
	TEST_ASSERT(QDELETED(mark.school_rain), "Девятая ступень сменяет ранний дождь кнопкой знания.")
	var/buttons = 0
	for(var/obj/effect/proc_holder/spell/pointed/heretic_lead/rain/button in user.mind.spell_list)
		buttons++
	TEST_ASSERT_EQUAL(buttons, 1, "Кнопка дождя одна.")
	var/datum/eldritch_knowledge/base_lead/hunter = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_HUNTER, heretic_lead_test_spot(4, 4))
	var/datum/antagonist/heretic/hunter_heretic = hunter.owner_heretic()
	var/datum/eldritch_knowledge/lead_mark/hunter_mark = hunter_heretic.get_knowledge(/datum/eldritch_knowledge/lead_mark)
	TEST_ASSERT(!hunter.rain_known() && QDELETED(hunter_mark.school_rain), "Охотнику ранний дождь не положен.")

/// Мгновение Стрелка сразу ловит летящие в него пули, как Ловля, и показывает окно значком.
/datum/unit_test/heretic_lead_standoff_catch/Run()
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_GUNSLINGER, heretic_lead_test_spot(4, 2))
	var/mob/living/carbon/human/user = lead.lead_body
	var/list/gunners = list()
	for(var/dy in list(0, 2, 4))
		gunners += heretic_lead_test_crew(heretic_lead_test_spot(0, dy))
	for(var/mob/living/carbon/human/gunner as anything in gunners)
		heretic_lead_test_shot(gunner, user)
	TEST_ASSERT_NOTNULL(user.has_status_effect(/datum/status_effect/heretic_lead_standoff), "Три стрелка начинают Мгновение.")
	var/datum/status_effect/heretic_lead_catch/window = user.has_status_effect(/datum/status_effect/heretic_lead_catch)
	TEST_ASSERT_NOTNULL(window, "Мгновение открывает окно Ловли без Шестизарядника и без знания Ловли.")
	TEST_ASSERT(window.duration <= world.time + HERETIC_LEAD_STANDOFF_TIME, "Окно держится не дольше Мгновения.")
	TEST_ASSERT_NOTNULL(user.alerts[window.id], "Окно Ловли видно значком.")
	var/brute = user.getBruteLoss()
	var/lead_before = lead.lead_total()
	heretic_lead_test_shot(gunners[2], user, damage = 20)
	TEST_ASSERT_EQUAL(user.getBruteLoss(), brute, "Пуля в Мгновении ловится и не ранит.")
	TEST_ASSERT(lead.lead_total() > lead_before, "Пойманная пуля даёт Свинец.")

/// Слух стрелка берёт стрелявших рядом на Пристрелку: 5 секунд, улучшения - 10 и 15; лазер не в счёт, дальность указателя не меняется.
/datum/unit_test/heretic_lead_ear_zeroing/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 0))
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_ear)
	var/datum/eldritch_knowledge/lead_ear/ear = heretic.get_knowledge(/datum/eldritch_knowledge/lead_ear)
	var/mob/living/carbon/human/laser_crew = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	var/obj/item/gun/energy/laser/laser = allocate(/obj/item/gun/energy/laser, get_turf(laser_crew))
	laser_crew.put_in_hands(laser)
	laser.process_fire(heretic_lead_test_spot(2, 4), laser_crew)
	TEST_ASSERT_NULL(laser_crew.has_status_effect(/datum/status_effect/heretic_lead_zeroed), "Лазер Пристрелку не даёт.")
	var/mob/living/carbon/human/crew = heretic_lead_test_armed(heretic_lead_test_spot(3, 3))
	var/obj/item/gun/ballistic/automatic/pistol/gun = locate() in crew.held_items
	gun.process_fire(heretic_lead_test_spot(3, 0), crew)
	var/datum/status_effect/heretic_lead_zeroed/zeroed = crew.has_status_effect(/datum/status_effect/heretic_lead_zeroed)
	TEST_ASSERT_NOTNULL(zeroed, "Стрелявший рядом с еретиком на Пристрелке.")
	TEST_ASSERT(zeroed.duration > world.time && zeroed.duration <= world.time + 5 SECONDS, "Без улучшений Пристрелка на 5 секунд.")
	ear.passive_level = 3
	gun.fire_delay = 0
	gun.last_fire = 0
	gun.process_fire(heretic_lead_test_spot(3, 0), crew)
	TEST_ASSERT(zeroed.duration >= world.time + 14 SECONDS, "Третья ступень Слуха держит Пристрелку 15 секунд.")
	TEST_ASSERT_EQUAL(ear.hearing_range(), 30, "Указатель на выстрел на любой ступени - 30 клеток.")

/// Тяжесть держится, пока Пуля с именем ещё может долететь, а снятая называет стрелку причину.
/datum/unit_test/heretic_lead_heavy_lift_reason/Run()
	var/obj/item/projectile/heretic_lead_named/named = /obj/item/projectile/heretic_lead_named
	TEST_ASSERT(initial(named.range) <= HERETIC_LEAD_HEAVY_BREAK_RANGE, "Тяжесть не рвётся раньше, чем кончается полёт пули: [initial(named.range)] и [HERETIC_LEAD_HEAVY_BREAK_RANGE].")
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 0))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 3))
	var/datum/status_effect/heretic_lead_heavy/heavy = victim.apply_status_effect(/datum/status_effect/heretic_lead_heavy, lead)
	TEST_ASSERT_NOTNULL(heavy, "Тяжесть легла.")
	TEST_ASSERT_NULL(heavy.break_reason(), "Рядом со стрелком тяжесть держится.")
	GLOB.unit_test_chat_capture = list()
	victim.reagents.add_reagent(/datum/reagent/water/holywater, 5)
	heavy.tick()
	TEST_ASSERT(QDELETED(heavy), "Святая вода снимает тяжесть.")
	TEST_ASSERT(heretic_lead_comfort_told(user, "святая вода"), "Стрелок узнаёт, что тяжесть сняла святая вода.")
	victim.reagents.clear_reagents()
	heavy = victim.apply_status_effect(/datum/status_effect/heretic_lead_heavy, lead)
	TEST_ASSERT_NOTNULL(heavy, "Тяжесть легла снова.")
	heavy.shaken_off(victim)
	TEST_ASSERT(QDELETED(heavy) && heretic_lead_comfort_told(user, "растолкали"), "Стрелок узнаёт, что цель растолкали.")
	GLOB.unit_test_chat_capture = null

/// Отказ Пули с именем считает Свинец патронташа, подсказка значка ведёт секунды невидимых окон, вытесненный заговор называет вещь.
/datum/unit_test/heretic_lead_hidden_timers/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 0))
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_named)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_catch)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(3, 3))
	lead.combat_resource = 0
	lead.bandolier = 1
	TEST_ASSERT(findtext(lead.named_block_reason(user, target), "сейчас 1"), "Отказ считает и патронташ: [lead.named_block_reason(user, target)]")
	var/datum/eldritch_knowledge/spell/lead_catch/catching = heretic.get_knowledge(/datum/eldritch_knowledge/spell/lead_catch)
	catching.granted_spell.cast(list(user), user)
	TEST_ASSERT(findtext(lead.combat_resource_state(), "Ловля пули: ещё"), "Подсказка значка ведёт окно Ловли.")
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/obj/item/projectile/heavy = heretic_lead_test_round(revolver, lead, user, target, 2)
	TEST_ASSERT(istype(heavy, /obj/item/projectile/bullet/heretic_lead/heavy) && target.has_status_effect(/datum/status_effect/heretic_lead_staggered), "Тяжёлая пуля попала и свалила цель.")
	TEST_ASSERT(findtext(lead.combat_resource_state(), "Снова не свалить: [target.name]"), "Подсказка значка называет, кого пока не свалить.")
	lead.refresh_shown_state()
	TEST_ASSERT(!lead.refresh_shown_state(), "Без перемен подсказка не пересобирается.")
	heretic.total_sacrifices = HERETIC_LEAD_SOUND_HUNT_SACRIFICES
	COOLDOWN_START(lead, sound_hunt, HERETIC_LEAD_SOUND_HUNT_COOLDOWN)
	TEST_ASSERT(findtext(lead.combat_resource_state(), "Охота на звук: через"), "Подсказка значка ведёт откат Охоты на звук.")
	GLOB.unit_test_chat_capture = list()
	var/obj/item/gun/ballistic/shotgun/first
	for(var/index in 1 to HERETIC_LEAD_CURSE_LIMIT + 1)
		var/obj/item/gun/ballistic/shotgun/gun = allocate(/obj/item/gun/ballistic/shotgun, heretic_lead_test_spot(1, 1))
		first ||= gun
		lead.place_curse(user, gun)
	TEST_ASSERT(heretic_lead_comfort_told(user, "Заговор на [first]") && heretic_lead_comfort_told(user, "вытеснил новый"), "Вытесненный заговор называет вещь.")
	GLOB.unit_test_chat_capture = null

/// Тугое ухо глушит светошумовой грохот, как наушники.
/datum/unit_test/heretic_lead_innate_bang/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(3, 3))
	user.soundbang_act(1, 20, 5, 15)
	crew.soundbang_act(1, 20, 5, 15)
	var/obj/item/organ/ears/heretic_ears = user.getorganslot(ORGAN_SLOT_EARS)
	var/obj/item/organ/ears/crew_ears = crew.getorganslot(ORGAN_SLOT_EARS)
	TEST_ASSERT(crew_ears.damage > 0, "Без защиты грохот бьёт по ушам.")
	TEST_ASSERT_EQUAL(heretic_ears.damage, 0, "Тугое ухо гасит грохот.")

/// Тексты: практика короче, без «Z в руке», рикошет не обещает пол, урок учит Отдаче и Сглазу.
/datum/unit_test/heretic_lead_comfort_texts/Run()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_LEAD]
	TEST_ASSERT(length_char(path.combat_practice) <= 1450, "Практика Свинца не длиннее 1450 знаков: [length_char(path.combat_practice)].")
	var/datum/eldritch_knowledge/lead_relic/relic = allocate(/datum/eldritch_knowledge/lead_relic)
	TEST_ASSERT(!findtext(relic.desc, "Z в руке") && findtext(relic.desc, "«Использовать в руке»"), "Стиль револьвера назван действием, а не клавишей.")
	var/datum/eldritch_knowledge/lead_ear/ear = allocate(/datum/eldritch_knowledge/lead_ear)
	TEST_ASSERT(!findtext(ear.desc, "Стрелка к выстрелу") && findtext(ear.desc, "Пристрелк"), "Слух стрелка описывает указатель и Пристрелку.")
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	var/datum/heretic_lead_lesson/lesson = new(null, lead, lead.lead_body, target)
	allocated += lesson
	TEST_ASSERT_NOTNULL(heretic.get_knowledge(/datum/eldritch_knowledge/lead_grasp), "Урок даёт Отдачу.")
	lesson.set_stage(7)
	TEST_ASSERT(!findtext(lesson.hint, "в пол") && findtext(lesson.hint, "дробиной"), "Шаг Рикошета не обещает пол и называет дробину.")
	lesson.set_stage(6)
	TEST_ASSERT(findtext(lesson.hint, "Сглаз ствола"), "Шаг Ловли учит и Сглазу.")
