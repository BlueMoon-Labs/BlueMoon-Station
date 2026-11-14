/datum/blood_oath/blood_brothers_capstone_test
	name = "Проверка венца"
	key = "capstone_test"

/area/blood_brothers_blackout_test
	name = "Blood Brothers Blackout Test"
	requires_power = FALSE

/// Команда с клятвой-заглушкой, венцом capstone_type и высшей ступенью связи
/proc/allocate_capstone_team(datum/unit_test/test, capstone_type, size = BROTHER_TEAM_START_SIZE)
	var/datum/team/brother_team/team = allocate_brother_team(test, size)
	var/datum/blood_oath/blood_brothers_capstone_test/oath = new
	oath.capstone_type = capstone_type
	oath.vow_type = /datum/blood_vow/shadow
	team.swear_oath(oath)
	team.set_bond_tier(BLOOD_BOND_TIER_MAX)
	return team

/proc/capstone_action(datum/team/brother_team/team, member_index, capstone_type)
	var/datum/mind/member = team.members[member_index]
	var/datum/antagonist/brother/brother = member.has_antag_datum(/datum/antagonist/brother)
	return brother.bond_actions[capstone_type]

/// Третья печать выдаёт венец клятвы с кнопкой из набора братьев; пассивный венец кнопки не даёт
/datum/unit_test/blood_brothers_capstone_granted

/datum/unit_test/blood_brothers_capstone_granted/Run()
	var/list/action_states = icon_states('modular_bluemoon/icons/mob/blood_brothers/actions.dmi')
	for(var/capstone_type in subtypesof(/datum/action/cooldown/blood_bond/capstone))
		var/datum/team/brother_team/team = allocate_capstone_team(src, capstone_type)
		TEST_ASSERT_EQUAL(team.oath?.capstone_type, capstone_type, "[capstone_type]: клятва принята")
		var/datum/action/cooldown/blood_bond/capstone/action = capstone_action(team, 1, capstone_type)
		TEST_ASSERT_NOTNULL(action, "[capstone_type]: венец выдан на высшей ступени")
		TEST_ASSERT(action.button_icon_state in action_states, "[capstone_type]: кнопка [action.button_icon_state] из actions.dmi")
		TEST_ASSERT_EQUAL(action.background_icon_state, "bg_blood_bond", "[capstone_type]: фон кнопок братьев")
		team.set_bond_tier(BLOOD_BOND_TIER_MAX - 1)
		TEST_ASSERT_NULL(capstone_action(team, 1, capstone_type), "[capstone_type]: ниже высшей ступени венца нет")
	var/datum/team/brother_team/circle_team = allocate_capstone_team(src, /datum/blood_bond_passive/circle)
	var/datum/mind/member = circle_team.members[1]
	var/datum/antagonist/brother/brother = member.has_antag_datum(/datum/antagonist/brother)
	for(var/action_type in brother.bond_actions)
		TEST_ASSERT(!ispath(action_type, /datum/action/cooldown/blood_bond/capstone), "Пассивный венец кнопки не даёт")

/// Схрон общий: положенное одним братом видно второму, лишнее не влезает, распад команды высыпает его под ноги открывавшему последним
/datum/unit_test/blood_brothers_capstone_stash

