/// Тесты, которым нужен перехват чата: базовый тип снимает перехват в Destroy.
/datum/unit_test/heretic_dusk_chat
	abstract_type = /datum/unit_test/heretic_dusk_chat

/datum/unit_test/heretic_dusk_chat/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()

/datum/unit_test/heretic_dusk_chat/proc/listen()
	GLOB.unit_test_chat_capture = list()

/datum/unit_test/heretic_dusk_chat/proc/heard(mob/listener, marker)
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		var/target = entry[1]
		if((target == listener || (islist(target) && (listener in target))) && findtext(entry[2], marker))
			return TRUE
	return FALSE

/// Смена облика бьёт по намерению: «Помощь» и «Схватить» - никого, «Обезоружить» - только бивших или держащих, «Вред» - всех врагов рядом.
/datum/unit_test/heretic_dusk_form_strike_intent/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(1, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/mob/living/carbon/human/bystander = heretic_lead_test_crew(get_step(user, EAST))
	for(var/intent in list(INTENT_HELP, INTENT_GRAB))
		user.a_intent = intent
		TEST_ASSERT(dusk.toggle_form(user), "Облик меняется: [dusk.dusk_failure]")
		TEST_ASSERT(COOLDOWN_FINISHED(dusk, form_strike), "В намерении [intent] смена облика не бьёт.")
		TEST_ASSERT_NULL(dusk.halo_timer, "В намерении [intent] нимб не заряжается.")
	TEST_ASSERT_EQUAL(dusk.form, HERETIC_DUSK_FORM_FACE, "Два переключения вернули Лик.")
	user.a_intent = INTENT_DISARM
	TEST_ASSERT(dusk.toggle_form(user), "Крыло раскрыто: [dusk.dusk_failure]")
	TEST_ASSERT(COOLDOWN_FINISHED(dusk, form_strike), "В «Обезоружить» небивший прохожий не задет.")
	TEST_ASSERT(!dusk.holds_grudge(bystander), "Прохожий еретика не бил.")
	var/obj/item/crowbar/bar = allocate(/obj/item/crowbar, get_turf(bystander))
	bystander.put_in_active_hand(bar)
	bystander.a_intent = INTENT_HARM
	bar.melee_attack_chain(bystander, user)
	TEST_ASSERT(dusk.holds_grudge(bystander), "Ударивший еретика запомнен.")
	TEST_ASSERT(dusk.toggle_form(user), "Лик обращён: [dusk.dusk_failure]")
	TEST_ASSERT_NOTNULL(dusk.halo_timer, "В «Обезоружить» нимб заряжается на ударившего.")
	deltimer(dusk.halo_timer)
	dusk.halo_timer = null
	dusk.grudges[bystander.weak_reference] = world.time - 1
	TEST_ASSERT(!dusk.holds_grudge(bystander), "Через [HERETIC_DUSK_GRUDGE_TIME / (1 SECONDS)] секунд обида забыта.")
	var/mob/living/carbon/human/holder = heretic_lead_test_crew(get_step(user, NORTH))
	holder.start_pulling(user)
	TEST_ASSERT_EQUAL(user.pulledby, holder, "Еретика держат.")
	TEST_ASSERT(dusk.holds_grudge(holder), "Держащий еретика - враг и в «Обезоружить».")
	holder.stop_pulling()
	user.a_intent = INTENT_HARM
	COOLDOWN_RESET(dusk, form_strike)
	TEST_ASSERT(dusk.toggle_form(user), "Крыло раскрыто: [dusk.dusk_failure]")
	TEST_ASSERT(!COOLDOWN_FINISHED(dusk, form_strike), "Во «Вреде» смена облика бьёт любого врага рядом.")
	for(var/obj/item/projectile/heretic_dusk_feather/feather in range(HERETIC_DUSK_FAN_RANGE + 2, user))
		qdel(feather)

/// Святая вода жжёт по объёму не чаще раза в 3 секунды; при запертой смене облик снова не переворачивается.
/datum/unit_test/heretic_dusk_holy_volume/Run()
	TEST_ASSERT_EQUAL(heretic_dusk_holy_burn(1), HERETIC_DUSK_HOLY_SPLASH_MIN_BURN, "Капля жжёт по нижней планке.")
	TEST_ASSERT_EQUAL(heretic_dusk_holy_burn(4), 4 * HERETIC_DUSK_HOLY_BURN_PER_UNIT, "Ожог растёт с объёмом.")
	TEST_ASSERT_EQUAL(heretic_dusk_holy_burn(50), HERETIC_DUSK_HOLY_SPLASH_BURN, "Ведро жжёт не больше верхней планки.")
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/datum/reagents/drops = new(4)
	drops.add_reagent(/datum/reagent/water/holywater, 4)
	drops.reaction(user, TOUCH)
	qdel(drops)
	var/small = user.getFireLoss()
	TEST_ASSERT(small >= heretic_dusk_holy_burn(4) - 0.5 && small < HERETIC_DUSK_HOLY_SPLASH_BURN, "Брызги жгут слабее ведра: [small].")
	TEST_ASSERT_EQUAL(dusk.form, HERETIC_DUSK_FORM_WING, "Брызги сбивают облик.")
	user.adjustFireLoss(-200)
	dusk_splash(user)
	TEST_ASSERT_EQUAL(user.getFireLoss(), 0, "Внутри [HERETIC_DUSK_HOLY_SPLASH_GAP / (1 SECONDS)] секунд святая вода снова не жжёт.")
	COOLDOWN_RESET(dusk, holy_splash)
	dusk_splash(user)
	TEST_ASSERT(abs(user.getFireLoss() - HERETIC_DUSK_HOLY_SPLASH_BURN) < 0.5, "Полный плеск после паузы жжёт в полную силу: [user.getFireLoss()].")
	TEST_ASSERT_EQUAL(dusk.form, HERETIC_DUSK_FORM_WING, "Пока смена облика заперта, святая вода его не переворачивает.")
	TEST_ASSERT(world.time < dusk.form_locked_until, "Смена облика ещё заперта.")

/// Завет переспрашивает перед выбором, и все его тексты говорят «до конца раунда» без обещаний сброса.
/datum/unit_test/heretic_dusk_covenant_confirm/Run()
	for(var/covenant_id in GLOB.heretic_dusk_covenants)
		var/datum/heretic_dusk_covenant/option = GLOB.heretic_dusk_covenants[covenant_id]
		var/question = option.confirm_text()
		TEST_ASSERT(findtext(question, option.name), "Вопрос называет Завет [option.name].")
		TEST_ASSERT(findtext(question, "до конца раунда"), "Вопрос предупреждает, что выбор навсегда: [question]")
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/datum/eldritch_knowledge/spell/dusk_covenant/entry = dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_covenant)
	var/obj/effect/proc_holder/spell/self/heretic_dusk/covenant/button = locate() in dusk.dusk_body.mind.spell_list
	TEST_ASSERT_NOTNULL(button, "Кнопка «Завет» выдана.")
	var/texts = jointext(list(entry.summary, button.desc, button.summary) + entry.details, " ")
	TEST_ASSERT(findtext(texts, "до конца раунда"), "Знание и кнопка говорят, что Завет держится до конца раунда.")
	TEST_ASSERT(!findtext(texts, "сброс"), "Тексты Завета не обещают сброса.")

