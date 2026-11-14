/// Выбор оружия и усиления в пульте выдаёт снаряжение стрелка без подсказок и импланта, стрелок сразу ходит, а перевыдача роли не рассыпает тело.
/datum/unit_test/antag_training_hatred_setup/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/hatred)
	TEST_ASSERT(session.prepare(), "Полигон готовит стрелка.")
	var/datum/antag_training_program/antag/hatred/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/hatred/training/role = program.role(session)
	TEST_ASSERT(istype(role), "Кукла получает учебного стрелка.")
	TEST_ASSERT_EQUAL(role.chosen_gun, "AK47", "Стартовое оружие - AK47.")
	TEST_ASSERT(istype(body.s_store, /obj/item/gun/ballistic/automatic/ak47/hatred), "AK47 Ненависти на плаще.")
	TEST_ASSERT(istype(body.l_store, /obj/item/storage/bag/ammo/hatred), "Подсумок Ненависти в кармане.")
	TEST_ASSERT_NULL(locate(/obj/item/implant/explosive) in body.implants, "Взрывного импланта нет.")
	TEST_ASSERT_NULL(locate(/datum/action/hatred_deploy) in body.actions, "Кнопки высадки на станцию нет.")
	var/list/data = session.ui_data(body)
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")

	var/turf/start = get_turf(body)
	var/turf/next = antag_training_free_step(body)
	TEST_ASSERT_NOTNULL(next, "Рядом со стрелком есть свободная клетка.")
	body.Move(next, get_dir(start, next))
	TEST_ASSERT_EQUAL(get_turf(body), next, "Стрелок ходит сразу, без высадки.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Усиление: Больше брони"))
	var/datum/antagonist/hatred/training/armored = program.role(session)
	TEST_ASSERT(QDELETED(role) && istype(armored), "Смена усиления перевыдаёт роль.")
	TEST_ASSERT(!QDELETED(body) && session.current_body == body, "Перевыдача роли оставляет то же тело.")
	TEST_ASSERT(intact_after_regrant(body), "Перевыдача роли не рассыпает тело.")
	TEST_ASSERT_EQUAL(armored.chosen_high_gear, "More armor", "Выбрано усиление брони.")
	TEST_ASSERT_EQUAL(armored.gear_level, 2, "Усиление - снаряжение второго уровня.")
	var/datum/armor/coat_armor = new_tg_get_armor_by_type(/datum/armor/hatred_gear)
	TEST_ASSERT_EQUAL(body.wear_suit?.armor?.melee, coat_armor.melee + 10, "Плащ крепче на 10.")
	TEST_ASSERT(istype(body.s_store, /obj/item/gun/ballistic/automatic/ak47/hatred), "Оружие прежнее - AK47.")
	TEST_ASSERT_EQUAL(count_items(body, /obj/item/gun/ballistic/automatic/ak47/hatred), 1, "AK47 один.")
	TEST_ASSERT_EQUAL(count_items(body, /obj/item/storage/belt/military/assault/hatred), 1, "Пояс Ненависти один.")

	antag_training_console_act(session, console, "program_option", list("option" = "Оружие: Пистолеты"))
	var/datum/antagonist/hatred/training/pistoleer = program.role(session)
	TEST_ASSERT(QDELETED(armored) && istype(pistoleer), "Смена оружия перевыдаёт роль.")
	TEST_ASSERT(!QDELETED(body) && session.current_body == body, "Смена оружия оставляет то же тело.")
	TEST_ASSERT(intact_after_regrant(body), "Смена оружия не рассыпает тело.")
	TEST_ASSERT_EQUAL(pistoleer.chosen_gun, "Pistols", "Выбранное в пульте оружие - пистолеты.")
	TEST_ASSERT(istype(body.s_store, /obj/item/storage/belt/holster/hatred), "Кобура Ненависти на плаще.")
	TEST_ASSERT(istype(body.l_store, /obj/item/storage/bag/ammo/hatred_c4), "Подсумок для взлома в кармане.")
	TEST_ASSERT_EQUAL(count_items(body, /obj/item/gun/ballistic/automatic/ak47/hatred), 0, "AK47 прежней роли убран.")
	TEST_ASSERT(HAS_TRAIT(body, TRAIT_DOUBLE_TAP), "Пистолеты стреляют с двух рук.")
	var/tough = 0
	for(var/datum/quirk/quirk as anything in body.roundstart_quirks)
		if(istype(quirk, /datum/quirk/tough))
			tough++
	TEST_ASSERT_EQUAL(tough, 1, "Черты стрелка не удваиваются.")
	var/obj/item/storage/bag/ammo/hatred_c4/breaching = body.l_store
	var/obj/item/grenade/plastic/c4/charge = locate() in breaching
	TEST_ASSERT_NOTNULL(charge, "В подсумке для взлома заряд C4.")
	qdel(charge)
	antag_training_console_act(session, console, "program_option", list("option" = "Пополнить магазины и C4"))
	TEST_ASSERT_NOTNULL(locate(/obj/item/grenade/plastic/c4) in breaching, "Пополнение сразу возвращает C4.")

