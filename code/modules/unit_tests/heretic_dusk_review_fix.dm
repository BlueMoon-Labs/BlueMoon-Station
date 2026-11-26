/// Перо, поднятое хозяином, не числится застрявшим: таймер возврата снят, кнопки нет; возврат одного Пера не снимает кнопку другого.
/datum/unit_test/heretic_dusk_quill_pickup/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(1, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, get_turf(user))
	blade.schedule_return(user, 5 SECONDS)
	blade.pickup(user)
	user.put_in_active_hand(blade)
	TEST_ASSERT_NULL(blade.return_timer, "Поднятое хозяином Перо не ждёт возврата.")
	TEST_ASSERT(!blade.fly_back(WEAKREF(user)), "Перо в руке никуда не летит.")
	TEST_ASSERT_NULL(dusk.quill_call, "Перо в руке не объявлено застрявшим.")
	TEST_ASSERT(!blade.fly_back(WEAKREF(user), TRUE) && dusk.dusk_failure == "Перо уже у вас.", "Зов Пера в руке называет причину: [dusk.dusk_failure]")
	user.dropItemToGround(blade)
	var/obj/item/melee/sickly_blade/dusk/stuck = allocate(/obj/item/melee/sickly_blade/dusk, locate(user.x + 3, user.y, user.z))
	allocate(/obj/structure/window/fulltile, locate(user.x + 1, user.y, user.z))
	TEST_ASSERT(!stuck.fly_back(WEAKREF(user)), "Перо за окном не летит.")
	TEST_ASSERT_NOTNULL(dusk.quill_call, "Застрявшее Перо даёт кнопку.")
	blade.forceMove(locate(user.x - 1, user.y, user.z))
	TEST_ASSERT(blade.fly_back(WEAKREF(user)), "Второе Перо возвращается: [dusk.dusk_failure]")
	TEST_ASSERT_NOTNULL(dusk.quill_call, "Возврат второго Пера не снимает кнопку застрявшего.")
	TEST_ASSERT_EQUAL(dusk.stray_quill_ref?.resolve(), stuck, "Застрявшим числится первое Перо.")

/// Отказ зова называет сторону и отсек, а хозяину в шкафу - честную причину.
/datum/unit_test/heretic_dusk_quill_whereabouts/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, locate(user.x + 4, user.y, user.z))
	allocate(/obj/structure/window/fulltile, locate(user.x + 2, user.y, user.z))
	TEST_ASSERT(!blade.fly_back(WEAKREF(user), TRUE), "Сквозь окно Перо не летит.")
	TEST_ASSERT(findtext(dusk.dusk_failure, "на востоке") && findtext(dusk.dusk_failure, get_area_name(blade, TRUE)), "Отказ называет сторону и отсек: [dusk.dusk_failure]")
	var/obj/structure/closet/locker = allocate(/obj/structure/closet, get_turf(user))
	user.forceMove(locker)
	TEST_ASSERT(!blade.fly_back(WEAKREF(user), TRUE), "Из шкафа Перо не поймать.")
	TEST_ASSERT(findtext(dusk.dusk_failure, "шкафу"), "Причина - укрытие, а не оглушение: [dusk.dusk_failure]")
	user.forceMove(get_turf(locker))