/datum/unit_test/blood_brothers_capstone_stash/Run()
	var/datum/team/brother_team/team = allocate_capstone_team(src, /datum/action/cooldown/blood_bond/capstone/stash)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/mob/living/carbon/human/first_body = first.current
	var/mob/living/carbon/human/second_body = second.current
	var/datum/action/cooldown/blood_bond/capstone/stash/first_action = capstone_action(team, 1, /datum/action/cooldown/blood_bond/capstone/stash)
	TEST_ASSERT(first_action.Trigger(), "Схрон открывается")
	var/obj/item/storage/blood_stash/stash = team.stash
	TEST_ASSERT(istype(stash), "Схрон создан при первом открытии")
	TEST_ASSERT_NULL(stash.loc, "Без открытого окна схрон в nullspace")
	var/obj/item/toy = allocate(/obj/item/toy/crayon/red)
	first_body.put_in_hands(toy)
	TEST_ASSERT(SEND_SIGNAL(stash, COMSIG_TRY_STORAGE_INSERT, toy, first_body), "Положено в схрон")
	TEST_ASSERT_EQUAL(toy.loc, stash, "Предмет в схроне")
	var/turf/start = get_turf(first_body)
	second_body.forceMove(locate(start.x + 2, start.y, start.z))
	var/datum/action/cooldown/blood_bond/capstone/stash/second_action = capstone_action(team, 2, /datum/action/cooldown/blood_bond/capstone/stash)
	TEST_ASSERT(second_action.Trigger(), "Второй брат открывает схрон")
	TEST_ASSERT_EQUAL(team.stash, stash, "Схрон у команды один")
	TEST_ASSERT_EQUAL(toy.loc, stash, "Второй брат видит положенное первым")
	TEST_ASSERT_EQUAL(team.stash_last_user, second, "Запомнен открывший последним")
	for(var/item_number in 2 to BROTHER_STASH_MAX_ITEMS)
		var/obj/item/filler = allocate(/obj/item/toy/crayon/blue)
		second_body.put_in_hands(filler)
		TEST_ASSERT(SEND_SIGNAL(stash, COMSIG_TRY_STORAGE_INSERT, filler, second_body), "Предмет [item_number] влез")
	var/obj/item/extra = allocate(/obj/item/toy/crayon/green)
	second_body.put_in_hands(extra)
	TEST_ASSERT(!SEND_SIGNAL(stash, COMSIG_TRY_STORAGE_INSERT, extra, second_body), "Лишний предмет не влезает")
	team.sever(second, "тест")
	TEST_ASSERT_EQUAL(toy.loc, stash, "Пока брат остаётся, схрон цел")
	team.sever(first, "тест")
	TEST_ASSERT_EQUAL(toy.loc, get_turf(second_body), "Распад команды высыпает схрон под ноги открывавшему последним")
	TEST_ASSERT_NULL(team.stash, "Схрон распался")
	TEST_ASSERT(!team.open_stash(first_body), "Распавшейся команде схрон не открыть")
	TEST_ASSERT_NULL(team.stash, "Новый схрон после распада не появляется")
	var/datum/action/cooldown/blood_bond/capstone/stash/stash_type = /datum/action/cooldown/blood_bond/capstone/stash
	TEST_ASSERT(findtext(initial(stash_type.desc), "[BROTHER_STASH_MAX_ITEMS] предметов"), "Вместимость в описании совпадает с дефайном")

/// Схрон не берёт диск и ничего живого, а пропавший венец высыпает его под ноги
/datum/unit_test/blood_brothers_capstone_stash_guard

/datum/unit_test/blood_brothers_capstone_stash_guard/Run()
	var/datum/team/brother_team/team = allocate_capstone_team(src, /datum/action/cooldown/blood_bond/capstone/stash)
	var/datum/mind/first = team.members[1]
	var/mob/living/carbon/human/first_body = first.current
	var/datum/action/cooldown/blood_bond/capstone/stash/action = capstone_action(team, 1, /datum/action/cooldown/blood_bond/capstone/stash)
	TEST_ASSERT(action.Trigger(), "Схрон открывается")
	var/obj/item/storage/blood_stash/stash = team.stash
	var/obj/item/disk/nuclear/disk = allocate(/obj/item/disk/nuclear/fake)
	first_body.put_in_hands(disk)
	TEST_ASSERT(!SEND_SIGNAL(stash, COMSIG_TRY_STORAGE_INSERT, disk, first_body), "Диск ядерной аутентификации в схрон не прячется")
	var/mob/living/simple_animal/mouse/mouse = allocate(/mob/living/simple_animal/mouse)
	var/obj/item/clothing/head/mob_holder/holder = allocate(/obj/item/clothing/head/mob_holder, null, mouse)
	first_body.put_in_hands(holder)
	TEST_ASSERT_EQUAL(holder.w_class, WEIGHT_CLASS_TINY, "Предпосылка: мышь в переноске крошечная")
	TEST_ASSERT(!SEND_SIGNAL(stash, COMSIG_TRY_STORAGE_INSERT, holder, first_body), "Мышь в переноске в схрон не прячется")
	TEST_ASSERT_EQUAL(mouse.loc, holder, "Мышь осталась в переноске")
	first_body.dropItemToGround(disk)
	var/obj/item/toy = allocate(/obj/item/toy/crayon/red)
	first_body.put_in_hands(toy)
	TEST_ASSERT(SEND_SIGNAL(stash, COMSIG_TRY_STORAGE_INSERT, toy, first_body), "Обычная вещь прячется")
	team.set_bond_tier(BLOOD_BOND_TIER_MAX - 1)
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT_EQUAL(toy.loc, get_turf(first_body), "Пропавший венец высыпает схрон под ноги открывавшему")
	TEST_ASSERT_NULL(team.stash, "Схрон без венца распался")

/// Разрыв оков снимает наручники и болы с себя и брата рядом, но не с дальнего брата и не с чужого
/datum/unit_test/blood_brothers_capstone_unshackle