/datum/unit_test/antag_training_hatred_setup/proc/count_items(mob/living/body, item_type)
	. = 0
	for(var/obj/item/item in body.GetAllContents())
		if(istype(item, item_type))
			.++

/datum/unit_test/antag_training_hatred_setup/proc/intact_after_regrant(mob/living/body)
	var/turf/spot = get_turf(body)
	return body.stat != DEAD && spot && !(locate(/obj/effect/decal/remains) in spot) && !(locate(/obj/effect/decal/cleanable/ash) in spot)

/// Смена уровня и смерть не будят станционную часть стрелка: ни крика с телепортом, ни взрыва, ни сброса плаща.
/datum/unit_test/antag_training_hatred_station_parts
	var/shouts = 0

/datum/unit_test/antag_training_hatred_station_parts/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/hatred)
	TEST_ASSERT(session.prepare(), "Полигон готовит стрелка.")
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antag_training_arena/arena = session.arena
	RegisterSignal(body, COMSIG_MOB_SAY, PROC_REF(count_shout))
	var/turf/spot = arena.zones["range"]["spawn"]
	body.moveToNullspace()
	body.forceMove(spot)
	TEST_ASSERT_EQUAL(get_turf(body), spot, "Возврат на уровень полигона не уносит стрелка на станцию.")
	TEST_ASSERT_EQUAL(shouts, 0, "Стрелок не кричит при смене уровня.")
	UnregisterSignal(body, COMSIG_MOB_SAY)

	body.death()
	TEST_ASSERT(!QDELETED(body), "Тело после смерти цело.")
	TEST_ASSERT_NULL(locate(/obj/item/clothing/suit/jacket/leather/overcoat/hatred) in spot, "С тела не падает второй плащ.")
	TEST_ASSERT(istype(body.s_store, /obj/item/gun/ballistic/automatic/ak47/hatred), "Оружие остаётся на стрелке.")

/datum/unit_test/antag_training_hatred_station_parts/proc/count_shout(datum/source)
	SIGNAL_HANDLER
	shouts++

/// Казнь учебной цели выстрелом в упор лечит стрелка и кормит Пояс Ненависти, хотя в цели нет игрока.
/datum/unit_test/antag_training_hatred_glory_kill/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/hatred)
	TEST_ASSERT(session.prepare(), "Полигон готовит стрелка.")
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antag_training_arena/arena = session.arena
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "spawn", list("id" = "human", "zone" = "range"))
	var/mob/living/carbon/human/dummy = arena.targets[length(arena.targets)]
	TEST_ASSERT(dummy && !dummy.client, "Учебная цель без игрока.")
	var/turf/beside = antag_training_free_step(dummy)
	TEST_ASSERT_NOTNULL(beside, "Рядом с целью есть место.")
	body.forceMove(beside)

	antag_training_console_act(session, console, "program_option", list("option" = "Цель для казни"))
	TEST_ASSERT(dummy.stat != CONSCIOUS && dummy.stat != DEAD, "«Цель для казни» лишает цель сознания.")

	body.apply_damage(40, BRUTE, BODY_ZONE_CHEST, forced = TRUE)
	TEST_ASSERT(body.getBruteLoss() > 0, "Стрелок ранен.")
	var/obj/item/storage/belt/military/assault/hatred/belt = body.belt
	TEST_ASSERT(istype(belt), "Пояс Ненависти на стрелке.")
	var/obj/item/gun/ballistic/automatic/ak47/hatred/rifle = body.s_store
	body.temporarilyRemoveItemFromInventory(rifle, TRUE)
	body.put_in_active_hand(rifle)
	TEST_ASSERT(body.get_active_held_item() == rifle, "AK47 в руке.")
	body.a_intent = INTENT_HELP
	body.zone_selected = BODY_ZONE_PRECISE_MOUTH
	rifle.melee_attack_chain(body, dummy)
	TEST_ASSERT(wait_for_var(dummy, "stat", DEAD, 3 SECONDS), "Выстрел в упор казнит цель.")
	TEST_ASSERT(wait_for_var(belt, "glory_points", 1, 5 SECONDS), "Казнь учебной цели даёт поясу сердце.")
	TEST_ASSERT_EQUAL(round(body.getBruteLoss(), 1), 0, "Казнь учебной цели лечит стрелка.")
	TEST_ASSERT(rifle.magazine.ammo_count() < rifle.magazine.max_ammo, "Выстрел потратил патрон магазина.")
	antag_training_console_act(session, console, "program_option", list("option" = "Пополнить магазины и C4"))
	TEST_ASSERT_EQUAL(rifle.magazine.ammo_count(), rifle.magazine.max_ammo, "Пополнение наполняет магазин в оружии.")