/// Гниль в ране от Пера ранит синтетика сбоем систем, а любителя токсинов жжёт, а не лечит.
/datum/unit_test/heretic_dusk_rot_wound_kinds/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_covenanted(HERETIC_DUSK_COVENANT_ROT, 1, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_light_all(0)
	var/mob/living/carbon/human/synth = heretic_lead_test_crew(get_step(user, EAST))
	var/mob/living/carbon/human/slime = heretic_lead_test_crew(get_step(user, NORTH))
	ADD_TRAIT(synth, TRAIT_ROBOTIC_ORGANISM, TRAIT_GENERIC)
	ADD_TRAIT(slime, TRAIT_TOXINLOVER, TRAIT_GENERIC)
	dusk.infect_rot(synth)
	dusk.infect_rot(slime)
	var/synth_before = synth.getToxLoss()
	dusk.on_eldritch_blade_damage(synth, user, 0)
	TEST_ASSERT(synth.getToxLoss() - synth_before >= HERETIC_DUSK_ROT_QUILL_TOX - 0.5, "Синтетику гниль бьёт сбоем систем: [synth.getToxLoss() - synth_before].")
	var/slime_burn = slime.getFireLoss()
	dusk.on_eldritch_blade_damage(slime, user, 0)
	TEST_ASSERT(slime.getFireLoss() - slime_burn >= HERETIC_DUSK_ROT_QUILL_TOX - 0.5, "Любителя токсинов гниль жжёт: [slime.getFireLoss() - slime_burn].")
	TEST_ASSERT_EQUAL(slime.getToxLoss(), 0, "Любителя токсинов гниль не лечит.")

/// Значок Сумрака сам узнаёт о смене света и показывает святое: запертый облик секундами и голубую букву без копления.
/datum/unit_test/heretic_dusk_hud_light_change/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_light(user, 1)
	dusk_tick(dusk)
	var/atom/movable/screen/alert/heretic_resource/indicator = user.alerts["heretic_path_resource"]
	TEST_ASSERT(findtext(indicator.maptext, "#ffd479"), "Лик на свету копит: буква яркая.")
	dusk_light(user, 0)
	dusk_tick(dusk)
	TEST_ASSERT(!findtext(indicator.maptext, "#ffd479") && findtext(indicator.desc, "не копится"), "Ушедший свет гасит букву без другого события: [indicator.desc]")
	dusk.holy_silence_until = world.time + 5 SECONDS
	dusk.form_locked_until = world.time + 5 SECONDS
	dusk.notify_resource_changed()
	TEST_ASSERT(findtext(indicator.maptext, "#8fdcff") && findtext(indicator.maptext, "5с"), "Святое красит букву, запертый облик виден секундами: [indicator.maptext]")
	TEST_ASSERT(findtext(indicator.desc, "Облик заперт святой водой: 5 с") && findtext(indicator.desc, "Святое не даёт копить"), "Подсказка называет запертый облик и святое: [indicator.desc]")
	dusk.holy_silence_until = 0
	dusk.form_locked_until = 0

/// Одноразовая кнопка «Завет» не занимает слот горячей клавиши.
/datum/unit_test/heretic_dusk_covenant_no_hotkey/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_covenant)
	var/obj/effect/proc_holder/spell/self/heretic_dusk/covenant/button = locate() in dusk.dusk_body.mind.spell_list
	TEST_ASSERT_NOTNULL(button, "Кнопка «Завет» выдана.")
	var/list/spells = list()
	var/datum/antagonist/heretic/heretic = dusk.owner_heretic()
	heretic.collect_combat_spells(spells)
	TEST_ASSERT(!(button in spells), "«Завет» не среди способностей с горячими клавишами.")

/// Веер в «Обезоружить» летит без разлёта и задевает только бивших еретика.
/datum/unit_test/heretic_dusk_fan_disarm_targets/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_light_all(0)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	var/mob/living/carbon/human/foe = heretic_lead_test_crew(locate(user.x + 3, user.y, user.z))
	var/mob/living/carbon/human/bystander = heretic_lead_test_crew(locate(user.x + 1, user.y, user.z))
	dusk.note_attacker(foe)
	user.a_intent = INTENT_DISARM
	var/list/feathers = dusk.feather_fan(user)
	TEST_ASSERT_EQUAL(length(feathers), HERETIC_DUSK_FAN_FEATHERS, "Веер выпущен в бившего.")
	var/obj/item/projectile/heretic_dusk_feather/first = feathers[1]
	for(var/obj/item/projectile/heretic_dusk_feather/feather as anything in feathers)
		TEST_ASSERT_EQUAL(feather.Angle, first.Angle, "В «Обезоружить» перья летят без разлёта.")
		TEST_ASSERT(!feather.can_hit_target(bystander, FALSE, TRUE, TRUE), "Перо пролетает не бившего.")
		TEST_ASSERT(feather.can_hit_target(foe, TRUE, TRUE, TRUE), "Перо бьёт бившего.")
	for(var/obj/item/projectile/heretic_dusk_feather/feather as anything in feathers)
		qdel(feather)

/// Удалённый атакующий не оставляет пустой записи в списке бивших.
/datum/unit_test/heretic_dusk_grudge_deleted/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/gone = heretic_lead_test_crew(locate(dusk.dusk_body.x + 1, dusk.dusk_body.y, dusk.dusk_body.z))
	qdel(gone)
	dusk.note_attacker(gone)
	TEST_ASSERT(!(null in dusk.grudges), "Нет записи без атакующего.")
	dusk.dusk_body.a_intent = INTENT_DISARM
	TEST_ASSERT_EQUAL(length(dusk.strike_foes(dusk.dusk_body, 2)), 0, "Удар облика без бивших никого не берёт.")

