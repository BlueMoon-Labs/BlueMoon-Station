#ifdef HUMAN_LIFE_BENCH
///Сколько людей в бенче Life().
#define HUMAN_LIFE_BENCH_MOBS 16
///Сколько фаеров SSmobs прогоняет бенч.
#define HUMAN_LIFE_BENCH_FIRES 48
///Сколько раз на человека вызывается каждая часть Life в поштучном замере.
#define HUMAN_LIFE_BENCH_PART_REPS 40

/// Замер Life() одетого живого человека рядом с другими людьми: мкс на вызов
/// и профиль процов в data/human_life_profile.json. Только под --define=HUMAN_LIFE_BENCH.
/datum/unit_test/human_life_benchmark
	priority = TEST_LONGER

/datum/unit_test/human_life_benchmark/Run()
	var/list/outfits = list(/datum/outfit/job/assistant, /datum/outfit/job/engineer, /datum/outfit/job/doctor, /datum/outfit/job/security, /datum/outfit/job/scientist, /datum/outfit/job/cook, /datum/outfit/job/cargo_tech, /datum/outfit/job/bartender)
	var/list/species_types = list(/datum/species/human, /datum/species/mammal, /datum/species/lizard, /datum/species/human/felinid)
	var/list/turfs = block(run_loc_floor_bottom_left, run_loc_floor_top_right)
	var/list/humans = list()
	var/with_reagents = TRUE
#ifdef HUMAN_LIFE_BENCH_CLEAN
	with_reagents = FALSE
