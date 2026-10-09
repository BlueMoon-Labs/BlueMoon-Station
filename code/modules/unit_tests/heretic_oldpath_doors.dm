/datum/unit_test/proc/oldpath_door_zone(datum/eldritch_knowledge/knowledge, zone_type, turf/center, mob/living/user)
	var/obj/effect/heretic_combat_zone/zone = allocate(zone_type, center, user.mind)
	STOP_PROCESSING(SSprocessing, zone)
	QDEL_NULL(knowledge.combat_zone)
	knowledge.combat_zone = zone
	knowledge.track_combat_effect(zone)
	zone.refresh_boundary(block(locate(center.x - zone.radius, center.y - zone.radius, center.z), locate(center.x + zone.radius, center.y + zone.radius, center.z)))
	return zone

/datum/unit_test/proc/oldpath_door_cuff(mob/living/carbon/human/victim)
	victim.handcuffed = allocate(/obj/item/restraints/handcuffs, victim)
	victim.update_handcuffed()

/datum/unit_test/proc/oldpath_douse(atom/target)
	var/datum/reagents/water = new(5)
	water.add_reagent(/datum/reagent/water, 5)
	water.reaction(target, TOUCH)
	qdel(water)

/datum/unit_test/proc/oldpath_servant(datum/antagonist/heretic/heretic, datum/eldritch_knowledge/knowledge, servant_type, turf/location)
	var/datum/antagonist/heretic_monster/servant = allocate(servant_type)
	var/datum/mind/servant_mind = allocate_mind()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, location)
	servant_mind.current = body
	body.mind = servant_mind
	servant.silent = TRUE
	servant.set_master(heretic)
	servant_mind.add_antag_datum(servant)
	knowledge.track_flesh_servant(servant)
	return body

/datum/oldpath_pull_probe
	var/done = FALSE
	var/result

/datum/oldpath_pull_probe/proc/pull(datum/antagonist/heretic/heretic, mob/living/user, mob/living/victim, list/door)
	result = heretic.pocket_pull(user, victim, get_turf(victim), door["time"], door["check"], door["text"])
	done = TRUE

/// Готовую цель посреди канала двери расковали и растолкали: вход срывается, изнанка не открывается; вернёт текст ошибки или null.
/datum/unit_test/proc/oldpath_door_stands_mid_channel(datum/antagonist/heretic/heretic, mob/living/user, mob/living/carbon/human/victim, list/door)
	var/datum/oldpath_pull_probe/pull = new
	allocated += pull
	INVOKE_ASYNC(pull, TYPE_PROC_REF(/datum/oldpath_pull_probe, pull), heretic, user, victim, door)
	if(!LAZYFIND(user.do_afters, victim))
		return "Канал двери не начался: [heretic.pocket_pull_reason(user, victim, get_turf(victim)) || "дверь не держит цель"], завершён [pull.done]."
	if(!victim.has_status_effect(/datum/status_effect/heretic_door_grip))
		return "Сердце не прижало цель на время канала."
	victim.uncuff()
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, null)
	if(!wait_for_var(pull, NAMEOF(pull, done), TRUE, door["time"] * 3))
		return "Канал двери не закончился."
	if(pull.result || heretic.pocket_holds(victim))
		return "Вставшую посреди канала цель дверь всё равно увела."
	return null

