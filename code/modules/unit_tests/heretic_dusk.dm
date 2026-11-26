/// Свет клеток и святость часовни на время теста: освещение тестовой зоны недостоверно, поэтому его подменяют.
/datum/heretic_dusk_test_env
	var/list/turf/lit = list()
	var/was_desecrated

/datum/heretic_dusk_test_env/New()
	was_desecrated = GLOB.heretic_dusk_chapel_desecrated

/datum/heretic_dusk_test_env/proc/set_light(turf/spot, lum)
	GLOB.heretic_dusk_light_overrides[spot] = lum
	lit |= spot

/datum/heretic_dusk_test_env/Destroy()
	for(var/turf/spot as anything in lit)
		GLOB.heretic_dusk_light_overrides -= spot
	lit.Cut()
	GLOB.heretic_dusk_chapel_desecrated = was_desecrated
	return ..()

/datum/unit_test/proc/dusk_env() as /datum/heretic_dusk_test_env
	for(var/datum/heretic_dusk_test_env/env in allocated)
		return env
	var/datum/heretic_dusk_test_env/env = new
	allocated += env
	return env

/datum/unit_test/proc/dusk_light(atom/place, lum)
	dusk_env().set_light(get_turf(place), lum)

/datum/unit_test/proc/dusk_light_all(lum)
	for(var/turf/spot as anything in block(run_loc_floor_bottom_left, run_loc_floor_top_right))
		dusk_light(spot, lum)

/datum/unit_test/proc/allocate_dusk(dx = 1, dy = 2)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_DUSK)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(dx, dy))
	dusk_env()
	return heretic.get_knowledge(/datum/eldritch_knowledge/base_dusk)

/datum/unit_test/proc/dusk_learn(datum/eldritch_knowledge/base_dusk/dusk, knowledge_type)
	var/datum/antagonist/heretic/heretic = dusk.owner_heretic()
	heretic.gain_knowledge(knowledge_type)
	return heretic.get_knowledge(knowledge_type)

/datum/unit_test/proc/dusk_tick(datum/eldritch_knowledge/base_dusk/dusk)
	COOLDOWN_RESET(dusk, light_check)
	dusk.on_life(dusk.dusk_body)

/datum/unit_test/proc/dusk_splash(atom/target)
	var/datum/reagents/holy = new(10)
	holy.add_reagent(/datum/reagent/water/holywater, 10)
	holy.reaction(target, TOUCH)
	qdel(holy)

/datum/unit_test/proc/dusk_lit_torch(mob/living/carbon/human/bearer)
	var/obj/item/flashlight/torch = allocate(/obj/item/flashlight, get_turf(bearer))
	torch.on = TRUE
	torch.update_brightness()
	bearer.put_in_active_hand(torch)
	return torch

/datum/unit_test/proc/dusk_crew_facing(turf/spot, direction)
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(spot)
	crew.setDir(direction)
	return crew

/// Вознёсшийся еретик Сумрака в своём теле, с финалом и его заклинаниями.
/datum/unit_test/proc/dusk_ascended()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	var/datum/antagonist/heretic/heretic = dusk.owner_heretic()
	var/mob/living/carbon/human/user = dusk.dusk_body
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/dusk_final)
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/dusk_final)
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	return list("heretic" = heretic, "user" = user, "dusk" = dusk, "finale" = finale)

/datum/unit_test/heretic_dusk_ascended_base
	abstract_type = /datum/unit_test/heretic_dusk_ascended_base
	var/datum/eldritch_knowledge/final_eldritch/sky_source

/datum/unit_test/heretic_dusk_ascended_base/Destroy()
	heretic_release_sky(sky_source)
	sky_source = null
	return ..()

/// Облик решает, где копится Сумрак: Лик на свету, Крыло в тени; святая вода в крови и часовня не дают копить.
/datum/unit_test/heretic_dusk_forms/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	var/mob/living/carbon/human/user = dusk.dusk_body
	TEST_ASSERT_EQUAL(dusk.form, HERETIC_DUSK_FORM_FACE, "Путь начинается в Лике.")
	TEST_ASSERT_EQUAL(dusk.combat_resource, HERETIC_DUSK_START, "Начальный запас Сумрака - [HERETIC_DUSK_START].")
	TEST_ASSERT(istype(dusk.combat_power, /obj/effect/proc_holder/spell/self/heretic_dusk/form), "База даёт смену облика.")
	TEST_ASSERT(istype(dusk.beam_power, /obj/effect/proc_holder/spell/pointed/heretic_dusk/beam), "База даёт Луч лампы.")
	dusk_light(user, 1)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.combat_resource, HERETIC_DUSK_START + 1, "Лик на свету копит Сумрак.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_face), "Лик на свету быстрее.")
	TEST_ASSERT(dusk.toggle_form(user), "Облик меняется: [dusk.dusk_failure]")
	TEST_ASSERT_EQUAL(dusk.form, HERETIC_DUSK_FORM_WING, "Второй облик - Крыло.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_face), "Крыло на свету не получает скорость Лика.")
	COOLDOWN_RESET(dusk, gather)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.combat_resource, HERETIC_DUSK_START + 1, "Крыло на свету не копит.")
	dusk_light(user, 0)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.combat_resource, HERETIC_DUSK_START + 2, "Крыло в тени копит.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_wing), "Крыло в тени быстрее.")
	user.reagents.add_reagent(/datum/reagent/water/holywater, 5)
	COOLDOWN_RESET(dusk, gather)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.combat_resource, HERETIC_DUSK_START + 2, "Святая вода в крови не даёт копить.")
	TEST_ASSERT_EQUAL(dusk.dusk_cost(1), 2, "Святая вода в крови делает приём дороже на единицу.")
	user.reagents.del_reagent(/datum/reagent/water/holywater)
	heretic_test_area(get_turf(user), /area/service/chapel/main)
	COOLDOWN_RESET(dusk, gather)
	dusk_tick(dusk)
	TEST_ASSERT(dusk.in_holy_ground, "Часовня - святая земля.")
	TEST_ASSERT_EQUAL(dusk.combat_resource, HERETIC_DUSK_START + 2, "В часовне Сумрак не копится.")
	TEST_ASSERT_NULL(dusk.cast_block_reason(user), "До вознесения часовня приёмы не запирает.")

/// Крылья режут урон спереди, сзади и сбоку Крыло получает полный, Лик - полный спереди; нулевой жезл бьёт сильнее и сбивает заряд Шага.
/datum/unit_test/heretic_dusk_wing_guard/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(2, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	user.setDir(EAST)
	var/mob/living/carbon/human/gunner = heretic_lead_test_crew(get_step(user, EAST))
	heretic_lead_test_shot(gunner, user, damage = 20)
	var/front = user.getBruteLoss()
	TEST_ASSERT(front > 0 && front <= 20 * (100 - HERETIC_DUSK_WING_FRONT_CUT) / 100 + 0.5, "Спереди крылья режут урон: [front].")
	user.adjustBruteLoss(-200)
	gunner.forceMove(get_step(user, WEST))
	user.setDir(EAST)
	heretic_lead_test_shot(gunner, user, damage = 20)
	TEST_ASSERT(user.getBruteLoss() >= 19.5, "Сзади Крыло получает полный урон: [user.getBruteLoss()].")
	user.adjustBruteLoss(-200)
	dusk.set_form(HERETIC_DUSK_FORM_FACE)
	gunner.forceMove(get_step(user, EAST))
	user.setDir(EAST)
	heretic_lead_test_shot(gunner, user, damage = 20)
	TEST_ASSERT(user.getBruteLoss() >= 19.5, "Лик спереди не прикрыт: [user.getBruteLoss()].")
	user.adjustBruteLoss(-200)
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_step)
	TEST_ASSERT_EQUAL(dusk.charges["step"], HERETIC_DUSK_STEP_CHARGES, "Шаг в тень приходит с полными зарядами.")
	var/mob/living/carbon/human/chaplain = heretic_lead_test_crew(get_step(user, SOUTH))
	chaplain.a_intent = INTENT_HARM
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, get_turf(chaplain))
	var/obj/item/crowbar/bar = allocate(/obj/item/crowbar, get_turf(chaplain))
	bar.force = rod.force
	bar.armour_penetration = rod.armour_penetration
	bar.damtype = rod.damtype
	chaplain.put_in_active_hand(bar)
	bar.melee_attack_chain(chaplain, user)
	var/plain = user.getBruteLoss() + user.getFireLoss()
	TEST_ASSERT(plain > 0, "Обычное оружие ранит Сумрак полностью.")
	user.adjustBruteLoss(-200)
	user.adjustFireLoss(-200)
	chaplain.dropItemToGround(bar)
	chaplain.put_in_active_hand(rod)
	rod.melee_attack_chain(chaplain, user)
	var/holy = user.getBruteLoss() + user.getFireLoss()
	// Зона удара случайна (ran_zone), у конечностей свой разброс урона - сверяем с нижней границей и с обычным оружием той же силы.
	TEST_ASSERT(holy >= rod.force * (100 + HERETIC_DUSK_NULLROD_BONUS) / 100 - 1 && holy > plain, "Нулевой жезл бьёт падшего на [HERETIC_DUSK_NULLROD_BONUS]% сильнее: [holy] при силе [rod.force], обычное оружие [plain].")
	TEST_ASSERT_EQUAL(dusk.charges["step"], HERETIC_DUSK_STEP_CHARGES - 1, "Удар жезла сбивает заряд Шага.")

/// Выплеснутая святая вода жжёт, сбивает облик и запирает его, гасит копление и рвёт Хватку; Библия капеллана жжёт и оглушает раз в 10 секунд.
/datum/unit_test/heretic_dusk_holy/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_grip)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/datum/status_effect/heretic_dusk_grip/grip = victim.apply_status_effect(/datum/status_effect/heretic_dusk_grip, dusk)
	TEST_ASSERT(!QDELETED(grip), "Хватка держит цель.")
	dusk_splash(user)
	TEST_ASSERT(user.getFireLoss() >= HERETIC_DUSK_HOLY_SPLASH_BURN, "Святая вода жжёт падшего: [user.getFireLoss()].")
	TEST_ASSERT_EQUAL(dusk.form, HERETIC_DUSK_FORM_FACE, "Святая вода сбивает облик.")
	TEST_ASSERT(!dusk.toggle_form(user) && findtext(dusk.dusk_failure, "Святое"), "Облик заперт после святой воды.")
	TEST_ASSERT(QDELETED(grip), "Святая вода на хозяине рвёт Хватку.")
	dusk_light(user, 1)
	var/before = dusk.combat_resource
	COOLDOWN_RESET(dusk, gather)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.combat_resource, before, "После святой воды Сумрак не копится.")
	user.adjustFireLoss(-200)
	var/mob/living/carbon/human/chaplain = heretic_lead_test_crew(get_step(user, EAST))
	chaplain.mind.isholy = TRUE
	var/obj/item/storage/book/bible/book = allocate(/obj/item/storage/book/bible, get_turf(chaplain))
	chaplain.put_in_active_hand(book)
	book.melee_attack_chain(chaplain, user)
	TEST_ASSERT_EQUAL(round(user.getFireLoss(), 1), HERETIC_DUSK_BIBLE_BURN, "Библия капеллана жжёт и не лечит падшего.")
	TEST_ASSERT(user.IsStun(), "Библия капеллана оглушает.")
	user.SetStun(0)
	book.melee_attack_chain(chaplain, user)
	TEST_ASSERT(round(user.getFireLoss(), 1) <= HERETIC_DUSK_BIBLE_BURN && !user.IsStun(), "Библия жжёт не чаще раза в 10 секунд.")
	var/mob/living/carbon/human/layman = heretic_lead_test_crew(get_step(user, NORTH))
	user.adjustFireLoss(-200)
	COOLDOWN_RESET(dusk, bible_hit)
	chaplain.dropItemToGround(book)
	layman.put_in_active_hand(book)
	book.melee_attack_chain(layman, user)
	TEST_ASSERT_EQUAL(user.getFireLoss(), 0, "Библия в руках не-капеллана не жжёт.")

/// Хватка в «Помощи» заговаривает лампу: мигание на экипаже ведёт дело, держится шесть ламп, жезл и святая вода снимают заговор.
/datum/unit_test/heretic_dusk_lamps/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(1, 1)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/datum/antagonist/heretic/heretic = dusk.owner_heretic()
	var/obj/machinery/light/small/lamp = allocate(/obj/machinery/light/small, heretic_lead_test_spot(4, 4))
	lamp.on = TRUE
	heretic_test_area(get_turf(lamp), /area/cargo/storage)
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	user.a_intent = INTENT_HARM
	fist.afterattack(lamp, user, TRUE)
	TEST_ASSERT_NULL(lamp.GetComponent(/datum/component/heretic_dusk_lamp), "Вне «Помощи» Хватка лампу не трогает.")
	user.a_intent = INTENT_HELP
	fist.afterattack(lamp, user, TRUE)
	var/datum/component/heretic_dusk_lamp/hex = lamp.GetComponent(/datum/component/heretic_dusk_lamp)
	TEST_ASSERT_NOTNULL(hex, "Хватка в «Помощи» заговаривает лампу.")
	TEST_ASSERT(hex in dusk.lamps, "Заговор занимает слот.")
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(0, 4))
	TEST_ASSERT(findtext(jointext(lamp.examine(crew), " "), "копоть"), "Экипаж видит копоть на заговорённой лампе.")
	crew.forceMove(heretic_lead_test_spot(3, 4))
	TEST_ASSERT(!COOLDOWN_FINISHED(hex, flicker_cooldown), "Лампа мигает на прохожем.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Мигание на экипаже в отделе станции продвигает дело.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dusk_test_still), lamp), 4 SECONDS, "мигание"), "Лампа отмигала.")
	COOLDOWN_RESET(hex, flicker_cooldown)
	var/datum/antagonist/heretic/ally = allocate_heretic(heretic_lead_test_spot(0, 3))
	ally.owner.current.forceMove(heretic_lead_test_spot(3, 3))
	TEST_ASSERT(COOLDOWN_FINISHED(hex, flicker_cooldown), "На еретике лампа не мигает.")
	for(var/index in 1 to HERETIC_DUSK_LAMP_LIMIT)
		var/obj/machinery/light/small/extra = allocate(/obj/machinery/light/small, heretic_lead_test_spot(index % 5, 0))
		dusk.hex_lamp(user, extra)
	TEST_ASSERT_EQUAL(length(dusk.lamps), HERETIC_DUSK_LAMP_LIMIT, "Держится шесть заговоров.")
	TEST_ASSERT(QDELETED(hex) && !lamp.GetComponent(/datum/component/heretic_dusk_lamp), "Седьмой заговор вытесняет старейший.")
	var/datum/component/heretic_dusk_lamp/newest = dusk.lamps[length(dusk.lamps)]
	var/obj/machinery/light/rodded = newest.parent
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	rodded.attackby(rod, crew)
	TEST_ASSERT(QDELETED(newest) && rodded.status == LIGHT_OK, "Нулевой жезл снимает заговор и не бьёт лампу.")
	var/datum/component/heretic_dusk_lamp/washed = dusk.lamps[1]
	dusk_splash(washed.parent)
	TEST_ASSERT(QDELETED(washed), "Святая вода снимает заговор.")
	TEST_ASSERT_EQUAL(length(dusk.lamps), HERETIC_DUSK_LAMP_LIMIT - 2, "Снятые заговоры освобождают слоты.")

/proc/heretic_dusk_test_overlay(datum/eldritch_knowledge/base_dusk/dusk, state)
	for(var/mutable_appearance/look as anything in dusk.mutation_overlays)
		if(look.icon_state == state && look.plane != EMISSIVE_PLANE)
			return look

/proc/heretic_dusk_test_still(obj/machinery/light/lamp)
	return !lamp.flickering

/// Хватка тени: только в Крыле, на свету короче, телеграф, захват и дверь сердца; фонарик ослабляет, святая вода, растолкать и жезл рвут.
/datum/unit_test/heretic_dusk_grip/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_grip)
	dusk.combat_resource = dusk.combat_resource_max
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	dusk_light(victim, 0)
	TEST_ASSERT(findtext(dusk.grip_block_reason(user, victim), "Крыла"), "Хватка тени только в облике Крыла.")
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	dusk_light(victim, 1)
	TEST_ASSERT_NULL(dusk.grip_block_reason(user, victim), "Хватка берёт и цель на свету.")
	TEST_ASSERT(!dusk.grip_light_ok(victim), "На свету тень мала: Хватка короче.")
	victim.apply_status_effect(/datum/status_effect/heretic_dusk_burnt, dusk)
	TEST_ASSERT(dusk.grip_light_ok(victim), "Выжженная тень держит полную Хватку и на свету.")
	victim.remove_status_effect(/datum/status_effect/heretic_dusk_burnt)
	dusk_light(victim, 0)
	TEST_ASSERT(dusk.grip(user, victim), "Хватка тени наложена: [dusk.dusk_failure]")
	TEST_ASSERT_EQUAL(dusk.combat_resource, dusk.combat_resource_max - HERETIC_DUSK_GRIP_COST, "Хватка стоит 2 Сумрака.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(victim, TYPE_PROC_REF(/mob/living, has_status_effect), /datum/status_effect/heretic_dusk_grip), 2 SECONDS, "Хватка тени"), "После телеграфа тень прибивает цель.")
	var/datum/status_effect/heretic_dusk_grip/grip = victim.has_status_effect(/datum/status_effect/heretic_dusk_grip)
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Хватка держит как захват.")
	TEST_ASSERT(victim.IsKnockdown() && victim.IsImmobilized(), "Цель прибита к полу.")
	var/atom/movable/screen/fullscreen/hands = victim.fullscreens["heretic_dusk_hands"]
	TEST_ASSERT_EQUAL(hands?.severity, 1, "Руки тени тянутся с краёв экрана.")
	TEST_ASSERT_NULL(dusk.pocket_door(user, victim), "Издалека сердце цель не уводит.")
	user.forceMove(get_step(victim, WEST))
	TEST_ASSERT_NOTNULL(dusk.pocket_door(user, victim), "Рядом с прибитой целью сердце уводит её.")
	grip.stage = 3
	grip.show_hands()
	var/left = grip.duration - world.time
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(get_step(victim, SOUTH))
	var/obj/item/flashlight/torch = dusk_lit_torch(crew)
	victim.attackby(torch, crew)
	TEST_ASSERT(grip.duration - world.time <= left / 2 + 1, "Фонарик укорачивает Хватку вдвое.")
	TEST_ASSERT_EQUAL(grip.stage, 2, "Свет отбрасывает руки тени на ступень.")
	hands = victim.fullscreens["heretic_dusk_hands"]
	TEST_ASSERT_EQUAL(hands?.severity, 2, "Экран показывает отброшенные руки.")
	TEST_ASSERT(!QDELETED(grip), "Фонарик Хватку не рвёт.")
	dusk_splash(victim)
	TEST_ASSERT(QDELETED(grip), "Святая вода на цели рвёт Хватку.")
	TEST_ASSERT_NULL(victim.fullscreens["heretic_dusk_hands"], "Руки тени уходят с экрана.")
	TEST_ASSERT(!victim.IsKnockdown(), "Сорванная Хватка поднимает цель.")
	var/mob/living/carbon/human/second = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	var/datum/status_effect/heretic_dusk_grip/second_grip = second.apply_status_effect(/datum/status_effect/heretic_dusk_grip, dusk)
	var/mob/living/carbon/human/helper = heretic_lead_test_crew(get_step(second, EAST))
	TEST_ASSERT(heretic_capture_shake(helper, second), "Без святого Хватку растолкать за 2 секунды.")
	TEST_ASSERT(QDELETED(second_grip), "Растолканная цель свободна.")
	var/mob/living/carbon/human/third = heretic_lead_test_crew(heretic_lead_test_spot(1, 0))
	var/datum/status_effect/heretic_dusk_grip/third_grip = third.apply_status_effect(/datum/status_effect/heretic_dusk_grip, dusk)
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	third.attackby(rod, helper)
	TEST_ASSERT(QDELETED(third_grip), "Нулевой жезл рвёт Хватку.")

/// Хватка сорвалась на телеграфе: цель спряталась в шкаф, Сумрак вернулся.
/datum/unit_test/heretic_dusk_grip_dodge/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_grip)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	dusk.combat_resource = HERETIC_DUSK_GRIP_COST
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	dusk_light(victim, 0)
	TEST_ASSERT(dusk.grip(user, victim), "Хватка вспухает: [dusk.dusk_failure]")
	var/obj/structure/closet/locker = allocate(/obj/structure/closet, get_turf(victim))
	victim.forceMove(locker)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_time_passed), world.time + HERETIC_DUSK_GRIP_TELEGRAPH + 2), 2 SECONDS, "телеграф"), "Телеграф прошёл.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_grip), "Спрятавшийся уходит от Хватки.")
	TEST_ASSERT_EQUAL(dusk.combat_resource, HERETIC_DUSK_GRIP_COST, "Сорвавшаяся Хватка возвращает Сумрак.")

