#define POOL_TILE_TEST_STACK 10
#define POOL_TILE_TEST_WAIT_SLACK (2 SECONDS)

/// Плитка бассейна кладётся с прогресс-баром и не ложится под чужие ноги, обычная плитка остаётся мгновенной.
/datum/unit_test/pool_tile_placement
	/// Клетки резервации, перестеленные тестом, и их исходные типы: уборка тестов турфы не возвращает.
	var/list/changed_turfs = list()

/datum/unit_test/pool_tile_placement/Destroy()
	for(var/turf/spot as anything in changed_turfs)
		spot.ChangeTurf(changed_turfs[spot])
	return ..()

/datum/unit_test/pool_tile_placement/proc/spot_at(offset_x, offset_y)
	return locate(run_loc_floor_bottom_left.x + offset_x, run_loc_floor_bottom_left.y + offset_y, run_loc_floor_bottom_left.z)

/datum/unit_test/pool_tile_placement/proc/make_plating(offset_x, offset_y)
	var/turf/spot = spot_at(offset_x, offset_y)
	if(!changed_turfs[spot])
		changed_turfs[spot] = spot.type
	return spot.ChangeTurf(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)

/datum/unit_test/pool_tile_placement/proc/wait_for_timed_actions(mob/living/builder)
	var/deadline = world.time + SUNKEN_TILE_WORK_TIME + POOL_TILE_TEST_WAIT_SLACK
	while(LAZYLEN(builder.do_afters) && world.time < deadline)
		sleep(world.tick_lag)

/datum/unit_test/pool_tile_placement/proc/check_timed_placement(mob/living/carbon/human/builder, obj/item/stack/tile/tiles)
	make_plating(3, 2)
	var/starting_amount = tiles.amount
	INVOKE_ASYNC(spot_at(3, 2), TYPE_PROC_REF(/atom, attackby), tiles, builder)

	var/turf/during = spot_at(3, 2)
	TEST_ASSERT(istype(during, /turf/open/floor/plating), "плитка бассейна легла мгновенно, турф стал [during.type]")
	TEST_ASSERT_EQUAL(tiles.amount, starting_amount, "плитка бассейна потрачена до конца прогресс-бара")
	TEST_ASSERT(LAZYLEN(builder.do_afters), "укладка плитки бассейна идёт без прогресс-бара")

	wait_for_timed_actions(builder)
	var/turf/after = spot_at(3, 2)
	TEST_ASSERT(istype(after, /turf/open/pool/pool_floor), "плитка бассейна не легла после прогресс-бара, турф [after.type]")
	TEST_ASSERT_EQUAL(tiles.amount, starting_amount - 1, "укладка плитки бассейна потратила не ровно одну плитку")

/datum/unit_test/pool_tile_placement/proc/check_builder_step_interrupts(mob/living/carbon/human/builder, obj/item/stack/tile/tiles)
	make_plating(1, 2)
	var/starting_amount = tiles.amount
	var/turf/builder_spot = builder.loc
	INVOKE_ASYNC(spot_at(1, 2), TYPE_PROC_REF(/atom, attackby), tiles, builder)
	builder.forceMove(spot_at(2, 3))
	wait_for_timed_actions(builder)
	builder.forceMove(builder_spot)

	var/turf/after = spot_at(1, 2)
	TEST_ASSERT(istype(after, /turf/open/floor/plating), "шаг строителя не сорвал укладку плитки бассейна, турф стал [after.type]")
	TEST_ASSERT_EQUAL(tiles.amount, starting_amount, "сорванная укладка потратила плитку бассейна")

/datum/unit_test/pool_tile_placement/proc/check_occupied_floor_refused(mob/living/carbon/human/builder, obj/item/stack/tile/tiles)
	var/turf/plating = make_plating(2, 1)
	var/turf/open/floor/floor = plating.PlaceOnTop(/turf/open/floor/plasteel, flags = CHANGETURF_INHERIT_AIR)
	TEST_ASSERT(floor.turf_flags & TURF_INTACT, "предусловие: под жертвой нужен целый пол поверх плейтинга, а не [floor.type]")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, floor)
	var/obj/item/crowbar/crowbar = allocate(/obj/item/crowbar, builder.loc)
	TEST_ASSERT(builder.put_in_inactive_hand(crowbar), "предусловие: лом не удалось вложить во вторую руку")
	var/starting_amount = tiles.amount

	floor.attackby(tiles, builder)
	var/started_timed_action = LAZYLEN(builder.do_afters)
	builder.dropItemToGround(crowbar, force = TRUE)

	var/turf/after = spot_at(2, 1)
	TEST_ASSERT(istype(after, /turf/open/floor/plating), "под стоящим [victim] вместо снятого пола оказался [after.type]")
	TEST_ASSERT_EQUAL(tiles.amount, starting_amount, "отказ в укладке под стоящим потратил плитку бассейна")
	TEST_ASSERT(!started_timed_action, "отказ в укладке под стоящим всё равно запустил прогресс-бар")