/// Пепел уводит готовую цель со своего огня Угасания: вставшая цель рвёт дверь и до канала, и в нём, вода гасит огонь, след вознёсшегося владыки дверью не служит.
/datum/unit_test/heretic_ash_pocket_door/Run()
	var/turf/start = run_loc_floor_bottom_left
	allocated += new /datum/heretic_test_station_level(start.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ASH)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_ash/ash = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/turf/spot = get_step(start, EAST)
	var/turf/outside = get_step(start, WEST)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	oldpath_door_cuff(victim)
	TEST_ASSERT_NULL(ash.pocket_door(user, victim), "Без огня Пепел не уводит.")
	var/obj/effect/heretic_combat_zone/ash/zone = oldpath_door_zone(ash, /obj/effect/heretic_combat_zone/ash, spot, user)
	TEST_ASSERT(spot in zone.field_turfs, "Клетка цели в огне Угасания.")
	var/list/door = ash.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "Готовую цель на своём огне Пепел уводит.")
	TEST_ASSERT_EQUAL(door["time"], HERETIC_POCKET_PULL_TIME, "Дверь Пепла открывается за 1 секунду.")
	TEST_ASSERT(("Увести: [door["name"]]") in heretic.pocket_doors(user, victim), "Сердце предлагает дверь Пепла.")
	var/datum/callback/check = door["check"]
	var/stand_failure = oldpath_door_stands_mid_channel(heretic, user, victim, door)
	TEST_ASSERT_NULL(stand_failure, "Пепел: цель встала посреди канала.")
	TEST_ASSERT(!heretic.hunt_target_ready(victim), "Без наручников цель на ногах.")
	TEST_ASSERT_NULL(ash.pocket_door(user, victim), "Стоящую цель дверь не открывает.")
	TEST_ASSERT(!check.Invoke(), "Вставшая цель рвёт начатую дверь.")
	var/refused_at = world.time
	TEST_ASSERT(!heretic.pocket_pull(user, victim, spot, door["time"], door["check"], door["text"]), "Ответ на вопрос сердца после того, как цель встала, дверь не открывает.")
	TEST_ASSERT_EQUAL(world.time, refused_at, "Отказ сразу, без канала.")
	oldpath_door_cuff(victim)
	TEST_ASSERT(check.Invoke(), "Снова готовая цель на огне держит дверь.")
	user.forceMove(locate(start.x, start.y + 2, start.z))
	TEST_ASSERT(!check.Invoke(), "Еретик дальше клетки от цели дверь не держит.")
	user.forceMove(start)
	victim.forceMove(outside)
	TEST_ASSERT(!check.Invoke(), "Цель вне огня дверь не держит.")
	victim.forceMove(spot)
	TEST_ASSERT(check.Invoke(), "Цель вернулась в огонь.")
	var/obj/effect/heretic_field_edge/edge = locate() in get_step(spot, NORTH)
	TEST_ASSERT_NOTNULL(edge, "У огня есть край.")
	oldpath_douse(edge)
	TEST_ASSERT(QDELETED(zone), "Вода из огнетушителя на краю гасит огонь Угасания.")
	TEST_ASSERT(!check.Invoke(), "Погашенный огонь закрывает дверь.")

	var/obj/effect/heretic_combat_zone/ash/lord_trail/trail = allocate(/obj/effect/heretic_combat_zone/ash/lord_trail, spot, user.mind)
	STOP_PROCESSING(SSprocessing, trail)
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Цель в наручниках готова.")
	TEST_ASSERT_NULL(ash.pocket_door(user, victim), "Свой след вознёсшегося владыки - не дверь в изнанку.")
	oldpath_douse(trail)
	TEST_ASSERT(!QDELETED(trail), "Вода не гасит след вознёсшегося.")
	qdel(trail)

	zone = oldpath_door_zone(ash, /obj/effect/heretic_combat_zone/ash, spot, user)
	door = ash.pocket_door(user, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, spot, door["time"], door["check"], door["text"]), "Дверь Пепла уводит цель в изнанку.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	TEST_ASSERT_NULL(ash.pocket_exits(user), "Своих выходов у Пепла нет, только руны.")
	heretic.pocket.collapse("проверка")