/// Шаг в тень ведёт за спину человека, а не в любую тёмную клетку; стена, товарищ и яркий свет за спиной не пускают; Удар из тени бьёт сильнее и замедляет.
/datum/unit_test/heretic_dusk_step/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_step)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/turf/behind = heretic_lead_test_spot(4, 2)
	dusk_light_all(0)
	TEST_ASSERT(findtext(dusk.step_block_reason(user, victim), "Крыла"), "Шаг в тень только в облике Крыла.")
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	TEST_ASSERT(findtext(dusk.step_block_reason(user, heretic_lead_test_spot(2, 4)), "чужую тень"), "В пустую тёмную клетку Шаг не ведёт.")
	dusk_light(behind, 1)
	TEST_ASSERT(findtext(dusk.step_block_reason(user, victim), "ярко"), "За спиной на ярком свету тень не держится.")
	dusk_light(behind, 0)
	var/mob/living/carbon/human/friend = heretic_lead_test_crew(behind)
	TEST_ASSERT(findtext(dusk.step_block_reason(user, victim), "другой человек"), "Товарищ за спиной не пускает Шаг.")
	qdel(friend)
	TEST_ASSERT(dusk.shadow_step(user, victim), "Шаг в тень за спину: [dusk.dusk_failure]")
	TEST_ASSERT_EQUAL(get_turf(user), behind, "Еретик встал за спиной цели.")
	TEST_ASSERT_EQUAL(dusk.charges["step"], HERETIC_DUSK_STEP_CHARGES - 1, "Шаг тратит заряд.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_dusk/puddle) in behind, "На выходе чернильная лужа.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_dusk/puddle) in heretic_lead_test_spot(0, 2), "На входе чернильная лужа.")
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, get_turf(user))
	user.put_in_active_hand(blade)
	user.a_intent = INTENT_HARM
	var/brute = victim.getBruteLoss()
	blade.attack(victim, user)
	TEST_ASSERT(victim.getBruteLoss() - brute >= HERETIC_DUSK_STRIKE_DAMAGE, "Удар из тени бьёт сильнее: [victim.getBruteLoss() - brute].")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_slowed), "Удар из тени сбивает с шага.")
	TEST_ASSERT(!dusk.strike_until, "Удар из тени разовый.")
	dusk.tick_charges(HERETIC_DUSK_STEP_RECHARGE)
	TEST_ASSERT_EQUAL(dusk.charges["step"], HERETIC_DUSK_STEP_CHARGES, "Заряд возвращается за 8 секунд.")
	dusk.charges["step"] = 0
	user.reagents.add_reagent(/datum/reagent/water/holywater, 5)
	dusk.refresh_light()
	dusk.tick_charges(HERETIC_DUSK_STEP_RECHARGE)
	TEST_ASSERT_EQUAL(dusk.charges["step"], 0, "Святая вода в крови держит заряды.")
	TEST_ASSERT(findtext(dusk.step_block_reason(user, victim), "святое"), "Отказ называет святое.")

/// Нисхождение падает к цели на свету с телеграфом, ранит и сбивает её; в тень не ведёт.
/datum/unit_test/heretic_dusk_descent/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	// Удар смены облика по соседям здесь не меряется.
	COOLDOWN_START(dusk, form_strike, 10 MINUTES)
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_covenant)
	dusk.combat_resource = dusk.combat_resource_max
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(4, 2))
	dusk_light_all(1)
	dusk_light(victim, 0)
	TEST_ASSERT(findtext(dusk.descent_block_reason(user, victim), "в тени"), "В тень Нисхождение не падает.")
	dusk_light(victim, 1)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	TEST_ASSERT(findtext(dusk.descent_block_reason(user, victim), "Лика"), "Нисхождение только в Лике.")
	dusk.set_form(HERETIC_DUSK_FORM_FACE)
	TEST_ASSERT(dusk.descent(user, victim), "Нисхождение: [dusk.dusk_failure]")
	TEST_ASSERT(get_dist(user, victim) <= 1, "Еретик приземлился рядом с целью.")
	TEST_ASSERT(victim.IsKnockdown(), "Цель сбита с ног.")
	TEST_ASSERT(abs(victim.getBruteLoss() - HERETIC_DUSK_DESCENT_DAMAGE) < 0.5, "Нисхождение бьёт на [HERETIC_DUSK_DESCENT_DAMAGE] ушибов: [victim.getBruteLoss()].")
	TEST_ASSERT_NULL(locate(/obj/effect/heretic_dusk_light_burn) in range(1, user), "Без Завета Нимба ожога света нет.")
	TEST_ASSERT_EQUAL(dusk.charges["descent"], 0, "Нисхождение тратит заряд.")
	victim.forceMove(heretic_lead_test_spot(4, 4))
	TEST_ASSERT(findtext(dusk.descent_block_reason(user, victim), "не готово"), "Без заряда Нисхождение ждёт.")

/// Лик ангела слепит смотрящих спереди, тёмные очки и отвернувшихся не берёт; перегрузка гасит чужой фонарик.
/datum/unit_test/heretic_dusk_glare/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_glare)
	dusk.combat_resource = dusk.combat_resource_max
	user.setDir(EAST)
	var/mob/living/carbon/human/watcher = dusk_crew_facing(heretic_lead_test_spot(2, 2), WEST)
	var/mob/living/carbon/human/shaded = dusk_crew_facing(heretic_lead_test_spot(2, 3), SOUTHWEST)
	var/obj/item/clothing/glasses/sunglasses/shades = allocate(/obj/item/clothing/glasses/sunglasses)
	shaded.equip_to_slot_or_del(shades, ITEM_SLOT_EYES)
	var/mob/living/carbon/human/turned = dusk_crew_facing(heretic_lead_test_spot(2, 1), EAST)
	TEST_ASSERT(dusk.glare(user, heretic_lead_test_spot(3, 2)), "Лик раскрыт: [dusk.dusk_failure]")
	TEST_ASSERT(watcher.eye_blind > 0, "Смотрящий на Лик слепнет.")
	TEST_ASSERT_NOTNULL(watcher.has_status_effect(/datum/status_effect/heretic_dusk_afterglow), "Ослеплённый видит выжженный нимб.")
	TEST_ASSERT(!shaded.eye_blind, "Тёмные очки держат свет Лика.")
	TEST_ASSERT(!turned.eye_blind, "Отвернувшийся не слепнет.")
	var/mob/living/carbon/human/bearer = heretic_lead_test_crew(heretic_lead_test_spot(4, 4))
	var/obj/item/flashlight/torch = dusk_lit_torch(bearer)
	TEST_ASSERT(dusk.glare(user, bearer), "Перегрузка фонарика: [dusk.dusk_failure]")
	TEST_ASSERT(!torch.on && HAS_TRAIT(torch, TRAIT_MOD_DISRUPTED), "Перегруженный фонарик гаснет и не включается.")
	TEST_ASSERT(!torch.attack_self(bearer), "Перегруженный фонарик не зажечь сразу.")

/// Перевёрнутый нимб: экран затмения у меченого, удар Пера - ушибы и слепота.
/datum/unit_test/heretic_dusk_mark/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/dusk_mark)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	user.a_intent = INTENT_HARM
	fist.afterattack(victim, user, TRUE)
	var/datum/status_effect/eldritch/dusk/mark = victim.has_status_effect(/datum/status_effect/eldritch/dusk)
	TEST_ASSERT_NOTNULL(mark, "Хватка вешает перевёрнутый нимб.")
	TEST_ASSERT(mark in dusk.marks, "Метка учтена.")
	TEST_ASSERT_NOTNULL(victim.fullscreens["heretic_dusk_eclipse"], "Меченый видит диск затмения.")
	victim.SetKnockdown(0)
	victim.adjustBruteLoss(-200)
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, get_turf(user))
	user.put_in_active_hand(blade)
	blade.attack(victim, user)
	TEST_ASSERT(QDELETED(mark), "Удар Пера взрывает метку.")
	TEST_ASSERT(victim.getBruteLoss() >= HERETIC_DUSK_MARK_DAMAGE, "Взрыв метки бьёт ушибами.")
	TEST_ASSERT(victim.eye_blind > 0, "Взрыв метки ослепляет.")
	TEST_ASSERT_NULL(victim.fullscreens["heretic_dusk_eclipse"], "Диск затмения уходит с экрана.")

/// Мутация растёт по ступеням, видна на свету и в осмотре, уходит со смертью и снятием роли.
/datum/unit_test/heretic_dusk_mutation/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	var/datum/antagonist/heretic/heretic = dusk.owner_heretic()
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/mob/living/carbon/human/witness = heretic_lead_test_crew(heretic_lead_test_spot(3, 3))
	dusk_light(user, 1)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.mutation_level, 1, "С выбора пути проступают трещины.")
	TEST_ASSERT(("dusk_mut_cracks" in dusk.mutation_states()) && !("dusk_mut_wing_stumps" in dusk.mutation_states()), "Первая ступень - только трещины.")
	var/list/overlays = list()
	SEND_SIGNAL(user, COMSIG_ATOM_UPDATE_OVERLAYS, overlays)
	TEST_ASSERT(length(overlays) >= 2, "На свету трещины видны и светятся.")
	TEST_ASSERT(findtext(jointext(user.examine(witness), " "), "трещины"), "Осмотр описывает трещины.")
	heretic.path_stage = 4
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.mutation_level, 2, "С четвёртой ступени - культи крыльев.")
	TEST_ASSERT("dusk_mut_wing_stumps" in dusk.mutation_states(), "Культи крыльев в мутации.")
	var/mutable_appearance/stumps = heretic_dusk_test_overlay(dusk, "dusk_mut_wing_stumps")
	TEST_ASSERT(stumps?.alpha == 255 && stumps.pixel_x == -16 && stumps.pixel_y == -16, "Культи видны и в Лике, кадр 64x64 стоит по центру тела.")
	TEST_ASSERT_NOTNULL(heretic_dusk_test_overlay(dusk, "dusk_mut_wing_stumps_front"), "У культей есть передний слой над телом.")
	TEST_ASSERT_NOTNULL(heretic_dusk_test_overlay(dusk, "dusk_mut_cracks_body"), "Трещины тела под одеждой.")
	for(var/mutable_appearance/look as anything in dusk.mutation_overlays)
		if(look.plane != EMISSIVE_PLANE)
			TEST_ASSERT(!(look.appearance_flags & KEEP_APART), "[look.icon_state] ложится по слою вместе с одеждой, а не поверх мантии.")
	var/list/states = dusk.mutation_states()
	TEST_ASSERT_EQUAL(states[length(states)], "dusk_stance_face", "Облик ложится поверх ступени.")
	TEST_ASSERT(findtext(jointext(user.examine(witness), " "), "культи"), "Осмотр описывает культи крыльев.")
	heretic.path_stage = 7
	dusk_tick(dusk)
	TEST_ASSERT("dusk_mut_halo_cracked" in dusk.mutation_states(), "С седьмой ступени - треснувший нимб.")
	TEST_ASSERT(findtext(jointext(user.examine(witness), " "), "нимб"), "Осмотр описывает нимб.")
	dusk_light(user, 0)
	dusk_tick(dusk)
	overlays = list()
	SEND_SIGNAL(user, COMSIG_ATOM_UPDATE_OVERLAYS, overlays)
	for(var/mutable_appearance/look as anything in overlays)
		TEST_ASSERT(look.plane != EMISSIVE_PLANE, "В тени мутация не светится.")
	TEST_ASSERT(findtext(jointext(user.examine(witness), " "), "почти не видно"), "Осмотр в тени подсказывает, что его почти не видно.")
	heretic.clear_heretic()
	overlays = list()
	SEND_SIGNAL(user, COMSIG_ATOM_UPDATE_OVERLAYS, overlays)
	TEST_ASSERT_EQUAL(length(overlays), 0, "Снятая роль убирает мутацию.")
	TEST_ASSERT(!findtext(jointext(user.examine(witness), " "), "трещины"), "Осмотр больше не видит мутацию.")

/// Смерть гасит мутацию и экран облика.
/datum/unit_test/heretic_dusk_death/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	dusk_light(user, 0)
	dusk_tick(dusk)
	TEST_ASSERT_NOTNULL(user.fullscreens["heretic_dusk_feathers"], "Крыло в тени видит перья по краям экрана.")
	TEST_ASSERT_NOTNULL(locate(/datum/client_colour/heretic_dusk_wing) in user.client_colours, "Мир Крыла в тени выцветает.")
	dusk_light(user, 1)
	dusk_tick(dusk)
	TEST_ASSERT_NULL(user.fullscreens["heretic_dusk_feathers"], "На свету перья сходят.")
	dusk_light(user, 0)
	dusk_tick(dusk)
	user.death()
	var/datum/antagonist/heretic/heretic = dusk.owner_heretic()
	heretic.handle_death(user)
	TEST_ASSERT_NULL(user.fullscreens["heretic_dusk_feathers"], "Смерть снимает экран облика.")
	TEST_ASSERT_NULL(locate(/datum/client_colour/heretic_dusk_wing) in user.client_colours, "Смерть снимает цвет облика.")
	var/list/overlays = list()
	SEND_SIGNAL(user, COMSIG_ATOM_UPDATE_OVERLAYS, overlays)
	TEST_ASSERT_EQUAL(length(overlays), 0, "Смерть гасит мутацию.")
	TEST_ASSERT_EQUAL(dusk.combat_resource, 0, "Смерть обнуляет Сумрак.")