#endif
	for(var/i in 1 to HUMAN_LIFE_BENCH_MOBS)
		var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human, turfs[(i % length(turfs)) + 1])
		subject.set_species(species_types[(i % length(species_types)) + 1])
		subject.equipOutfit(outfits[(i % length(outfits)) + 1], TRUE)
		// половина - с едой и питьём в крови, половина - пустая
		if((i % 2) && with_reagents)
			subject.reagents.add_reagent(/datum/reagent/consumable/nutriment, 30)
			subject.reagents.add_reagent(/datum/reagent/water, 30)
			subject.reagents.add_reagent(/datum/reagent/consumable/coffee, 20)
			// каждый четвёртый - после бара и медбея: десяток реагентов разом
			if(i % 4 == 3)
				subject.reagents.add_reagent_list(list(/datum/reagent/consumable/sugar = 10, /datum/reagent/consumable/sodiumchloride = 5, /datum/reagent/consumable/tea = 15, /datum/reagent/consumable/space_cola = 15, /datum/reagent/consumable/ethanol/beer = 10, /datum/reagent/medicine/salglu_solution = 10, /datum/reagent/medicine/bicaridine = 10, /datum/reagent/iron = 5))
		humans += subject

	var/bench_z = run_loc_floor_bottom_left.z
	var/saved_can_fire = SSmobs.can_fire
	SSmobs.can_fire = FALSE
	SSmobs.clients_by_zlevel[bench_z] |= humans[1]
	// прогрев: кэши органов, гравитации, подписи мобильности
	var/fire = 1000
	for(var/warm in 1 to 4)
		fire++
		for(var/mob/living/carbon/human/subject as anything in humans)
			subject.cached_nearby_player = TRUE
			subject.cached_nearby_player_fire = fire
			subject.Life(SSMOBS_DT, fire)
		sleep(world.tick_lag)

	world.Profile(PROFILE_CLEAR)
	world.Profile(PROFILE_START)
	var/list/samples = list()
	var/list/fed_samples = list()
	var/list/heavy_samples = list()
	var/list/clean_samples = list()
	for(var/round in 1 to HUMAN_LIFE_BENCH_FIRES)
		fire++
		for(var/mob/living/carbon/human/subject as anything in humans)
			subject.cached_nearby_player = TRUE
			subject.cached_nearby_player_fire = fire
			var/start = TICK_USAGE_REAL
			subject.Life(SSMOBS_DT, fire)
			var/cost = TICK_DELTA_TO_MS(TICK_USAGE_REAL - start) * 1000
			samples += cost
			if(length(subject.reagents.reagent_list) > 5)
				heavy_samples += cost
			else if(length(subject.reagents.reagent_list))
				fed_samples += cost
			else
				clean_samples += cost
		sleep(world.tick_lag)
	var/profile_data = world.Profile(PROFILE_REFRESH, format = "json")
	world.Profile(PROFILE_STOP)
	world.Profile(PROFILE_CLEAR)

	// части Life по отдельности: мкс на вызов на одного человека, за вычетом пустого вызова
	var/list/parts = list("noop", "signal_life", "physical", "biological", "status_effects", "environment", "species_environment", "thermal_cold", "affecting_pressure", "plasma_clothing", "fire", "gravity", "visible_name", "organs", "breathing", "breathe", "blood", "bodyparts", "stamina", "mobility_dirty", "mobility_signature", "update_mobility", "sprint_regen", "brain_damage", "liver", "corruption", "diseases", "wounds", "mutations", "random_events", "stomach", "block_parry", "traits", "active_genes", "heart", "spec_life", "updatehealth", "mood_clear", "breath_gas", "check_breath", "internal", "smell")
	var/list/part_costs = list()
	for(var/part in parts)
		var/part_start = TICK_USAGE_REAL
		for(var/rep in 1 to HUMAN_LIFE_BENCH_PART_REPS)
			fire++
			for(var/mob/living/carbon/human/subject as anything in humans)
				run_part(subject, part, fire)
		part_costs[part] = TICK_DELTA_TO_MS(TICK_USAGE_REAL - part_start) * 1000 / (HUMAN_LIFE_BENCH_PART_REPS * length(humans))
		sleep(world.tick_lag)
	// органы по типам: мкс на один on_life
	var/list/organ_costs = list()
	var/list/organ_calls = list()
	for(var/rep in 1 to HUMAN_LIFE_BENCH_PART_REPS)
		fire++
		for(var/mob/living/carbon/human/subject as anything in humans)
			for(var/obj/item/organ/organ as anything in subject.internal_organs)
				if(!organ.processes_on_life)
					continue
				var/organ_start = TICK_USAGE_REAL
				organ.on_life(SSMOBS_DT, fire)
				organ_costs["[organ.type]"] += TICK_DELTA_TO_MS(TICK_USAGE_REAL - organ_start) * 1000
				organ_calls["[organ.type]"] += 1
	for(var/organ_type in organ_costs)
		organ_costs[organ_type] = round(organ_costs[organ_type] / organ_calls[organ_type], 0.1)
	// профиль процов внутри самых дорогих частей
	for(var/part in list("check_breath", "species_environment", "organs", "biological", "physical"))
		world.Profile(PROFILE_CLEAR)
		world.Profile(PROFILE_START)
		for(var/rep in 1 to HUMAN_LIFE_BENCH_PART_REPS * 5)
			fire++
			for(var/mob/living/carbon/human/subject as anything in humans)
				run_part(subject, part, fire)
		var/part_profile = world.Profile(PROFILE_REFRESH, format = "json")
		world.Profile(PROFILE_STOP)
		world.Profile(PROFILE_CLEAR)
		fdel("data/human_life_part_[part].json")
		text2file(part_profile, "data/human_life_part_[part].json")
		sleep(world.tick_lag)
	var/noop_cost = part_costs["noop"]
	for(var/part in parts)
		part_costs[part] = round(part_costs[part] - noop_cost, 0.1)

	SSmobs.clients_by_zlevel[bench_z] -= humans[1]
	SSmobs.can_fire = saved_can_fire

	var/list/report = list(
		"all" = summarize_samples(samples),
		"fed" = summarize_samples(fed_samples),
		"heavy" = summarize_samples(heavy_samples),
		"clean" = summarize_samples(clean_samples),
		"parts_us" = part_costs,
		"organs_us" = organ_costs,
	)
	fdel("data/human_life_bench.json")
	text2file(json_encode(report), "data/human_life_bench.json")
	fdel("data/human_life_profile.json")
	text2file(profile_data, "data/human_life_profile.json")
	for(var/mob/living/carbon/human/subject as anything in humans)
		TEST_ASSERT(subject.stat == CONSCIOUS, "[subject] умер или потерял сознание за бенч - замер не про живого игрока")