/// Скверна сильнее: носитель держит полную Хватку на свету, Шаг берёт его как отнятую тень, Перо гноит его раны.
/datum/unit_test/heretic_dusk_rot_strength/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_covenanted(HERETIC_DUSK_COVENANT_ROT, 1, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_light_all(1)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	var/mob/living/carbon/human/clean = heretic_lead_test_crew(get_step(user, NORTH))
	TEST_ASSERT(!dusk.shadowed_by_me(victim) && !dusk.grip_light_ok(victim), "Чистую цель на свету Хватка держит коротко.")
	dusk.infect_rot(victim)
	TEST_ASSERT_NOTNULL(dusk_rotten(victim), "Цель заражена.")
	TEST_ASSERT(dusk.shadowed_by_me(victim), "Носитель скверны для Шага - как отнятая тень.")
	TEST_ASSERT(dusk.grip_light_ok(victim), "Носителя Хватка держит полностью и на свету.")
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, get_turf(user))
	user.put_in_active_hand(blade)
	user.a_intent = INTENT_HARM
	var/tox_before = victim.getToxLoss()
	blade.attack(victim, user)
	TEST_ASSERT(victim.getToxLoss() - tox_before >= HERETIC_DUSK_ROT_QUILL_TOX - 0.5, "Перо гноит рану носителя: [victim.getToxLoss() - tox_before].")
	dusk.combo_reset()
	blade.attack(clean, user)
	TEST_ASSERT_EQUAL(clean.getToxLoss(), 0, "Чистую цель Перо не гноит.")

