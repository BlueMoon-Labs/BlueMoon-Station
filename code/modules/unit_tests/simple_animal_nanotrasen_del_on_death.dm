// Регрессия: на NEO/spacebattle/? после смерти нанодрановских офицеров тело
// оставалось лежать и не исчезало. del_on_death = TRUE наследовался всеми
// отрядами, а труп-спавнер падал - то есть цепочка смерти добиралась до
// базового /mob/living/simple_animal/death() и до qdel(src) в её del_on_death-
// ветке. Раз так, gc_destroyed обязан выставляться в тот же тик.
//
// Проверяем весь трупак: базовый отряд и каждый наследник (ranged, smg,
// assault, elite, elite/akins, survivor) должен уходить в qdel синхронно со
// смертью, при этом выронив лут (труп-спавнер офицера) на свою клетку. Если
// какое-то переопределение когда-нибудь порвёт ..()-цепочку или тихо сбросит
// del_on_death, тест это поймает.

/datum/unit_test/simple_animal_nanotrasen_del_on_death
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/simple_animal_nanotrasen_del_on_death/Run()
	configure_immediate_gc()

	var/checked = 0
	for(var/animal_type in typesof(/mob/living/simple_animal/hostile/nanotrasen))
		var/turf/drop = run_loc_floor_bottom_left
		var/mob/living/simple_animal/hostile/nanotrasen/victim = allocate(animal_type, drop)
		if(QDELETED(victim))
			continue
		checked++
		// дефолт базового типа обязан долетать до каждого наследника
		TEST_ASSERT(victim.del_on_death, "[victim.type] обязан иметь del_on_death = TRUE")
		var/had_corpse_loot = FALSE
		for(var/loot_type in victim.loot)
			if(ispath(loot_type, /obj/effect/mob_spawn/human/corpse))
				had_corpse_loot = TRUE
				break
		victim.death()
		// главная регрессия: тело обязано уйти в qdel синхронно со смертью
		TEST_ASSERT(QDELETED(victim), "[victim.type] не удалился после death()")
		TEST_ASSERT_EQUAL(victim.stat, DEAD, "Sanity: [victim.type] не умер")
		// drop_loot() бежит до qdel: труп-спавнер обязан лежать на той же клетке
		if(had_corpse_loot)
			var/got_corpse = FALSE
			for(var/obj/effect/mob_spawn/human/corpse/spawner in drop)
				got_corpse = TRUE
				break
			if(!got_corpse)
				for(var/mob/living/carbon/human/body in drop)
					if(body.stat == DEAD)
						got_corpse = TRUE
						break
			TEST_ASSERT(got_corpse, "[victim.type] не выронил труп-спавнер (drop_loot сломан)")
	TEST_ASSERT(checked > 0, "Не заспавнилось ни одного нанодрановского отряда")
	run_gc_fire_cycles(2, yield_for_gc = TRUE)