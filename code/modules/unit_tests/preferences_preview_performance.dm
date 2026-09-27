/mob/living/carbon/human/dummy/consistent/preferences_preview_test
	var/body_updates = 0
	var/hair_updates = 0

/mob/living/carbon/human/dummy/consistent/preferences_preview_test/update_body(update_genitals = FALSE, block_recursive_calls = FALSE)
	body_updates++
	return ..()

/mob/living/carbon/human/dummy/consistent/preferences_preview_test/update_hair()
	hair_updates++
	return ..()

/// Отложенная отрисовка сохраняет конечности, одежду и изображение после полной сборки.
/datum/unit_test/preferences_preview_deferred_render
	var/list/copied_icon_updates = list()

/datum/unit_test/preferences_preview_deferred_render/proc/on_prefs_copied(datum/source, datum/preferences/prefs, icon_updates, roundstart_checks)
	SIGNAL_HANDLER
	copied_icon_updates += icon_updates

/datum/unit_test/preferences_preview_deferred_render/Run()
	var/datum/preferences/navigation_test/prefs = allocate(/datum/preferences/navigation_test)
	var/list/species_types = list(/datum/species/human, /datum/species/lizard)
	for(var/species_type in species_types)
		prefs.pref_species = new species_type
		prefs.random_character(MALE)
		prefs.modified_limbs = list()
		if(species_type == /datum/species/lizard)
			prefs.modified_limbs[BODY_ZONE_R_ARM] = list(LOADOUT_LIMB_PROSTHETIC, "prosthetic")
			prefs.modified_limbs[BODY_ZONE_L_LEG] = list(LOADOUT_LIMB_AMPUTATED)
		var/mob/living/carbon/human/dummy/consistent/preferences_preview_test/baseline = allocate(/mob/living/carbon/human/dummy/consistent/preferences_preview_test)
		var/mob/living/carbon/human/dummy/consistent/preferences_preview_test/deferred = allocate(/mob/living/carbon/human/dummy/consistent/preferences_preview_test)
		RegisterSignal(baseline, COMSIG_HUMAN_PREFS_COPIED_TO, PROC_REF(on_prefs_copied))
		RegisterSignal(deferred, COMSIG_HUMAN_PREFS_COPIED_TO, PROC_REF(on_prefs_copied))
		copied_icon_updates.Cut()
		baseline.wipe_state()
		deferred.wipe_state()
		baseline.body_updates = 0
		baseline.hair_updates = 0
		deferred.body_updates = 0
		deferred.hair_updates = 0
		prefs.copy_to(baseline, icon_updates = TRUE, roundstart_checks = FALSE, initial_spawn = TRUE)
		prefs.copy_to(deferred, icon_updates = FALSE, roundstart_checks = FALSE, initial_spawn = TRUE)
		TEST_ASSERT_EQUAL(length(copied_icon_updates), 2, "Оба копирования должны отправить сигнал")
		TEST_ASSERT_EQUAL(copied_icon_updates[1], TRUE, "Обычное копирование передало неверный флаг отрисовки")
		TEST_ASSERT_EQUAL(copied_icon_updates[2], FALSE, "Отложенное копирование передало неверный флаг отрисовки")
		if(species_type == /datum/species/lizard)
			var/obj/item/bodypart/prosthetic = deferred.get_bodypart(BODY_ZONE_R_ARM)
			TEST_ASSERT_NOTNULL(prosthetic, "Протез не установлен без промежуточной отрисовки")
			TEST_ASSERT(prosthetic.is_robotic_limb(FALSE), "Рука не стала протезом")
			TEST_ASSERT_NULL(deferred.get_bodypart(BODY_ZONE_L_LEG), "Ампутированная нога осталась на месте")
			baseline.equip_to_slot_or_del(new /obj/item/clothing/under/color/grey(baseline), ITEM_SLOT_ICLOTHING)
			deferred.equip_to_slot_or_del(new /obj/item/clothing/under/color/grey(deferred), ITEM_SLOT_ICLOTHING)
		baseline.regenerate_icons()
		deferred.regenerate_icons()
		TEST_ASSERT(baseline.body_updates > deferred.body_updates, "Отсрочка не уменьшила число обновлений тела [species_type]")
		if(species_type == /datum/species/human)
			TEST_ASSERT(baseline.hair_updates > deferred.hair_updates, "Отсрочка не уменьшила число обновлений волос человека")
		TEST_ASSERT(length(baseline.overlays), "Эталонное изображение не собрано")
		TEST_ASSERT_EQUAL(deferred.transform.a, baseline.transform.a, "Изменился масштаб персонажа по X")
		TEST_ASSERT_EQUAL(deferred.transform.e, baseline.transform.e, "Изменился масштаб персонажа по Y")
		for(var/direction in GLOB.cardinals)
			var/icon/expected = getFlatIcon(baseline, defdir = direction, no_anim = TRUE)
			var/icon/actual = getFlatIcon(deferred, defdir = direction, no_anim = TRUE)
			TEST_ASSERT_EQUAL(actual.Width(), expected.Width(), "Изменилась ширина изображения [species_type]")
			TEST_ASSERT_EQUAL(actual.Height(), expected.Height(), "Изменилась высота изображения [species_type]")
			for(var/pixel_x in 1 to expected.Width())
				for(var/pixel_y in 1 to expected.Height())
					TEST_ASSERT_EQUAL(actual.GetPixel(pixel_x, pixel_y), expected.GetPixel(pixel_x, pixel_y), "Изменилось изображение [species_type], направление [direction], пиксель [pixel_x],[pixel_y]")

#ifdef ROUND_10294_BENCHMARK

/// Парный замер копирования внешности и полной сборки после прогрева кэшей.
/datum/unit_test/preferences_preview_render_benchmark/Run()
	var/datum/preferences/navigation_test/prefs = allocate(/datum/preferences/navigation_test)
	var/mob/living/carbon/human/dummy/consistent/mannequin = allocate(/mob/living/carbon/human/dummy/consistent)
	var/iterations = 20
	for(var/species_type in list(/datum/species/human, /datum/species/lizard))
		prefs.pref_species = new species_type
		prefs.random_character(MALE)
		prefs.real_name = "Preview Benchmark"
		for(var/warmup in 1 to 4)
			mannequin.wipe_state()
			prefs.copy_to(mannequin, icon_updates = !!(warmup % 2), roundstart_checks = FALSE, initial_spawn = TRUE)
			mannequin.regenerate_icons()
		for(var/paired_round in 1 to 3)
			var/list/variants = paired_round % 2 ? list(TRUE, FALSE) : list(FALSE, TRUE)
			for(var/icon_updates in variants)
				var/elapsed_ms = 0
				for(var/iteration in 1 to iterations)
					mannequin.wipe_state()
					var/start = TICK_USAGE_REAL
					prefs.copy_to(mannequin, icon_updates = icon_updates, roundstart_checks = FALSE, initial_spawn = TRUE)
					mannequin.regenerate_icons()
					elapsed_ms += TICK_USAGE_TO_MS(start)
				log_test("PREVIEWBENCH [species_type] pair=[paired_round] [icon_updates ? "legacy" : "current"] calls=[iterations] ms=[round(elapsed_ms, 0.001)]")

#endif
