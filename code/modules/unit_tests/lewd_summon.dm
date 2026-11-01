/// Руна, на которой призываемый в теле и ответил «да»: окно согласия в тесте не нажать.
/obj/effect/summon_rune/consenting

/obj/effect/summon_rune/consenting/ask_summon_consent(mob/living/summoner, mob/living/carbon/human/target)
	return TRUE

/datum/unit_test/proc/make_summon_target(turf/where)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, where)
	ADD_TRAIT(target, TRAIT_LEWD_SUMMON, TRAIT_GENERIC)
	target.equip_to_slot_or_del(new /obj/item/storage/backpack(target), ITEM_SLOT_BACK)
	return target

/// Репорт: агостнувшегося призывали без согласия. Тело без игрока не уходит на руну.
/datum/unit_test/lewd_summon_needs_player_in_body/Run()
	var/obj/effect/summon_rune/rune = allocate(/obj/effect/summon_rune, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/summoner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/target = make_summon_target(run_loc_floor_top_right)
	TEST_ASSERT(!rune.can_be_summoned(target), "Тело без игрока не должно попадать в список призыва")

	TEST_ASSERT(!rune.try_summon(summoner, target), "Призыв тела без игрока должен сорваться")
	TEST_ASSERT_EQUAL(get_turf(target), run_loc_floor_top_right, "Тело без игрока ушло на руну без согласия")
	TEST_ASSERT(!HAS_TRAIT(target, TRAIT_LEWD_SUMMONED), "Тело без игрока помечено призванным")
	TEST_ASSERT(!QDELETED(rune), "Сорванный призыв не должен тратить руну")

/// Репорт: при возврате пропадали снятые вещи. Всё своё возвращается с хозяином, чужое остаётся у призывателя.
/datum/unit_test/lewd_summon_returns_owner_items/Run()
	var/obj/effect/summon_rune/consenting/rune = allocate(/obj/effect/summon_rune/consenting, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/summoner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/target = make_summon_target(run_loc_floor_top_right)
	var/obj/item/backpack = target.back
	var/obj/item/clothing/under/color/grey/uniform = new(target)
	target.equip_to_slot_or_del(uniform, ITEM_SLOT_ICLOTHING)
	var/obj/item/clothing/suit/wizrobe/robe = new(target)
	target.equip_to_slot_or_del(robe, ITEM_SLOT_OCLOTHING)
	var/obj/item/clothing/gloves/color/black/gloves = new(target)
	target.equip_to_slot_or_del(gloves, ITEM_SLOT_GLOVES)
	var/obj/item/storage/box/box = new(run_loc_floor_top_right)
	var/obj/item/pen/hidden = new(box)
	target.put_in_hands(box)
	TEST_ASSERT(target.wear_suit == robe && target.gloves == gloves && target.is_holding(box), "Санити: снаряжение не надето")

	TEST_ASSERT(rune.try_summon(summoner, target), "Санити: призыв с согласием должен пройти")
	TEST_ASSERT_EQUAL(get_turf(target), run_loc_floor_bottom_left, "Санити: призванный не на руне")
	var/obj/effect/summon_rune/return_rune/return_rune = locate() in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(return_rune, "Санити: после призыва нет руны возврата")
	TEST_ASSERT_EQUAL(backpack.loc, return_rune, "Рюкзак призванного должен ждать в руне возврата")

	target.dropItemToGround(gloves)
	target.dropItemToGround(robe)
	summoner.put_in_hands(robe)
	hidden.forceMove(run_loc_floor_bottom_left)
	target.put_in_hands(hidden)
	var/obj/item/paper/borrowed = new(run_loc_floor_bottom_left)
	target.equip_to_slot_if_possible(borrowed, ITEM_SLOT_LPOCKET)
	TEST_ASSERT_EQUAL(target.l_store, borrowed, "Санити: чужая вещь не легла в карман")

	return_rune.attack_hand(target)

	TEST_ASSERT_EQUAL(get_turf(target), run_loc_floor_top_right, "Призванный не вернулся домой")
	TEST_ASSERT(QDELETED(return_rune), "Руна возврата должна исчезнуть")
	TEST_ASSERT(!HAS_TRAIT(target, TRAIT_LEWD_SUMMONED), "Вернувшийся остался призванным")
	for(var/obj/item/owned as anything in list(backpack, uniform, robe, gloves, box, hidden))
		TEST_ASSERT(!QDELETED(owned), "[owned.type] удалился при возврате")
		TEST_ASSERT_EQUAL(get_turf(owned), run_loc_floor_top_right, "[owned.type] не вернулся с хозяином")
	TEST_ASSERT(!summoner.is_holding(robe), "Роба осталась в руке призывателя")
	TEST_ASSERT_EQUAL(hidden.loc, target, "Вынутая из своей коробки вещь должна остаться в руке хозяина")
	TEST_ASSERT_EQUAL(get_turf(borrowed), run_loc_floor_bottom_left, "Взятое у призывателя должно остаться у него")

/// Призванный пропал (гиб, крио): отобранный рюкзак не удаляется вместе с руной, а ложится на место отправки.
/datum/unit_test/lewd_summon_lost_returner_keeps_stash/Run()
	var/obj/effect/summon_rune/consenting/rune = allocate(/obj/effect/summon_rune/consenting, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/summoner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/target = make_summon_target(run_loc_floor_top_right)
	var/obj/item/backpack = target.back
	TEST_ASSERT(rune.try_summon(summoner, target), "Санити: призыв с согласием должен пройти")
	var/obj/effect/summon_rune/return_rune/return_rune = locate() in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(return_rune, "Санити: после призыва нет руны возврата")

	qdel(target)
	return_rune.process()

	TEST_ASSERT(QDELETED(return_rune), "Руна без призванного должна исчезнуть")
	TEST_ASSERT(!QDELETED(backpack), "Рюкзак призванного удалился вместе с руной")
	TEST_ASSERT_EQUAL(get_turf(backpack), run_loc_floor_top_right, "Рюкзак должен лечь на место отправки")

/// Комната инфинити ушла в сток вместе с руной: руна отпускает призванного домой, а не тянет в подсобку.
/datum/unit_test/lewd_summon_stored_rune_sends_home/Run()
	var/obj/effect/summon_rune/consenting/rune = allocate(/obj/effect/summon_rune/consenting, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/summoner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/target = make_summon_target(run_loc_floor_top_right)
	var/obj/item/backpack = target.back
	TEST_ASSERT(rune.try_summon(summoner, target), "Санити: призыв с согласием должен пройти")
	var/obj/effect/summon_rune/return_rune/return_rune = locate() in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(return_rune, "Санити: после призыва нет руны возврата")

	var/obj/item/abstracthotelstorage/storage = allocate(/obj/item/abstracthotelstorage, run_loc_floor_bottom_left)
	return_rune.forceMove(storage)
	target.forceMove(locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	return_rune.process()

	TEST_ASSERT_EQUAL(get_turf(target), run_loc_floor_top_right, "Руна из стока утащила призванного к себе")
	TEST_ASSERT(QDELETED(return_rune), "Руна из стока должна исчезнуть")
	TEST_ASSERT(!HAS_TRAIT(target, TRAIT_LEWD_SUMMONED), "Отпущенный домой остался призванным")
	TEST_ASSERT_EQUAL(get_turf(backpack), run_loc_floor_top_right, "Рюкзак должен вернуться с хозяином")