/datum/unit_test/blood_brothers_capstone_unshackle/Run()
	var/datum/team/brother_team/team = allocate_capstone_team(src, /datum/action/cooldown/blood_bond/capstone/unshackle, 3)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/mind/third = team.members[3]
	var/mob/living/carbon/human/first_body = first.current
	var/mob/living/carbon/human/second_body = second.current
	var/mob/living/carbon/human/third_body = third.current
	var/turf/start = get_turf(first_body)
	second_body.forceMove(get_step(first_body, EAST))
	third_body.forceMove(locate(start.x + 2, start.y + 2, start.z))
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	stranger.forceMove(get_step(first_body, NORTH))
	var/datum/action/cooldown/blood_bond/capstone/unshackle/action = capstone_action(team, 1, /datum/action/cooldown/blood_bond/capstone/unshackle)
	TEST_ASSERT(!action.Trigger(), "Без оков рвать нечего")
	TEST_ASSERT_EQUAL(action.next_use_time, 0, "Пустое нажатие не тратит перезарядку")
	var/obj/item/restraints/handcuffs/metal_cuffs = allocate(/obj/item/restraints/handcuffs, first_body)
	first_body.handcuffed = metal_cuffs
	first_body.update_handcuffed()
	first_body.update_mobility()
	var/obj/item/restraints/legcuffs/bola/bola = allocate(/obj/item/restraints/legcuffs/bola, second_body)
	second_body.legcuffed = bola
	second_body.update_inv_legcuffed()
	var/obj/item/restraints/handcuffs/cable/zipties/zipties = allocate(/obj/item/restraints/handcuffs/cable/zipties, second_body)
	second_body.handcuffed = zipties
	second_body.update_handcuffed()
	third_body.handcuffed = allocate(/obj/item/restraints/handcuffs, third_body)
	third_body.update_handcuffed()
	stranger.handcuffed = allocate(/obj/item/restraints/handcuffs, stranger)
	stranger.update_handcuffed()
	TEST_ASSERT(action.Trigger(), "Скованный брат рвёт оковы")
	TEST_ASSERT_NULL(first_body.handcuffed, "Свои наручники сорваны")
	TEST_ASSERT_NULL(second_body.legcuffed, "Бола с брата рядом сорвана")
	TEST_ASSERT_NULL(second_body.handcuffed, "Стяжки с брата рядом сорваны")
	TEST_ASSERT(!QDELETED(metal_cuffs) && metal_cuffs.loc == get_turf(first_body), "Металлические наручники падают на пол целыми")
	TEST_ASSERT(QDELETED(bola), "Бола рвётся")
	TEST_ASSERT(QDELETED(zipties), "Стяжки лопаются")
	TEST_ASSERT_NOTNULL(third_body.handcuffed, "Дальний брат остаётся в наручниках")
	TEST_ASSERT_NOTNULL(stranger.handcuffed, "С чужого оковы не рвутся")
	TEST_ASSERT(action.next_use_time > world.time, "Перезарядка пошла")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/blood_brothers/unshackle_flash) in get_turf(first_body), "Вспышка на месте сорванных оков")

/// Заслон переводит половину ушибов и ожогов подзащитного на брата, пока брат жив; яд не делится
/datum/unit_test/blood_brothers_capstone_bulwark

