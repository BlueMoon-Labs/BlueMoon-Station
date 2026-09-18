/// Промах по полу, стене или предмету рядом с противником находит самого противника.
/datum/unit_test/heretic_aim_assist_mob/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	knowledge.combat_resource = 1
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blade_lunge)
	var/obj/effect/proc_holder/spell/pointed/heretic_lunge/lunge = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lunge)
	lunge.selection_type = "range"
	var/turf/attacker_turf = get_step(get_step(get_step(user, EAST), EAST), EAST)
	attacker.forceMove(attacker_turf)
	var/turf/near_floor = get_step(attacker_turf, NORTH)
	var/obj/item/pen/litter = allocate(/obj/item/pen, attacker_turf)
	TEST_ASSERT_EQUAL(lunge.assisted_target(user, near_floor), attacker, "Клик по полу рядом с противником наводит выпад на него.")
	TEST_ASSERT_EQUAL(lunge.assisted_target(user, litter), attacker, "Клик по предмету под противником наводит выпад на него.")
	TEST_ASSERT_EQUAL(lunge.assisted_target(user, attacker), attacker, "Прямой клик по противнику не меняется.")
	var/turf/far_floor = get_step(get_step(user, NORTH), NORTH)
	TEST_ASSERT_EQUAL(lunge.assisted_target(user, far_floor), far_floor, "Без противника рядом клик остаётся прежним и даёт обычный отказ.")
	lunge.cast(list(lunge.assisted_target(user, near_floor)), user)
	TEST_ASSERT(user.Adjacent(attacker), "Выпад по наведённой цели сближает с противником.")

/// Способности по клетке принимают клик по предмету или мобу как клик по его клетке.
/datum/unit_test/heretic_aim_assist_turf/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/obj/effect/proc_holder/spell/pointed/heretic_moon/create/create = allocate(/obj/effect/proc_holder/spell/pointed/heretic_moon/create)
	create.selection_type = "range"
	var/turf/target_turf = get_step(user, EAST)
	var/obj/item/pen/litter = allocate(/obj/item/pen, target_turf)
	TEST_ASSERT_EQUAL(create.assisted_target(user, litter), target_turf, "Клик по предмету на полу ставит отражение на эту клетку.")
	var/obj/effect/proc_holder/spell/pointed/heretic_lunge/lunge = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lunge)
	TEST_ASSERT_EQUAL(lunge.assisted_target(user, litter), litter, "Способность без мобов рядом и без наведения по клетке оставляет клик прежним.")

/// Клик еретика на «помощи» сразу после хватки не поднимает цель, а чужая помощь работает.
/datum/unit_test/heretic_grasp_hold_blocks_own_help/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(victim, user, TRUE)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_grasp_hold), "Хватка удерживает сбитую цель.")
	var/knockdown_before = victim.AmountKnockdown()
	victim.help_shake_act(user)
	TEST_ASSERT_EQUAL(victim.AmountKnockdown(), knockdown_before, "Помощь самого еретика не снимает падение от хватки.")
	victim.help_shake_act(bystander)
	TEST_ASSERT(victim.AmountKnockdown() < knockdown_before, "Помощь другого человека поднимает цель как обычно.")
	fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(victim, user, TRUE)
	victim.remove_status_effect(/datum/status_effect/heretic_grasp_hold)
	knockdown_before = victim.AmountKnockdown()
	victim.help_shake_act(user)
	TEST_ASSERT(victim.AmountKnockdown() < knockdown_before, "После окончания удержания помощь еретика снова работает.")