/// Ржавчина уводит готовую цель на ржавом полу своего очага; очаг - выход из изнанки.
/datum/unit_test/heretic_rust_pocket_door/Run()
	var/turf/start = run_loc_floor_bottom_left
	allocated += new /datum/heretic_test_station_level(start.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_RUST)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_rust/rust = heretic.get_knowledge(/datum/eldritch_knowledge/base_rust)
	var/turf/spot = get_step(start, EAST)
	spot = spot.ChangeTurf(/turf/open/floor/plating/rust)
	var/turf/bare = get_step(start, NORTH)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	oldpath_door_cuff(victim)
	TEST_ASSERT_NULL(rust.pocket_door(user, victim), "Без очага ржавый пол не дверь.")
	var/obj/effect/heretic_combat_zone/rust/hearth = oldpath_door_zone(rust, /obj/effect/heretic_combat_zone/rust, spot, user)
	TEST_ASSERT(spot in hearth.field_turfs, "Ржавая клетка цели в границе очага.")
	TEST_ASSERT(!(bare in hearth.field_turfs), "Нержавый пол вне границы очага.")
	var/list/door = rust.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "Готовую цель на ржавчине своего очага Ржавчина уводит.")
	TEST_ASSERT_EQUAL(door["time"], HERETIC_POCKET_PULL_TIME, "Дверь Ржавчины открывается за 1 секунду.")
	var/datum/callback/check = door["check"]
	victim.forceMove(bare)
	TEST_ASSERT_NULL(rust.pocket_door(user, victim), "Готовую цель на нержавом полу очаг не уводит.")
	TEST_ASSERT(!check.Invoke(), "Сошедшая с ржавчины цель рвёт дверь.")
	victim.forceMove(spot)
	victim.uncuff()
	TEST_ASSERT(!check.Invoke(), "Дверь очага требует готовности всё время.")
	oldpath_door_cuff(victim)
	var/list/exits = rust.pocket_exits(user)
	TEST_ASSERT_EQUAL(length(exits), 1, "Действующий очаг - выход из изнанки.")
	TEST_ASSERT(findtext(exits[1], "Очаг - "), "Выход подписан очагом: [exits[1]]")
	TEST_ASSERT_EQUAL(exits[exits[1]], spot, "Выход у очага.")
	TEST_ASSERT(heretic.pocket_pull(user, victim, spot, door["time"], door["check"], door["text"]), "Дверь очага уводит цель в изнанку.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	heretic.pocket.collapse("проверка")
	qdel(hearth)
	TEST_ASSERT_NULL(rust.pocket_door(user, victim), "Без очага двери нет.")
	TEST_ASSERT_EQUAL(length(rust.pocket_exits(user)), 0, "Угасший очаг больше не выход.")
	var/turf/elsewhere = locate(start.x + 4, start.y + 4, start.z)
	elsewhere = elsewhere.ChangeTurf(/turf/open/floor/plating/rust)
	hearth = oldpath_door_zone(rust, /obj/effect/heretic_combat_zone/rust, elsewhere, user)
	hearth.refresh_boundary(list(elsewhere))
	var/datum/mind/stranger = allocate_mind()
	var/obj/effect/heretic_combat_zone/rust/foreign = allocate(/obj/effect/heretic_combat_zone/rust, spot, stranger)
	STOP_PROCESSING(SSprocessing, foreign)
	foreign.refresh_boundary(list(spot))
	TEST_ASSERT_EQUAL(length(rust.pocket_exits(user)), 1, "Свой очаг в другом месте действует.")
	TEST_ASSERT_NULL(rust.pocket_door(user, victim), "Чужой очаг не дверь, даже когда свой очаг горит в другом месте.")

/// Плоть уводит готовую цель у своего гуля, мертвеца или ползуна из 7 клеток за 1,5 секунды; сжатое сердце спрашивает, найти цель или увести её.
/datum/unit_test/heretic_flesh_pocket_door/Run()
	var/turf/start = run_loc_floor_bottom_left
	allocated += new /datum/heretic_test_station_level(start.z)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, start)
	var/datum/mind/user_mind = allocate_mind()
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/door_fixture/heretic = allocate(/datum/antagonist/heretic/door_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	heretic.selected_path = PATH_FLESH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/base_flesh/flesh = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/flesh_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/turf/spot = locate(start.x - 1, start.y + 2, start.z)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	oldpath_door_cuff(victim)
	TEST_ASSERT_NULL(flesh.pocket_door(user, victim), "Без слуги Плоть не уводит.")
	var/mob/living/carbon/human/summon = oldpath_servant(heretic, grasp, /datum/antagonist/heretic_monster, get_step(spot, SOUTH))
	TEST_ASSERT_NULL(flesh.pocket_door(user, victim), "Призванный слуга не гуль, не мертвец и не ползун.")
	qdel(summon)
	var/mob/living/carbon/human/ghoul = oldpath_servant(heretic, grasp, /datum/antagonist/heretic_monster/ghoul, get_step(spot, SOUTH))
	var/list/door = flesh.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "Готовую цель у своего гуля Плоть уводит издалека.")
	TEST_ASSERT(abs(door["time"] - HERETIC_FLESH_DOOR_TIME) < 1, "Дверь слуги открывается за 1,5 секунды.")
	TEST_ASSERT(door["remote"], "Дверь слуги работает издалека.")
	var/datum/callback/check = door["check"]
	ghoul.forceMove(locate(spot.x + 2, spot.y, spot.z))
	TEST_ASSERT(!check.Invoke(), "Слуга дальше клетки от цели дверь не держит.")
	ghoul.forceMove(get_step(spot, SOUTH))
	victim.uncuff()
	TEST_ASSERT(!check.Invoke(), "Дверь слуги требует готовности всё время.")
	oldpath_door_cuff(victim)
	ghoul.Unconscious(10 SECONDS)
	TEST_ASSERT(!check.Invoke(), "Слуга без сознания цель не утащит.")
	ghoul.SetUnconscious(0)
	oldpath_door_cuff(ghoul)
	TEST_ASSERT(!check.Invoke(), "Скованный слуга цель не утащит.")
	ghoul.uncuff()
	ghoul.Paralyze(5 SECONDS)
	TEST_ASSERT(!check.Invoke(), "Оглушённый слуга цель не утащит.")
	ghoul.SetParalyzed(0)
	TEST_ASSERT(check.Invoke(), "Освобождённый слуга снова держит дверь.")
	var/turf/limit = locate(spot.x + HERETIC_FLESH_DOOR_RANGE, spot.y, spot.z)
	var/turf/beyond = get_step(spot, WEST)
	TEST_ASSERT(limit && beyond, "Есть клетки на пределе и за ним.")
	user.forceMove(limit)
	TEST_ASSERT(check.Invoke(), "Еретик ровно в 7 клетках держит дверь.")
	victim.forceMove(beyond)
	TEST_ASSERT_EQUAL(get_dist(user, victim), HERETIC_FLESH_DOOR_RANGE + 1, "Цель на клетку дальше предела.")
	TEST_ASSERT(!check.Invoke(), "Дальше 7 клеток еретик дверь не держит.")
	victim.forceMove(spot)
	user.forceMove(start)
	TEST_ASSERT(check.Invoke(), "Еретик рядом снова держит дверь.")

	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, start)
	TEST_ASSERT(heart.bind(user_mind), "Сердце привязано к еретику.")
	user.put_in_hands(heart)
	heretic.answer = null
	heart.attack_self(user)
	TEST_ASSERT_EQUAL(length(heretic.offered), 2, "Сжатое сердце спрашивает: найти цель или увести через слугу.")
	TEST_ASSERT_EQUAL(heretic.offered[1], HERETIC_POCKET_TRACK_TARGET, "Первая кнопка - найти цель.")
	TEST_ASSERT_EQUAL(heretic.offered[2], "Увести: [door["name"]]", "Вторая кнопка - дверь слуги.")
	TEST_ASSERT_NULL(heretic.pocket, "Закрытый вопрос никуда не уводит.")
	TEST_ASSERT(!COOLDOWN_FINISHED(heart, track_cooldown), "Закрытый вопрос ищет цель, как обычное сжатие.")
	COOLDOWN_RESET(heart, track_cooldown)
	heretic.answer = HERETIC_POCKET_TRACK_TARGET
	heart.attack_self(user)
	TEST_ASSERT(!COOLDOWN_FINISHED(heart, track_cooldown), "Выбор «Найти цель» ищет цель.")
	TEST_ASSERT_NULL(heretic.pocket, "Поиск цели никуда не уводит.")
	TEST_ASSERT_EQUAL(heretic.prompt_timeout, HERETIC_RITUAL_CHOICE_TIMEOUT, "Вопрос сжатого сердца закрывается сам через минуту.")
	COOLDOWN_RESET(heart, track_cooldown)
	heretic.during_prompt = CALLBACK(user, TYPE_PROC_REF(/mob, dropItemToGround), heart)
	heart.attack_self(user)
	TEST_ASSERT(COOLDOWN_FINISHED(heart, track_cooldown), "Сердце, выпавшее из руки за время вопроса, цель не ищет.")
	TEST_ASSERT(!heretic.remote_door_prompt_open, "Отказ после вопроса освобождает сердце.")
	user.put_in_hands(heart)
	heretic.answer = "Увести: [door["name"]]"
	TEST_ASSERT(!heretic.choose_remote_pocket_door(user, victim, heart, heretic.pocket_doors(user, victim, TRUE)), "Сердце, выпавшее за время вопроса, дверь не открывает.")
	TEST_ASSERT(!heretic.remote_door_prompt_open, "Отказ двери освобождает сердце.")
	TEST_ASSERT_NULL(heretic.pocket, "Изнанка не открылась.")
	user.put_in_hands(heart)
	heretic.during_prompt = CALLBACK(ghoul, TYPE_PROC_REF(/mob/living, Unconscious), 10 SECONDS)
	TEST_ASSERT(!heretic.choose_remote_pocket_door(user, victim, heart, heretic.pocket_doors(user, victim, TRUE)), "Слуга, вырубленный за время вопроса, дверь не открывает.")
	TEST_ASSERT_NULL(heretic.pocket, "Изнанка не открылась и без слуги.")
	heretic.during_prompt = null
	ghoul.SetUnconscious(0)
	heretic.offered = null
	heretic.remote_door_prompt_open = TRUE
	heart.attack_self(user)
	TEST_ASSERT_NULL(heretic.offered, "Пока вопрос открыт, новое сжатие не задаёт второй.")
	TEST_ASSERT(COOLDOWN_FINISHED(heart, track_cooldown), "Пока вопрос открыт, сжатие и не ищет цель.")
	heretic.remote_door_prompt_open = FALSE
	heretic.answer = "Увести: [door["name"]]"
	var/started = world.time
	TEST_ASSERT(heretic.choose_remote_pocket_door(user, victim, heart, heretic.pocket_doors(user, victim, TRUE)), "Дверь слуги уводит цель в изнанку.")
	TEST_ASSERT(world.time - started >= HERETIC_FLESH_DOOR_TIME - 1, "Переход занимает 1,5 секунды: [world.time - started] дс.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	TEST_ASSERT(istype(get_area(user), /area/heretic_pocket), "Еретик входит следом.")
	TEST_ASSERT(!heretic.remote_door_prompt_open, "После ответа сердце снова свободно.")
	var/list/exits = flesh.pocket_exits(user)
	TEST_ASSERT_EQUAL(length(exits), 1, "Живой слуга - выход из изнанки.")
	TEST_ASSERT(findtext(exits[1], "Слуга - "), "Выход подписан слугой: [exits[1]]")
	TEST_ASSERT_EQUAL(exits[exits[1]], get_turf(ghoul), "Выход у слуги.")
	heretic.pocket.collapse("проверка")
	ghoul.death()
	TEST_ASSERT_EQUAL(length(flesh.pocket_exits(user)), 0, "Мёртвый слуга не выход.")
	TEST_ASSERT_NULL(flesh.pocket_door(user, victim), "Мёртвый слуга не дверь.")
	heretic.offered = null
	COOLDOWN_RESET(heart, track_cooldown)
	heart.attack_self(user)
	TEST_ASSERT_NULL(heretic.offered, "Без двери сердце ничего не спрашивает.")
	TEST_ASSERT(!COOLDOWN_FINISHED(heart, track_cooldown), "Без двери сжатое сердце сразу ищет цель.")

	victim.forceMove(spot)
	user.forceMove(start)
	flesh.combat_resource = flesh.combat_resource_max
	var/obj/item/organ/heart/organ = allocate(/obj/item/organ/heart, get_step(user, EAST))
	TEST_ASSERT(flesh.grow_fleshling(user, organ), "Ползун вырос из органа.")
	var/mob/living/simple_animal/heretic_fleshling/crawler = flesh.fleshling
	allocated += crawler
	STOP_PROCESSING(SSfastprocess, crawler)
	crawler.forceMove(get_step(spot, SOUTH))
	TEST_ASSERT_NOTNULL(flesh.pocket_door(user, victim), "Ползун у цели - тоже дверь.")
	TEST_ASSERT_EQUAL(length(flesh.pocket_exits(user)), 1, "Ползун - выход из изнанки.")
	qdel(crawler)
	TEST_ASSERT_NULL(flesh.pocket_door(user, victim), "Без ползуна двери нет.")
	oldpath_servant(heretic, grasp, /datum/antagonist/heretic_monster/voiceless_dead, get_step(spot, SOUTH))
	TEST_ASSERT_NOTNULL(flesh.pocket_door(user, victim), "Безмолвный мертвец у цели - тоже дверь.")

/// Касание безумия валит цель на 3 секунды, путает шаги и даёт одну временную фобию без урона мозгу; сбитая цель готова к обряду.
/datum/unit_test/heretic_flesh_madness_knockdown/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, get_step(user, EAST))
	var/obj/effect/proc_holder/spell/targeted/touch/mad_touch/spell = allocate(/obj/effect/proc_holder/spell/targeted/touch/mad_touch)
	TEST_ASSERT(spell.ChargeHand(user), "Касание готово.")
	spell.attached_hand.afterattack(victim, user, TRUE)
	TEST_ASSERT(victim.IsKnockdown(), "Касание безумия сбивает с ног.")
	TEST_ASSERT(abs(victim.AmountKnockdown() - HERETIC_FLESH_MADNESS_KNOCKDOWN) <= 1, "Падение длится 3 секунды: [victim.AmountKnockdown()] дс.")
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Сбитая касанием цель готова к обряду.")
	TEST_ASSERT_EQUAL(victim.getOrganLoss(ORGAN_SLOT_BRAIN), 0, "Касание не бьёт по мозгу и не бросает кубик случайных травм.")
	TEST_ASSERT_EQUAL(victim.confused, HERETIC_FLESH_MADNESS_CONFUSION, "Касание путает шаги.")
	var/obj/item/organ/brain/brain = victim.getorganslot(ORGAN_SLOT_BRAIN)
	TEST_ASSERT_EQUAL(length(brain.traumas), 1, "Касание даёт ровно одну травму.")
	TEST_ASSERT(istype(brain.traumas[1], /datum/brain_trauma/mild/phobia), "Эта травма - фобия.")

