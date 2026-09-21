/// Предметы во рту искажают голос, но не язык жестов.
/datum/unit_test/sign_language_mouth_items/Run()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/obj/item/toy/fluff/tennis_poly/ball = allocate(/obj/item/toy/fluff/tennis_poly)
	TEST_ASSERT(speaker.equip_to_slot_if_possible(ball, ITEM_SLOT_MASK), "Мяч не надет")
	var/message = "Testing tongue movements"
	TEST_ASSERT_EQUAL(speaker.treat_message(message, /datum/language/signlanguage), message, "Мяч искажает жесты")
	TEST_ASSERT_NOTEQUAL(speaker.treat_message(message, /datum/language/common), message, "Мяч перестал искажать голос")
	speaker.dropItemToGround(ball)
	var/obj/item/clothing/mask/muzzle/gag = allocate(/obj/item/clothing/mask/muzzle)
	gag.mute = MUFFLE_HIGH
	TEST_ASSERT(speaker.equip_to_slot_if_possible(gag, ITEM_SLOT_MASK), "Кляп не надет")
	TEST_ASSERT_EQUAL(speaker.treat_message(message, /datum/language/signlanguage), message, "Кляп искажает жесты")

#define TEST_POOL_WATER_VOLUME 300

/// Водное дыхание защищает лежащего пловца от утопления в бассейне.
/datum/unit_test/water_aspect_pool
	var/area/test_area
	var/saved_gravity

/datum/unit_test/water_aspect_pool/Destroy()
	if(test_area)
		test_area.has_gravity = saved_gravity
	test_area = null
	return ..()

/datum/unit_test/water_aspect_pool/Run()
	var/turf/open/pool/pool = run_loc_floor_bottom_left.ChangeTurf(/turf/open/pool)
	test_area = get_area(pool)
	saved_gravity = test_area.has_gravity
	test_area.has_gravity = STANDARD_GRAVITY
	pool.add_liquid(/datum/reagent/water, TEST_POOL_WATER_VOLUME, TRUE)
	TEST_ASSERT_NOTNULL(pool.liquids, "В бассейне нет воды")
	var/mob/living/carbon/human/swimmer = allocate(/mob/living/carbon/human, get_step(pool, EAST))
	ADD_TRAIT(swimmer, TRAIT_WATER_BREATHING, TRAIT_SOURCE_UNIT_TESTS)
	swimmer.forceMove(pool)
	TEST_ASSERT_EQUAL(swimmer.getOxyLoss(), 0, "Падение в бассейн душит водного персонажа")
	swimmer.set_resting(TRUE)
	var/datum/status_effect/swimming/swimming = swimmer.has_status_effect(/datum/status_effect/swimming)
	TEST_ASSERT_NOTNULL(swimming, "Нет эффекта плавания")
	swimming.tick()
	TEST_ASSERT_EQUAL(swimmer.getOxyLoss(), 0, "Эффект плавания душит водного персонажа")
	TEST_ASSERT_EQUAL(swimmer.losebreath, 0, "Водный персонаж теряет дыхание")
	REMOVE_TRAIT(swimmer, TRAIT_WATER_BREATHING, TRAIT_SOURCE_UNIT_TESTS)
	swimming.tick()
	TEST_ASSERT(swimmer.getOxyLoss() > 0, "Обычный персонаж перестал тонуть")

#undef TEST_POOL_WATER_VOLUME