/datum/unit_test/blood_brothers_capstone_bulwark/Run()
	var/datum/team/brother_team/team = allocate_capstone_team(src, /datum/action/cooldown/blood_bond/capstone/bulwark)
	var/datum/mind/guard_mind = team.members[1]
	var/datum/mind/second = team.members[2]
	var/mob/living/carbon/human/guard = guard_mind.current
	var/turf/start = get_turf(guard)
	second.current.forceMove(locate(start.x + 3, start.y, start.z))
	var/mob/living/carbon/human/protected = allocate(/mob/living/carbon/human)
	protected.forceMove(get_step(guard, EAST))
	var/brute_mod = protected.physiology.brute_mod
	var/burn_mod = protected.physiology.burn_mod
	var/datum/action/cooldown/blood_bond/capstone/bulwark/action = capstone_action(team, 1, /datum/action/cooldown/blood_bond/capstone/bulwark)
	TEST_ASSERT(action.Trigger(), "Заслон поставлен")
	var/datum/status_effect/brother_bulwark/bulwark = guard.has_status_effect(/datum/status_effect/brother_bulwark)
	TEST_ASSERT_NOTNULL(bulwark, "Брат держит заслон")
	TEST_ASSERT_EQUAL(bulwark.protected, protected, "Прикрыт сосед")
	var/datum/beam/thread = bulwark.thread
	TEST_ASSERT_NOTNULL(thread, "Между братом и подзащитным тянется нить")
	TEST_ASSERT_EQUAL(thread.icon_state, "blood_thread", "Нить крови")
	TEST_ASSERT_EQUAL(thread.origin, guard, "Нить идёт от брата")
	TEST_ASSERT_EQUAL(thread.target, protected, "Нить идёт к подзащитному")
	protected.apply_damage(20, BRUTE)
	TEST_ASSERT(abs(protected.getBruteLoss() - 20 * BROTHER_BULWARK_SHARE) < 0.1, "Подзащитный получил свою долю ушибов: [protected.getBruteLoss()]")
	TEST_ASSERT(abs(guard.getBruteLoss() - 20 * (1 - BROTHER_BULWARK_SHARE)) < 0.1, "Брат принял остальное: [guard.getBruteLoss()]")
	protected.apply_damage(10, BURN)
	TEST_ASSERT(abs(protected.getFireLoss() - 10 * BROTHER_BULWARK_SHARE) < 0.1, "Ожоги тоже делятся: [protected.getFireLoss()]")
	TEST_ASSERT(abs(guard.getFireLoss() - 10 * (1 - BROTHER_BULWARK_SHARE)) < 0.1, "Брат принял ожоги: [guard.getFireLoss()]")
	protected.apply_damage(10, TOX)
	TEST_ASSERT(abs(guard.getToxLoss()) < 0.1, "Яд не делится")
	guard.death()
	TEST_ASSERT_NULL(guard.has_status_effect(/datum/status_effect/brother_bulwark), "Смерть брата снимает заслон")
	TEST_ASSERT(QDELETED(thread), "Нить гаснет вместе с заслоном")
	TEST_ASSERT(abs(protected.physiology.brute_mod - brute_mod) < 0.01, "Множитель ушибов вернулся")
	TEST_ASSERT(abs(protected.physiology.burn_mod - burn_mod) < 0.01, "Множитель ожогов вернулся")
	var/brute_before = protected.getBruteLoss()
	protected.apply_damage(20, BRUTE)
	TEST_ASSERT(abs(protected.getBruteLoss() - brute_before - 20) < 0.1, "Без заслона урон целиком")
	var/datum/action/cooldown/blood_bond/capstone/bulwark/bulwark_type = /datum/action/cooldown/blood_bond/capstone/bulwark
	TEST_ASSERT(findtext(initial(bulwark_type.desc), "[BROTHER_BULWARK_DURATION / (1 SECONDS)] секунд"), "Длительность в описании совпадает с дефайном")
	TEST_ASSERT(findtext(initial(bulwark_type.desc), "[BROTHER_BULWARK_RANGE] клеток"), "Дальность в описании совпадает с дефайном")

/// Доля Заслона ложится на брата мимо его стойкости и чужого заслона, взаимный Заслон делит урон без потерь, старый снимок не засчитывается
/datum/unit_test/blood_brothers_capstone_bulwark_forced

/datum/unit_test/blood_brothers_capstone_bulwark_forced/Run()
	var/datum/team/brother_team/team = allocate_capstone_team(src, /datum/action/cooldown/blood_bond/capstone/bulwark)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/mob/living/carbon/human/first_body = first.current
	var/mob/living/carbon/human/second_body = second.current
	second_body.forceMove(get_step(first_body, EAST))
	ADD_TRAIT(first_body, TRAIT_TOUGHT, "test")
	var/datum/action/cooldown/blood_bond/capstone/bulwark/first_action = capstone_action(team, 1, /datum/action/cooldown/blood_bond/capstone/bulwark)
	var/datum/action/cooldown/blood_bond/capstone/bulwark/second_action = capstone_action(team, 2, /datum/action/cooldown/blood_bond/capstone/bulwark)
	TEST_ASSERT(first_action.Trigger(), "Первый прикрывает второго")
	second_body.apply_damage(20, BRUTE)
	TEST_ASSERT(abs(first_body.getBruteLoss() - 20 * (1 - BROTHER_BULWARK_SHARE)) < 0.1, "Стойкость не переводит долю Заслона в усталость: [first_body.getBruteLoss()]")
	REMOVE_TRAIT(first_body, TRAIT_TOUGHT, "test")
	first_body.fully_heal()
	second_body.fully_heal()
	TEST_ASSERT(second_action.Trigger(), "Второй прикрывает первого в ответ")
	second_body.apply_damage(20, BRUTE)
	var/total = first_body.getBruteLoss() + second_body.getBruteLoss()
	TEST_ASSERT(abs(total - 20) < 0.1, "Взаимный Заслон делит урон без потерь: [first_body.getBruteLoss()] + [second_body.getBruteLoss()]")
	var/datum/status_effect/brother_bulwark/bulwark = first_body.has_status_effect(/datum/status_effect/brother_bulwark)
	var/guard_brute = first_body.getBruteLoss()
	second_body.apply_damage(20, BRUTE, blocked = 100)
	TEST_ASSERT_NOTNULL(bulwark.brute_before, "Предпосылка: удар без урона оставил снимок")
	var/hit_time = world.time
	sleep(1)
	TEST_ASSERT(world.time > hit_time, "Предпосылка: тик сменился")
	second_body.adjustBruteLoss(10)
	TEST_ASSERT(abs(first_body.getBruteLoss() - guard_brute) < 0.1, "Снимок прошлого тика не засчитывается: [first_body.getBruteLoss()]")