/// Хватка на свету держит 5 секунд и объясняет почему, в тени - полные 10; сорванная на телеграфе готова снова через 5 секунд.
/datum/unit_test/heretic_dusk_chat/heretic_dusk_grip_lit/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_grip)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	dusk.combat_resource = dusk.combat_resource_max
	var/mob/living/carbon/human/lit_victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/mob/living/carbon/human/dark_victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	var/mob/living/carbon/human/dodger = heretic_lead_test_crew(heretic_lead_test_spot(3, 4))
	dusk_light(lit_victim, 1)
	dusk_light(dark_victim, 0)
	dusk_light(dodger, 0)
	listen()
	TEST_ASSERT(dusk.grip(user, lit_victim), "Хватка берёт цель на свету: [dusk.dusk_failure]")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(lit_victim, TYPE_PROC_REF(/mob/living, has_status_effect), /datum/status_effect/heretic_dusk_grip), 2 SECONDS, "Хватка на свету"), "Хватка легла.")
	var/datum/status_effect/heretic_dusk_grip/grip = lit_victim.has_status_effect(/datum/status_effect/heretic_dusk_grip)
	var/left = grip.duration - world.time
	TEST_ASSERT(left < HERETIC_DUSK_GRIP_LIT_TIME + 1 && left > HERETIC_DUSK_GRIP_LIT_TIME - 1 SECONDS, "На свету Хватка держит [HERETIC_DUSK_GRIP_LIT_TIME / (1 SECONDS)] секунд: [left / (1 SECONDS)].")
	TEST_ASSERT(heard(user, "Цель на свету"), "Хозяин узнаёт, почему Хватка короче.")
	TEST_ASSERT(!dusk.grip_short, "Пометка короткой Хватки не остаётся на следующую.")
	TEST_ASSERT(dusk.grip(user, dark_victim), "Хватка берёт цель в тени: [dusk.dusk_failure]")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(dark_victim, TYPE_PROC_REF(/mob/living, has_status_effect), /datum/status_effect/heretic_dusk_grip), 2 SECONDS, "Хватка в тени"), "Хватка легла.")
	grip = dark_victim.has_status_effect(/datum/status_effect/heretic_dusk_grip)
	left = grip.duration - world.time
	TEST_ASSERT(left > HERETIC_DUSK_GRIP_TIME - 1 SECONDS, "В тени Хватка держит полные [HERETIC_DUSK_GRIP_TIME / (1 SECONDS)] секунд: [left / (1 SECONDS)].")
	var/obj/effect/proc_holder/spell/pointed/heretic_dusk/grip/power = locate() in user.mind.spell_list
	TEST_ASSERT_NOTNULL(power, "Кнопка Хватки выдана.")
	power.charge_counter = 0
	var/resource = dusk.combat_resource
	TEST_ASSERT(dusk.grip(user, dodger), "Хватка вспухает: [dusk.dusk_failure]")
	var/obj/structure/closet/locker = allocate(/obj/structure/closet, get_turf(dodger))
	dodger.forceMove(locker)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_time_passed), world.time + HERETIC_DUSK_GRIP_TELEGRAPH + 2), 2 SECONDS, "телеграф"), "Телеграф прошёл.")
	TEST_ASSERT_EQUAL(dusk.combat_resource, resource, "Сорванная Хватка вернула Сумрак.")
	TEST_ASSERT(power.charge_max - power.charge_counter <= HERETIC_DUSK_GRIP_MISS_COOLDOWN, "Сорванная Хватка готова через [HERETIC_DUSK_GRIP_MISS_COOLDOWN / (1 SECONDS)] секунд: осталось [(power.charge_max - power.charge_counter) / (1 SECONDS)].")
	TEST_ASSERT(heard(user, "Хватка готова через"), "Хозяин знает, когда Хватка вернётся.")
	power.charge_counter = power.charge_max