/// Свечение аксессуаров появляется и снимается вместе с настройкой.
/datum/unit_test/mutant_accessory_glow/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.set_species(/datum/species/mammal)
	human.dna.features["mam_ears"] = "Husky"
	human.dna.features["mam_tail"] = "Husky"
	human.dna.features["mam_snouts"] = "Husky"
	human.dna.features["wings"] = "Angel"
	human.dna.species.mutant_bodyparts["wings"] = "Angel"
	var/list/emissive_parts = list("ears", "tail", "snout", "wings")
	human.dna.features["emissive_parts"] = emissive_parts
	for(var/enabled as anything in list(TRUE, FALSE))
		human.dna.features["allow_emissives"] = enabled
		human.update_mutant_bodyparts()
		var/list/glowing_parts = list()
		for(var/layer as anything in list(BODY_BEHIND_LAYER, BODY_ADJ_LAYER, BODY_ADJ_UPPER_LAYER, BODY_FRONT_LAYER, HORNS_LAYER))
			for(var/mutable_appearance/overlay as anything in human.overlays_standing[layer])
				if(overlay.plane != EMISSIVE_PLANE)
					continue
				for(var/part as anything in emissive_parts)
					if(findtext(overlay.icon_state, "_[part]_"))
						glowing_parts |= part
		TEST_ASSERT_EQUAL(length(glowing_parts), enabled ? length(emissive_parts) : 0, "Свечение аксессуаров не соответствует настройке")

/// Цвета молей сохраняются раздельно, старый общий цвет переносится без изменений.
/datum/unit_test/insect_accessory_colors
	var/fixture_path

/datum/unit_test/insect_accessory_colors/Destroy()
	if(fixture_path)
		fdel(fixture_path)
	return ..()

/datum/unit_test/insect_accessory_colors/Run()
	var/datum/preferences/prefs = new
	allocated += prefs
	fixture_path = "data/unit_tests/insect_accessory_colors.sav"
	prefs.path = fixture_path
	prefs.features["wings_color"] = "112233"
	prefs.features["insect_fluff_color"] = "445566"
	prefs.features["insect_markings_color"] = "778899"
	TEST_ASSERT(prefs.save_character(bypass_cooldown = TRUE, silent = TRUE), "Цвета не сохранены")
	TEST_ASSERT(prefs.load_character(bypass_cooldown = TRUE), "Цвета не загружены")
	TEST_ASSERT_EQUAL(prefs.features["insect_fluff_color"], "445566", "Цвет пуха потерян")
	TEST_ASSERT_EQUAL(prefs.features["insect_markings_color"], "778899", "Цвет отметин потерян")
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.set_species(/datum/species/mammal)
	human.dna.features = prefs.features.Copy()
	human.dna.features["wings"] = "None"
	var/list/colors = list("insect_wings" = "112233", "insect_fluff" = "445566", "insect_markings" = "778899")
	var/list/styles = list("insect_wings" = "Moth (Whitefly Greyscale)", "insect_fluff" = "Deathshead", "insect_markings" = "Deathshead")
	for(var/part as anything in colors)
		var/list/choices = GLOB.mutant_reference_list[part]
		TEST_ASSERT_NOTNULL(choices[styles[part]], "Нет аксессуара [part]: [styles[part]]")
		human.dna.species.mutant_bodyparts[part] = styles[part]
		human.dna.features[part] = styles[part]
	human.update_mutant_bodyparts()
	var/list/seen = list()
	for(var/layer as anything in list(BODY_BEHIND_LAYER, BODY_ADJ_LAYER, BODY_FRONT_LAYER))
		for(var/mutable_appearance/overlay as anything in human.overlays_standing[layer])
			for(var/part as anything in colors)
				if(findtext(overlay.icon_state, "_[part]_"))
					TEST_ASSERT_EQUAL(overlay.color, "#[colors[part]]", "У [part] неверный цвет")
					seen |= part
	TEST_ASSERT_EQUAL(length(seen), length(colors), "Не все части тела отрисованы")
	var/savefile/legacy = new(fixture_path)
	legacy.cd = "/character[prefs.default_slot]"
	legacy.dir.Remove("feature_insect_fluff_color", "feature_insect_markings_color")
	legacy = null
	TEST_ASSERT(prefs.load_character(bypass_cooldown = TRUE), "Старые настройки не загружены")
	TEST_ASSERT_EQUAL(prefs.features["insect_fluff_color"], "112233", "Старый цвет пуха изменился")
	TEST_ASSERT_EQUAL(prefs.features["insect_markings_color"], "112233", "Старый цвет отметин изменился")