/// Пустота уводит готовую цель в своём Зимнем пределе; вставшая цель рвёт дверь и до канала, и в нём, выход из поля тоже.
/datum/unit_test/heretic_void_pocket_door/Run()
	var/turf/start = run_loc_floor_bottom_left
	allocated += new /datum/heretic_test_station_level(start.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_VOID)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_void/void = heretic.get_knowledge(/datum/eldritch_knowledge/base_void)
	var/turf/spot = get_step(start, EAST)
	var/turf/outside = get_step(start, WEST)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	oldpath_door_cuff(victim)
	TEST_ASSERT_NULL(void.pocket_door(user, victim), "Без Зимнего предела Пустота не уводит.")
	var/obj/effect/heretic_combat_zone/void/winter = oldpath_door_zone(void, /obj/effect/heretic_combat_zone/void, get_step(spot, EAST), user)
	TEST_ASSERT(spot in winter.field_turfs, "Цель в Зимнем пределе.")
	TEST_ASSERT(!(outside in winter.field_turfs), "Клетка у еретика с запада вне поля.")
	var/list/door = void.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "Готовую цель в своём Зимнем пределе Пустота уводит.")
	TEST_ASSERT_EQUAL(door["time"], HERETIC_POCKET_PULL_TIME, "Дверь Пустоты открывается за 1 секунду.")
	var/datum/callback/check = door["check"]
	var/stand_failure = oldpath_door_stands_mid_channel(heretic, user, victim, door)
	TEST_ASSERT_NULL(stand_failure, "Пустота: цель встала посреди канала.")
	TEST_ASSERT_NULL(void.pocket_door(user, victim), "Стоящую цель дверь не открывает.")
	TEST_ASSERT(!check.Invoke(), "Вставшая в поле цель рвёт начатую дверь.")
	var/refused_at = world.time
	TEST_ASSERT(!heretic.pocket_pull(user, victim, spot, door["time"], door["check"], door["text"]), "Ответ на вопрос сердца после того, как цель встала, дверь не открывает.")
	TEST_ASSERT_EQUAL(world.time, refused_at, "Отказ сразу, без канала.")
	oldpath_door_cuff(victim)
	TEST_ASSERT(check.Invoke(), "Снова готовая цель в поле держит дверь.")
	victim.forceMove(outside)
	TEST_ASSERT(!check.Invoke(), "Вышедшая из поля цель рвёт дверь.")
	victim.forceMove(spot)
	var/turf/elsewhere = locate(start.x + 4, start.y + 4, start.z)
	winter.refresh_boundary(list(elsewhere))
	TEST_ASSERT(!(spot in winter.field_turfs), "Своё поле теперь в другом месте.")
	var/datum/mind/stranger = allocate_mind()
	var/obj/effect/heretic_combat_zone/void/foreign = allocate(/obj/effect/heretic_combat_zone/void, spot, stranger)
	STOP_PROCESSING(SSprocessing, foreign)
	foreign.refresh_boundary(list(spot))
	TEST_ASSERT_NULL(void.pocket_door(user, victim), "Чужое поле не дверь, даже когда своё стоит в другом месте.")
	qdel(foreign)
	winter = oldpath_door_zone(void, /obj/effect/heretic_combat_zone/void, get_step(spot, EAST), user)
	door = void.pocket_door(user, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, spot, door["time"], door["check"], door["text"]), "Дверь Пустоты уводит цель в изнанку.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	TEST_ASSERT_NULL(void.pocket_exits(user), "Своих выходов у Пустоты нет, только руны.")
	heretic.pocket.collapse("проверка")