/// Хватка по лампе не в «Помощи» называет причину; мигание лампы слышно раз в минуту, зачёт отдела - всегда; вытеснение и снятие заговора слышны, сброс ламп - молча.
/datum/unit_test/heretic_dusk_chat/heretic_dusk_lamp_notices/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(1, 1)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/obj/machinery/light/small/lamp = allocate(/obj/machinery/light/small, heretic_lead_test_spot(4, 4))
	lamp.on = TRUE
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	listen()
	user.a_intent = INTENT_HARM
	fist.afterattack(lamp, user, TRUE)
	TEST_ASSERT(findtext(dusk.grasp_failure_reason, "Помощь"), "Отказ называет нужное намерение: [dusk.grasp_failure_reason]")
	TEST_ASSERT(heard(user, "Помощь"), "Еретик видит, почему лампа не заговорена.")
	TEST_ASSERT(dusk.hex_lamp(user, lamp), "Лампа заговорена: [dusk.grasp_failure_reason]")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, heretic_lead_test_spot(0, 4))
	TEST_ASSERT(dusk.on_lamp_flicker(lamp, stranger), "Первое мигание еретик видит.")
	TEST_ASSERT(heard(user, "лампа мигнула"), "Сообщение о мигании дошло.")
	TEST_ASSERT(!dusk.on_lamp_flicker(lamp, stranger), "Повторное мигание без зачёта в ту же минуту молчит.")
	allocate(/datum/heretic_test_station_level, run_loc_floor_bottom_left.z)
	heretic_test_area(get_turf(lamp), /area/cargo/storage)
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(0, 3))
	TEST_ASSERT(dusk.on_lamp_flicker(lamp, crew), "Зачёт отдела еретик слышит и в паузу.")
	TEST_ASSERT(heard(user, "Отдел засчитан"), "Сообщение называет зачёт.")
	for(var/index in 1 to HERETIC_DUSK_LAMP_LIMIT - 1)
		var/obj/machinery/light/small/extra = allocate(/obj/machinery/light/small, heretic_lead_test_spot(index % 5, 0))
		TEST_ASSERT(dusk.hex_lamp(user, extra), "Лампа [index] заговорена: [dusk.grasp_failure_reason]")
	listen()
	var/obj/machinery/light/small/seventh = allocate(/obj/machinery/light/small, heretic_lead_test_spot(0, 1))
	TEST_ASSERT(dusk.hex_lamp(user, seventh), "Седьмая лампа заговорена: [dusk.grasp_failure_reason]")
	TEST_ASSERT_NULL(lamp.GetComponent(/datum/component/heretic_dusk_lamp), "Вытеснена старейшая.")
	TEST_ASSERT(heard(user, "Старейшая заговорённая лампа забывает вас"), "Вытеснение слышно.")
	TEST_ASSERT(!heard(user, "забыла вас"), "Вытеснение не повторяется сообщением о снятии.")
	qdel(dusk.lamps[1])
	TEST_ASSERT(heard(user, "забыла вас"), "Снятый заговор слышен.")
	TEST_ASSERT_EQUAL(length(dusk.lamps), HERETIC_DUSK_LAMP_LIMIT - 1, "Снятый заговор освободил слот.")
	listen()
	dusk.clear_lamps()
	TEST_ASSERT_EQUAL(length(dusk.lamps), 0, "Сброс снимает все заговоры.")
	TEST_ASSERT(!heard(user, "забыла вас"), "Сброс ламп проходит молча.")