/// Часы выдают действия только из доступных слотов, включая смену привязок.
/datum/unit_test/clockwork_slab_storage_actions/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/obj/item/clockwork/slab/slab = allocate(/obj/item/clockwork/slab, holder)
	TEST_ASSERT(length(slab.actions), "У часов нет действий для проверки")
	for(var/datum/action/action as anything in slab.actions)
		TEST_ASSERT_NULL(action.owner, "Часы выдали действия до экипировки")
	TEST_ASSERT(holder.put_in_active_hand(slab), "Часы не взяты в руку")
	for(var/datum/action/action as anything in slab.actions)
		TEST_ASSERT_EQUAL(action.owner, holder, "У часов в руке нет действий")
	holder.dropItemToGround(slab)
	var/obj/item/storage/backpack/backpack = allocate(/obj/item/storage/backpack, holder)
	slab.forceMove(backpack)
	slab.update_quickbind()
	for(var/datum/action/action as anything in slab.actions)
		TEST_ASSERT_NULL(action.owner, "Часы в рюкзаке выдали действия")
	TEST_ASSERT(!slab.item_action_slot_check(ITEM_SLOT_BACKPACK, holder), "Действия доступны из рюкзака")
	TEST_ASSERT(slab.item_action_slot_check(ITEM_SLOT_LPOCKET, holder), "Действия недоступны из кармана")

/// Раундстартовый рулсет выдаёт ровно одни часы и один фабрикатор.
/datum/unit_test/clockwork_roundstart_equipment/Run()
	var/mob/living/carbon/human/servant = allocate(/mob/living/carbon/human)
	servant.mind_initialize()
	var/obj/item/storage/backpack/backpack = allocate(/obj/item/storage/backpack)
	TEST_ASSERT(servant.equip_to_slot_if_possible(backpack, ITEM_SLOT_BACK), "Рюкзак не надет")
	var/datum/dynamic_ruleset/roundstart/clockcult/ruleset = new
	allocated += ruleset
	ruleset.assigned = list(servant.mind)
	TEST_ASSERT(ruleset.execute(), "Рулсет не запущен")
	allocated += ruleset.main_clockcult
	TEST_ASSERT_EQUAL(length(servant.GetAllContents(/obj/item/clockwork/slab)), 1, "Выдано неверное число часов")
	TEST_ASSERT_EQUAL(length(servant.GetAllContents(/obj/item/clockwork/replica_fabricator)), 1, "Выдано неверное число фабрикаторов")
	servant.mind.remove_antag_datum(/datum/antagonist/clockcult)

/// Цель кражи не выбирается по наличию непомеченного белья.
/datum/unit_test/captain_underwear_objective/Run()
	var/mob/living/carbon/human/captain = allocate(/mob/living/carbon/human)
	captain.job = "Captain"
	var/obj/item/clothing/underwear/briefs/briefs = allocate(/obj/item/clothing/underwear/briefs)
	TEST_ASSERT(captain.equip_to_slot_if_possible(briefs, ITEM_SLOT_UNDERWEAR), "Бельё не надето")
	TEST_ASSERT(briefs.worn_by_captain, "Бельё капитана не помечено")
	var/datum/objective_item/steal/captain_panties/objective = allocate(/datum/objective_item/steal/captain_panties)
	TEST_ASSERT(objective.ExtraCheck(), "Помеченное бельё не допускает выдачу цели")
	TEST_ASSERT(objective.check_special_completion(briefs), "Помеченное бельё не завершает цель")
	briefs.worn_by_captain = FALSE
	TEST_ASSERT(!objective.ExtraCheck(), "Непомеченное бельё допускает невыполнимую цель")

#define TEST_CHANGELING_CRIT_DAMAGE 120