/// Заклинания старых путей до вознесения не колдуются под оглушением и в стамкрите, в чужой хватке - только Пепельный переход и Пустотный сдвиг; вознёсшийся колдует весь набор как прежде, не-еретика проверка не трогает.
/datum/unit_test/heretic_oldpath_spells_stunned/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.ascended = TRUE
	heretic.selected_path = PATH_VOID
	var/list/escapes = list(
		/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash,
		/obj/effect/proc_holder/spell/pointed/void_blink,
	)
	var/list/spell_types = escapes + list(
		/obj/effect/proc_holder/spell/targeted/fiery_rebirth,
		/obj/effect/proc_holder/spell/pointed/nightwatchers_rite,
		/obj/effect/proc_holder/spell/pointed/cleave,
		/obj/effect/proc_holder/spell/aoe_turf/rust_conversion,
		/obj/effect/proc_holder/spell/aimed/rust_wave,
		/obj/effect/proc_holder/spell/cone/staggered/entropic_plume,
		/obj/effect/proc_holder/spell/targeted/touch/grasp_of_decay,
		/obj/effect/proc_holder/spell/pointed/blood_siphon,
		/obj/effect/proc_holder/spell/targeted/touch/mad_touch,
		/obj/effect/proc_holder/spell/targeted/void_pull,
		/obj/effect/proc_holder/spell/pointed/boogie_woogie,
		/obj/effect/proc_holder/spell/aoe_turf/domain_expansion,
	)
	var/list/ascension_types = list(
		/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/big,
		/obj/effect/proc_holder/spell/targeted/fire_sworn,
		/obj/effect/proc_holder/spell/self/rust_corrosive_wave,
		/obj/effect/proc_holder/spell/targeted/shed_human_form,
		/obj/effect/proc_holder/spell/self/heretic_last_waltz,
	)
	var/list/spells = list()
	var/list/all_spells = list()
	for(var/spell_type in spell_types + ascension_types)
		var/obj/effect/proc_holder/spell/spell = allocate(spell_type)
		heretic.owner.AddSpell(spell)
		all_spells += spell
		if(!(spell_type in ascension_types))
			spells += spell
		TEST_ASSERT(spell.can_cast(user, TRUE, TRUE), "[spell_type] колдуется свободным еретиком: [spell.heretic_failure_reason]")
	var/obj/effect/proc_holder/spell/pointed/cleave/stranger_cleave = allocate(/obj/effect/proc_holder/spell/pointed/cleave)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/datum/mind/stranger_mind = allocate_mind()
	stranger_mind.current = stranger
	stranger.mind = stranger_mind
	stranger_mind.AddSpell(stranger_cleave)
	stranger.Stun(5 SECONDS, ignore_canstun = TRUE)
	TEST_ASSERT(stranger_cleave.can_cast(stranger, TRUE, TRUE), "Не-еретика с тем же заклинанием новая проверка не трогает.")

	heretic.ascended = FALSE
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human, get_step(user, EAST))
	grabber.start_pulling(user)
	grabber.setGrabState(GRAB_AGGRESSIVE)
	TEST_ASSERT(user.incapacitated(), "Агрессивная хватка сковывает еретика.")
	for(var/obj/effect/proc_holder/spell/spell as anything in spells)
		if(spell.type in escapes)
			TEST_ASSERT(spell.can_cast(user, TRUE, TRUE), "[spell.type] - уход, он работает в чужой хватке.")
		else
			TEST_ASSERT(!spell.can_cast(user, TRUE, TRUE), "[spell.type] до вознесения не колдуется в чужой хватке.")
	grabber.stop_pulling()
	user.Stun(5 SECONDS, ignore_canstun = TRUE)
	for(var/obj/effect/proc_holder/spell/spell as anything in spells)
		TEST_ASSERT(!spell.can_cast(user, TRUE, TRUE), "[spell.type] до вознесения не колдуется под оглушением.")
	var/obj/effect/proc_holder/spell/shift = spells[1]
	shift.can_cast(user, TRUE, TRUE)
	TEST_ASSERT(findtext(shift.heretic_failure_reason, "оглушения"), "Отказ называет оглушение: [shift.heretic_failure_reason]")
	user.SetStun(0)
	user.adjustStaminaLoss(500)
	TEST_ASSERT(IS_STAMCRIT(user), "Еретик в стамкрите.")
	for(var/obj/effect/proc_holder/spell/spell as anything in spells)
		TEST_ASSERT(!spell.can_cast(user, TRUE, TRUE), "[spell.type] до вознесения не колдуется в стамкрите.")

	heretic.ascended = TRUE
	user.Stun(5 SECONDS, ignore_canstun = TRUE)
	grabber.start_pulling(user)
	grabber.setGrabState(GRAB_AGGRESSIVE)
	TEST_ASSERT(IS_STAMCRIT(user) && user.IsStun() && user.pulledby == grabber, "Вознёсшийся в стамкрите, под оглушением и в чужой хватке.")
	for(var/obj/effect/proc_holder/spell/spell as anything in all_spells)
		TEST_ASSERT(spell.can_cast(user, TRUE, TRUE), "[spell.type] у вознёсшегося колдуется как прежде: [spell.heretic_failure_reason]")