/// Экраны Сумрака: подвижные части - слои из листа, растягиваются вместе с кадром, ступени Хватки меняют видимые руки, qdel убирает слои.
/datum/unit_test/heretic_dusk_screens/Run()
	var/list/states = icon_states(HERETIC_DUSK_FULLSCREEN_ICON)
	var/list/layered = list(/atom/movable/screen/fullscreen/scaled/heretic_dusk/feathers, /atom/movable/screen/fullscreen/scaled/heretic_dusk/glare, /atom/movable/screen/fullscreen/scaled/heretic_dusk/cracks, /atom/movable/screen/fullscreen/scaled/heretic_dusk/wings_halo, /atom/movable/screen/fullscreen/scaled/heretic_dusk/hands, /atom/movable/screen/fullscreen/scaled/heretic_dusk/eclipse, /atom/movable/screen/fullscreen/scaled/heretic_dusk/vignette)
	for(var/screen_type in subtypesof(/atom/movable/screen/fullscreen/scaled/heretic_dusk))
		var/atom/movable/screen/fullscreen/scaled/heretic_dusk/screen = new screen_type
		TEST_ASSERT(screen.icon_state in states, "[screen_type]: кадр [screen.icon_state] есть в листе.")
		var/list/atom/movable/layers = dusk_screen_layers(screen)
		if(screen_type in layered)
			TEST_ASSERT(length(layers), "[screen_type]: движение вынесено в слои.")
		for(var/atom/movable/part as anything in layers)
			TEST_ASSERT(part.icon_state in states, "[screen_type]: слой [part.icon_state] есть в листе.")
			TEST_ASSERT(!(part.appearance_flags & RESET_TRANSFORM), "[screen_type]: слой [part.icon_state] растягивается вместе с кадром.")
		qdel(screen)
		for(var/atom/movable/part as anything in layers)
			TEST_ASSERT(QDELETED(part), "[screen_type]: слой [part.icon_state] удаляется с экраном.")
	var/atom/movable/screen/fullscreen/scaled/heretic_dusk/hands/hands = new
	for(var/stage in list(1, 2, 3, 2))
		hands.SetSeverity(stage)
		var/list/shown = list()
		for(var/atom/movable/part as anything in dusk_screen_layers(hands))
			if(part.alpha && findtext(part.icon_state, "_hands") && part.icon_state != "dusk_fs_hands_veil")
				shown |= copytext(part.icon_state, 1, length("dusk_fs_handsN") + 1)
		TEST_ASSERT_EQUAL(jointext(shown, ","), "dusk_fs_hands[stage]", "На ступени [stage] видны только её руки.")
	qdel(hands)
	var/atom/movable/screen/fullscreen/scaled/heretic_dusk/glare/glare = new
	for(var/atom/movable/part as anything in list(glare) + dusk_screen_layers(glare))
		TEST_ASSERT_EQUAL(part.blend_mode, BLEND_ADD, "Засвет Лика ложится светом поверх мира: [part.icon_state].")
	qdel(glare)
	var/atom/movable/screen/fullscreen/scaled/heretic_dusk/eclipse/eclipse = new
	var/atom/movable/ring_flash
	for(var/atom/movable/part as anything in dusk_screen_layers(eclipse))
		if(part.icon_state == "dusk_fs_eclipse_flash")
			ring_flash = part
	TEST_ASSERT(ring_flash?.blend_mode == BLEND_ADD, "Закрытый диск затмения вспыхивает кольцом.")
	qdel(eclipse)

/// Квадратный вид 15x15: размытые слои растягиваются, рисунок держит пропорции и свой край, затмение и ожог не сплющены.
/datum/unit_test/heretic_dusk_screen_square/Run()
	var/list/shaped = list("dusk_fs_feathers_l" = WEST, "dusk_fs_feathers_r" = EAST, "dusk_fs_feathers_t" = 0, "dusk_fs_feathers_eyes_l" = WEST, "dusk_fs_feathers_eyes_r" = EAST, "dusk_fs_wings_halo_l" = WEST, "dusk_fs_wings_halo_r" = EAST, "dusk_fs_wings_halo_ring" = 0, "dusk_fs_hands3_l" = WEST, "dusk_fs_hands3_r" = EAST, "dusk_fs_hands1_b" = 0)
	var/list/whole = list(/atom/movable/screen/fullscreen/scaled/heretic_dusk/eclipse, /atom/movable/screen/fullscreen/scaled/heretic_dusk/afterglow)
	var/checked = 0
	for(var/screen_type in list(/atom/movable/screen/fullscreen/scaled/heretic_dusk/feathers, /atom/movable/screen/fullscreen/scaled/heretic_dusk/wings_halo, /atom/movable/screen/fullscreen/scaled/heretic_dusk/hands) + whole)
		var/atom/movable/screen/fullscreen/scaled/heretic_dusk/screen = new screen_type
		var/half = screen.size_x * world.icon_size / 2
		var/view_half = 15 * world.icon_size / 2
		screen.SetView("15x15")
		var/matrix/frame = screen.transform
		if(screen_type in whole)
			TEST_ASSERT(abs(frame.a - frame.e) < 0.01, "[screen_type] не сплющен на квадратном виде.")
		if(screen_type == /atom/movable/screen/fullscreen/scaled/heretic_dusk/eclipse)
			TEST_ASSERT(abs(half * frame.a + frame.c - view_half) < 0.5, "Затмение держится у правого края, как на широком виде.")
		for(var/atom/movable/part as anything in dusk_screen_layers(screen))
			if(!(part.icon_state in shaped))
				continue
			checked++
			var/matrix/own = part.transform
			TEST_ASSERT(abs(frame.a * own.a - frame.e * own.e) < 0.01, "[part.icon_state] держит пропорции на квадратном виде.")
			var/edge = shaped[part.icon_state]
			if(edge)
				var/side = edge == WEST ? -1 : 1
				TEST_ASSERT(abs((own.a * side * half + own.c) * frame.a + frame.c - side * view_half) < 0.5, "[part.icon_state] прижат к своему краю экрана.")
		screen.SetView("21x15")
		frame = screen.transform
		TEST_ASSERT(abs(frame.a - 2) < 0.01 && abs(frame.e - 2) < 0.01 && !frame.c, "[screen_type]: на широком виде кадр растянут вдвое, как раньше.")
		qdel(screen)
	TEST_ASSERT_EQUAL(checked, length(shaped), "Проверены все слои с рисунком.")

/// Экран жертвы: без тени в темноте экран темнеет, но не гаснет; ожог нимба поверх слепоты; Лик слепит тьмой, а не белой вспышкой.
/datum/unit_test/heretic_dusk_victim_screens/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/mob/living/carbon/human/shadowless = heretic_lead_test_crew(heretic_lead_test_spot(4, 4))
	dusk_light(shadowless, 0)
	shadowless.apply_status_effect(/datum/status_effect/heretic_dusk_shadow, dusk)
	var/atom/movable/screen/fullscreen/dim = shadowless.fullscreens["heretic_dusk_blind"]
	TEST_ASSERT_EQUAL(dim?.severity, 1, "Без тени в темноте экран темнеет по краям, а не уходит в черноту.")
	TEST_ASSERT_NOTNULL(shadowless.fullscreens["heretic_dusk_blind_fx"], "Без тени в темноте видна кромка тьмы.")
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_glare)
	dusk.combat_resource = dusk.combat_resource_max
	user.setDir(EAST)
	var/mob/living/carbon/human/watcher = dusk_crew_facing(heretic_lead_test_spot(2, 2), WEST)
	TEST_ASSERT(dusk.glare(user, heretic_lead_test_spot(3, 2)), "Лик раскрыт: [dusk.dusk_failure]")
	TEST_ASSERT(watcher.eye_blind > 0, "Смотрящий на Лик слепнет.")
	var/atom/movable/screen/fullscreen/burn = watcher.fullscreens["heretic_dusk_afterglow"]
	TEST_ASSERT(burn?.layer > BLIND_LAYER, "Выжженный нимб виден поверх слепоты.")
	TEST_ASSERT(istype(watcher.fullscreens["flash"], /atom/movable/screen/fullscreen/tiled/flash/heretic_dusk), "Лик слепит тьмой: сквозь слепоту не светит белым.")

/datum/unit_test/proc/dusk_screen_layers(atom/movable/holder)
	. = list()
	for(var/atom/movable/part as anything in holder.vis_contents)
		. += part
		. += dusk_screen_layers(part)

/// Локальное затмение гасит лампы после телеграфа, а внутри Хватка берёт и на свету.
/datum/unit_test/heretic_dusk_eclipse/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(2, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_eclipse)
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_grip)
	dusk.combat_resource = dusk.combat_resource_max
	var/obj/machinery/light/small/lamp = allocate(/obj/machinery/light/small, heretic_lead_test_spot(3, 3))
	lamp.on = TRUE
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(4, 2))
	dusk_light(victim, 1)
	TEST_ASSERT(dusk.eclipse(user), "Затмение: [dusk.dusk_failure]")
	TEST_ASSERT_EQUAL(dusk.combat_resource, dusk.combat_resource_max - HERETIC_DUSK_ECLIPSE_COST, "Затмение стоит 3 Сумрака.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_time_passed), world.time + HERETIC_DUSK_ECLIPSE_TELEGRAPH + 1), 3 SECONDS, "телеграф затмения"), "Телеграф затмения прошёл.")
	TEST_ASSERT(dusk.eclipse_until > world.time, "Затмение стоит.")
	TEST_ASSERT(!lamp.on, "Лампа в затмении погасла.")
	TEST_ASSERT(dusk.in_eclipse(victim), "Цель внутри затмения.")
	TEST_ASSERT(dusk.grip_light_ok(victim), "Внутри затмения Хватка берёт и на свету.")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_eclipsed), "Экипаж в затмении видит виньетку.")
	var/obj/effect/heretic_dusk_eclipse/zone = dusk.eclipse_zone
	dusk.end_eclipse()
	TEST_ASSERT(QDELETED(zone) && !dusk.in_eclipse(victim), "Конец затмения убирает тьму.")
	TEST_ASSERT(heretic_dusk_restore_lamp(WEAKREF(lamp)) || lamp.on == lamp.has_power(), "Лампа загорается снова.")

/// Фонарь полуночи: в руке копит Сумрак в любом облике и даёт ночное зрение, в руке же гасит лампы рядом.
/datum/unit_test/heretic_dusk_lantern/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(1, 1)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/datum/eldritch_knowledge/dusk_relic/recipe = dusk_learn(dusk, /datum/eldritch_knowledge/dusk_relic)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Обряд создаёт Фонарь полуночи.")
	var/obj/item/heretic_path_relic/dusk_lantern/lantern = recipe.new_path_relic_ref.resolve()
	TEST_ASSERT_NOTNULL(lantern, "Фонарь создан.")
	TEST_ASSERT(!recipe.recipe_snowflake_check(list(), get_turf(user), list(), user), "Второй Фонарь не сделать, пока жив первый.")
	user.put_in_active_hand(lantern)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	dusk_light(user, 1)
	dusk_tick(dusk)
	TEST_ASSERT(dusk.can_gather(), "С Фонарём Крыло копит Сумрак и на свету.")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_TRUE_NIGHT_VISION), "Фонарь в руке даёт видеть в темноте.")
	var/obj/machinery/light/small/lamp = allocate(/obj/machinery/light/small, heretic_lead_test_spot(2, 2))
	lamp.on = TRUE
	lantern.attack_self(user)
	TEST_ASSERT(!lamp.on, "Фонарь гасит лампу рядом.")
	TEST_ASSERT(!COOLDOWN_FINISHED(lantern, relic_cooldown), "У Фонаря перезарядка.")
	user.dropItemToGround(lantern)
	dusk_tick(dusk)
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_TRUE_NIGHT_VISION), "Без Фонаря ночное зрение уходит.")
	var/mob/living/carbon/human/stranger = heretic_lead_test_crew(get_turf(user))
	stranger.put_in_active_hand(lantern)
	lamp.on = TRUE
	COOLDOWN_RESET(lantern, relic_cooldown)
	lantern.attack_self(stranger)
	TEST_ASSERT(lamp.on, "Не-еретику Фонарь не светит.")

/// Крыло видит тьму холодными сумерками, Лик - как человек; свет в лицо и вспышка гасят это зрение, защита глаз держит.
/datum/unit_test/heretic_dusk_dark_sight/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(2, 2)
	var/datum/antagonist/heretic/heretic = dusk.owner_heretic()
	var/mob/living/carbon/human/user = dusk.dusk_body
	heretic.path_stage = 1
	heretic.refresh_evolution()
	dusk_light_all(0)
	dusk_tick(dusk)
	TEST_ASSERT_NULL(dusk.night_sight, "Лик в темноте видит как человек.")
	TEST_ASSERT(!heretic_dusk_test_sight_raised(user), "Зрение Лика не меняется.")
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	TEST_ASSERT_EQUAL(dusk.night_sight, HERETIC_DUSK_SIGHT_WING, "Крыло видит в темноте с первой ступени.")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_TRUE_NIGHT_VISION), "Крыло видит тьму не как днём.")
	TEST_ASSERT(heretic_dusk_test_sight_raised(user), "Крыло высветляет тьму.")
	var/list/cutoffs = user.lighting_color_cutoffs
	TEST_ASSERT(user.lighting_alpha > LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE && cutoffs[3] > cutoffs[1], "Тьма Крыла - приглушённые холодные сумерки: [user.lighting_alpha], [jointext(cutoffs, ",")].")
	TEST_ASSERT(heretic_dusk_test_eyes(user), "В тени у Крыла горят глаза.")
	user.setDir(EAST)
	var/mob/living/carbon/human/behind = heretic_lead_test_crew(get_step(user, WEST))
	var/obj/item/flashlight/back_torch = dusk_lit_torch(behind)
	behind.a_intent = INTENT_HELP
	back_torch.melee_attack_chain(behind, user)
	TEST_ASSERT_EQUAL(dusk.night_sight, HERETIC_DUSK_SIGHT_WING, "Фонарь в спину зрение не гасит.")
	var/mob/living/carbon/human/spotter = heretic_lead_test_crew(get_step(user, EAST))
	var/obj/item/flashlight/torch = dusk_lit_torch(spotter)
	spotter.a_intent = INTENT_HELP
	torch.melee_attack_chain(spotter, user)
	TEST_ASSERT_NULL(dusk.night_sight, "Фонарь в лицо гасит тёмное зрение Крыла.")
	TEST_ASSERT(abs(dusk.sight_snuffed_until - world.time - HERETIC_DUSK_SIGHT_SNUFF) < 1, "Зрение гаснет на [HERETIC_DUSK_SIGHT_SNUFF / (1 SECONDS)] секунд.")
	TEST_ASSERT(!heretic_dusk_test_eyes(user), "Ослеплённое Крыло не светит глазами.")
	dusk.sight_snuffed_until = world.time
	dusk.end_snuff()
	TEST_ASSERT_EQUAL(dusk.night_sight, HERETIC_DUSK_SIGHT_WING, "Зрение возвращается.")
	TEST_ASSERT(heretic_dusk_test_eyes(user), "Глаза загораются снова.")
	var/obj/item/assembly/flash/handheld/flash = allocate(/obj/item/assembly/flash/handheld, get_turf(spotter))
	flash.attack(user, spotter)
	TEST_ASSERT_NULL(dusk.night_sight, "Вспышка перед Крылом гасит его тёмное зрение.")
	dusk.sight_snuffed_until = world.time
	dusk.end_snuff()
	var/obj/item/clothing/glasses/sunglasses/shades = allocate(/obj/item/clothing/glasses/sunglasses)
	TEST_ASSERT(user.equip_to_slot_if_possible(shades, ITEM_SLOT_EYES), "Очки надеты.")
	TEST_ASSERT(!heretic_dusk_test_eyes(user), "Тёмные очки закрывают отблеск глаз.")
	flash.last_trigger = 0
	flash.attack(user, spotter)
	TEST_ASSERT_EQUAL(dusk.night_sight, HERETIC_DUSK_SIGHT_WING, "Защита глаз держит вспышку.")
	user.dropItemToGround(shades)
	TEST_ASSERT(heretic_dusk_test_eyes(user), "Без очков глаза снова видны.")
	var/obj/item/clothing/mask/gas/mask = allocate(/obj/item/clothing/mask/gas)
	TEST_ASSERT(user.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK), "Противогаз надет.")
	TEST_ASSERT(!heretic_dusk_test_eyes(user), "Противогаз закрывает отблеск глаз.")
	user.dropItemToGround(mask)
	dusk_light(user, 1)
	dusk_tick(dusk)
	TEST_ASSERT(!heretic_dusk_test_eyes(user), "На свету глаза не светятся.")
	TEST_ASSERT_EQUAL(dusk.night_sight, HERETIC_DUSK_SIGHT_WING, "Крыло видит в темноте и стоя на свету.")
	dusk.set_form(HERETIC_DUSK_FORM_FACE)
	TEST_ASSERT_NULL(dusk.night_sight, "Лик теряет тёмное зрение Крыла.")
	TEST_ASSERT(!heretic_dusk_test_sight_raised(user), "Без Крыла сумерки сходят.")
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT(isnull(dusk.night_sight) && !heretic_dusk_test_eyes(user), "Смерть снимает тёмное зрение и глаза.")
	user.revive(full_heal = TRUE, admin_revive = TRUE)
	dusk_light(user, 0)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.night_sight, HERETIC_DUSK_SIGHT_WING, "Воскресшее Крыло снова видит в темноте.")
	heretic.clear_heretic()
	TEST_ASSERT(isnull(dusk.night_sight) && !heretic_dusk_test_eyes(user) && !heretic_dusk_test_sight_raised(user), "Сброс пути снимает тёмное зрение.")