/// Отстрел головы сохраняет разум генокрада и после замены мозга.
/datum/unit_test/changeling_head_gib_mind/Run()
	for(var/replace_brain as anything in list(FALSE, TRUE))
		var/mob/living/carbon/human/changeling = allocate(/mob/living/carbon/human)
		changeling.mind_initialize()
		var/datum/mind/ling_mind = changeling.mind
		var/datum/antagonist/changeling/antag = new
		antag.silent = TRUE
		antag.give_objectives = FALSE
		ling_mind.add_antag_datum(antag)
		if(replace_brain)
			var/obj/item/organ/brain/replacement = allocate(/obj/item/organ/brain)
			replacement.Insert(changeling)
		changeling.setBruteLoss(TEST_CHANGELING_CRIT_DAMAGE)
		changeling.gib_head()
		TEST_ASSERT_EQUAL(ling_mind.current, changeling, "Разум генокрада покинул тело при отстреле головы; замена мозга: [replace_brain]")
		TEST_ASSERT_NULL(changeling.get_bodypart(BODY_ZONE_HEAD), "Голова осталась на теле")
		TEST_ASSERT(HAS_TRAIT(changeling, TRAIT_BLIND), "Генокрад видит после отстрела головы")
	var/mob/living/carbon/human/decapitated = allocate(/mob/living/carbon/human)
	decapitated.mind_initialize()
	var/datum/antagonist/changeling/decapitated_antag = new
	decapitated_antag.silent = TRUE
	decapitated_antag.give_objectives = FALSE
	decapitated.mind.add_antag_datum(decapitated_antag)
	var/obj/item/bodypart/head/head = decapitated.get_bodypart(BODY_ZONE_HEAD)
	head.drop_limb()
	TEST_ASSERT(HAS_TRAIT(decapitated, TRAIT_BLIND), "Генокрад видит после обезглавливания")
	head.attach_limb(decapitated)
	TEST_ASSERT(!HAS_TRAIT(decapitated, TRAIT_BLIND), "Генокрад не прозрел после возврата головы")

#undef TEST_CHANGELING_CRIT_DAMAGE

/// Пересадка через генокрада сохраняет свойства мозга и перенос разума обычного владельца.
/datum/unit_test/changeling_brain_reuse/Run()
	for(var/original_vital as anything in list(0, ORGAN_VITAL))
		for(var/original_decoy as anything in list(FALSE, TRUE))
			var/mob/living/carbon/human/changeling = allocate(/mob/living/carbon/human)
			changeling.mind_initialize()
			var/datum/mind/changeling_mind = changeling.mind
			var/datum/antagonist/changeling/antag = new
			antag.silent = TRUE
			antag.give_objectives = FALSE
			changeling_mind.add_antag_datum(antag)
			var/obj/item/organ/brain/brain = allocate(/obj/item/organ/brain)
			brain.organ_flags = original_vital
			brain.decoy_override = original_decoy
			brain.Insert(changeling)
			TEST_ASSERT_EQUAL(brain.owner, changeling, "Мозг не вставлен генокраду")
			TEST_ASSERT(!(brain.organ_flags & ORGAN_VITAL), "Мозг генокрада остался жизненно важным")
			TEST_ASSERT(brain.decoy_override, "Мозг генокрада не стал рудиментарным")
			TEST_ASSERT(!brain.Insert(changeling), "Повторная вставка в то же тело разрешена")
			brain.organ_flags |= ORGAN_NO_SPOIL
			brain.Remove()
			TEST_ASSERT_EQUAL(changeling_mind.current, changeling, "Извлечение унесло разум генокрада")
			TEST_ASSERT_NOTEQUAL(changeling.stat, DEAD, "Извлечение мозга убило генокрада")
			TEST_ASSERT_EQUAL(brain.organ_flags, original_vital | ORGAN_NO_SPOIL, "Извлечение изменило исходную важность мозга или посторонние флаги")
			TEST_ASSERT_EQUAL(brain.decoy_override, original_decoy, "Извлечение не вернуло исходный decoy_override")
			brain.Insert(changeling)
			brain.Remove(FALSE, TRUE)
			TEST_ASSERT_EQUAL(brain.organ_flags, original_vital | ORGAN_NO_SPOIL, "Повторная пересадка потеряла исходные флаги")
			TEST_ASSERT_EQUAL(brain.decoy_override, original_decoy, "Извлечение без переноса разума потеряло исходный decoy_override")
			var/mob/living/carbon/human/recipient = allocate(/mob/living/carbon/human)
			brain.Insert(recipient)
			recipient.mind_initialize()
			var/datum/mind/recipient_mind = recipient.mind
			brain.Remove()
			TEST_ASSERT_EQUAL(recipient_mind.current, original_decoy ? recipient : brain.brainmob, "Повторно использованный мозг неверно переносит разум обычного владельца")
			TEST_ASSERT_EQUAL(recipient.stat == DEAD, !!original_vital, "Важность мозга не действует после пересадки обычному владельцу")

