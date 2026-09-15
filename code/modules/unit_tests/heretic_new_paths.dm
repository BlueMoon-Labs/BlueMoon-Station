/// Новые пути проходят все ступени за награды обычной охоты и сохраняют запрет второго пути.
/datum/unit_test/heretic_new_paths_progression/Run()
	for(var/path_id in list(PATH_LOCK, PATH_TIDE, PATH_GLASS, PATH_BLOOD, PATH_ECHO))
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		var/mob/living/user = heretic.owner.current
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		heretic.ascension_notice_sent = TRUE
		heretic.total_sacrifices = HERETIC_THREAT_SACRIFICES
		heretic.knowledge_points = HERETIC_STARTING_KNOWLEDGE + HERETIC_INFLUENCE_LIMIT + HERETIC_DEED_TIERS * HERETIC_DEED_KNOWLEDGE + HERETIC_LIVE_SACRIFICE_KNOWLEDGE * HERETIC_ASCENSION_SACRIFICES
		TEST_ASSERT(!heretic.research_knowledge(path.knowledge[2], user), "Нельзя начать [path_id] со второй ступени.")
		for(var/stage in 1 to length(path.knowledge))
			var/knowledge_type = path.knowledge[stage]
			if(stage == length(path.knowledge))
				heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES - 1
				var/balance = heretic.knowledge_points
				TEST_ASSERT(!heretic.research_knowledge(knowledge_type, user), "Без нужного числа подношений финал [path_id] недоступен.")
				TEST_ASSERT_EQUAL(heretic.knowledge_points, balance, "Отказ финального знания сохраняет очки.")
				heretic.total_sacrifices++
			TEST_ASSERT(heretic.research_knowledge(knowledge_type, user), "Ступень [stage] пути [path_id] доступна после предыдущей.")
			TEST_ASSERT_EQUAL(heretic.path_stage, stage, "Исследование продвигает ровно на одну ступень.")
			TEST_ASSERT(heretic.get_knowledge(knowledge_type), "Исследованная ступень действительно выдана.")
		TEST_ASSERT_EQUAL(heretic.selected_path, path_id, "Прогресс не меняет выбранный путь.")
		TEST_ASSERT(!heretic.ascended, "Изучение финала ещё не завершает обряд.")
		for(var/other_id in GLOB.heretic_paths - path_id)
			var/datum/heretic_path/other_path = GLOB.heretic_paths[other_id]
			TEST_ASSERT(!heretic.research_knowledge(other_path.knowledge[1], user), "После [path_id] нельзя выбрать [other_id].")
		qdel(heretic)

/// Клинок и реликвия каждого нового пути создаются настоящей руной с расходом компонентов.
/datum/unit_test/heretic_new_paths_recipes/Run()
	for(var/path_id in list(PATH_LOCK, PATH_TIDE, PATH_GLASS, PATH_BLOOD, PATH_ECHO))
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		var/mob/living/user = heretic.owner.current
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		heretic.selected_path = path_id
		var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, get_turf(user))
		for(var/stage in list(1, 5))
			heretic.gain_knowledge(path.knowledge[stage])
			var/datum/eldritch_knowledge/recipe = heretic.get_knowledge(path.knowledge[stage])
			recipe.ritual_time = 0
			TEST_ASSERT(length(recipe.required_atoms) && length(recipe.result_atoms), "У ступени [stage] пути [path_id] есть рецепт с результатом.")
			var/list/ingredients = list()
			for(var/ingredient_type in recipe.required_atoms)
				var/amount = recipe.required_atoms[ingredient_type]
				amount = isnum(amount) ? amount : 1
				for(var/index in 1 to amount)
					ingredients += allocate(ingredient_type, get_turf(rune))
			TEST_ASSERT(rune.do_ritual(user, recipe), "Обряд [recipe.name] завершается с настоящими компонентами.")
			for(var/atom/ingredient as anything in ingredients)
				TEST_ASSERT(QDELETED(ingredient), "Обряд расходует выбранный компонент [ingredient.type].")
				TEST_ASSERT_NULL(GLOB.heretic_ritual_reservations[ingredient], "Завершение освобождает резервирование компонентов.")
			for(var/result_type in recipe.result_atoms)
				var/obj/item/product = locate(result_type) in get_turf(rune)
				TEST_ASSERT(product, "Руна создаёт [result_type] на своём полу.")
				allocated += product
				if(istype(product, /obj/item/melee/sickly_blade))
					var/obj/item/melee/sickly_blade/blade = product
					TEST_ASSERT_EQUAL(blade.route, path_id, "Клинок проводит знания своего пути.")
				qdel(product)
		qdel(heretic)