/// Тьма на экране светлее обычной: сигнал обновления зрения поверх голого тела.
/proc/heretic_dusk_test_sight_raised(mob/living/user)
	user.lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
	user.lighting_color_cutoffs = null
	SEND_SIGNAL(user, COMSIG_MOB_UPDATE_SIGHT)
	return user.lighting_alpha < LIGHTING_PLANE_ALPHA_VISIBLE && length(user.lighting_color_cutoffs) == 3

/proc/heretic_dusk_test_eyes(mob/living/user)
	var/list/overlays = list()
	SEND_SIGNAL(user, COMSIG_ATOM_UPDATE_OVERLAYS, overlays)
	for(var/mutable_appearance/look as anything in overlays)
		if(findtext(look.icon_state, "_left_eye") && look.plane == EMISSIVE_PLANE)
			return TRUE
	return FALSE

/// Вознёсшийся видит тьму как день в обоих обликах, свет в лицо гасит и это зрение.
/datum/unit_test/heretic_dusk_ascended_base/heretic_dusk_ascended_sight/Run()
	var/list/fixture = dusk_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_dusk/dusk = fixture["dusk"]
	sky_source = fixture["finale"]
	dusk_light_all(0)
	dusk_tick(dusk)
	TEST_ASSERT(dusk.night_sight == HERETIC_DUSK_SIGHT_FULL && HAS_TRAIT(user, TRAIT_TRUE_NIGHT_VISION), "Лик вознёсшегося видит тьму как день.")
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	TEST_ASSERT(dusk.night_sight == HERETIC_DUSK_SIGHT_FULL && HAS_TRAIT(user, TRAIT_TRUE_NIGHT_VISION), "Крыло вознёсшегося видит тьму как день.")
	TEST_ASSERT(dusk.snuff_sight(), "Вспышка слепит и вознёсшегося.")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_TRUE_NIGHT_VISION), "Ослеплённый вознёсшийся теряет ночное зрение.")
	dusk.sight_snuffed_until = world.time
	dusk.end_snuff()
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_TRUE_NIGHT_VISION), "Зрение вознёсшегося возвращается.")
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = fixture["finale"]
	finale.on_body_lose(user)
	TEST_ASSERT_EQUAL(dusk.night_sight, HERETIC_DUSK_SIGHT_WING, "Без вознесения остаётся зрение Крыла.")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_TRUE_NIGHT_VISION), "Ночное зрение вознесения снимается.")

/// Вознесение: Чёрные солнца встают на полигоне, гасят свет отсека, выключатель не помогает, святое и оружие их бьют, последнее возвращает свет.
/datum/unit_test/heretic_dusk_ascended_base/heretic_dusk_suns/Run()
	var/list/fixture = dusk_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_dusk/dusk = fixture["dusk"]
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = fixture["finale"]
	sky_source = finale
	TEST_ASSERT(dusk.ascension_active, "Вознесение включено.")
	TEST_ASSERT_EQUAL(dusk.charge_cap("descent"), 0, "Без Завета падшего зарядов Нисхождения нет.")
	var/turf/spot = heretic_lead_test_spot(4, 4)
	var/turf/lamp_spot = heretic_lead_test_spot(3, 4)
	var/turf/chapel_spot = heretic_lead_test_spot(0, 4)
	var/turf/dorm_spot = heretic_lead_test_spot(0, 3)
	heretic_test_area(chapel_spot, /area/service/chapel/main)
	heretic_test_area(dorm_spot, /area/commons/dorms)
	heretic_test_area(spot, /area/hallway/primary/fore)
	TEST_ASSERT(heretic_dusk_sun_area(get_area(spot)), "Солнце встаёт в общем коридоре.")
	TEST_ASSERT(!heretic_dusk_sun_area(get_area(chapel_spot)), "В часовне солнце не встаёт.")
	TEST_ASSERT(!heretic_dusk_sun_area(get_area(dorm_spot)), "В жилых каютах солнце не встаёт.")
	heretic_test_area(lamp_spot, /area/hallway/primary/fore)
	var/obj/machinery/light/small/lamp = allocate(/obj/machinery/light/small, lamp_spot)
	lamp.on = TRUE
	var/area/night = get_area(spot)
	var/obj/structure/heretic_dusk_black_sun/sun = new(spot, finale, night)
	finale.suns += sun
	finale.suns_raised = TRUE
	finale.darken_area(night)
	dusk.suns_standing = TRUE
	finale.process_lamps()
	TEST_ASSERT(!lamp.on && !night.lightswitch, "Под Чёрным солнцем свет гаснет.")
	night.lightswitch = TRUE
	night.power_change()
	TEST_ASSERT(!night.lightswitch, "Выключатель не зажигает свет, пока солнце стоит.")
	finale.process_lamps()
	TEST_ASSERT(!lamp.on, "Лампа гаснет снова.")
	dusk_splash(sun)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dusk_test_integrity), sun, HERETIC_DUSK_SUN_INTEGRITY - HERETIC_DUSK_SUN_HOLY_DAMAGE), 2 SECONDS, "святая вода по солнцу"), "Святая вода снимает 50 прочности: [sun.obj_integrity].")
	var/mob/living/carbon/human/chaplain = heretic_lead_test_crew(get_step(spot, WEST))
	chaplain.mind.isholy = TRUE
	var/obj/item/storage/book/bible/book = allocate(/obj/item/storage/book/bible)
	sun.attackby(book, chaplain)
	TEST_ASSERT_EQUAL(sun.obj_integrity, HERETIC_DUSK_SUN_INTEGRITY - HERETIC_DUSK_SUN_HOLY_DAMAGE - HERETIC_DUSK_SUN_PRAYER_DAMAGE, "Молитва капеллана снимает 30.")
	sun.take_damage(sun.obj_integrity, BRUTE, MELEE, FALSE)
	TEST_ASSERT(QDELETED(sun), "Обычный урон разбивает солнце.")
	TEST_ASSERT(night.lightswitch && finale.night_over, "Последнее солнце возвращает свет, ночь отступает.")
	TEST_ASSERT(!dusk.suns_standing, "Без солнц вознёсшийся не питается тенями.")
	finale.process_lamps()
	TEST_ASSERT_EQUAL(lamp.on, lamp.has_power(), "Лампа загорается по выключателю.")
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(1, 1))
	user.adjustBruteLoss(30)
	dusk.suns_standing = TRUE
	victim.apply_status_effect(/datum/status_effect/heretic_dusk_shadow, dusk)
	TEST_ASSERT(user.getBruteLoss() <= 30 - HERETIC_DUSK_SHADOW_HEAL + 0.5, "При стоящем солнце отнятая тень лечит вознёсшегося.")

/// Долгая ночь: экипаж у Чёрного солнца видит виньетку ночи, вознёсшийся - нет; с концом ночи виньетка больше не вешается.
/datum/unit_test/heretic_dusk_ascended_base/heretic_dusk_night_vignette/Run()
	var/list/fixture = dusk_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = fixture["finale"]
	sky_source = finale
	finale.simulated = TRUE
	for(var/turf/spot as anything in block(run_loc_floor_bottom_left, run_loc_floor_top_right))
		heretic_test_area(spot, /area/antag_training)
	var/mob/living/carbon/human/witness = heretic_lead_test_crew(heretic_lead_test_spot(4, 4))
	TEST_ASSERT(finale.raise_suns(user), "Чёрные солнца встают.")
	TEST_ASSERT_NOTNULL(witness.has_status_effect(/datum/status_effect/heretic_dusk_eclipsed), "Свидетель у Чёрного солнца видит виньетку ночи.")
	TEST_ASSERT_NOTNULL(witness.fullscreens["heretic_dusk_vignette"], "Виньетка на экране свидетеля.")
	TEST_ASSERT_NULL(user.has_status_effect(/datum/status_effect/heretic_dusk_eclipsed), "Вознёсшийся виньетку ночи не видит.")
	TEST_ASSERT_NOTNULL(finale.night_timer, "Ночь повторяет виньетку, пока стоят солнца.")
	finale.end_night(TRUE)
	TEST_ASSERT(isnull(finale.night_timer) && !finale.night_pulse(), "С концом ночи виньетка больше не вешается.")

/// Лик на свету выбеливает и приглушает мир, а не красит его в жёлтый: серое остаётся серым, тёмное - тёмным.
/datum/unit_test/heretic_dusk_face_colour/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_light(user, 1)
	dusk_tick(dusk)
	var/datum/client_colour/face = locate(/datum/client_colour/heretic_dusk_face) in user.client_colours
	TEST_ASSERT_NOTNULL(face, "Лик на свету меняет цвет мира.")
	var/list/grey = heretic_dusk_test_tint(face.colour, list(0.5, 0.5, 0.5))
	TEST_ASSERT(max(grey) - min(grey) < 0.1, "Серое под Ликом остаётся серым: [jointext(grey, ", ")].")
	var/list/yellow = heretic_dusk_test_tint(face.colour, list(1, 1, 0))
	TEST_ASSERT(max(yellow) - min(yellow) < 0.8, "Жёлтое под Ликом выцветает: [jointext(yellow, ", ")].")
	var/list/white = heretic_dusk_test_tint(face.colour, list(1, 1, 1))
	TEST_ASSERT(min(white) > 0.8 && white[1] >= white[3], "Белое остаётся тёплым белым: [jointext(white, ", ")].")
	var/list/black = heretic_dusk_test_tint(face.colour, list(0, 0, 0))
	TEST_ASSERT(max(black) < 0.2, "Тёмные фигуры остаются тёмными: [jointext(black, ", ")].")

/// Цвет после матрицы клиента: строки - вклад красного, зелёного, синего, затем сдвиг.
/proc/heretic_dusk_test_tint(list/matrix, list/rgb)
	. = list()
	for(var/channel in 1 to 3)
		var/value = matrix[9 + channel]
		for(var/source in 1 to 3)
			value += rgb[source] * matrix[(source - 1) * 3 + channel]
		. += value

/proc/heretic_dusk_test_integrity(obj/structure/structure, value)
	return QDELETED(structure) || structure.obj_integrity <= value

/// На полигоне солнца встают рядом; смерть вознёсшегося гасит их.
/datum/unit_test/heretic_dusk_ascended_base/heretic_dusk_suns_training/Run()
	var/list/fixture = dusk_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = fixture["finale"]
	sky_source = finale
	finale.simulated = TRUE
	for(var/turf/spot as anything in block(run_loc_floor_bottom_left, run_loc_floor_top_right))
		heretic_test_area(spot, /area/antag_training)
	TEST_ASSERT(finale.raise_suns(user), "Чёрные солнца встают.")
	TEST_ASSERT_EQUAL(length(finale.suns), HERETIC_DUSK_SUNS, "Встают три солнца.")
	TEST_ASSERT_NOTNULL(user.alerts[HERETIC_DUSK_SUNS_ALERT], "Вознёсшийся видит значок солнц.")
	TEST_ASSERT(!finale.raise_suns(user), "Солнца встают один раз.")
	var/list/obj/structure/heretic_dusk_black_sun/suns = finale.suns.Copy()
	user.death()
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	heretic.handle_death(user)
	TEST_ASSERT(finale.night_over && !length(finale.suns), "Смерть вознёсшегося гасит ночь.")
	for(var/obj/structure/heretic_dusk_black_sun/sun as anything in suns)
		TEST_ASSERT(QDELETED(sun), "Солнце уходит со смертью вознёсшегося.")

/// Вознёсшегося часовня жжёт и держит его силу; осквернение срывает сильный удар, успех снимает святость.
/datum/unit_test/heretic_dusk_ascended_base/heretic_dusk_chapel/Run()
	var/list/fixture = dusk_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_dusk/dusk = fixture["dusk"]
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = fixture["finale"]
	sky_source = finale
	TEST_ASSERT(findtext(finale.desecrate_block_reason(user), "часовню"), "Вне часовни осквернять нечего.")
	heretic_test_area(get_turf(user), /area/service/chapel/main)
	user.adjustFireLoss(-200)
	dusk_tick(dusk)
	TEST_ASSERT(user.getFireLoss() >= HERETIC_DUSK_CHAPEL_BURN, "Святая земля жжёт вознёсшегося.")
	TEST_ASSERT(findtext(dusk.cast_block_reason(user), "Святая земля"), "На святой земле сила вознёсшегося заперта.")
	var/obj/effect/proc_holder/spell/self/heretic_dusk/form/form = dusk.combat_power
	TEST_ASSERT_NULL(form.block_reason(user), "Смена облика работает и на святой земле.")
	INVOKE_ASYNC(finale, TYPE_PROC_REF(/datum/eldritch_knowledge/final_eldritch/dusk_final, desecrate), user)
	TEST_ASSERT(finale.desecrating, "Осквернение началось.")
	user.apply_damage(HERETIC_DUSK_DESECRATE_BREAK + 5, BRUTE)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dusk_test_not_desecrating), finale), 3 SECONDS, "осквернение"), "Сильный удар срывает осквернение.")
	TEST_ASSERT(!GLOB.heretic_dusk_chapel_desecrated, "Сорванное осквернение часовню не трогает.")
	INVOKE_ASYNC(finale, TYPE_PROC_REF(/datum/eldritch_knowledge/final_eldritch/dusk_final, desecrate), user)
	dusk_splash(user)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dusk_test_not_desecrating), finale), 3 SECONDS, "осквернение"), "Святая вода срывает осквернение.")
	TEST_ASSERT(!GLOB.heretic_dusk_chapel_desecrated, "Часовня осталась святой.")
	TEST_ASSERT(finale.finish_desecration(user), "Осквернение завершается.")
	TEST_ASSERT(GLOB.heretic_dusk_chapel_desecrated && !heretic_dusk_holy_ground(user), "Осквернённая часовня больше не святая земля.")
	user.adjustFireLoss(-200)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(user.getFireLoss(), 0, "Осквернённая часовня не жжёт.")
	TEST_ASSERT_NULL(dusk.cast_block_reason(user), "В осквернённой часовне сила свободна.")
	TEST_ASSERT(findtext(finale.desecrate_block_reason(user), "уже осквернена"), "Осквернение - один раз за раунд.")

/proc/heretic_dusk_test_not_desecrating(datum/eldritch_knowledge/final_eldritch/dusk_final/finale)
	return !finale.desecrating