/// Удалённый брат снимает Заслон, и подзащитному возвращаются его множители
/datum/unit_test/blood_brothers_capstone_bulwark_guard_deleted

/datum/unit_test/blood_brothers_capstone_bulwark_guard_deleted/Run()
	var/datum/team/brother_team/team = allocate_capstone_team(src, /datum/action/cooldown/blood_bond/capstone/bulwark)
	var/datum/mind/guard_mind = team.members[1]
	var/mob/living/carbon/human/guard = guard_mind.current
	var/datum/mind/second = team.members[2]
	var/turf/start = get_turf(guard)
	second.current.forceMove(locate(start.x + 3, start.y, start.z))
	var/mob/living/carbon/human/protected = allocate(/mob/living/carbon/human)
	protected.forceMove(get_step(guard, EAST))
	var/brute_mod = protected.physiology.brute_mod
	var/datum/action/cooldown/blood_bond/capstone/bulwark/action = capstone_action(team, 1, /datum/action/cooldown/blood_bond/capstone/bulwark)
	TEST_ASSERT(action.Trigger(), "Заслон поставлен")
	TEST_ASSERT(HAS_TRAIT(protected, TRAIT_BROTHER_BULWARK), "Предпосылка: подзащитный под заслоном")
	qdel(guard)
	TEST_ASSERT(!HAS_TRAIT(protected, TRAIT_BROTHER_BULWARK), "Удалённый брат снимает заслон")
	TEST_ASSERT(abs(protected.physiology.brute_mod - brute_mod) < 0.01, "Множитель ушибов вернулся")

/// Метка крови обводит цель клятвы только для незаглушённых братьев и ведёт к ней Чутьё; без цели не тратится
/datum/unit_test/blood_brothers_capstone_mark

/datum/unit_test/blood_brothers_capstone_mark/Run()
	var/datum/team/brother_team/team = allocate_capstone_team(src, /datum/action/cooldown/blood_bond/capstone/mark, 3)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/mind/third = team.members[3]
	var/datum/action/cooldown/blood_bond/capstone/mark/action = capstone_action(team, 1, /datum/action/cooldown/blood_bond/capstone/mark)
	TEST_ASSERT(!action.Trigger(), "Без цели клятвы метить некого")
	TEST_ASSERT_EQUAL(action.next_use_time, 0, "Пустое нажатие не тратит перезарядку")
	var/datum/mind/victim = allocate_brother_mind(src)
	var/mob/living/carbon/human/victim_body = victim.current
	var/turf/start = get_turf(second.current)
	victim_body.forceMove(locate(start.x + 3, start.y, start.z))
	team.oath.target_mind = victim
	victim_body.death()
	TEST_ASSERT(!action.Trigger(), "Мёртвую цель не метят")
	TEST_ASSERT_EQUAL(action.next_use_time, 0, "Метка на труп не тратит перезарядку")
	victim_body.revive(full_heal = TRUE, admin_revive = TRUE)
	ADD_TRAIT(third.current, TRAIT_MINDSHIELD, "test")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	stranger.mind_initialize()
	TEST_ASSERT(action.Trigger(), "Метка поставлена")
	TEST_ASSERT(action.next_use_time > world.time, "Перезарядка пошла")
	var/datum/atom_hud/alternate_appearance/basic/blood_mark/mark
	for(var/key in victim_body.alternate_appearances)
		mark = victim_body.alternate_appearances[key]
		if(istype(mark))
			break
	TEST_ASSERT(istype(mark), "Обводка висит на цели")
	TEST_ASSERT(mark.hudusers[first.current], "Отметивший видит обводку")
	TEST_ASSERT(mark.hudusers[second.current], "Второй брат видит обводку")
	TEST_ASSERT(!mark.hudusers[third.current], "Заглушённый обводку не видит")
	TEST_ASSERT(!mark.mobShouldSee(stranger), "Чужим обводку не показывают")
	TEST_ASSERT(length(mark.theImage.filters), "На образе обводка")
	var/datum/status_effect/brother_sense/blood_mark/sense = second.current.has_status_effect(/datum/status_effect/brother_sense/blood_mark)
	TEST_ASSERT_NOTNULL(sense, "Чутьё ведёт к цели")
	TEST_ASSERT_EQUAL(sense.tracked, victim, "Чутьё следит за целью клятвы")
	TEST_ASSERT(findtext(sense.linked_alert.desc, "восток"), "Направление к цели словами: [sense.linked_alert.desc]")
	TEST_ASSERT_NOTNULL(second.current.has_status_effect(/datum/status_effect/brother_sense), "Чутьё на брата не сбито меткой")
	TEST_ASSERT_NULL(third.current.has_status_effect(/datum/status_effect/brother_sense/blood_mark), "Заглушённому метка не приходит")
	TEST_ASSERT_EQUAL(sense.linked_alert.color, BROTHER_MARK_COLOR, "Стрелка метки окрашена кровью")
	TEST_ASSERT_EQUAL(team.active_mark, mark, "Команда помнит свою метку")
	var/datum/antagonist/brother/second_brother = second.has_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT(second_brother.trigger_fury(force = TRUE, play_sound = FALSE), "Предпосылка: у второго горит Ярость")
	ADD_TRAIT(second.current, TRAIT_MINDSHIELD, "test")
	TEST_ASSERT(!mark.hudusers[second.current], "Глушение гасит обводку")
	TEST_ASSERT_NULL(second.current.has_status_effect(/datum/status_effect/brother_sense/blood_mark), "Глушение гасит Чутьё метки")
	TEST_ASSERT_NULL(second.current.has_status_effect(/datum/status_effect/brother_fury), "Глушение гасит Ярость")
	REMOVE_TRAIT(second.current, TRAIT_MINDSHIELD, "test")
	var/datum/antagonist/brother/first_brother = first.has_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT(first_brother.trigger_fury(force = TRUE, play_sound = FALSE), "Предпосылка: у первого горит Ярость")
	var/mob/living/carbon/human/first_body = first.current
	first.remove_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT(!mark.hudusers[first_body], "Снятая клятва гасит обводку")
	TEST_ASSERT_NULL(first_body.has_status_effect(/datum/status_effect/brother_fury), "Снятая клятва гасит Ярость")
	mark.expire()
	TEST_ASSERT(QDELETED(mark), "Метка гаснет")
	TEST_ASSERT_NULL(team.active_mark, "Погасшая метка забыта командой")
	for(var/key in victim_body.alternate_appearances)
		TEST_ASSERT(!istype(victim_body.alternate_appearances[key], /datum/atom_hud/alternate_appearance/basic/blood_mark), "Обводка снята с цели")
	var/datum/action/cooldown/blood_bond/capstone/mark/mark_type = /datum/action/cooldown/blood_bond/capstone/mark
	TEST_ASSERT(findtext(initial(mark_type.desc), "[BROTHER_MARK_DURATION / (1 SECONDS)] секунд"), "Длительность в описании совпадает с дефайном")