#define TEST_MIXER_OFFSET 2
#define TEST_MIXER_LAYER 2
#define TEST_ADAPTER_OXYGEN_MOLES 10

/// Слои возле миксера остаются раздельными, а адаптер соединяет нужный порт.
/datum/unit_test/atmos_mixer_layer_adapter/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + TEST_MIXER_OFFSET, run_loc_floor_bottom_left.y + TEST_MIXER_OFFSET, run_loc_floor_bottom_left.z)
	var/obj/machinery/atmospherics/components/trinary/mixer/mixer = allocate(/obj/machinery/atmospherics/components/trinary/mixer, center)
	mixer.setDir(EAST)
	mixer.SetInitDirections()
	mixer.setPipingLayer(TEST_MIXER_LAYER)
	var/obj/machinery/atmospherics/pipe/layer_manifold/adapter = allocate(/obj/machinery/atmospherics/pipe/layer_manifold, get_step(center, WEST))
	adapter.setDir(EAST)
	adapter.SetInitDirections()
	adapter.on_construction(null, PIPING_LAYER_DEFAULT)
	mixer.atmosinit()
	TEST_ASSERT_EQUAL(mixer.nodes[1], adapter, "Адаптер не подключился ко входу миксера")
	TEST_ASSERT_EQUAL(adapter.front_nodes[TEST_MIXER_LAYER], mixer, "Адаптер не нашёл слой миксера")
	adapter.parent.ensure_built()
	TEST_ASSERT_EQUAL(mixer.parents[1], adapter.parent, "Начальное соединение не построено")
	for(var/piping_layer in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
		if(piping_layer == TEST_MIXER_LAYER)
			continue
		var/obj/machinery/atmospherics/pipe/simple/other_layer = allocate(/obj/machinery/atmospherics/pipe/simple, adapter.loc)
		other_layer.setDir(EAST)
		other_layer.SetInitDirections()
		other_layer.on_construction(null, piping_layer)
		mixer.atmosinit()
		TEST_ASSERT_EQUAL(mixer.nodes[1], adapter, "Чужой слой [piping_layer] вытеснил адаптер из миксера")
		TEST_ASSERT(!(mixer in other_layer.nodes), "Труба другого слоя подключилась к миксеру")
		other_layer.parent.ensure_built()
		TEST_ASSERT_EQUAL(mixer.parents[1], adapter.parent, "Чужой слой перехватил сеть миксера")
	adapter.build_network(TRUE)
	adapter.parent.ensure_built()
	TEST_ASSERT_EQUAL(mixer.parents[1], adapter.parent, "Адаптер и вход миксера оказались в разных сетях")
	adapter.parent.air.set_temperature(T20C)
	adapter.parent.air.adjust_moles(GAS_O2, TEST_ADAPTER_OXYGEN_MOLES)
	adapter.parent.reconcile_air()
	var/datum/gas_mixture/input_air = mixer.airs[1]
	TEST_ASSERT(input_air.get_moles(GAS_O2) > 0, "Газ не дошёл через адаптер до миксера")

#undef TEST_MIXER_OFFSET
#undef TEST_MIXER_LAYER
#undef TEST_ADAPTER_OXYGEN_MOLES