/// Полдень в полночь слепит смотрящих и гасит их фонарики.
/datum/unit_test/heretic_dusk_ascended_base/heretic_dusk_noon/Run()
	var/list/fixture = dusk_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = fixture["finale"]
	sky_source = finale
	var/mob/living/carbon/human/watcher = dusk_crew_facing(get_step(get_step(user, EAST), EAST), WEST)
	var/mob/living/carbon/human/turned = dusk_crew_facing(get_step(get_step(user, NORTH), NORTH), NORTH)
	var/obj/item/flashlight/torch = dusk_lit_torch(turned)
	finale.noon(user)
	TEST_ASSERT_NULL(finale.noon_failure, "Полдень раскрыт: [finale.noon_failure]")
	TEST_ASSERT(watcher.eye_blind > 0, "Смотрящий слепнет.")
	TEST_ASSERT(!turned.eye_blind, "Отвернувшийся не слепнет.")
	TEST_ASSERT(!torch.on && HAS_TRAIT(torch, TRAIT_MOD_DISRUPTED), "Фонарики вокруг гаснут.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_dusk_wave) in get_turf(user), "Полдень расходится пиксельным кольцом перьев, а не мыльным пузырём.")

/// Вознёсшийся виден и в своей ночи: в тени облик не тускнеет, Лик светится, как на свету.
/datum/unit_test/heretic_dusk_ascended_base/heretic_dusk_ascended_visible/Run()
	var/list/fixture = dusk_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_dusk/dusk = fixture["dusk"]
	sky_source = fixture["finale"]
	var/mob/living/carbon/human/witness = heretic_lead_test_crew(heretic_lead_test_spot(3, 3))
	dusk.set_form(HERETIC_DUSK_FORM_FACE)
	dusk_light(user, 0)
	dusk_tick(dusk)
	TEST_ASSERT(!dusk.lit, "Вознёсшийся стоит в тени.")
	TEST_ASSERT_NOTNULL(heretic_dusk_test_overlay(dusk, "dusk_mut_wings_full"), "Крылья вознёсшегося на теле.")
	var/glows = 0
	for(var/mutable_appearance/look as anything in dusk.mutation_overlays)
		if(look.plane == EMISSIVE_PLANE)
			glows++
		else
			TEST_ASSERT_EQUAL(look.alpha, 255, "[look.icon_state] в тени виден полностью.")
	TEST_ASSERT(glows, "Лик вознёсшегося светится и в тени.")
	TEST_ASSERT(!findtext(jointext(user.examine(witness), " "), "почти не видно"), "Осмотр не прячет вознёсшегося в тени.")

/// В Крыле поднятые крылья облика заменяют культи и крылья вознесения, тусклый нимб - тёмный, но непрозрачный.
/datum/unit_test/heretic_dusk_ascended_base/heretic_dusk_wing_silhouette/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	var/datum/antagonist/heretic/heretic = dusk.owner_heretic()
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_light(user, 1)
	heretic.path_stage = 7
	dusk_tick(dusk)
	TEST_ASSERT("dusk_mut_wing_stumps" in dusk.mutation_states(), "В Лике культи на месте.")
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	var/list/states = dusk.mutation_states()
	TEST_ASSERT(!("dusk_mut_wing_stumps" in states) && ("dusk_stance_wing" in states), "В Крыле одна пара крыльев - крылья облика, без культей.")
	var/mutable_appearance/stance_back = heretic_dusk_test_overlay(dusk, "dusk_stance_wing")
	var/mutable_appearance/stance_front = heretic_dusk_test_overlay(dusk, "dusk_stance_wing_front")
	TEST_ASSERT(stance_back?.layer == -BODY_BEHIND_LAYER, "Крылья облика растут из-за плеч, а не висят перед телом.")
	TEST_ASSERT(stance_front?.layer == -BODY_FRONT_LAYER && ("dusk_stance_wing_front" in icon_states(dusk.mutation_icon())), "Корни крыльев облика поверх спины - свой передний слой.")
	var/mutable_appearance/halo = heretic_dusk_test_overlay(dusk, "dusk_mut_halo_cracked")
	TEST_ASSERT(halo?.alpha == 255 && halo.color, "Погасший нимб Крыла тёмный, но не просвечивает.")
	dusk_light(user, 0)
	dusk_tick(dusk)
	for(var/mutable_appearance/look as anything in dusk.mutation_overlays)
		TEST_ASSERT_EQUAL(look.alpha, 255, "[look.icon_state] в тени темнеет, а не просвечивает.")
	var/list/fixture = dusk_ascended()
	var/datum/eldritch_knowledge/base_dusk/ascended = fixture["dusk"]
	sky_source = fixture["finale"]
	ascended.set_form(HERETIC_DUSK_FORM_FACE)
	TEST_ASSERT("dusk_mut_wings_full" in ascended.mutation_states(), "Лик вознёсшегося раскрывает крылья вознесения.")
	TEST_ASSERT(heretic_dusk_test_glow(ascended, "dusk_mut_wings_full_rim"), "Кромка крыльев вознёсшегося светится в его ночи.")
	ascended.set_form(HERETIC_DUSK_FORM_WING)
	states = ascended.mutation_states()
	TEST_ASSERT(!("dusk_mut_wings_full" in states) && ("dusk_stance_wing" in states), "Крыло вознёсшегося - поднятые крылья облика вместо крыльев вознесения.")
	TEST_ASSERT(heretic_dusk_test_glow(ascended, "dusk_stance_wing_rim") && heretic_dusk_test_glow(ascended, "dusk_stance_wing_front_rim"), "Кромка поднятых крыльев светится на обоих слоях.")
	TEST_ASSERT(!heretic_dusk_test_glow(dusk, "dusk_stance_wing_rim"), "До вознесения Крыло в тени не светится.")

/proc/heretic_dusk_test_glow(datum/eldritch_knowledge/base_dusk/dusk, state)
	for(var/mutable_appearance/look as anything in dusk.mutation_overlays)
		if(look.icon_state == state && look.plane == EMISSIVE_PLANE)
			return TRUE
	return FALSE

/// Смена облика отмечена всплеском перьев в цвете листа мутации.
/datum/unit_test/heretic_dusk_form_burst/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	var/obj/effect/temp_visual/heretic_dusk_burst/burst = locate() in get_turf(user)
	TEST_ASSERT_NOTNULL(burst, "Смена облика выбрасывает перья.")
	TEST_ASSERT_EQUAL(burst.icon_state, "dusk_burst_wing", "Крыло роняет чёрные перья.")
	TEST_ASSERT(burst.icon == dusk.mutation_icon() && (burst.icon_state in icon_states(burst.icon)), "Всплеск нарисован в листе мутации.")
	qdel(burst)
	dusk.set_form(HERETIC_DUSK_FORM_FACE)
	burst = locate() in get_turf(user)
	TEST_ASSERT_EQUAL(burst?.icon_state, "dusk_burst_face", "Лик рассыпает бледно-золотые перья.")

/// Вознесение Сумрака без обводки фильтром и мыльного кольца: завеса держится на частицах, волна - пиксельное кольцо перьев, вспышка индиго.
/datum/unit_test/heretic_dusk_ascended_base/heretic_dusk_ascension_wave/Run()
	var/list/fixture = dusk_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = fixture["finale"]
	sky_source = finale
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_DUSK]
	var/datum/status_effect/heretic_emergence/veil = user.apply_status_effect(/datum/status_effect/heretic_emergence)
	TEST_ASSERT_NOTNULL(veil, "Вознёсшийся входит в явление.")
	TEST_ASSERT(isnull(user.get_filter("heretic_emergence")) && isnull(user.get_filter("heretic_emergence_glow")), "Силуэт Сумрака без автообводки: кромку крыльев рисует спрайт.")
	TEST_ASSERT_NOTNULL(veil.motes, "Завесу видно по частицам.")
	qdel(veil)
	var/turf/spot = get_turf(user)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_dusk_wave) in spot, "Завеса спадает пиксельным кольцом перьев.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_vfx/shockwave) in spot, "Общего кольца-пузыря нет.")
	for(var/obj/effect/temp_visual/heretic_dusk_wave/wave in spot)
		qdel(wave)
	finale.play_ascension_climax(user)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_dusk_wave) in spot, "Кульминация - то же кольцо перьев.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_vfx/shockwave) in spot, "И на кульминации без пузыря.")
	var/mob/living/carbon/human/witness = heretic_lead_test_crew(heretic_lead_test_spot(3, 3))
	var/datum/status_effect/heretic_ascension_omen/omen = witness.apply_status_effect(/datum/status_effect/heretic_ascension_omen, PATH_DUSK)
	var/atom/movable/screen/fullscreen/haze = witness.fullscreens[omen?.fullscreen_key]
	TEST_ASSERT_EQUAL(haze?.color, path.climax_ink, "Знамение Сумрака - дымка индиго, а не грязное золото.")
	TEST_ASSERT(path.climax_ink != path.book_ink, "Кульминация Сумрака красится не чернилами книги.")

/// Числа в описаниях заклинаний совпадают с дефайнами и перезарядками.
/datum/unit_test/heretic_dusk_texts/Run()
	var/list/expected = list(
		/obj/effect/proc_holder/spell/pointed/heretic_dusk/beam = list("[HERETIC_DUSK_BEAM_DAMAGE] ожогов", "[HERETIC_DUSK_BEAM_RANGE] клеток"),
		/obj/effect/proc_holder/spell/pointed/heretic_dusk/grip = list("За [HERETIC_DUSK_GRIP_COST] Сумрака", "[HERETIC_DUSK_GRIP_RANGE] клетках", "на [HERETIC_DUSK_GRIP_TIME / (1 SECONDS)] секунд", "за [HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)] секунды"),
		/obj/effect/proc_holder/spell/pointed/heretic_dusk/glare = list("[HERETIC_DUSK_GLARE_RANGE] клетках", "на [HERETIC_DUSK_GLARE_BLIND / (1 SECONDS)] секунды", "[HERETIC_DUSK_OVERLOAD_RANGE] клетках", "[HERETIC_DUSK_OVERLOAD_JAM / (1 SECONDS)] секунд без фонарика"),
		/obj/effect/proc_holder/spell/self/heretic_dusk/eclipse = list("За [HERETIC_DUSK_ECLIPSE_COST] Сумрака", "[HERETIC_DUSK_ECLIPSE_LAMPS] ближайших", "[HERETIC_DUSK_ECLIPSE_RADIUS] клетках", "на [HERETIC_DUSK_ECLIPSE_TIME / (1 SECONDS)] секунд"),
		/obj/effect/proc_holder/spell/self/heretic_dusk/noon = list("[HERETIC_DUSK_NOON_RADIUS] клетках", "на [HERETIC_DUSK_NOON_BLIND / (1 SECONDS)] секунд", "на [HERETIC_DUSK_NOON_DOUSE / (1 SECONDS)] секунд"),
	)
	for(var/spell_type in expected)
		var/obj/effect/proc_holder/spell/spell = spell_type
		var/desc = initial(spell.desc)
		for(var/fragment in expected[spell_type] + "Перезарядка [initial(spell.charge_max) / (1 SECONDS)] секунд")
			TEST_ASSERT(findtext(desc, fragment), "[spell_type]: в описании есть «[fragment]».")
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_DUSK]
	TEST_ASSERT(findtext(path.capture_summary, "[HERETIC_DUSK_GRIP_TIME / (1 SECONDS)] секунд"), "Шапка захвата называет время Хватки.")
	TEST_ASSERT(findtext(path.escape_summary, "[HERETIC_DUSK_STEP_RANGE] клетках") && findtext(path.escape_summary, "[HERETIC_DUSK_STEP_CHARGES] заряда"), "Шапка ухода называет дальность и заряды Шага.")
	TEST_ASSERT(findtext(jointext(path.strength_points, " "), "[HERETIC_DUSK_WING_FRONT_CUT]%"), "Сильная сторона называет защиту крыльев.")
	var/list/more = list(
		/obj/effect/proc_holder/spell/pointed/heretic_dusk/beam = list("до [HERETIC_DUSK_SERAPH_CHAIN] других", "по [HERETIC_DUSK_SERAPH_CHAIN_DAMAGE] ожога"),
		/obj/effect/proc_holder/spell/pointed/heretic_dusk/grip = list("на [HERETIC_DUSK_FALLEN_GRIP_BONUS / (1 SECONDS)] секунды дольше"),
		/obj/effect/proc_holder/spell/pointed/heretic_dusk/descent = list("[HERETIC_DUSK_DESCENT_DAMAGE] ушибов", "[HERETIC_DUSK_DESCENT_RANGE] клеток", "за [HERETIC_DUSK_DESCENT_RECHARGE / (1 SECONDS)] секунд", "на [HERETIC_DUSK_SERAPH_BURN_TIME / (1 SECONDS)] секунд"),
		/obj/effect/proc_holder/spell/pointed/heretic_dusk/glare = list("в [HERETIC_DUSK_SERAPH_GLARE_RANGE] клетках на [HERETIC_DUSK_SERAPH_GLARE_BLIND / (1 SECONDS)] секунд"),
		/obj/effect/proc_holder/spell/pointed/heretic_dusk/step = list("[HERETIC_DUSK_STEP_CHARGES] заряда по [HERETIC_DUSK_STEP_RECHARGE / (1 SECONDS)] секунд", "у Завета Крыла - [HERETIC_DUSK_FALLEN_STEP_CHARGES]", "Шаг на [HERETIC_DUSK_FALLEN_LIGHT_JAM / (1 SECONDS)] секунды", "[HERETIC_DUSK_STEP_RANGE] клеток", "[HERETIC_DUSK_STEP_SHADOW_RANGE] клеток"),
		/obj/effect/proc_holder/spell/self/heretic_dusk/form = list("слабее на [HERETIC_DUSK_WING_FRONT_CUT]%", "зрение на [HERETIC_DUSK_SIGHT_SNUFF / (1 SECONDS)] секунд", "[HERETIC_DUSK_STRIKE_DAMAGE] ушибов", "на [HERETIC_DUSK_HOLY_FORM_LOCK / (1 SECONDS)] секунд"),
		/obj/effect/proc_holder/spell/self/heretic_dusk/covenant = list("в [HERETIC_DUSK_SERAPH_GLARE_RANGE] клетках на [HERETIC_DUSK_SERAPH_GLARE_BLIND / (1 SECONDS)] секунд", "[HERETIC_DUSK_FALLEN_STEP_CHARGES] заряда Шага", "на [HERETIC_DUSK_FALLEN_GRIP_BONUS / (1 SECONDS)] секунды", "на [HERETIC_DUSK_ROT_TIME / (1 SECONDS)] секунд", "до [HERETIC_DUSK_ROT_CARRIERS] носителей"),
	)
	for(var/spell_type in more)
		var/obj/effect/proc_holder/spell/spell = spell_type
		for(var/fragment in more[spell_type])
			TEST_ASSERT(findtext(initial(spell.desc), fragment), "[spell_type]: в описании есть «[fragment]».")
	var/list/knowledge_texts = list(
		/datum/eldritch_knowledge/base_dusk = list("[HERETIC_DUSK_STRIKE_DAMAGE] ушибов", "во тьме на [HERETIC_DUSK_SIGHT_SNUFF / (1 SECONDS)] секунд", "слабее на [HERETIC_DUSK_WING_FRONT_CUT]%", "[HERETIC_DUSK_BEAM_DAMAGE] ожогов", "до [HERETIC_DUSK_LAMP_LIMIT] ламп", "Начальный запас [HERETIC_DUSK_START] из [HERETIC_DUSK_CAPACITY]", "раз в [HERETIC_DUSK_GATHER_TIME / (1 SECONDS)] секунды", "раз в [HERETIC_DUSK_ROT_FEED_TIME / (1 SECONDS)] секунд"),
		/datum/eldritch_knowledge/spell/dusk_step = list("[HERETIC_DUSK_STEP_CHARGES] заряда", "за [HERETIC_DUSK_STEP_RECHARGE / (1 SECONDS)] секунд"),
		/datum/eldritch_knowledge/spell/dusk_grip = list("на [HERETIC_DUSK_GRIP_TIME / (1 SECONDS)] секунд"),
		/datum/eldritch_knowledge/spell/dusk_covenant = list("[HERETIC_DUSK_DESCENT_DAMAGE] ушибов", "за [HERETIC_DUSK_DESCENT_RECHARGE / (1 SECONDS)] секунд", "в [HERETIC_DUSK_SERAPH_GLARE_RANGE] клетках на [HERETIC_DUSK_SERAPH_GLARE_BLIND / (1 SECONDS)] секунд", "[HERETIC_DUSK_FALLEN_STEP_CHARGES] заряда Шага", "на [HERETIC_DUSK_FALLEN_GRIP_BONUS / (1 SECONDS)] секунды"),
	)
	for(var/knowledge_type in knowledge_texts)
		var/datum/eldritch_knowledge/knowledge = new knowledge_type
		var/text = "[knowledge.summary] [jointext(knowledge.details, " ")] [jointext(knowledge.resource_rules || list(), " ")]"
		for(var/fragment in knowledge_texts[knowledge_type])
			TEST_ASSERT(findtext(text, fragment), "[knowledge_type]: в кодексе есть «[fragment]».")
		qdel(knowledge)

/// Урок Сумрака проходит десять шагов по ступеням пути настоящими действиями: Шаг и Удар из тени, затем Хватка и добивание, учебный Завет - восьмым.
/datum/unit_test/heretic_dusk_lesson/Run()
	var/datum/antagonist/heretic/heretic = path_lesson_heretic(PATH_DUSK, /datum/eldritch_knowledge/base_dusk)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	dusk_light_all(1)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/datum/heretic_path_lesson/dusk/lesson = new(null, dusk, user, target)
	allocated += lesson
	TEST_ASSERT(heretic.get_knowledge(/datum/eldritch_knowledge/spell/dusk_step) && heretic.get_knowledge(/datum/eldritch_knowledge/spell/dusk_grip) && heretic.get_knowledge(/datum/eldritch_knowledge/spell/dusk_covenant) && heretic.get_knowledge(/datum/eldritch_knowledge/spell/dusk_glare), "Урок открывает Шаг, Хватку, Завет и Лик ангела.")
	var/obj/item/melee/sickly_blade/dusk/blade = locate() in user.held_items
	TEST_ASSERT_NOTNULL(blade, "Урок даёт Перо падшего в руку.")
	TEST_ASSERT(dusk.toggle_form(user), "Облик сменён.")
	TEST_ASSERT_EQUAL(lesson.stage, 2, "Смена облика открывает лампу.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(lesson.lamp_ref, TYPE_PROC_REF(/datum/weakref, resolve)), 2 SECONDS, "лампа урока"), "Урок ставит лампу.")
	var/obj/machinery/light/lamp = lesson.lamp_ref.resolve()
	TEST_ASSERT(dusk.hex_lamp(user, lamp), "Лампа заговорена: [dusk.grasp_failure_reason]")
	TEST_ASSERT_EQUAL(lesson.stage, 3, "Заговор открывает луч.")
	dusk.set_form(HERETIC_DUSK_FORM_FACE)
	user.setDir(get_dir(user, target))
	TEST_ASSERT(dusk.lamp_beam(user, target), "Луч лампы: [dusk.dusk_failure]")
	TEST_ASSERT_EQUAL(lesson.stage, 4, "Луч открывает Шаг в тень.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(target, TYPE_PROC_REF(/mob/living, has_status_effect), /datum/status_effect/heretic_dusk_burnt), 2 SECONDS, "выжженная тень"), "Урок выжигает тень мишени.")
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	TEST_ASSERT(dusk.shadow_step(user, target), "Шаг в тень: [dusk.dusk_failure]")
	TEST_ASSERT_EQUAL(lesson.stage, 5, "Шаг открывает Удар из тени.")
	user.a_intent = INTENT_HARM
	blade.attack(target, user)
	TEST_ASSERT_EQUAL(lesson.stage, 6, "Удар из тени открывает Хватку тени.")
	TEST_ASSERT(dusk.grip(user, target), "Хватка тени: [dusk.dusk_failure]")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dusk_test_stage_past), lesson, 6), 3 SECONDS, "Хватка урока"), "Хватка прибивает мишень и открывает добивание.")
	TEST_ASSERT(dusk.drag_finish(user, target), "Добивание из тени: [dusk.drag_block_reason(user, target)]")
	TEST_ASSERT_EQUAL(lesson.stage, 8, "Добивание открывает Завет.")
	TEST_ASSERT(dusk.choose_covenant(user, HERETIC_DUSK_COVENANT_FALLEN), "Учебный Завет: [dusk.dusk_failure]")
	TEST_ASSERT_EQUAL(lesson.stage, 9, "Завет открывает Лик ангела.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(target, TYPE_PROC_REF(/mob/living/carbon/human, get_item_by_slot), ITEM_SLOT_EYES), 2 SECONDS, "очки мишени"), "Мишени надели очки.")
	dusk.set_form(HERETIC_DUSK_FORM_FACE, TRUE)
	user.setDir(get_dir(user, target))
	TEST_ASSERT(dusk.glare(user, target), "Лик ангела: [dusk.dusk_failure]")
	TEST_ASSERT(!target.eye_blind, "Мишень в очках не ослепла.")
	TEST_ASSERT_EQUAL(lesson.stage, 10, "Лик открывает святую воду.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(lesson, TYPE_PROC_REF(/datum/heretic_path_lesson, finished)), 5 SECONDS, "святая вода"), "Учебный капеллан плеснул святой водой.")
	TEST_ASSERT(user.getFireLoss() >= HERETIC_DUSK_HOLY_SPLASH_BURN, "Святая вода обожгла ученика.")
	TEST_ASSERT_EQUAL(length(lesson.steps()), 10, "В уроке десять шагов.")
	qdel(lesson)
	TEST_ASSERT(QDELETED(lamp) && QDELETED(blade), "Реквизит урока убирается вместе с ним.")

/// Урок не ждёт Завета, если он уже принесён.
/datum/unit_test/heretic_dusk_lesson_covenant_chosen/Run()
	var/datum/antagonist/heretic/heretic = path_lesson_heretic(PATH_DUSK, /datum/eldritch_knowledge/base_dusk)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dusk_covenant)
	TEST_ASSERT(dusk.choose_covenant(user, HERETIC_DUSK_COVENANT_ROT), "Завет принесён до урока: [dusk.dusk_failure]")
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/datum/heretic_path_lesson/dusk/lesson = new(null, dusk, user, target)
	allocated += lesson
	lesson.set_stage(8)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dusk_test_stage_past), lesson, 8), 2 SECONDS, "шаг Завета"), "Принесённый Завет засчитывает шаг сам.")