/// Вознесение новых путей требует трёх тел, переносит силы и полностью снимается вместе с ролью.
/datum/unit_test/heretic_new_paths_ascension/Run()
	for(var/path_id in list(PATH_LOCK, PATH_TIDE, PATH_GLASS, PATH_BLOOD, PATH_ECHO))
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		var/mob/living/carbon/human/old_body = heretic.owner.current
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		heretic.selected_path = path_id
		heretic.ascension_notice_sent = TRUE
		heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
		heretic.apply_innate_effects(old_body)
		heretic.gain_knowledge(path.knowledge[length(path.knowledge)])
		var/datum/eldritch_knowledge/final_eldritch/final_knowledge = heretic.get_knowledge(path.knowledge[length(path.knowledge)])
		final_knowledge.ritual_time = 0
		var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, get_turf(old_body))
		var/list/bodies = list()
		for(var/body_index in 1 to HERETIC_ASCENSION_BODIES - 1)
			var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_turf(rune))
			victim.stat = DEAD
			bodies += victim
		TEST_ASSERT(!rune.do_ritual(old_body, final_knowledge), "Два тела не завершают вознесение [path_id].")
		for(var/mob/living/victim as anything in bodies)
			TEST_ASSERT(!QDELETED(victim), "Отказ сохраняет тела для следующей попытки.")
		var/mob/living/carbon/human/last_victim = allocate(/mob/living/carbon/human, get_turf(rune))
		last_victim.stat = DEAD
		bodies += last_victim
		var/original_brute_mod = old_body.physiology.brute_mod
		TEST_ASSERT(rune.do_ritual(old_body, final_knowledge), "Три тела завершают вознесение [path_id].")
		TEST_ASSERT(heretic.ascended && final_knowledge.finished, "Обряд отмечает вознесение роли и знания.")
		for(var/mob/living/victim as anything in bodies)
			TEST_ASSERT(QDELETED(victim), "Успешный обряд расходует каждое тело.")
		TEST_ASSERT_EQUAL(final_knowledge.applied_body, old_body, "Вознесение сразу применяет силы к телу.")
		var/list/old_spells = final_knowledge.ascension_spell_instances.Copy()
		TEST_ASSERT(length(old_spells), "Вознесение [path_id] выдаёт собственную способность.")
		var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
		var/new_body_brute_mod = new_body.physiology.brute_mod
		heretic.owner.transfer_to(new_body, TRUE)
		TEST_ASSERT_EQUAL(final_knowledge.applied_body, new_body, "Вознесение следует за разумом.")
		TEST_ASSERT_EQUAL(old_body.physiology.brute_mod, original_brute_mod, "Прежнее тело теряет защиту.")
		TEST_ASSERT_EQUAL(old_body.physiology.heretic_ascension_mod, 1, "Прежнее тело теряет множитель вознесения.")
		TEST_ASSERT_EQUAL(new_body.physiology.heretic_ascension_mod, final_knowledge.damage_modifier, "Новое тело получает множитель вознесения.")
		for(var/obj/effect/proc_holder/spell/old_spell as anything in old_spells)
			TEST_ASSERT(QDELETED(old_spell), "Способности прежнего тела удалены.")
		var/list/new_spells = final_knowledge.ascension_spell_instances.Copy()
		TEST_ASSERT_EQUAL(length(new_spells), length(old_spells), "Новое тело получает ровно тот же набор сил.")
		var/list/ascension_traits = final_knowledge.ascension_traits.Copy()
		var/trait_source = REF(final_knowledge)
		qdel(heretic)
		TEST_ASSERT_EQUAL(new_body.physiology.brute_mod, new_body_brute_mod, "Удаление роли возвращает защиту нового тела.")
		TEST_ASSERT_EQUAL(new_body.physiology.heretic_ascension_mod, 1, "Снятие роли убирает множитель вознесения.")
		for(var/obj/effect/proc_holder/spell/new_spell as anything in new_spells)
			TEST_ASSERT(QDELETED(new_spell), "Снятие роли удаляет финальные способности.")
		for(var/trait in ascension_traits)
			TEST_ASSERT(!HAS_TRAIT_FROM(new_body, trait, trait_source), "Снятие роли удаляет свой источник черты [trait].")
