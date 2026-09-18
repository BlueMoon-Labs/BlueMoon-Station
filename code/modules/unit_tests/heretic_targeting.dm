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
