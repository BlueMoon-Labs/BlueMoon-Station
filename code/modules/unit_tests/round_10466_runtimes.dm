/// Телепорт вендиго находит точку у цели и в тёмной пещере, где view() от турфа не видит пол.
/datum/unit_test/wendigo_teleport_in_darkness
	var/area/darkened_area
	var/darkened_area_luminosity
	var/list/darkened_turfs = list()

/datum/unit_test/wendigo_teleport_in_darkness/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/turf/start = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/megafauna/wendigo/wendigo = allocate(/mob/living/simple_animal/hostile/megafauna/wendigo, start)
	wendigo.target = victim
	darkened_area = get_area(run_loc_floor_bottom_left)
	darkened_area_luminosity = darkened_area.luminosity
	darkened_area.luminosity = 0
	for(var/turf/dark_turf as anything in RANGE_TURFS(5, run_loc_floor_bottom_left))
		darkened_turfs[dark_turf] = dark_turf.luminosity
		dark_turf.luminosity = 0

	wendigo.teleport()

	TEST_ASSERT_EQUAL(get_dist(wendigo, victim), 4, "Вендиго должен прыгнуть на кольцо в 4 тайла от цели")

/datum/unit_test/wendigo_teleport_in_darkness/Destroy()
	if(darkened_area)
		darkened_area.luminosity = darkened_area_luminosity
	for(var/turf/dark_turf as anything in darkened_turfs)
		dark_turf.luminosity = darkened_turfs[dark_turf]
	darkened_turfs = null
	darkened_area = null
	return ..()

/// Щит, разбитый во время активного блока, снимает блок с владельца.
/datum/unit_test/shattered_shield_ends_active_block/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/obj/item/shield/riot/pointman/shield = allocate(/obj/item/shield/riot/pointman)
	holder.put_in_active_hand(shield)
	TEST_ASSERT(holder.active_block_start(shield), "test premise: блок щитом должен начаться")

	qdel(shield)

	TEST_ASSERT_NULL(holder.active_block_item, "Удалённый щит не должен оставаться предметом активного блока")
	TEST_ASSERT(!(holder.combat_flags & COMBAT_FLAG_ACTIVE_BLOCKING), "Активный блок должен закончиться вместе со щитом")

/// Второй удар парными когтями не бьёт цель, удалённую первым ударом.
/datum/unit_test/ambidextria_second_strike_skips_deleted_target/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/kitchen/knife/claws/natural/first_claw = allocate(/obj/item/kitchen/knife/claws/natural)
	var/obj/item/kitchen/knife/claws/natural/second_claw = allocate(/obj/item/kitchen/knife/claws/natural)
	user.put_in_active_hand(first_claw)
	user.put_in_inactive_hand(second_claw)
	user.a_intent = INTENT_HARM
	var/mob/living/simple_animal/mouse/mouse = allocate(/mob/living/simple_animal/mouse, get_step(run_loc_floor_bottom_left, EAST))

	first_claw.attack(mouse, user)
	TEST_ASSERT(QDELETED(mouse), "test premise: первый удар должен убить и удалить мышь")
	sleep(0.5 SECONDS)

	TEST_ASSERT(!LAZYLEN(user.do_afters), "Второй удар не должен начинать разделку удалённой цели")

/// Снятие модуля, который киборг держит в слоте, освобождает слот.
/datum/unit_test/borg_remove_held_module/Run()
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot)
	borg.set_hud_used(new borg.hud_type(borg))
	var/obj/item/robot_module/module = borg.module
	var/obj/item/dogborg_nose/tool = new(module)
	module.basic_modules += tool
	module.rebuild_modules()
	TEST_ASSERT(borg.activate_module(tool), "test premise: киборг должен взять инструмент модуля")

	module.remove_module(tool, TRUE)

	TEST_ASSERT(!(tool in borg.held_items), "Снятый модуль не должен оставаться в слоте киборга")