/// Глаза знаков смотрят через целый знак команды и возвращаются в тело от шага или пропажи знака
/datum/unit_test/blood_brothers_capstone_sign_eyes

/datum/unit_test/blood_brothers_capstone_sign_eyes/Run()
	var/datum/team/brother_team/team = allocate_capstone_team(src, /datum/action/cooldown/blood_bond/capstone/sign_eyes)
	var/datum/mind/first = team.members[1]
	var/mob/living/carbon/human/viewer = first.current
	var/datum/action/cooldown/blood_bond/capstone/sign_eyes/action = capstone_action(team, 1, /datum/action/cooldown/blood_bond/capstone/sign_eyes)
	TEST_ASSERT(!action.Trigger(), "Без знаков смотреть не через что")
	TEST_ASSERT_EQUAL(action.next_use_time, 0, "Пустое нажатие не тратит перезарядку")
	var/turf/start = get_turf(viewer)
	var/obj/effect/decal/cleanable/blood/brother_sign/sign = allocate(/obj/effect/decal/cleanable/blood/brother_sign, locate(start.x + 3, start.y + 3, start.z))
	sign.bind_team(team)
	TEST_ASSERT(action.Trigger(), "Взгляд через знак")
	TEST_ASSERT_EQUAL(action.viewed_sign, sign, "Смотрит через выбранный знак")
	TEST_ASSERT(action.next_use_time > world.time, "Перезарядка пошла")
	viewer.forceMove(get_step(viewer, NORTH))
	TEST_ASSERT_NULL(action.viewed_sign, "Шаг возвращает взгляд в тело")
	action.next_use_time = 0
	TEST_ASSERT(action.Trigger(), "Снова смотрит через знак")
	qdel(sign)
	TEST_ASSERT_NULL(action.viewed_sign, "Стёртый знак возвращает взгляд")
	var/obj/effect/decal/cleanable/blood/brother_sign/other_sign = allocate(/obj/effect/decal/cleanable/blood/brother_sign, locate(start.x + 1, start.y + 3, start.z))
	other_sign.bind_team(team)
	action.next_use_time = 0
	TEST_ASSERT(action.Trigger(), "Смотрит через другой знак")
	viewer.Knockdown(1 SECONDS)
	TEST_ASSERT_NULL(action.viewed_sign, "Падение с ног возвращает взгляд")
	viewer.SetKnockdown(0)
	action.next_use_time = 0
	TEST_ASSERT(action.Trigger(), "Снова смотрит после падения")
	viewer.adjustBruteLoss(5)
	TEST_ASSERT_NULL(action.viewed_sign, "Урон мимо apply_damage возвращает взгляд")
	action.next_use_time = 0
	TEST_ASSERT(action.Trigger(), "Снова смотрит после раны")
	ADD_TRAIT(viewer, TRAIT_MINDSHIELD, "test")
	TEST_ASSERT_NULL(action.viewed_sign, "Глушение возвращает взгляд")
	REMOVE_TRAIT(viewer, TRAIT_MINDSHIELD, "test")
	var/datum/action/cooldown/blood_bond/capstone/sign_eyes/eyes_type = /datum/action/cooldown/blood_bond/capstone/sign_eyes
	TEST_ASSERT(findtext(initial(eyes_type.desc), "[BROTHER_SIGN_EYES_DURATION / (1 SECONDS)] секунд"), "Длительность в описании совпадает с дефайном")

