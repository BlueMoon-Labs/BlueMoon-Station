/proc/foam_spread_limits_cleanup(turf/centre, radius)
	for(var/obj/effect/particle_effect/foam/foam in range(radius, centre))
		qdel(foam)

/// Пена с остатком amount, но с истёкшим сроком больше не растекается и уходит в медленную фазу.
/datum/unit_test/foam_spread_stops_at_deadline/Run()
	var/turf/source_turf = run_loc_floor_bottom_left
	source_turf.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(length(source_turf.atmos_adjacent_turfs), "Нужны открытые соседние клетки")
	var/obj/effect/particle_effect/foam/short_life/unit_test_spread/foam = allocate(/obj/effect/particle_effect/foam/short_life/unit_test_spread, source_turf)
	foam.set_spread_amount(5)
	TEST_ASSERT(foam.spread_deadline > world.time, "Свежая пена должна получить срок разлива в будущем")
	foam.lifetime = 40
	foam.spread_deadline = world.time - 1
	foam.process()
	for(var/turf/neighbor as anything in source_turf.atmos_adjacent_turfs)
		TEST_ASSERT_NULL(locate(/obj/effect/particle_effect/foam) in neighbor, "Пена с истёкшим сроком растеклась на [neighbor.x],[neighbor.y]")
	TEST_ASSERT(foam.slow_processing, "Пена с истёкшим сроком должна перейти в медленную фазу")

/// Потомки наследуют срок разлива источника, а не заводят свой.
/datum/unit_test/foam_children_inherit_spread_deadline/Run()
	var/turf/source_turf = run_loc_floor_bottom_left
	source_turf.ImmediateCalculateAdjacentTurfs()
	var/obj/effect/particle_effect/foam/short_life/unit_test_spread/foam = allocate(/obj/effect/particle_effect/foam/short_life/unit_test_spread, source_turf)
	foam.set_spread_amount(3)
	foam.spread_deadline = world.time + 7
	foam.spread_foam()
	var/children = 0
	for(var/turf/neighbor as anything in source_turf.atmos_adjacent_turfs)
		var/obj/effect/particle_effect/foam/child = locate() in neighbor
		if(!child)
			continue
		children++
		allocated += child
		TEST_ASSERT_EQUAL(child.spread_deadline, foam.spread_deadline, "Потомок завёл свой срок разлива")
	TEST_ASSERT(children, "Пена не растеклась ни на одну соседнюю клетку")

/// Через дыру в полу пена стекает на этаж ниже, но из-под дыры наверх не поднимается.
/datum/unit_test/foam_flows_down_through_hole_only/Run()
	var/list/levels = multiz_gravity_test_levels()
	var/turf/floor = multiz_gravity_test_turf(50, 10, levels[1], /turf/open/floor/plating)
	var/turf/hole = multiz_gravity_test_turf(50, 10, levels[2], /turf/open/openspace)
	floor.ImmediateCalculateAdjacentTurfs()
	hole.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(floor in hole.atmos_adjacent_turfs, "Дыра не связана с клеткой под ней")

	var/obj/effect/particle_effect/foam/short_life/unit_test_spread/below = allocate(/obj/effect/particle_effect/foam/short_life/unit_test_spread, floor)
	below.set_spread_amount(3)
	below.spread_foam()
	TEST_ASSERT_NULL(locate(/obj/effect/particle_effect/foam) in hole, "Пена поднялась в дыру над собой")
	foam_spread_limits_cleanup(floor, 1)

	var/obj/effect/particle_effect/foam/short_life/unit_test_spread/above = allocate(/obj/effect/particle_effect/foam/short_life/unit_test_spread, hole)
	above.set_spread_amount(3)
	above.spread_foam()
	TEST_ASSERT_NOTNULL(locate(/obj/effect/particle_effect/foam) in floor, "Пена из дыры не стекла на этаж ниже")
	foam_spread_limits_cleanup(floor, 1)
	foam_spread_limits_cleanup(hole, 1)

/// Лужа, в которой прошла реакция пены, отдаёт реагенты в пену и не остаётся источником новой.
/datum/unit_test/foam_reaction_consumes_puddle/Run()
	var/turf/open/spot = run_loc_floor_bottom_left
	spot.add_liquid(/datum/reagent/fluorosurfactant, 30, TRUE)
	spot.add_liquid(/datum/reagent/water, 30)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/particle_effect/foam) in spot, "Фторсурфактант с водой в луже не дали пену")
	TEST_ASSERT(!spot.liquids || !spot.liquids.reagent_list[/datum/reagent/fluorosurfactant], "Лужа сохранила фторсурфактант после реакции")
	foam_spread_limits_cleanup(spot, 1)

	spot.add_liquid(/datum/reagent/water, 30)
	TEST_ASSERT_NULL(locate(/obj/effect/particle_effect/foam) in spot, "Повторный подлив воды снова дал пену")
	if(spot.liquids)
		qdel(spot.liquids, TRUE)