/datum/unit_test/human_life_benchmark/proc/run_part(mob/living/carbon/human/subject, part, fire)
	switch(part)
		if("noop")
			return
		if("signal_life")
			SEND_SIGNAL(subject, COMSIG_LIVING_LIFE, SSMOBS_DT, fire)
		if("physical")
			subject.PhysicalLife(SSMOBS_DT, fire)
		if("biological")
			subject.BiologicalLife(SSMOBS_DT, fire)
		if("status_effects")
			subject.handle_status_effects()
		if("environment")
			subject.handle_environment(subject.loc.return_air())
		if("species_environment")
			subject.dna.species.handle_environment(subject.loc.return_air(), subject)
		if("thermal_cold")
			subject.get_thermal_protection(T20C, TRUE)
		if("affecting_pressure")
			subject.calculate_affecting_pressure(ONE_ATMOSPHERE)
		if("plasma_clothing")
			subject.handle_plasma_clothing(subject.loc.return_air())
		if("fire")
			subject.handle_fire()
		if("gravity")
			subject.handle_gravity()
		if("visible_name")
			subject.get_visible_name()
		if("organs")
			subject.handle_organs(SSMOBS_DT, fire)
		if("breathing")
			subject.handle_breathing(fire)
		if("breathe")
			subject.breathe()
		if("blood")
			subject.handle_blood(SSMOBS_DT, fire)
		if("bodyparts")
			subject.handle_bodyparts()
		if("stamina")
			subject.update_stamina()
		if("mobility_dirty")
			subject.update_mobility_if_dirty(fire)
		if("mobility_signature")
			subject.mobility_input_signature()
		if("update_mobility")
			subject.update_mobility()
		if("sprint_regen")
			subject.doSprintBufferRegen()
		if("brain_damage")
			subject.handle_brain_damage()
		if("liver")
			subject.handle_liver(SSMOBS_DT, fire)
		if("corruption")
			subject.handle_corruption(SSMOBS_DT)
		if("diseases")
			subject.handle_diseases()
		if("wounds")
			subject.handle_wounds()
		if("mutations")
			subject.handle_mutations_and_radiation()
		if("random_events")
			subject.handle_random_events()
		if("stomach")
			subject.handle_stomach()
		if("block_parry")
			subject.handle_block_parry(SSMOBS_DT)
		if("traits")
			subject.handle_traits()
		if("active_genes")
			subject.handle_active_genes()
		if("heart")
			subject.handle_heart(SSMOBS_DT, fire)
		if("spec_life")
			subject.dna.species.spec_life(subject)
		if("updatehealth")
			subject.updatehealth()
		if("mood_clear")
			SEND_SIGNAL(subject, COMSIG_CLEAR_MOOD_EVENT, "jittery")
		if("breath_gas", "check_breath", "smell")
			var/datum/gas_mixture/environment = subject.loc.return_air()
			var/datum/gas_mixture/breath = subject.loc.remove_air_ratio(BREATH_VOLUME / environment.return_volume())
			breath.set_volume(BREATH_VOLUME)
			if(part == "check_breath")
				subject.check_breath(breath)
			else if(part == "smell")
				subject.smell(breath)
			subject.loc.assume_air(breath)
			qdel(breath)
			subject.air_update_turf()
		if("internal")
			subject.get_breath_from_internal(BREATH_VOLUME)