/proc/heretic_dusk_test_stage_past(datum/heretic_path_lesson/lesson, stage)
	return lesson.stage > stage

/// Еретик Сумрака с изученными второй-четвёртой ступенями и принесённым Заветом.
/datum/unit_test/proc/dusk_covenanted(covenant_id, dx = 0, dy = 2)
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(dx, dy)
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_step)
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_grip)
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_covenant)
	if(!dusk.choose_covenant(dusk.dusk_body, covenant_id))
		TEST_FAIL("Завет [covenant_id] не принесён: [dusk.dusk_failure]")
	return dusk

/datum/unit_test/proc/dusk_rotten(mob/living/victim)
	return victim.has_status_effect(/datum/status_effect/heretic_dusk_rot)

/datum/unit_test/proc/dusk_reagent_splash(atom/target, reagent_type)
	var/datum/reagents/splash = new(10)
	splash.add_reagent(reagent_type, 10)
	splash.reaction(target, TOUCH)
	qdel(splash)

/// Порядок под бой со старта: Шаг второй ступенью, Хватка третьей, Завет с Нисхождением четвёртой, всего 10 ступеней.
/datum/unit_test/heretic_dusk_order/Run()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_DUSK]
	var/list/expected = list(
		/datum/eldritch_knowledge/base_dusk,
		/datum/eldritch_knowledge/spell/dusk_step,
		/datum/eldritch_knowledge/spell/dusk_grip,
		/datum/eldritch_knowledge/spell/dusk_covenant,
		/datum/eldritch_knowledge/dusk_grasp,
		/datum/eldritch_knowledge/dusk_mark,
		/datum/eldritch_knowledge/spell/dusk_glare,
		/datum/eldritch_knowledge/dusk_relic,
		/datum/eldritch_knowledge/spell/dusk_eclipse,
		/datum/eldritch_knowledge/final_eldritch/dusk_final,
	)
	TEST_ASSERT_EQUAL(length(path.knowledge), length(expected), "У Сумрака 10 ступеней.")
	for(var/index in 1 to length(expected))
		TEST_ASSERT_EQUAL(path.knowledge[index], expected[index], "Ступень [index] Сумрака.")
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	var/datum/antagonist/heretic/heretic = dusk.owner_heretic()
	var/mob/living/carbon/human/user = dusk.dusk_body
	heretic.knowledge_points = 10
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/spell/dusk_step, user), "Шаг в тень изучается второй ступенью.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/proc_holder/spell/pointed/heretic_dusk/step) in user.mind.spell_list, "Шаг в тень на кнопке со второй ступени.")
	TEST_ASSERT_EQUAL(dusk.charges["step"], HERETIC_DUSK_STEP_CHARGES, "Шаг приходит с полными зарядами.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/spell/dusk_grip, user), "Хватка тени - третья ступень.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/spell/dusk_covenant, user), "Завет падшего - четвёртая ступень.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/proc_holder/spell/pointed/heretic_dusk/descent) in user.mind.spell_list, "Завет падшего даёт Нисхождение.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/proc_holder/spell/self/heretic_dusk/covenant) in user.mind.spell_list, "Завет падшего даёт кнопку выбора.")
	TEST_ASSERT_EQUAL(dusk.charges["descent"], 1, "Нисхождение приходит с зарядом.")
	TEST_ASSERT_EQUAL(heretic.path_stage, 4, "Путь на четвёртой ступени.")

/// Удар из тени встроен в Перо: первый удар после смены облика бьёт сильнее и замедляет; облик, сбитый святой водой, удара не даёт.
/datum/unit_test/heretic_dusk_strike_after_form/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	// Удар смены облика по соседям здесь не меряется.
	COOLDOWN_START(dusk, form_strike, 10 MINUTES)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, get_turf(user))
	user.put_in_active_hand(blade)
	user.a_intent = INTENT_HARM
	blade.attack(victim, user)
	var/plain = victim.getBruteLoss()
	TEST_ASSERT(plain > 0, "Перо ранит.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_slowed), "Без смены облика удар обычный.")
	victim.adjustBruteLoss(-200)
	TEST_ASSERT(dusk.toggle_form(user), "Облик сменён: [dusk.dusk_failure]")
	blade.attack(victim, user)
	TEST_ASSERT(abs(victim.getBruteLoss() - plain - HERETIC_DUSK_STRIKE_DAMAGE) < 1, "Удар после смены облика сильнее на [HERETIC_DUSK_STRIKE_DAMAGE]: [victim.getBruteLoss()] против [plain].")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_slowed), "Удар после смены облика замедляет.")
	TEST_ASSERT(!dusk.strike_until, "Окно удара разовое.")
	dusk_splash(user)
	TEST_ASSERT(!dusk.strike_until, "Облик, сбитый святой водой, Удара из тени не даёт.")

/// Завет: кнопка с четвёртой ступени, выбор раз и до конца раунда, мутация с листа Завета, сброс пути возвращает выбор.
/datum/unit_test/heretic_dusk_covenant_choice/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	var/datum/antagonist/heretic/heretic = dusk.owner_heretic()
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/mob/living/carbon/human/witness = heretic_lead_test_crew(heretic_lead_test_spot(3, 3))
	dusk_light(user, 1)
	TEST_ASSERT(findtext(dusk.covenant_block_reason(user), "четвёртой"), "До четвёртой ступени Завета нет.")
	TEST_ASSERT(!dusk.choose_covenant(user, HERETIC_DUSK_COVENANT_SERAPH), "Без ступени Завет не принести.")
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_covenant)
	heretic.path_stage = 4
	dusk_tick(dusk)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/proc_holder/spell/self/heretic_dusk/covenant) in user.mind.spell_list, "Ступень даёт кнопку «Завет».")
	var/mutable_appearance/stumps = heretic_dusk_test_overlay(dusk, "dusk_mut_wing_stumps")
	TEST_ASSERT(stumps?.icon == HERETIC_DUSK_MUTATION_ICON, "До выбора мутация с общего листа.")
	TEST_ASSERT(!dusk.choose_covenant(user, "none"), "Неизвестный Завет не принять.")
	TEST_ASSERT(dusk.choose_covenant(user, HERETIC_DUSK_COVENANT_SERAPH), "Завет Нимба: [dusk.dusk_failure]")
	TEST_ASSERT_EQUAL(dusk.covenant, HERETIC_DUSK_COVENANT_SERAPH, "Завет принесён.")
	TEST_ASSERT_NULL(locate(/obj/effect/proc_holder/spell/self/heretic_dusk/covenant) in user.mind.spell_list, "Кнопка выбора уходит после выбора.")
	TEST_ASSERT(length(dusk.mutation_overlays), "Мутация на теле.")
	for(var/mutable_appearance/look as anything in dusk.mutation_overlays)
		TEST_ASSERT(look.icon == 'modular_bluemoon/icons/mob/heretic_dusk_mutation_seraph.dmi', "[look.icon_state] лежит с листа Нимба.")
	TEST_ASSERT(findtext(jointext(user.examine(witness), " "), "кровоточит светом"), "Осмотр описывает облик Нимба.")
	TEST_ASSERT(findtext(dusk.combat_resource_state(), "Завет Нимба"), "Состояние Сумрака называет Завет.")
	TEST_ASSERT(!dusk.choose_covenant(user, HERETIC_DUSK_COVENANT_ROT) && findtext(dusk.dusk_failure, "до конца раунда"), "Завет держится до конца раунда.")
	TEST_ASSERT_EQUAL(dusk.covenant, HERETIC_DUSK_COVENANT_SERAPH, "Второй выбор Завет не меняет.")
	heretic.release_path(user)
	TEST_ASSERT(QDELETED(dusk), "Сброс пути снимает знание с Заветом.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_dusk, user), "Путь выбирается заново.")
	var/datum/eldritch_knowledge/base_dusk/fresh = heretic.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	TEST_ASSERT(fresh && isnull(fresh.covenant), "После сброса Завета нет.")
	for(var/mutable_appearance/look as anything in fresh.mutation_overlays)
		TEST_ASSERT(look.icon == HERETIC_DUSK_MUTATION_ICON, "[look.icon_state] вернулся на общий лист.")

/// Каждый Завет берёт мутацию со своего листа, и в листе есть все стейты общего.
/datum/unit_test/heretic_dusk_covenant_sheets/Run()
	var/list/base_states = icon_states(HERETIC_DUSK_MUTATION_ICON)
	for(var/covenant_id in GLOB.heretic_dusk_covenants)
		var/datum/heretic_dusk_covenant/covenant = GLOB.heretic_dusk_covenants[covenant_id]
		TEST_ASSERT(covenant.mutation_icon && covenant.mutation_icon != HERETIC_DUSK_MUTATION_ICON, "У [covenant.name] свой лист мутации.")
		var/list/states = icon_states(covenant.mutation_icon)
		for(var/state in base_states)
			TEST_ASSERT(state in states, "[covenant.name]: стейт [state] есть в листе Завета.")
		TEST_ASSERT(covenant.choice_state in icon_states('modular_bluemoon/icons/obj/heretic_actions.dmi'), "[covenant.name]: кнопка выбора нарисована.")
		TEST_ASSERT(covenant.flash_state in icon_states(HERETIC_DUSK_FX_ICON), "[covenant.name]: вспышка выбора нарисована.")

/// Завет Нимба: Лик дальше и дольше, луч идёт цепью ламп и слабее по тёмным очкам, Нисхождение жжёт пол светом, в Лике на свету раны затягиваются, светящий фонарём в лицо слепнет.
/datum/unit_test/heretic_dusk_seraph/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_covenanted(HERETIC_DUSK_COVENANT_SERAPH, 0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_glare)
	dusk.combat_resource = dusk.combat_resource_max
	dusk_light_all(1)
	user.setDir(EAST)
	var/mob/living/carbon/human/far = dusk_crew_facing(heretic_lead_test_spot(4, 2), WEST)
	TEST_ASSERT(dusk.glare(user, heretic_lead_test_spot(3, 2)), "Лик Нимба: [dusk.dusk_failure]")
	TEST_ASSERT(far.eye_blind > 0, "Лик Нимба слепит в [HERETIC_DUSK_SERAPH_GLARE_RANGE] клетках.")
	var/datum/status_effect/heretic_dusk_afterglow/glow = far.has_status_effect(/datum/status_effect/heretic_dusk_afterglow)
	TEST_ASSERT(glow && abs(glow.duration - world.time - HERETIC_DUSK_SERAPH_GLARE_BLIND) < 1 SECONDS, "Лик Нимба слепит на [HERETIC_DUSK_SERAPH_GLARE_BLIND / (1 SECONDS)] секунд.")
	for(var/turf/spot in list(heretic_lead_test_spot(4, 3), heretic_lead_test_spot(1, 4)))
		var/obj/machinery/light/small/lamp = allocate(/obj/machinery/light/small, spot)
		lamp.on = TRUE
		TEST_ASSERT(dusk.hex_lamp(user, lamp), "Лампа заговорена: [dusk.grasp_failure_reason]")
	far.adjustFireLoss(-200)
	dusk.combat_resource = dusk.combat_resource_max
	TEST_ASSERT(dusk.lamp_beam(user, far), "Луч Нимба: [dusk.dusk_failure]")
	TEST_ASSERT(abs(far.getFireLoss() - HERETIC_DUSK_BEAM_DAMAGE - HERETIC_DUSK_SERAPH_CHAIN_DAMAGE) < 0.5, "Вторая лампа в цепи добавляет [HERETIC_DUSK_SERAPH_CHAIN_DAMAGE] ожога: [far.getFireLoss()].")
	far.adjustFireLoss(-200)
	var/obj/item/clothing/glasses/sunglasses/shades = allocate(/obj/item/clothing/glasses/sunglasses)
	far.equip_to_slot_or_del(shades, ITEM_SLOT_EYES)
	TEST_ASSERT(dusk.lamp_beam(user, far), "Луч Нимба по очкам: [dusk.dusk_failure]")
	TEST_ASSERT(abs(far.getFireLoss() - (HERETIC_DUSK_BEAM_DAMAGE + HERETIC_DUSK_SERAPH_CHAIN_DAMAGE) / 2) < 0.5, "Тёмные очки вдвое ослабляют луч Нимба: [far.getFireLoss()].")
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	var/turf/landing = dusk.descent_landing(user, victim)
	var/mob/living/carbon/human/shaded = heretic_lead_test_crew(get_step(landing, WEST))
	var/obj/item/clothing/glasses/sunglasses/welder = allocate(/obj/item/clothing/glasses/sunglasses)
	shaded.equip_to_slot_or_del(welder, ITEM_SLOT_EYES)
	TEST_ASSERT(dusk.descent(user, victim), "Нисхождение Нимба: [dusk.dusk_failure]")
	var/obj/effect/heretic_dusk_light_burn/zone = locate() in get_turf(user)
	TEST_ASSERT_NOTNULL(zone, "Нисхождение Нимба оставляет ожог света.")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_light_burned), "Цель на ожоге подсвечена.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_light_burned), "Цель на ожоге вязнет.")
	TEST_ASSERT_NOTNULL(shaded.has_status_effect(/datum/status_effect/heretic_dusk_light_burned), "Человек в очках на ожоге тоже подсвечен.")
	TEST_ASSERT(!shaded.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_light_burned), "Тёмные очки спасают от замедления ожога.")
	TEST_ASSERT_NULL(user.has_status_effect(/datum/status_effect/heretic_dusk_light_burned), "Свой ожог еретика не держит.")
	user.adjustBruteLoss(20)
	var/mob/living/carbon/human/bearer = heretic_lead_test_crew(heretic_lead_test_spot(0, 4))
	dusk_lit_torch(bearer)
	bearer.setDir(get_dir(bearer, user))
	dusk_tick(dusk)
	TEST_ASSERT(user.getBruteLoss() <= 20 - HERETIC_DUSK_SERAPH_HEAL + 0.5, "Нимб в Лике на свету лечится: [user.getBruteLoss()].")
	TEST_ASSERT_NOTNULL(bearer.has_status_effect(/datum/status_effect/heretic_dusk_dazzled), "Светящий фонарём на Нимба ослеплён его ликом.")