/// Пацифист не бьёт сменой облика.
/datum/unit_test/heretic_dusk_form_strike_pacifist/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_light_all(0)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	heretic_lead_test_crew(locate(user.x + 2, user.y, user.z))
	user.a_intent = INTENT_HARM
	ADD_TRAIT(user, TRAIT_PACIFISM, TRAIT_GENERIC)
	TEST_ASSERT(!dusk.form_strike(user), "Пацифист не мечет перья.")
	REMOVE_TRAIT(user, TRAIT_PACIFISM, TRAIT_GENERIC)
	TEST_ASSERT(dusk.form_strike(user), "Без пацифизма веер летит.")
	var/mob/living/carbon/human/pinned = heretic_lead_test_crew(get_step(user, EAST))
	pinned.apply_status_effect(/datum/status_effect/heretic_dusk_grip, dusk)
	ADD_TRAIT(user, TRAIT_PACIFISM, TRAIT_GENERIC)
	TEST_ASSERT(findtext(dusk.drag_block_reason(user, pinned), "ранить"), "Пацифист не утягивает в тень: [dusk.drag_block_reason(user, pinned)]")
	REMOVE_TRAIT(user, TRAIT_PACIFISM, TRAIT_GENERIC)
	for(var/obj/item/projectile/feather in get_turf(user))
		qdel(feather)

/// Добивание срывает второе попадание или одно сильное, союзник Мансуса не в счёт; святая вода называет себя причиной.
/datum/unit_test/heretic_dusk_drag_hits/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(2, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_grip)
	dusk_light_all(0)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	user.setDir(EAST)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	var/mob/living/carbon/human/brawler = heretic_lead_test_crew(get_step(user, WEST))
	victim.apply_status_effect(/datum/status_effect/heretic_dusk_grip, dusk)
	dusk.drag_ref = WEAKREF(victim)
	dusk.drag_broken = FALSE
	dusk.drag_hits = 0
	dusk.on_body_block(user, TRUE, null, 3, "кулак", ATTACK_TYPE_MELEE, 0, brawler, BODY_ZONE_CHEST, list())
	TEST_ASSERT(dusk.drag_holds(user, victim), "Одна царапина добивание не срывает: [dusk.drag_failure]")
	dusk.on_body_block(user, TRUE, null, 3, "кулак", ATTACK_TYPE_MELEE, 0, brawler, BODY_ZONE_CHEST, list())
	TEST_ASSERT(!dusk.drag_holds(user, victim) && findtext(dusk.drag_failure, "второй"), "Второе попадание срывает добивание: [dusk.drag_failure]")
	dusk.drag_broken = FALSE
	dusk.drag_hits = 0
	dusk.drag_failure = null
	dusk.on_body_block(user, TRUE, null, HERETIC_DUSK_DRAG_BREAK_DAMAGE, "лом", ATTACK_TYPE_MELEE, 0, brawler, BODY_ZONE_CHEST, list())
	TEST_ASSERT(!dusk.drag_holds(user, victim) && findtext(dusk.drag_failure, "ранили"), "Сильный удар срывает сразу: [dusk.drag_failure]")
	dusk.drag_broken = FALSE
	dusk.drag_failure = null
	dusk.holy_splash(10)
	TEST_ASSERT(!dusk.drag_holds(user, victim) && findtext(dusk.drag_failure, "святая вода"), "Святая вода называет себя причиной: [dusk.drag_failure]")
	dusk.drag_broken = FALSE
	dusk.drag_hits = 0
	dusk.drag_failure = null
	dusk.on_body_block(user, TRUE, null, HERETIC_DUSK_DRAG_BREAK_DAMAGE, "ящик", ATTACK_TYPE_PROJECTILE, 0, null, BODY_ZONE_CHEST, list())
	TEST_ASSERT(!dusk.drag_holds(user, victim), "Удар без атакующего срывает добивание без рантайма: [dusk.drag_failure]")
	var/obj/structure/table/turret = allocate(/obj/structure/table, get_step(user, WEST))
	dusk.drag_broken = FALSE
	dusk.drag_hits = 0
	dusk.drag_failure = null
	dusk.on_body_block(user, TRUE, null, HERETIC_DUSK_DRAG_BREAK_DAMAGE, "лазер", ATTACK_TYPE_PROJECTILE, 0, turret, BODY_ZONE_CHEST, list())
	TEST_ASSERT(!dusk.drag_holds(user, victim), "Выстрел машины (не моба) срывает добивание: [dusk.drag_failure]")
	dusk.drag_ref = null
	dusk.drag_broken = TRUE

/// Значок прибитого называет срок этой Хватки и что на свету она вдвое короче.
/datum/unit_test/heretic_dusk_grip_alert_time/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	dusk_light_all(0)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(locate(dusk.dusk_body.x + 2, dusk.dusk_body.y, dusk.dusk_body.z))
	var/datum/status_effect/heretic_dusk_grip/grip = victim.apply_status_effect(/datum/status_effect/heretic_dusk_grip, dusk)
	TEST_ASSERT_NOTNULL(grip?.linked_alert, "У прибитого есть значок.")
	TEST_ASSERT(findtext(grip.linked_alert.desc, "ещё [heretic_dusk_seconds(dusk.grip_time())]") && findtext(grip.linked_alert.desc, "вдвое короче"), "Значок называет срок Хватки: [grip.linked_alert.desc]")
	qdel(grip)