/datum/unit_test/pool_tile_placement/proc/check_step_in_during_placement(mob/living/carbon/human/builder, obj/item/stack/tile/tiles)
	make_plating(3, 3)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, spot_at(4, 4))
	var/starting_amount = tiles.amount
	INVOKE_ASYNC(spot_at(3, 3), TYPE_PROC_REF(/atom, attackby), tiles, builder)
	victim.forceMove(spot_at(3, 3))
	wait_for_timed_actions(builder)

	var/turf/after = spot_at(3, 3)
	TEST_ASSERT(!istype(after, /turf/open/pool), "плитку бассейна уложили под [victim], вставшего на клетку во время укладки")
	TEST_ASSERT_EQUAL(tiles.amount, starting_amount, "укладка под вставшего на клетку потратила плитку бассейна")

/datum/unit_test/pool_tile_placement/proc/check_plain_tile_instant(mob/living/carbon/human/mason)
	var/turf/spot = make_plating(1, 1)
	allocate(/mob/living/carbon/human, spot)
	var/obj/item/stack/tile/plasteel/plain = allocate(/obj/item/stack/tile/plasteel, mason.loc, POOL_TILE_TEST_STACK)
	TEST_ASSERT(mason.put_in_active_hand(plain, forced = TRUE), "предусловие: обычную плитку не удалось вложить в руку")

	spot.attackby(plain, mason)

	var/turf/after = spot_at(1, 1)
	TEST_ASSERT(istype(after, /turf/open/floor/plasteel), "обычная плитка не легла сразу, турф [after.type]")
	TEST_ASSERT_EQUAL(plain.amount, POOL_TILE_TEST_STACK - 1, "обычная плитка потрачена не ровно один раз")
	TEST_ASSERT(!LAZYLEN(mason.do_afters), "обычная плитка запустила прогресс-бар")

/datum/unit_test/pool_tile_placement/proc/check_self_placement(mob/living/carbon/human/builder, obj/item/stack/tile/tiles)
	var/turf/spot = make_plating(2, 2)
	TEST_ASSERT_EQUAL(builder.loc, spot, "предусловие: строитель обязан стоять на клетке укладки")
	var/starting_amount = tiles.amount
	spot.attackby(tiles, builder)

	var/turf/after = spot_at(2, 2)
	TEST_ASSERT(istype(after, /turf/open/pool/pool_floor), "строитель не смог уложить плитку бассейна под себя, турф [after.type]")
	TEST_ASSERT_EQUAL(tiles.amount, starting_amount - 1, "укладка под себя потратила не ровно одну плитку")

/datum/unit_test/pool_tile_placement/Run()
	var/mob/living/carbon/human/builder = allocate(/mob/living/carbon/human, spot_at(2, 2))
	builder.a_intent = INTENT_HELP
	var/obj/item/stack/tile/plasteel/pool/tiles = allocate(/obj/item/stack/tile/plasteel/pool, builder.loc, POOL_TILE_TEST_STACK)
	TEST_ASSERT(builder.put_in_active_hand(tiles, forced = TRUE), "предусловие: плитку бассейна не удалось вложить в руку")
	var/mob/living/carbon/human/mason = allocate(/mob/living/carbon/human, spot_at(0, 0))

	check_timed_placement(builder, tiles)
	check_builder_step_interrupts(builder, tiles)
	check_occupied_floor_refused(builder, tiles)
	check_step_in_during_placement(builder, tiles)
	check_plain_tile_instant(mason)
	check_self_placement(builder, tiles)

#undef POOL_TILE_TEST_STACK
#undef POOL_TILE_TEST_WAIT_SLACK