/// Глушь мигает и гасит свет зоны без поломки ламп и возвращает его; зону без ламп и уже гаснущую зону не трогает
/datum/unit_test/blood_brothers_capstone_blackout

/datum/unit_test/blood_brothers_capstone_blackout/Run()
	var/datum/team/brother_team/team = allocate_capstone_team(src, /datum/action/cooldown/blood_bond/capstone/blackout)
	var/datum/mind/first = team.members[1]
	var/mob/living/carbon/human/first_body = first.current
	heretic_test_area(get_turf(first_body), /area/blood_brothers_blackout_test)
	var/datum/action/cooldown/blood_bond/capstone/blackout/action = capstone_action(team, 1, /datum/action/cooldown/blood_bond/capstone/blackout)
	TEST_ASSERT(!action.Trigger(), "В зоне без ламп гасить нечего")
	TEST_ASSERT_EQUAL(action.next_use_time, 0, "Пустое нажатие не тратит перезарядку")
	var/turf/lamp_spot = get_step(first_body, NORTH)
	heretic_test_area(lamp_spot, /area/blood_brothers_blackout_test)
	var/obj/machinery/light/lamp = allocate(/obj/machinery/light, lamp_spot)
	var/turf/other_deck_spot = locate(2, 2, first_body.z == 1 ? 2 : 1)
	heretic_test_area(other_deck_spot, /area/blood_brothers_blackout_test)
	var/obj/machinery/light/other_deck_lamp = allocate(/obj/machinery/light, other_deck_spot)
	sleep(5)
	for(var/obj/machinery/light/each_lamp as anything in list(lamp, other_deck_lamp))
		each_lamp.status = LIGHT_OK
		each_lamp.on = TRUE
		each_lamp.update(trigger = FALSE, silent = TRUE)
	var/area/dark_area = get_area(lamp)
	TEST_ASSERT_EQUAL(get_area(other_deck_lamp), dark_area, "Предпосылка: лампа другой палубы в той же зоне")
	TEST_ASSERT(dark_area.lightswitch, "Предпосылка: выключатель зоны включён")
	TEST_ASSERT(action.Trigger(), "Глушь начата")
	TEST_ASSERT(action.next_use_time > world.time, "Перезарядка пошла")
	TEST_ASSERT(!lamp.on, "Первый миг гасит лампу")
	TEST_ASSERT(!dark_area.lightswitch, "Свет зоны выключен")
	var/datum/action/cooldown/blood_bond/capstone/blackout/second_action = capstone_action(team, 2, /datum/action/cooldown/blood_bond/capstone/blackout)
	TEST_ASSERT(!second_action.Trigger(), "Гаснущую зону второй раз не гасят")
	blood_bond_blackout_step(dark_area, 2)
	TEST_ASSERT(lamp.on, "Мерцание зажигает лампу")
	blood_bond_blackout_step(dark_area, BROTHER_BLACKOUT_FLICKERS + 1)
	TEST_ASSERT(!lamp.on, "После мерцания темно")
	TEST_ASSERT(other_deck_lamp.on, "Лампа на другой палубе не гаснет")
	TEST_ASSERT_EQUAL(lamp.status, LIGHT_OK, "Лампа цела")
	blood_bond_blackout_end(dark_area)
	TEST_ASSERT(lamp.on, "Свет вернулся")
	TEST_ASSERT(dark_area.lightswitch, "Выключатель зоны вернулся")
	TEST_ASSERT(!(dark_area in GLOB.blood_bond_blackouts), "Глушь закончилась")
	var/datum/action/cooldown/blood_bond/capstone/blackout/blackout_type = /datum/action/cooldown/blood_bond/capstone/blackout
	TEST_ASSERT(findtext(initial(blackout_type.desc), "мигает [BROTHER_BLACKOUT_FLICKER_TIME / (1 SECONDS)] секунды"), "Мерцание в описании совпадает с дефайном")
	TEST_ASSERT(findtext(initial(blackout_type.desc), "на [BROTHER_BLACKOUT_DURATION / (1 SECONDS)] секунд"), "Темнота в описании совпадает с дефайном")