/// Завет Крыла: три заряда Шага, в тени Крыло расплывается, Удар из тени сильнее и режет до крови, Хватка дольше, тень-слуга бежит за хозяином, фонарь в лицо сбивает Шаг.
/datum/unit_test/heretic_dusk_fallen/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_covenanted(HERETIC_DUSK_COVENANT_FALLEN, 0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	// Удар смены облика по соседям здесь не меряется.
	COOLDOWN_START(dusk, form_strike, 10 MINUTES)
	dusk_learn(dusk, /datum/eldritch_knowledge/dusk_grasp)
	TEST_ASSERT_EQUAL(dusk.charge_cap("step"), HERETIC_DUSK_FALLEN_STEP_CHARGES, "У Крыла три заряда Шага.")
	TEST_ASSERT_EQUAL(dusk.charges["step"], HERETIC_DUSK_FALLEN_STEP_CHARGES, "Заряды Шага полны после Завета.")
	dusk_light_all(0)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, get_turf(user))
	user.put_in_active_hand(blade)
	user.a_intent = INTENT_HARM
	user.zone_selected = BODY_ZONE_CHEST
	blade.attack(victim, user)
	var/plain = victim.getBruteLoss()
	victim.adjustBruteLoss(-200)
	var/obj/item/bodypart/chest = victim.get_bodypart(BODY_ZONE_CHEST)
	var/stacks = chest.generic_bleedstacks
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	dusk_tick(dusk)
	TEST_ASSERT(dusk.shade_blur && user.get_filter("heretic_dusk_shade"), "Крыло в тени расплывается.")
	blade.attack(victim, user)
	TEST_ASSERT(abs(victim.getBruteLoss() - plain - HERETIC_DUSK_STRIKE_DAMAGE - HERETIC_DUSK_FALLEN_STRIKE_BONUS) < 1, "Удар из тени Крыла сильнее на [HERETIC_DUSK_FALLEN_STRIKE_BONUS]: [victim.getBruteLoss()] против [plain].")
	TEST_ASSERT(chest.generic_bleedstacks >= stacks + HERETIC_DUSK_FALLEN_BLEED, "Удар из тени Крыла режет до крови.")
	var/mob/living/carbon/human/pinned = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	var/datum/status_effect/heretic_dusk_grip/grip = pinned.apply_status_effect(/datum/status_effect/heretic_dusk_grip, dusk)
	TEST_ASSERT(abs(grip.duration - world.time - HERETIC_DUSK_GRIP_TIME - HERETIC_DUSK_FALLEN_GRIP_BONUS) < 1, "Хватка Крыла держит на [HERETIC_DUSK_FALLEN_GRIP_BONUS / (1 SECONDS)] секунды дольше.")
	qdel(grip)
	var/mob/living/carbon/human/shadowed = heretic_lead_test_crew(heretic_lead_test_spot(0, 3))
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(shadowed, user, TRUE)
	var/obj/structure/heretic_dusk_shade/shade = dusk.servant
	TEST_ASSERT_NOTNULL(shade, "Отнятая тень встаёт слугой.")
	TEST_ASSERT_EQUAL(get_turf(shade), get_turf(shadowed), "Слуга встаёт из тени цели.")
	var/turf/left = get_turf(user)
	user.forceMove(get_step(user, SOUTH))
	TEST_ASSERT_EQUAL(get_turf(shade), left, "Слуга бежит за хозяином по пятам.")
	var/mob/living/carbon/human/chaser = heretic_lead_test_crew(heretic_lead_test_spot(1, 1))
	chaser.forceMove(left)
	TEST_ASSERT_NOTNULL(chaser.has_status_effect(/datum/status_effect/heretic_dusk_slowed), "Наступивший на слугу спотыкается.")
	var/obj/item/flashlight/torch = dusk_lit_torch(chaser)
	shade.attackby(torch, chaser)
	TEST_ASSERT(QDELETED(shade) && isnull(dusk.servant), "Фонарик рвёт слугу.")
	var/mob/living/carbon/human/spotter = heretic_lead_test_crew(get_step(user, EAST))
	user.setDir(EAST)
	var/obj/item/flashlight/lamp = dusk_lit_torch(spotter)
	spotter.a_intent = INTENT_HELP
	lamp.melee_attack_chain(spotter, user)
	TEST_ASSERT(findtext(dusk.step_block_reason(user, victim), "Фонарь"), "Фонарь в лицо Крылу сбивает Шаг.")

/// Завет Скверны: Хватка заражает, скверна липнет к касавшимся не больше трёх носителей и кормит Сумраком; огонь, очиститель и святая вода её снимают; лампы гниют до замены трубки; святая вода жжёт как всех.
/datum/unit_test/heretic_dusk_rot/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_covenanted(HERETIC_DUSK_COVENANT_ROT, 0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_light_all(0)
	var/mob/living/carbon/human/first = heretic_lead_test_crew(get_step(user, EAST))
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	user.a_intent = INTENT_HARM
	fist.afterattack(first, user, TRUE)
	TEST_ASSERT_NOTNULL(dusk_rotten(first), "Хватка Скверны заражает цель.")
	TEST_ASSERT_NOTNULL(user.alerts[HERETIC_DUSK_ROT_ALERT], "Еретик видит счётчик носителей.")
	var/mob/living/carbon/human/second = heretic_lead_test_crew(heretic_lead_test_spot(2, 3))
	second.a_intent = INTENT_HELP
	second.UnarmedAttack(first, TRUE)
	TEST_ASSERT_NOTNULL(dusk_rotten(second), "Скверна липнет к тому, кто тронул носителя.")
	var/mob/living/carbon/human/third = heretic_lead_test_crew(heretic_lead_test_spot(3, 3))
	second.UnarmedAttack(third, TRUE)
	TEST_ASSERT_NOTNULL(dusk_rotten(third), "Носитель заражает того, кого трогает.")
	var/mob/living/carbon/human/fourth = heretic_lead_test_crew(heretic_lead_test_spot(3, 4))
	fourth.a_intent = INTENT_HELP
	fourth.UnarmedAttack(third, TRUE)
	TEST_ASSERT_NULL(dusk_rotten(fourth), "Носителей не больше трёх.")
	TEST_ASSERT_EQUAL(length(dusk.rot), HERETIC_DUSK_ROT_CARRIERS, "Хозяин знает всех носителей.")
	dusk.combat_resource = 0
	COOLDOWN_RESET(dusk, rot_feed)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.combat_resource, HERETIC_DUSK_ROT_CARRIERS, "Каждый носитель кормит хозяина единицей Сумрака.")
	dusk_reagent_splash(first, /datum/reagent/space_cleaner)
	TEST_ASSERT_NULL(dusk_rotten(first), "Очиститель снимает скверну.")
	dusk_splash(second)
	TEST_ASSERT_NULL(dusk_rotten(second), "Святая вода снимает скверну.")
	third.adjust_fire_stacks(1)
	third.IgniteMob()
	TEST_ASSERT_NULL(dusk_rotten(third), "Огонь выжигает скверну.")
	third.ExtinguishMob()
	TEST_ASSERT_NULL(user.alerts[HERETIC_DUSK_ROT_ALERT], "Без носителей счётчик уходит.")
	var/obj/machinery/light/small/lamp = allocate(/obj/machinery/light/small, heretic_lead_test_spot(4, 0))
	lamp.on = TRUE
	var/clean_power = lamp.bulb_power
	TEST_ASSERT(dusk.hex_lamp(user, lamp), "Лампа заговорена: [dusk.grasp_failure_reason]")
	var/datum/component/heretic_dusk_lamp/hex = lamp.GetComponent(/datum/component/heretic_dusk_lamp)
	TEST_ASSERT(hex.rot_stage > 0 && lamp.bulb_power < clean_power, "Лампа Скверны гниёт и тускнеет.")
	allocated += lamp.drop_light_tube()
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dusk_test_unhexed), lamp), 2 SECONDS, "замена трубки"), "Снятая трубка уносит гниль и заговор.")
	TEST_ASSERT_EQUAL(lamp.bulb_power, clean_power, "Свет лампы возвращается после замены трубки.")
	user.adjustFireLoss(-200)
	dusk_splash(user)
	TEST_ASSERT(abs(user.getFireLoss() - HERETIC_DUSK_HOLY_SPLASH_BURN) < 0.5, "Святая вода жжёт Скверну наравне с другими Заветами: [user.getFireLoss()].")

/proc/heretic_dusk_test_unhexed(obj/machinery/light/lamp)
	return !lamp.GetComponent(/datum/component/heretic_dusk_lamp)

/// У Чёрных солнц Скверны растёт налёт: наступивший заражается, святая вода смывает, разбитое солнце забирает налёт с собой.
/datum/unit_test/heretic_dusk_ascended_base/heretic_dusk_rot_suns/Run()
	var/list/fixture = dusk_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_dusk/dusk = fixture["dusk"]
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = fixture["finale"]
	sky_source = finale
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_covenant)
	TEST_ASSERT(dusk.choose_covenant(user, HERETIC_DUSK_COVENANT_ROT), "Завет Скверны: [dusk.dusk_failure]")
	finale.simulated = TRUE
	for(var/turf/spot as anything in block(run_loc_floor_bottom_left, run_loc_floor_top_right))
		heretic_test_area(spot, /area/antag_training)
	TEST_ASSERT(finale.raise_suns(user), "Чёрные солнца встают.")
	var/list/obj/effect/decal/cleanable/heretic_dusk_rot/blooms = list()
	for(var/obj/structure/heretic_dusk_black_sun/sun as anything in finale.suns)
		for(var/datum/weakref/bloom_ref as anything in sun.rot_decals)
			blooms += bloom_ref.resolve()
	TEST_ASSERT(length(blooms), "Вокруг солнц Скверны растёт налёт.")
	var/obj/effect/decal/cleanable/heretic_dusk_rot/bloom = blooms[1]
	var/turf/bloom_turf = get_turf(bloom)
	var/turf/start
	for(var/turf/spot as anything in block(run_loc_floor_bottom_left, run_loc_floor_top_right))
		if(spot != bloom_turf && !spot.is_blocked_turf(exclude_mobs = TRUE))
			start = spot
			break
	var/mob/living/carbon/human/walker = heretic_lead_test_crew(start)
	walker.forceMove(bloom_turf)
	TEST_ASSERT_NOTNULL(dusk_rotten(walker), "Наступивший на налёт заражается.")
	dusk_splash(bloom_turf)
	TEST_ASSERT(QDELETED(bloom), "Святая вода смывает налёт.")
	var/list/obj/structure/heretic_dusk_black_sun/suns = finale.suns.Copy()
	for(var/obj/structure/heretic_dusk_black_sun/sun as anything in suns)
		sun.take_damage(sun.obj_integrity, BRUTE, MELEE, FALSE)
	for(var/obj/effect/decal/cleanable/heretic_dusk_rot/left as anything in blooms)
		TEST_ASSERT(QDELETED(left), "Разбитое солнце забирает налёт с собой.")

/// Постройки и эффекты Заветов создаются и удаляются без ошибок.
/datum/unit_test/heretic_dusk_covenant_types/Run()
	for(var/effect_type in list(/obj/effect/temp_visual/heretic_dusk/covenant_flash, /obj/effect/temp_visual/heretic_dusk/servant_burst, /obj/effect/heretic_dusk_light_burn, /obj/effect/decal/cleanable/heretic_dusk_rot))
		var/atom/effect = allocate(effect_type, run_loc_floor_bottom_left)
		TEST_ASSERT(!QDELETED(effect), "[effect_type] создаётся.")
		qdel(effect)
		TEST_ASSERT(QDELETED(effect), "[effect_type] удаляется.")
	var/obj/structure/heretic_dusk_shade/orphan = new(run_loc_floor_bottom_left)
	TEST_ASSERT(QDELETED(orphan), "Слуга без хозяина не встаёт.")
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_covenanted(HERETIC_DUSK_COVENANT_FALLEN, 0, 2)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	var/obj/structure/heretic_dusk_shade/shade = dusk.raise_servant(victim)
	TEST_ASSERT_NOTNULL(shade, "Слуга встаёт.")
	var/obj/structure/heretic_dusk_shade/next = dusk.raise_servant(victim)
	TEST_ASSERT(QDELETED(shade) && dusk.servant == next, "Слуга один: новый сменяет прежнего.")
	dusk.on_death(dusk.dusk_body)
	TEST_ASSERT(QDELETED(next) && isnull(dusk.servant), "Смерть хозяина рвёт слугу.")

/// Новые эффекты и постройки пути создаются и удаляются без ошибок.
/// Смена облика во «Вреде» при враге рядом бьёт сама: из Лика в Крыло - веер перьев, из Крыла в Лик - вспышка нимба после знака; без врага и от святой воды - нет.
/datum/unit_test/heretic_dusk_form_strike/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(1, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	user.a_intent = INTENT_HARM
	TEST_ASSERT(dusk.toggle_form(user), "Облик меняется: [dusk.dusk_failure]")
	TEST_ASSERT(COOLDOWN_FINISHED(dusk, form_strike), "Без врага рядом смена облика не бьёт.")
	dusk.set_form(HERETIC_DUSK_FORM_FACE)
	TEST_ASSERT_NULL(dusk.halo_timer, "Без врага рядом нимб не вспыхивает.")
	var/mob/living/carbon/human/far = heretic_lead_test_crew(locate(user.x + 3, user.y, user.z))
	TEST_ASSERT(dusk.set_form(HERETIC_DUSK_FORM_WING), "Крыло раскрыто.")
	TEST_ASSERT(!COOLDOWN_FINISHED(dusk, form_strike), "Смена облика при враге в [HERETIC_DUSK_FAN_RANGE] клетках бьёт и уходит на перезарядку.")
	for(var/obj/item/projectile/heretic_dusk_feather/feather in range(HERETIC_DUSK_FAN_RANGE + 2, user))
		heretic_lead_test_fly(feather)
	TEST_ASSERT(far.getBruteLoss() >= HERETIC_DUSK_FAN_DAMAGE - 0.5, "Перо режет врага: [far.getBruteLoss()].")
	TEST_ASSERT_NOTNULL(far.has_status_effect(/datum/status_effect/heretic_dusk_slowed), "Перо замедляет.")
	var/obj/item/bodypart/chest = far.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT(chest.generic_bleedstacks >= HERETIC_DUSK_FAN_BLEED, "Перо пускает кровь: [chest.generic_bleedstacks].")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Свои перья хозяина не ранят.")
	var/list/feathers = dusk.feather_fan(user)
	TEST_ASSERT_EQUAL(length(feathers), HERETIC_DUSK_FAN_FEATHERS, "Крыло мечет [HERETIC_DUSK_FAN_FEATHERS] пера и в одного врага.")
	for(var/obj/item/projectile/feather as anything in feathers)
		qdel(feather)
	var/mob/living/carbon/human/near = heretic_lead_test_crew(get_step(user, EAST))
	var/obj/item/clothing/glasses/sunglasses/shades = allocate(/obj/item/clothing/glasses/sunglasses)
	TEST_ASSERT(far.equip_to_slot_if_possible(shades, ITEM_SLOT_EYES), "Дальнему надеты очки.")
	dusk.set_form(HERETIC_DUSK_FORM_FACE)
	TEST_ASSERT_NULL(dusk.halo_timer, "Перезарядка удара общая со сменой облика.")
	COOLDOWN_RESET(dusk, form_strike)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	for(var/obj/item/projectile/feather in get_turf(user))
		qdel(feather)
	COOLDOWN_RESET(dusk, form_strike)
	dusk.set_form(HERETIC_DUSK_FORM_FACE)
	TEST_ASSERT_NOTNULL(dusk.halo_timer, "Вплотную к врагу Лик заряжает нимб: знак до вспышки.")
	far.forceMove(locate(user.x - 1, user.y, user.z))
	TEST_ASSERT_EQUAL(dusk.halo_flash(WEAKREF(user)), 1, "Вспышка оглушает одного: второй в очках.")
	TEST_ASSERT(near.IsStun(), "Вспышка нимба оглушает вплотную.")
	TEST_ASSERT(near.confused > 0, "Вспышка путает шаги.")
	TEST_ASSERT(!far.IsStun(), "Тёмные очки держат вспышку нимба.")
	near.SetStun(0)
	near.forceMove(locate(user.x + 2, user.y, user.z))
	TEST_ASSERT_EQUAL(dusk.halo_flash(WEAKREF(user)), 0, "Отошедший на 2 клетки уходит от вспышки.")
	TEST_ASSERT(!near.IsStun(), "Вспышка бьёт только в 1 клетке.")
	COOLDOWN_RESET(dusk, form_strike)
	dusk_splash(user)
	TEST_ASSERT(COOLDOWN_FINISHED(dusk, form_strike), "Облик, сбитый святой водой, не бьёт.")

/// Серия Пера: каждый третий удар по одной цели - световой разрез в Лике и теневая нить в Крыле; оглушение и другая цель сбивают серию.
/datum/unit_test/heretic_dusk_combo/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(2, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	var/mob/living/carbon/human/other = heretic_lead_test_crew(get_step(user, NORTH))
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, get_turf(user))
	user.put_in_active_hand(blade)
	user.a_intent = INTENT_HARM
	dusk_light_all(1)
	dusk_tick(dusk)
	blade.attack(victim, user)
	blade.attack(victim, user)
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_lit), "Два удара - ещё не серия.")
	user.Stun(1)
	TEST_ASSERT_EQUAL(dusk.combo_hits, 0, "Оглушение сбивает серию.")
	user.SetStun(0)
	blade.attack(victim, user)
	blade.attack(other, user)
	blade.attack(victim, user)
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_lit), "Удар по другой цели сбивает серию.")
	victim.fully_heal(TRUE)
	blade.attack(victim, user)
	dusk.combo_last -= HERETIC_DUSK_COMBO_WINDOW + 1
	blade.attack(victim, user)
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_lit), "Пауза дольше [HERETIC_DUSK_COMBO_WINDOW / (1 SECONDS)] секунд сбивает серию.")
	victim.fully_heal(TRUE)
	blade.attack(victim, user)
	var/burn_before = victim.getFireLoss()
	blade.attack(victim, user)
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_lit), "Третий удар в Лике подсвечивает цель.")
	TEST_ASSERT(victim.getFireLoss() - burn_before >= HERETIC_DUSK_SLASH_BURN - 0.5, "Световой разрез жжёт: [victim.getFireLoss() - burn_before].")
	TEST_ASSERT(locate(/obj/effect/dummy/lighting_obj/moblight) in victim, "Подсвеченная цель несёт свет.")
	TEST_ASSERT_EQUAL(dusk.combo_hits, 0, "После разреза серия начинается заново.")
	victim.remove_status_effect(/datum/status_effect/heretic_dusk_lit)
	TEST_ASSERT_NULL(locate(/obj/effect/dummy/lighting_obj/moblight) in victim, "Свет разреза гаснет вместе с ним.")
	victim.adjustBruteLoss(-200)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	for(var/obj/item/projectile/feather in get_turf(user))
		qdel(feather)
	dusk_light_all(0)
	for(var/hit in 1 to HERETIC_DUSK_COMBO_HITS)
		blade.attack(victim, user)
	var/datum/status_effect/heretic_dusk_tether/tether = victim.has_status_effect(/datum/status_effect/heretic_dusk_tether)
	TEST_ASSERT_NOTNULL(tether, "Третий удар в Крыле пришивает тень цели.")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_slowed), "Теневой разрез замедляет.")
	victim.forceMove(locate(user.x + 2, user.y, user.z))
	TEST_ASSERT(get_dist(victim, user) <= 1, "Отступившего в тени нить дёргает назад: [get_dist(victim, user)].")
	TEST_ASSERT(QDELETED(tether), "Нить дёргает один раз.")
	victim.apply_status_effect(/datum/status_effect/heretic_dusk_tether, user)
	var/turf/bright = locate(user.x + 2, user.y, user.z)
	dusk_light(bright, 1)
	victim.forceMove(bright)
	TEST_ASSERT_EQUAL(get_dist(victim, user), 2, "На свету нить рвётся и не дёргает.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_tether), "Свет снимает нить.")

/// Брошенное Перо возвращается в руку и режет врагов на пути; святое роняет его на 5 секунд; чужому не возвращается.
/datum/unit_test/heretic_dusk_quill_return/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/mob/living/carbon/human/target = heretic_lead_test_crew(locate(user.x + 4, user.y, user.z))
	var/mob/living/carbon/human/between = heretic_lead_test_crew(locate(user.x + 2, user.y, user.z))
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, get_turf(target))
	var/datum/thrownthing/throw_data = new(blade, target, EAST, 7, 1, user)
	blade.throw_impact(target, throw_data)
	TEST_ASSERT_NOTNULL(blade.return_timer, "Брошенное хозяином Перо собирается назад.")
	TEST_ASSERT(blade.fly_back(WEAKREF(user)), "Перо возвращается.")
	TEST_ASSERT_EQUAL(blade.loc, user, "Перо в руке хозяина.")
	TEST_ASSERT(between.getBruteLoss() >= HERETIC_DUSK_QUILL_PASS_DAMAGE - 0.5, "Перо режет врага на пути: [between.getBruteLoss()].")
	user.dropItemToGround(blade)
	blade.forceMove(get_turf(target))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, get_turf(between))
	between.put_in_active_hand(rod)
	TEST_ASSERT(!blade.fly_back(WEAKREF(user)), "Нулевой жезл на пути сбивает Перо.")
	TEST_ASSERT_EQUAL(blade.loc, get_turf(between), "Перо падает у того, кто держит святое.")
	TEST_ASSERT(blade.holy_dropped_until > world.time, "Святое держит Перо на полу.")
	TEST_ASSERT(!blade.fly_back(WEAKREF(user)), "Пока святое держит, Перо не летит.")
	blade.holy_dropped_until = 0
	between.dropItemToGround(rod)
	qdel(rod)
	var/obj/item/crowbar/left = allocate(/obj/item/crowbar, get_turf(user))
	var/obj/item/crowbar/right = allocate(/obj/item/crowbar, get_turf(user))
	user.put_in_hands(left)
	user.put_in_hands(right)
	TEST_ASSERT(blade.fly_back(WEAKREF(user)), "Перо возвращается и при занятых руках.")
	TEST_ASSERT_EQUAL(blade.loc, get_turf(user), "С занятыми руками Перо падает к ногам.")
	deltimer(blade.return_timer)
	blade.return_timer = null
	blade.forceMove(get_turf(target))
	var/datum/thrownthing/crew_throw = new(blade, target, EAST, 7, 1, between)
	blade.throw_impact(target, crew_throw)
	TEST_ASSERT_NULL(blade.return_timer, "Не-еретику Перо не возвращается.")
	TEST_ASSERT(!blade.fly_back(WEAKREF(between)), "Чужая рука Перо не зовёт.")
	var/obj/item/storage/book/bible/book = allocate(/obj/item/storage/book/bible, get_turf(target))
	target.put_in_active_hand(book)
	blade.throw_impact(target, throw_data)
	TEST_ASSERT(blade.holy_dropped_until > world.time, "Библия в руке у задетого роняет Перо.")
	qdel(throw_data)
	qdel(crew_throw)