/datum/unit_test/human_life_benchmark/proc/summarize_samples(list/samples)
	var/count = length(samples)
	if(!count)
		return list("calls" = 0)
	sortTim(samples, GLOBAL_PROC_REF(cmp_numeric_asc))
	var/total = 0
	for(var/sample in samples)
		total += sample
	return list(
		"calls" = count,
		"mean_us" = total / count,
		"p10_us" = samples[max(1, round(count * 0.1))],
		"p50_us" = samples[max(1, round(count * 0.5))],
		"p90_us" = samples[max(1, round(count * 0.9))],
		"max_us" = samples[count],
	)

#undef HUMAN_LIFE_BENCH_MOBS
#undef HUMAN_LIFE_BENCH_FIRES
#undef HUMAN_LIFE_BENCH_PART_REPS
#endif

/// Рецепт для проверок памяти разбора реакций. required_reagents пуст на уровне типа,
/// поэтому build_chemical_reactions_list() его не индексирует - в игре его нет.
/datum/chemical_reaction/unit_test_scan_memo
	name = "unit test scan memo"
	results = list(/datum/reagent/consumable/sodiumchloride = 1)
	mix_message = null
	mix_sound = null
	var/special_allowed = TRUE

/datum/chemical_reaction/unit_test_scan_memo/check_special_react(datum/reagents/holder)
	return special_allowed

/// Разбор реакций запоминает "ничего не реагирует" и не повторяет его, пока объёмы только
/// убывают. Всё, что может включить реакцию, обязано память сбросить.
/datum/unit_test/reaction_scan_memo
	var/datum/chemical_reaction/unit_test_scan_memo/recipe

/datum/unit_test/reaction_scan_memo/Destroy()
	unregister_recipe()
	return ..()

/datum/unit_test/reaction_scan_memo/proc/register_recipe(list/required, required_temp = 0, special = FALSE)
	recipe = new
	recipe.required_reagents = required
	recipe.required_temp = required_temp
	recipe.special_react = special
	LAZYADD(GLOB.chemical_reactions_list[required[1]], recipe)

/datum/unit_test/reaction_scan_memo/proc/unregister_recipe()
	if(!recipe)
		return
	for(var/reagent_type in recipe.required_reagents)
		LAZYREMOVE(GLOB.chemical_reactions_list[reagent_type], recipe)
	QDEL_NULL(recipe)

/datum/unit_test/reaction_scan_memo/proc/fresh_beaker()
	var/obj/item/reagent_containers/glass/beaker/beaker = allocate(/obj/item/reagent_containers/glass/beaker, run_loc_floor_bottom_left)
	beaker.reagents.chem_temp = T20C
	return beaker.reagents

/datum/unit_test/reaction_scan_memo/Run()
	// снижение объёма не будит разбор, и состав при этом считается как раньше
	var/datum/reagents/holder = fresh_beaker()
	holder.add_reagent(/datum/reagent/iron, 5, reagtemp = T20C)
	TEST_ASSERT(holder.reaction_scan_still_empty(), "После разбора без реакций память обязана совпадать с составом")
	holder.remove_reagent(/datum/reagent/iron, 1)
	TEST_ASSERT(holder.reaction_scan_still_empty(), "Убыль объёма не может включить реакцию - память должна остаться")
	TEST_ASSERT_EQUAL(holder.total_volume, 4, "Пропуск разбора обязан пересчитать total_volume")

/// Рецепт, появившийся после разбора: рандомные рецепты грузятся позже карты.
/datum/unit_test/reaction_scan_memo/new_recipe/Run()
	var/datum/reagents/holder = fresh_beaker()
	holder.add_reagent(/datum/reagent/iron, 5, reagtemp = T20C)
	register_recipe(list(/datum/reagent/iron = 1))
	holder.handle_reactions()
	TEST_ASSERT(holder.has_reagent(/datum/reagent/consumable/sodiumchloride), "Новый рецепт на уже лежащий реагент обязан сработать")

