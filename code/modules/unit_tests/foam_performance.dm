/obj/effect/particle_effect/foam/short_life/unit_test_spread
	var/turf/remove_neighbor_on_hit
	var/mob_hits = 0

/obj/effect/particle_effect/foam/short_life/unit_test_spread/Initialize(mapload)
	. = ..()
	STOP_PROCESSING(SSfastprocess, src)

/obj/effect/particle_effect/foam/short_life/unit_test_spread/foam_mob(mob/living/target, tick_multiplier = 1)
	mob_hits++
	if(remove_neighbor_on_hit)
		var/turf/source_turf = get_turf(src)
		source_turf.atmos_adjacent_turfs -= remove_neighbor_on_hit
		remove_neighbor_on_hit = null
	return ..()

/// Пена повторно проверяет открывшийся проход и освободившуюся клетку, сохраняя состав потомков.
/datum/unit_test/foam_spread_rechecks_neighbors/Run()
	var/turf/source_turf = run_loc_floor_bottom_left
	var/turf/door_turf = get_step(source_turf, NORTH)
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, door_turf)
	door.density = TRUE
	door.air_update_turf(TRUE)
	source_turf.ImmediateCalculateAdjacentTurfs()
	var/obj/effect/particle_effect/foam/short_life/unit_test_spread/source = allocate(/obj/effect/particle_effect/foam/short_life/unit_test_spread, source_turf)
	source.reagents.add_reagent(/datum/reagent/consumable/sugar, 14)
	source.amount = 3
	source.add_atom_colour("#4499cc", FIXED_COLOUR_PRIORITY)
	var/original_lifetime = source.lifetime
	var/list/original_adjacency = source_turf.atmos_adjacent_turfs
	TEST_ASSERT(!(door_turf in original_adjacency), "Закрытая дверь должна перекрыть соседство")
	TEST_ASSERT(length(original_adjacency) >= 2, "Нужны открытые соседние клетки")
	source.spread_foam()
	TEST_ASSERT_NULL(locate(/obj/effect/particle_effect/foam) in door_turf, "Пена не должна проходить закрытую дверь")
	TEST_ASSERT_EQUAL(source_turf.atmos_adjacent_turfs, original_adjacency, "Распространение не должно подменять список соседства турфа")
	for(var/turf/neighbor as anything in original_adjacency)
		var/obj/effect/particle_effect/foam/child = locate() in neighbor
		TEST_ASSERT_NOTNULL(child, "Открытая соседняя клетка должна получить пену")
		TEST_ASSERT_EQUAL(child.type, source.type, "Потомок должен сохранить тип пены")
		TEST_ASSERT_EQUAL(child.amount, source.amount, "Потомок должен сохранить оставшееся распространение")
		TEST_ASSERT(abs(child.reagents.get_reagent_amount(/datum/reagent/consumable/sugar) - 14) < 0.001, "Потомок должен получить прежнюю дозу химии")
		TEST_ASSERT_EQUAL(child.color, source.color, "Потомок должен сохранить цвет")
		TEST_ASSERT_EQUAL(child.lifetime, initial(child.lifetime), "Новая частица должна получить полный срок жизни")
	TEST_ASSERT_EQUAL(source.lifetime, original_lifetime, "Распространение без мобов не должно менять срок жизни")

	door.density = FALSE
	door.air_update_turf(TRUE)
	source.spread_foam()
	var/obj/effect/particle_effect/foam/door_foam = locate() in door_turf
	TEST_ASSERT_NOTNULL(door_foam, "Следующая попытка должна пройти открытую дверь")
	qdel(door_foam)
	source.spread_foam()
	var/obj/effect/particle_effect/foam/replacement = locate() in door_turf
	TEST_ASSERT_NOTNULL(replacement, "Пена должна снова занять освободившуюся клетку")
	TEST_ASSERT_NOTEQUAL(replacement, door_foam, "В освободившейся клетке нужна новая частица")
	source.moveToNullspace()
	TEST_ASSERT_NULL(get_turf(source), "Проба должна убрать источник пены с карты")
	source.spread_foam()

/// Изменение соседства при контакте с мобом не меняет уже начатую волну и не удваивает контакт.
/datum/unit_test/foam_spread_keeps_reaction_snapshot
	var/turf/source_turf
	var/list/saved_adjacency