/// Круг троих лечит каждого, пока все трое рядом, в сознании и 10 секунд не ранены; дальний или заглушённый брат и ступень ниже высшей рвут круг
/datum/unit_test/blood_brothers_capstone_circle

/datum/unit_test/blood_brothers_capstone_circle/Run()
	var/datum/team/brother_team/team = allocate_capstone_team(src, /datum/blood_bond_passive/circle, 3)
	var/datum/mind/first = team.members[1]
	var/datum/mind/third = team.members[3]
	var/mob/living/carbon/human/first_body = first.current
	var/mob/living/carbon/human/third_body = third.current
	first_body.adjustBruteLoss(20)
	first_body.adjustFireLoss(20)
	circle_pass(team)
	TEST_ASSERT(abs(first_body.getBruteLoss() - 20) < 0.1, "Только что сложившийся круг ещё не лечит: [first_body.getBruteLoss()]")
	team.circle_hit_at = world.time - BROTHER_CIRCLE_QUIET_TIME
	circle_pass(team)
	TEST_ASSERT(abs(first_body.getBruteLoss() - (20 - BROTHER_CIRCLE_HEAL)) < 0.1, "Круг лечит ушибы: [first_body.getBruteLoss()]")
	TEST_ASSERT(abs(first_body.getFireLoss() - (20 - BROTHER_CIRCLE_HEAL)) < 0.1, "Круг лечит ожоги: [first_body.getFireLoss()]")
	var/brute = first_body.getBruteLoss()
	third_body.apply_damage(5, BURN)
	circle_pass(team)
	TEST_ASSERT(abs(first_body.getBruteLoss() - brute) < 0.1, "Рана одного из троих останавливает круг")
	third_body.fully_heal()
	team.circle_hit_at = world.time - BROTHER_CIRCLE_QUIET_TIME
	third_body.adjustOxyLoss(150)
	TEST_ASSERT(third_body.InCritical(), "Предпосылка: третий при смерти")
	circle_pass(team)
	TEST_ASSERT(abs(first_body.getBruteLoss() - brute) < 0.1, "Брат при смерти останавливает круг")
	third_body.fully_heal()
	var/turf/start = get_turf(first_body)
	third_body.forceMove(locate(start.x + BROTHER_CIRCLE_RANGE + 1, start.y, start.z))
	team.circle_hit_at = world.time - BROTHER_CIRCLE_QUIET_TIME
	circle_pass(team)
	TEST_ASSERT(abs(first_body.getBruteLoss() - brute) < 0.1, "Дальний брат размыкает круг")
	third_body.forceMove(start)
	ADD_TRAIT(third_body, TRAIT_MINDSHIELD, "test")
	circle_pass(team)
	TEST_ASSERT(abs(first_body.getBruteLoss() - brute) < 0.1, "Заглушённый брат размыкает круг")
	REMOVE_TRAIT(third_body, TRAIT_MINDSHIELD, "test")
	team.set_bond_tier(BLOOD_BOND_TIER_MAX - 1)
	circle_pass(team)
	TEST_ASSERT(abs(first_body.getBruteLoss() - brute) < 0.1, "До третьей печати круга нет")
	TEST_ASSERT(!length(team.circle_watched), "Без венца круг не слушает раны")
	var/datum/blood_bond_passive/circle/circle_type = /datum/blood_bond_passive/circle
	TEST_ASSERT(findtext(initial(circle_type.desc), "[BROTHER_CIRCLE_RANGE] клеток"), "Дальность круга в описании совпадает с дефайном")
	TEST_ASSERT(findtext(initial(circle_type.desc), "по [BROTHER_CIRCLE_HEAL] единицы"), "Лечение круга в описании совпадает с дефайном")
	TEST_ASSERT(findtext(initial(circle_type.desc), "последние [BROTHER_CIRCLE_QUIET_TIME / (1 SECONDS)] секунд"), "Затишье круга в описании совпадает с дефайном")
	TEST_ASSERT(findtext(initial(circle_type.desc), "раз в [BROTHER_SENSE_INTERVAL / (1 SECONDS)] секунды"), "Частота круга в описании совпадает с дефайном")

/datum/unit_test/blood_brothers_capstone_circle/proc/circle_pass(datum/team/brother_team/team)
	team.next_sense_at = 0
	team.process()