/// Объём, выросший мимо add_reagent.
/datum/unit_test/reaction_scan_memo/direct_volume/Run()
	register_recipe(list(/datum/reagent/iron = 10))
	var/datum/reagents/holder = fresh_beaker()
	holder.add_reagent(/datum/reagent/iron, 5, reagtemp = T20C)
	TEST_ASSERT(!holder.has_reagent(/datum/reagent/consumable/sodiumchloride), "Пяти единиц на рецепт из десяти мало")
	var/datum/reagent/iron = holder.has_reagent(/datum/reagent/iron)
	iron.volume += 10
	holder.handle_reactions()
	TEST_ASSERT(holder.has_reagent(/datum/reagent/consumable/sodiumchloride), "Реагент, прибавивший напрямую, обязан будить разбор")

/datum/unit_test/reaction_scan_memo/heating/Run()
	register_recipe(list(/datum/reagent/iron = 1), required_temp = 400)
	var/datum/reagents/holder = fresh_beaker()
	holder.add_reagent(/datum/reagent/iron, 5, reagtemp = T20C)
	TEST_ASSERT(!holder.has_reagent(/datum/reagent/consumable/sodiumchloride), "Рецепт на 400 К не должен идти при 293 К")
	holder.chem_temp = 450
	holder.handle_reactions()
	TEST_ASSERT(holder.has_reagent(/datum/reagent/consumable/sodiumchloride), "Нагрев обязан будить разбор")

/// Особое условие смотрит не в объёмы - такой разбор не запоминается.
/datum/unit_test/reaction_scan_memo/special/Run()
	register_recipe(list(/datum/reagent/iron = 1), special = TRUE)
	recipe.special_allowed = FALSE
	var/datum/reagents/holder = fresh_beaker()
	holder.add_reagent(/datum/reagent/iron, 5, reagtemp = T20C)
	TEST_ASSERT(!holder.has_reagent(/datum/reagent/consumable/sodiumchloride), "Особое условие запретило реакцию")
	recipe.special_allowed = TRUE
	holder.handle_reactions()
	TEST_ASSERT(holder.has_reagent(/datum/reagent/consumable/sodiumchloride), "Особое условие стало разрешать - реакция обязана пройти")

/// clear_mood_event_if_set снимает мудлет, если он есть, и молчит, если нет.
/datum/unit_test/clear_mood_event_if_set

/datum/unit_test/clear_mood_event_if_set/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/component/mood/mood = patient.GetComponent(/datum/component/mood) || patient.AddComponent(/datum/component/mood)
	SEND_SIGNAL(patient, COMSIG_ADD_MOOD_EVENT, "jittery", /datum/mood_event/jittery)
	TEST_ASSERT(mood.mood_events["jittery"], "Мудлет не повесился - проверять нечего")
	patient.clear_mood_event_if_set("jittery")
	TEST_ASSERT(!mood.mood_events["jittery"], "Висящий мудлет обязан сняться")
	patient.clear_mood_event_if_set("jittery")
	TEST_ASSERT(!mood.mood_events["jittery"], "Повторное снятие ничего не ломает")

/// Тестовая травма считает свои on_life.
/datum/brain_trauma/unit_test_counter
	random_gain = FALSE
	var/life_ticks = 0

/datum/brain_trauma/unit_test_counter/on_life()
	life_ticks++

/// Ранний выход handle_brain_damage() для мозга без травм не теряет живые травмы.
/datum/unit_test/brain_damage_ticks_traumas

/datum/unit_test/brain_damage_ticks_traumas/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	patient.handle_brain_damage()
	var/datum/brain_trauma/unit_test_counter/trauma = patient.gain_trauma(/datum/brain_trauma/unit_test_counter, TRAUMA_RESILIENCE_ABSOLUTE)
	TEST_ASSERT_NOTNULL(trauma, "Травма не повесилась")
	patient.handle_brain_damage()
	TEST_ASSERT_EQUAL(trauma.life_ticks, 1, "Живая травма обязана получить on_life")