/// Лик пьёт лазер спереди раз в 4 секунды и получает Сумрак; сзади, по Крылу, пулей и станнером - урон как обычно.
/datum/unit_test/heretic_dusk_light_drink/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(2, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	user.setDir(EAST)
	var/mob/living/carbon/human/gunner = heretic_lead_test_crew(get_step(user, EAST))
	var/before = dusk.combat_resource
	heretic_lead_test_shot(gunner, user, /obj/item/projectile/beam/laser, 20)
	TEST_ASSERT_EQUAL(user.getFireLoss(), 0, "Лазер в лицо Лику не ранит.")
	TEST_ASSERT_EQUAL(dusk.combat_resource, before + 1, "Выпитый луч даёт Сумрак.")
	heretic_lead_test_shot(gunner, user, /obj/item/projectile/beam/laser, 20)
	TEST_ASSERT(user.getFireLoss() >= 19.5, "Второй луч подряд ранит: [user.getFireLoss()].")
	user.adjustFireLoss(-200)
	COOLDOWN_RESET(dusk, light_drink)
	gunner.forceMove(get_step(user, WEST))
	user.setDir(EAST)
	heretic_lead_test_shot(gunner, user, /obj/item/projectile/beam/laser, 20)
	TEST_ASSERT(user.getFireLoss() >= 19.5, "Лазер в спину ранит Лик: [user.getFireLoss()].")
	user.adjustFireLoss(-200)
	gunner.forceMove(get_step(user, EAST))
	user.setDir(EAST)
	heretic_lead_test_shot(gunner, user, /obj/item/projectile/bullet, 20)
	TEST_ASSERT(user.getBruteLoss() >= 19.5, "Пулю Лик не пьёт: [user.getBruteLoss()].")
	user.adjustBruteLoss(-200)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	user.setDir(EAST)
	heretic_lead_test_shot(gunner, user, /obj/item/projectile/beam/laser, 20)
	TEST_ASSERT(user.getFireLoss() > 0, "Крыло лазер не пьёт.")
	TEST_ASSERT(COOLDOWN_FINISHED(dusk, light_drink), "Крыло не тратит глоток Лика.")

/// Утянуть в тень: только цель под своей Хваткой вплотную и в Крыле; свет в лицо, удар и «растолкать» срывают, итог - тяжёлый урон и лечение.
/datum/unit_test/heretic_dusk_shadow_drag/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(2, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_grip)
	dusk_light_all(0)
	user.setDir(EAST)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	TEST_ASSERT_NOTNULL(dusk.drag_block_reason(user, victim), "Без Хватки тянуть нечего.")
	victim.apply_status_effect(/datum/status_effect/heretic_dusk_grip, dusk)
	TEST_ASSERT_NOTNULL(dusk.drag_block_reason(user, victim), "В Лике тень не тянется.")
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	for(var/obj/item/projectile/feather in get_turf(user))
		qdel(feather)
	TEST_ASSERT_NULL(dusk.drag_block_reason(user, victim), "Крыло тянет прибитую цель.")
	dusk.drag_ref = WEAKREF(victim)
	dusk.drag_hits = 0
	TEST_ASSERT(dusk.drag_holds(user, victim), "Тень держит.")
	var/mob/living/carbon/human/spotter = heretic_lead_test_crew(locate(user.x + 1, user.y + 1, user.z))
	var/obj/item/flashlight/torch = dusk_lit_torch(spotter)
	spotter.a_intent = INTENT_HELP
	torch.melee_attack_chain(spotter, user)
	TEST_ASSERT(!dusk.drag_holds(user, victim), "Свет в лицо срывает добивание.")
	dusk.drag_broken = FALSE
	dusk.on_body_block(user, TRUE, null, HERETIC_DUSK_DRAG_BREAK_DAMAGE, "удар", ATTACK_TYPE_MELEE, 0, spotter, BODY_ZONE_CHEST, list())
	TEST_ASSERT(!dusk.drag_holds(user, victim), "Удар по Крылу срывает добивание.")
	dusk.drag_broken = FALSE
	dusk.drag_hits = 0
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, spotter)
	TEST_ASSERT(!dusk.drag_holds(user, victim), "Растолканная цель уходит из тени.")
	dusk.drag_ref = null
	victim.apply_status_effect(/datum/status_effect/heretic_dusk_grip, dusk)
	user.adjustBruteLoss(30)
	var/hurt = user.getBruteLoss()
	var/brute_before = victim.getBruteLoss()
	TEST_ASSERT(dusk.drag_finish(user, victim), "Добивание завершается.")
	TEST_ASSERT(victim.getBruteLoss() - brute_before >= HERETIC_DUSK_DRAG_DAMAGE - 1, "Тень рвёт цель: [victim.getBruteLoss() - brute_before].")
	TEST_ASSERT(user.getBruteLoss() < hurt, "Крыло лечится отнятой тенью.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_grip), "Добивание отпускает Хватку.")
	victim.adjustBruteLoss(-200)
	victim.apply_status_effect(/datum/status_effect/heretic_dusk_grip, dusk)
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, get_turf(user))
	user.put_in_active_hand(blade)
	user.a_intent = INTENT_GRAB
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(dusk.drag_ref?.resolve(), victim, "Перо в намерении «Схватить» тянет прибитую тень.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Вместо удара - добивание.")
	dusk.drag_broken = TRUE

/// Отблески глаз Крыла по 2 пикселя на глаз, глаза не сливаются, и редко моргают.
/datum/unit_test/heretic_dusk_eye_glints/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(2, 2)
	var/datum/antagonist/heretic/heretic = dusk.owner_heretic()
	heretic.path_stage = 1
	heretic.refresh_evolution()
	dusk_light_all(0)
	dusk_tick(dusk)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	TEST_ASSERT(length(dusk.eye_overlays), "В тени у Крыла горят глаза.")
	var/list/lit_pixels = list()
	for(var/mutable_appearance/look as anything in dusk.eye_overlays)
		TEST_ASSERT_EQUAL(look.icon, 'modular_bluemoon/icons/mob/heretic_dusk_eyes.dmi', "Отблеск рисует лист глаз Сумрака.")
		if(look.plane == EMISSIVE_PLANE)
			continue
		var/icon/sheet = icon(look.icon, look.icon_state, SOUTH, 1)
		var/count = 0
		for(var/x in 1 to sheet.Width())
			for(var/y in 1 to sheet.Height())
				if(sheet.GetPixel(x, y))
					count++
					lit_pixels["[x],[y]"] = look.icon_state
		TEST_ASSERT(count >= 2, "Отблеск [look.icon_state] не меньше 2 пикселей: [count].")
	for(var/key in lit_pixels)
		var/list/xy = splittext(key, ",")
		var/right = "[text2num(xy[1]) + 1],[xy[2]]"
		TEST_ASSERT(!lit_pixels[right] || lit_pixels[right] == lit_pixels[key], "Глаза не сливаются в одно пятно: [key].")
	for(var/eye_state in icon_states('modular_bluemoon/icons/mob/eyes.dmi'))
		if(findtext(eye_state, "_eye"))
			TEST_ASSERT(eye_state in icon_states('modular_bluemoon/icons/mob/heretic_dusk_eyes.dmi'), "Отблеск есть на глаз [eye_state].")

/datum/unit_test/proc/dusk_eye_light(mob/living/body)
	var/obj/effect/dummy/lighting_obj/moblight/heretic_dusk_eyes/glow = locate() in body
	return glow?.light_on ? glow : null

/// Глаза Крыла видны и в полной темноте: светимость тела показывает его клетку, но клетки вокруг не светлеют.
/datum/unit_test/heretic_dusk_eye_light/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(2, 2)
	var/datum/antagonist/heretic/heretic = dusk.owner_heretic()
	heretic.path_stage = 1
	heretic.refresh_evolution()
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/dark_luminosity = user.luminosity
	var/list/turf/near = RANGE_TURFS(3, user)
	var/list/lums = list()
	for(var/turf/spot as anything in near)
		lums += spot.dynamic_lumcount
	dusk_light_all(0)
	dusk_tick(dusk)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	var/obj/effect/dummy/lighting_obj/moblight/heretic_dusk_eyes/glow = dusk_eye_light(user)
	TEST_ASSERT(length(dusk.eye_overlays) && glow, "В тени у Крыла глаза видны и сквозь полную тьму.")
	TEST_ASSERT(user.luminosity > dark_luminosity, "Светимость тела открывает его клетку экипажу дальше see_in_dark.")
	for(var/i in 1 to length(near))
		var/turf/spot = near[i]
		TEST_ASSERT(spot.dynamic_lumcount == lums[i], "Свет глаз не освещает клетку [spot.x],[spot.y]: [spot.dynamic_lumcount] вместо [lums[i]].")
	dusk.set_form(HERETIC_DUSK_FORM_FACE)
	TEST_ASSERT_NULL(dusk_eye_light(user), "У Лика глаза не светят во тьме.")
	TEST_ASSERT_EQUAL(user.luminosity, dark_luminosity, "Без глаз тело снова тонет во тьме.")
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	TEST_ASSERT(dusk_eye_light(user), "Крыло снова светит глазами.")
	dusk_light_all(1)
	dusk_tick(dusk)
	TEST_ASSERT_NULL(dusk_eye_light(user), "На свету глаза не светят.")
	dusk_light_all(0)
	dusk_tick(dusk)
	TEST_ASSERT(dusk_eye_light(user), "В тени глаза загораются снова.")
	TEST_ASSERT(dusk.snuff_sight(), "Фонарь в лицо гасит зрение.")
	TEST_ASSERT_NULL(dusk_eye_light(user), "Погашенное зрение гасит и глаза.")
	dusk.sight_snuffed_until = 0
	dusk.end_snuff()
	TEST_ASSERT(dusk_eye_light(user), "Зрение вернулось - глаза горят.")
	glow = dusk_eye_light(user)
	glow.forceMove(get_turf(user))
	TEST_ASSERT(QDELETED(glow), "Свет глаз вне тела удаляется.")
	dusk.refresh_eyes()
	user.death()
	TEST_ASSERT_NULL(dusk_eye_light(user), "Мёртвое Крыло не светит глазами.")
	user.revive(full_heal = TRUE)
	dusk_tick(dusk)
	TEST_ASSERT(dusk_eye_light(user), "Ожившее Крыло в тени снова светит глазами.")
	dusk.on_body_lose(user)
	TEST_ASSERT_NULL(locate(/obj/effect/dummy/lighting_obj/moblight/heretic_dusk_eyes) in user, "Потеря тела убирает свет глаз.")
	TEST_ASSERT_EQUAL(user.luminosity, dark_luminosity, "После потери тела оно не светится.")

/datum/unit_test/heretic_dusk_types_create_and_destroy/Run()
	for(var/effect_type in list(/obj/effect/temp_visual/heretic_dusk/grip_rise, /obj/effect/temp_visual/heretic_dusk/puddle, /obj/effect/temp_visual/heretic_dusk/pillar, /obj/effect/temp_visual/heretic_dusk/sun_broken, /obj/effect/temp_visual/heretic_dusk/holy_burn, /obj/effect/temp_visual/heretic_dusk/wing_guard, /obj/effect/temp_visual/heretic_dusk/stance_switch, /obj/effect/temp_visual/heretic_dusk_burst, /obj/effect/temp_visual/heretic_dusk_wave, /obj/effect/temp_visual/heretic_dusk_combat/slash_light, /obj/effect/temp_visual/heretic_dusk_combat/slash_shadow, /obj/effect/temp_visual/heretic_dusk_combat/halo_charge, /obj/effect/temp_visual/heretic_dusk_combat/halo_flash, /obj/effect/temp_visual/heretic_dusk_combat/drink, /obj/effect/temp_visual/heretic_dusk_combat/drag, /obj/effect/temp_visual/heretic_dusk_quill_flight, /obj/item/projectile/heretic_dusk_feather))
		var/atom/effect = allocate(effect_type, run_loc_floor_bottom_left)
		qdel(effect)
		TEST_ASSERT(QDELETED(effect), "[effect_type] удаляется.")
	var/obj/effect/heretic_dusk_eclipse/zone = allocate(/obj/effect/heretic_dusk_eclipse, run_loc_floor_bottom_left, 2)
	TEST_ASSERT(length(zone.overlays) > 1, "Тьма затмения - плитки-оверлеи одного объекта.")
	qdel(zone)
	var/obj/structure/heretic_dusk_black_sun/orphan = new(run_loc_floor_bottom_left)
	TEST_ASSERT(QDELETED(orphan), "Солнце без вознесения не встаёт.")