/// Луч лампы сам поворачивает Лик к указанной цели; проверка без каста никого не вертит.
/datum/unit_test/heretic_dusk_beam_turns/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(1, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(locate(user.x + 2, user.y, user.z))
	user.setDir(WEST)
	TEST_ASSERT(findtext(dusk.beam_block_reason(user, victim, FALSE), "перед вами"), "Без поворота Лик видит только вперёд.")
	TEST_ASSERT_EQUAL(user.dir, WEST, "Проверка без каста еретика не вертит.")
	var/obj/machinery/light/small/lamp = allocate(/obj/machinery/light/small, locate(user.x + 3, user.y + 1, user.z))
	lamp.on = TRUE
	TEST_ASSERT(dusk.hex_lamp(user, lamp), "Лампа заговорена: [dusk.grasp_failure_reason]")
	var/reason = dusk.beam_block_reason(user, victim, FALSE, TRUE)
	TEST_ASSERT_EQUAL(user.dir, EAST, "Луч поворачивает Лик к цели.")
	TEST_ASSERT_NULL(reason, "Повернувшись, Лик бьёт цель сбоку и сзади: [reason]")

/// Не вернувшееся Перо называет причину и даёт кнопку «Позвать Перо»; зов возвращает его, кнопка уходит с Пером в руке или с уничтоженным Пером.
/datum/unit_test/heretic_dusk_chat/heretic_dusk_quill_call/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, locate(user.x + 4, user.y, user.z))
	var/obj/structure/window/fulltile/pane = allocate(/obj/structure/window/fulltile, locate(user.x + 2, user.y, user.z))
	listen()
	TEST_ASSERT(!blade.fly_back(WEAKREF(user)), "Сквозь окно Перо не летит.")
	TEST_ASSERT(heard(user, "Между вами и Пером"), "Хозяин знает, почему Перо не вернулось.")
	TEST_ASSERT(heard(user, "Позвать Перо"), "Сообщение называет кнопку.")
	TEST_ASSERT_NOTNULL(dusk.quill_call, "Кнопка «Позвать Перо» выдана.")
	TEST_ASSERT(dusk.quill_call in user.mind.spell_list, "Кнопка в списке способностей.")
	TEST_ASSERT(!dusk.call_quill(user) && findtext(dusk.dusk_failure, "окно"), "Зов через окно называет причину: [dusk.dusk_failure]")
	qdel(pane)
	TEST_ASSERT(dusk.call_quill(user), "Зов возвращает Перо: [dusk.dusk_failure]")
	TEST_ASSERT_EQUAL(blade.loc, user, "Перо в руке.")
	TEST_ASSERT_NULL(dusk.quill_call, "С Пером в руке кнопка уходит.")
	TEST_ASSERT_NULL(locate(/obj/effect/proc_holder/spell/self/heretic_dusk/quill_call) in user.mind.spell_list, "Кнопки нет среди способностей.")
	user.dropItemToGround(blade)
	var/obj/structure/closet/locker = allocate(/obj/structure/closet, locate(user.x + 2, user.y, user.z))
	blade.forceMove(locker)
	TEST_ASSERT(!blade.fly_back(WEAKREF(user)), "Запертое Перо не летит.")
	TEST_ASSERT(heard(user, "заперто"), "Причина - Перо заперто.")
	blade.forceMove(get_turf(user))
	blade.pickup(user)
	user.put_in_active_hand(blade)
	TEST_ASSERT_NULL(dusk.quill_call, "Поднятое рукой Перо убирает кнопку.")
	user.dropItemToGround(blade)
	blade.forceMove(locker)
	blade.fly_back(WEAKREF(user))
	TEST_ASSERT_NOTNULL(dusk.quill_call, "Кнопка снова выдана.")
	qdel(blade)
	TEST_ASSERT_NULL(dusk.quill_call, "Уничтоженное Перо уносит кнопку.")
	TEST_ASSERT_NULL(dusk.stray_quill_ref, "Ссылка на Перо снята.")