/// Строки захвата и ухода, базовые знания, Касание безумия и уходы описывают двери и хватку числами из дефайнов, а кодекс называет способности как их кнопки.
/datum/unit_test/heretic_oldpath_door_texts/Run()
	var/datum/heretic_path/ash_path = GLOB.heretic_paths[PATH_ASH]
	var/datum/heretic_path/rust_path = GLOB.heretic_paths[PATH_RUST]
	var/datum/heretic_path/flesh_path = GLOB.heretic_paths[PATH_FLESH]
	var/datum/heretic_path/void_path = GLOB.heretic_paths[PATH_VOID]
	var/obj/effect/proc_holder/spell/targeted/touch/mad_touch/madness = /obj/effect/proc_holder/spell/targeted/touch/mad_touch
	var/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash/shift = /obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash
	var/obj/effect/proc_holder/spell/pointed/void_blink/blink = /obj/effect/proc_holder/spell/pointed/void_blink
	var/obj/effect/proc_holder/spell/self/heretic_power/ash/ember = /obj/effect/proc_holder/spell/self/heretic_power/ash
	var/obj/effect/heretic_pocket_rift/rift = /obj/effect/heretic_pocket_rift
	var/pull_time = "[HERETIC_POCKET_PULL_TIME / (1 SECONDS)] секунд"
	var/flesh_time = replacetext("[HERETIC_FLESH_DOOR_TIME / (1 SECONDS)] секунды", ".", ",")
	var/madness_time = "[HERETIC_FLESH_MADNESS_KNOCKDOWN / (1 SECONDS)] секунды"
	var/list/facts = list(
		list(ash_path.capture_summary, "в изнанку", pull_time),
		list(rust_path.capture_summary, "в изнанку", pull_time),
		list(flesh_path.capture_summary, "в изнанку", "из [HERETIC_FLESH_DOOR_RANGE] клеток", madness_time, "гуля, мертвеца или ползуна"),
		list(void_path.capture_summary, "в изнанку", pull_time),
		list(rust_path.escape_summary, "очагу"),
		list(jointext(ash_path.weakness_points, " "), "До вознесения", "крепкой хватки уводит только Пепельный переход"),
		list(jointext(ash_path.strength_points, " "), "Возрождение ночного дозорного", "до 4 горящих врагов"),
		list(jointext(rust_path.weakness_points, " "), "До вознесения", "крепкая чужая хватка"),
		list(jointext(flesh_path.weakness_points, " "), "До вознесения", "крепкая чужая хватка", "слугу оглушат или скуют", "цель оттащат от него"),
		list(jointext(void_path.weakness_points, " "), "До вознесения", "крепкой хватки уводит только Пустотный сдвиг"),
		list(flesh_path.escape_summary, "к живому гулю, мертвецу или ползуну"),
		list(flesh_path.combat_practice, "гулем, мертвецом или ползуном", "из [HERETIC_FLESH_DOOR_RANGE] клеток", "слугу оглушат, скуют", "цель оттащат"),
		list(heretic_codex_text(/datum/eldritch_knowledge/base_ash), "в изнанку", pull_time, "Вода и пена гасят", "не встанет"),
		list(heretic_codex_text(/datum/eldritch_knowledge/base_rust), "в изнанку", pull_time),
		list(heretic_codex_text(/datum/eldritch_knowledge/base_flesh), "в изнанку", "из [HERETIC_FLESH_DOOR_RANGE] клеток", flesh_time, "гуля, мертвеца или ползуна", "слугу оглушат, скуют или схватят", "цель оттащат", "дальше [HERETIC_FLESH_DOOR_RANGE] клеток"),
		list(heretic_codex_text(/datum/eldritch_knowledge/base_void), "в изнанку", pull_time, "встанет"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/touch_of_madness), madness_time),
		list(initial(madness.desc), madness_time),
		list(initial(ember.desc), "Вода и пена гасят"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/ashen_shift), "в чужой хватке"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/void_phase), "в чужой хватке"),
		list(initial(shift.desc), "в чужой хватке", "до вознесения"),
		list(initial(blink.desc), "в чужой хватке", "до вознесения"),
		list(initial(rift.desc), "Нулевой жезл", "Библия"),
	)
	for(var/list/fact_line as anything in facts)
		var/fact_text = fact_line[1]
		for(var/index in 2 to length(fact_line))
			TEST_ASSERT(findtext(fact_text, fact_line[index]), "Текст называет «[fact_line[index]]»: [fact_text]")
	for(var/knowledge_type in list(/datum/eldritch_knowledge/spell/ashen_shift, /datum/eldritch_knowledge/spell/flame_birth, /datum/eldritch_knowledge/spell/entropic_plume))
		var/datum/eldritch_knowledge/spell/knowledge = knowledge_type
		var/obj/effect/proc_holder/spell/spell_type = initial(knowledge.spell_to_add)
		TEST_ASSERT_EQUAL(initial(knowledge.name), initial(spell_type.name), "Кодекс называет [knowledge_type] как кнопку способности.")