/datum/unit_test/foam_spread_keeps_reaction_snapshot/Destroy()
	if(source_turf && saved_adjacency)
		source_turf.atmos_adjacent_turfs = saved_adjacency
	source_turf = null
	saved_adjacency = null
	return ..()

/datum/unit_test/foam_spread_keeps_reaction_snapshot/Run()
	source_turf = run_loc_floor_bottom_left
	source_turf.ImmediateCalculateAdjacentTurfs()
	saved_adjacency = source_turf.atmos_adjacent_turfs.Copy()
	TEST_ASSERT(length(saved_adjacency) >= 2, "Нужны две открытые соседние клетки")
	var/turf/first_target = saved_adjacency[1]
	var/turf/removed_target = saved_adjacency[2]
	var/obj/effect/particle_effect/foam/short_life/unit_test_spread/source = allocate(/obj/effect/particle_effect/foam/short_life/unit_test_spread, source_turf)
	allocate(/mob/living, first_target)
	source.remove_neighbor_on_hit = removed_target
	source.spread_foam()
	TEST_ASSERT_EQUAL(source.mob_hits, 1, "Моб должен получить ровно один контакт при распространении")
	TEST_ASSERT(!(removed_target in source_turf.atmos_adjacent_turfs), "Проба должна изменить исходный список соседей")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/particle_effect/foam) in removed_target, "Начатый обход должен закончиться по снимку соседей до реакции")

#ifdef FOAM_SPREAD_BENCHMARK

/obj/effect/particle_effect/foam/short_life/unit_test_spread/proc/legacy_spread_foam()
	var/turf/source_turf = get_turf(src)
	if(!source_turf)
		return
	for(var/turf/target in source_turf.GetAtmosAdjacentTurfs())
		var/obj/effect/particle_effect/foam/found_foam = locate() in target
		if(found_foam)
			continue
		if(is_type_in_typecache(target, blacklisted_turfs))
			continue
		for(var/mob/living/target_mob in target)
			foam_mob(target_mob)
		var/obj/effect/particle_effect/foam/child = new src.type(target)
		child.amount = amount
		reagents.copy_to(child, reagents.total_volume)
		child.add_atom_colour(color, FIXED_COLOUR_PRIORITY)
		child.metal = metal

/// Парный замер занятого внутреннего участка и фронта с созданием частиц, звуком и переносом химии.
/datum/unit_test/foam_spread_benchmark/Run()
	var/turf/source_turf = run_loc_floor_bottom_left
	source_turf.ImmediateCalculateAdjacentTurfs()
	var/list/neighbors = source_turf.GetAtmosAdjacentTurfs()
	TEST_ASSERT_EQUAL(length(neighbors), 4, "Для замера нужны четыре открытых соседа")
	var/obj/effect/particle_effect/foam/short_life/unit_test_spread/source = allocate(/obj/effect/particle_effect/foam/short_life/unit_test_spread, source_turf)
	for(var/scenario in list("occupied", "empty_front", "chemical_front"))
		if(scenario == "occupied")
			source.spread_foam()
		if(scenario == "chemical_front")
			source.reagents.add_reagent(/datum/reagent/consumable/sugar, 14)
			source.reagents.add_reagent(/datum/reagent/consumable/nutriment, 7)
		var/iterations = scenario == "occupied" ? 20000 : 200
		for(var/paired_round in 1 to 4)
			var/list/variants = paired_round % 2 ? list("legacy", "current") : list("current", "legacy")
			for(var/variant in variants)
				var/elapsed_ms = 0
				if(scenario == "occupied")
					var/start = TICK_USAGE_REAL
					for(var/iteration in 1 to iterations)
						if(variant == "legacy")
							source.legacy_spread_foam()
						else
							source.spread_foam()
					elapsed_ms = TICK_USAGE_TO_MS(start)
				else
					for(var/iteration in 1 to iterations)
						for(var/turf/neighbor as anything in neighbors)
							var/obj/effect/particle_effect/foam/child = locate() in neighbor
							qdel(child)
						var/start = TICK_USAGE_REAL
						if(variant == "legacy")
							source.legacy_spread_foam()
						else
							source.spread_foam()
						elapsed_ms += TICK_USAGE_TO_MS(start)
				log_test("FOAMBENCH [scenario] pair=[paired_round] [variant] calls=[iterations] ms=[round(elapsed_ms, 0.001)]")

#endif