/// Добивание срывает удар от 10, а не любой; причина срыва сохраняется для сообщения.
/datum/unit_test/heretic_dusk_drag_threshold/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(2, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_grip)
	dusk_light_all(0)
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	user.setDir(EAST)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	victim.apply_status_effect(/datum/status_effect/heretic_dusk_grip, dusk)
	dusk.drag_ref = WEAKREF(victim)
	dusk.drag_broken = FALSE
	dusk.drag_hits = 0
	var/mob/living/carbon/human/brawler = heretic_lead_test_crew(get_step(user, WEST))
	dusk.on_body_block(user, TRUE, null, HERETIC_DUSK_DRAG_BREAK_DAMAGE - 1, "удар", ATTACK_TYPE_MELEE, 0, brawler, BODY_ZONE_CHEST, list())
	TEST_ASSERT(dusk.drag_holds(user, victim), "Царапина добивание не срывает: [dusk.drag_failure]")
	dusk.drag_hits = 0
	dusk.on_body_block(user, TRUE, null, HERETIC_DUSK_DRAG_BREAK_DAMAGE, "удар", ATTACK_TYPE_MELEE, 0, brawler, BODY_ZONE_CHEST, list())
	TEST_ASSERT(!dusk.drag_holds(user, victim), "Удар от [HERETIC_DUSK_DRAG_BREAK_DAMAGE] срывает добивание.")
	TEST_ASSERT(findtext(dusk.drag_failure, "ранили"), "Причина - рана: [dusk.drag_failure]")
	dusk.drag_broken = FALSE
	dusk.drag_hits = 0
	dusk.drag_failure = null
	var/mob/living/carbon/human/spotter = heretic_lead_test_crew(locate(user.x + 1, user.y + 1, user.z))
	var/obj/item/flashlight/torch = dusk_lit_torch(spotter)
	spotter.a_intent = INTENT_HELP
	torch.melee_attack_chain(spotter, user)
	TEST_ASSERT(!dusk.drag_holds(user, victim), "Свет в лицо срывает добивание.")
	TEST_ASSERT(findtext(dusk.drag_failure, "фонар"), "Причина - фонарь в лицо: [dusk.drag_failure]")
	dusk.drag_ref = null
	dusk.drag_broken = TRUE

/// Лик на освещённой клетке жжёт каждым ударом Пера; в тени и в Крыле добавки нет.
/datum/unit_test/heretic_dusk_face_burn/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(1, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	victim.setDir(WEST)
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, get_turf(user))
	user.put_in_active_hand(blade)
	user.a_intent = INTENT_HARM
	dusk_light_all(1)
	dusk_tick(dusk)
	blade.attack(victim, user)
	TEST_ASSERT(abs(victim.getFireLoss() - HERETIC_DUSK_FACE_BURN) < 0.5, "Лик на свету жжёт Пером на [HERETIC_DUSK_FACE_BURN]: [victim.getFireLoss()].")
	victim.adjustFireLoss(-200)
	dusk.combo_reset()
	dusk_light_all(0)
	dusk_tick(dusk)
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Лик в тени Пером не жжёт.")
	dusk.combo_reset()
	dusk_light_all(1)
	user.a_intent = INTENT_HELP
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	dusk_tick(dusk)
	user.a_intent = INTENT_HARM
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Крыло Пером не жжёт.")

/// Перья Веера бьют тем же набором звуков, что и Перо.
/datum/unit_test/heretic_dusk_feather_hitsound/Run()
	var/obj/item/projectile/heretic_dusk_feather/feather = allocate(/obj/item/projectile/heretic_dusk_feather, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(feather.hitsound, HERETIC_DUSK_HIT_SFX, "Перо Веера звучит как удар Пером.")
	var/datum/sound_effect/hit = GLOB.sfx_datum_by_key[HERETIC_DUSK_HIT_SFX]
	TEST_ASSERT(length(hit?.file_paths) >= 3, "Набор звуков удара Пером собран.")
	var/obj/effect/proc_holder/spell/self/heretic_dusk/quill_call/button = allocate(/obj/effect/proc_holder/spell/self/heretic_dusk/quill_call)
	qdel(button)
	TEST_ASSERT(QDELETED(button), "Кнопка «Позвать Перо» удаляется.")
