// Общая фикстура проходит тот же путь применения ДНК, что и создание персонажа.
/datum/unit_test/supporting_tail
	var/list/saved_features
	var/list/save_paths = list()
	var/list/saved_taurs
	var/list/saved_taur_reference

/datum/unit_test/supporting_tail/Destroy()
	if(saved_features)
		GLOB.innate_features = saved_features
		saved_features = null
	if(saved_taurs)
		GLOB.taur_list = saved_taurs
		saved_taurs = null
	if(saved_taur_reference)
		GLOB.mutant_reference_list["taur"] = saved_taur_reference
		saved_taur_reference = null
	for(var/datum/preferences/prefs in allocated)
		prefs.path = null
	. = ..()
	for(var/file_path in save_paths)
		fdel(file_path)
	save_paths = null

/datum/unit_test/supporting_tail/proc/patient(style = "Naga")
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.dna.features["taur"] = style
	human.dna.features["innate_features"] = list(INNATE_NAGA_TAIL)
	human.sync_innate_features()
	return human

/datum/unit_test/supporting_tail/proc/preferences()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.pref_species = new /datum/species/human
	prefs.features["taur"] = "Naga"
	prefs.modified_limbs = list()
	prefs.all_quirks = list()
	prefs.innate_features = list()
	prefs.be_random_body = FALSE
	return prefs

/datum/unit_test/supporting_tail/proc/feature(feature_id, primary = FALSE, cost = 0)
	if(!saved_features)
		saved_features = GLOB.innate_features
		GLOB.innate_features = saved_features.Copy()
	var/datum/innate_feature/feature = allocate(/datum/innate_feature)
	feature.id = feature_id
	feature.primary = primary
	feature.quirk_cost = cost
	feature.display_name = "Тестовая особенность"
	GLOB.innate_features[feature_id] = feature
	return feature

// allocate передаёт координаты первым аргументом; прототипу операции пациент не нужен.
/datum/unit_test/supporting_tail/proc/surgery_prototype(surgery_type)
	var/datum/surgery/surgery = new surgery_type
	allocated += surgery
	return surgery

/datum/unit_test/supporting_tail/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	TEST_ASSERT(istype(tail, /obj/item/bodypart/l_leg/naga_tail), "Применение особенности создаёт опорный хвост.")
	TEST_ASSERT_EQUAL(human.get_bodypart(BODY_ZONE_R_LEG), tail, "Обе зоны указывают на один объект.")
	TEST_ASSERT_EQUAL(length(human.bodyparts), 5, "В теле нет скрытой второй ноги.")
	TEST_ASSERT_EQUAL(human.get_num_legs(FALSE), 0, "Хвост не считается физическими ногами.")
	TEST_ASSERT(!human.has_left_leg() && !human.has_right_leg(), "Проверки ступней не видят ложные ноги.")
	TEST_ASSERT_EQUAL(human.get_num_supporting_limbs(), 2, "Хвост обеспечивает полную опору.")
	TEST_ASSERT_EQUAL(length(human.get_missing_limbs()), 0, "Целый хвост не создаёт отсутствующую правую ногу.")
	TEST_ASSERT(!human.resting && CHECK_MOBILITY(human, MOBILITY_STAND), "Применение анатомии не укладывает стоящего персонажа.")

/datum/unit_test/supporting_tail/variants/Run()
	for(var/style in list("Naga", "Naga (coiled)", "Naga, Fat", "RadDog Naga (Hyper)"))
		var/mob/living/carbon/human/human = patient(style)
		TEST_ASSERT(HAS_TRAIT(human, TRAIT_NAGA_ANATOMY), "Поддерживается вариант [style].")
	var/mob/living/carbon/human/other = patient("Tentacle")
	TEST_ASSERT(!HAS_TRAIT(other, TRAIT_NAGA_ANATOMY), "Общий змеиный стиль не даёт особенность неподходящему телу.")
	TEST_ASSERT_EQUAL(other.get_num_legs(), 2, "У другого тавра сохраняются ноги.")

/datum/unit_test/supporting_tail/idempotent/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.receive_damage(brute = 18, burn = 7, wound_bonus = CANT_WOUND, can_dismember = FALSE)
	for(var/iteration in 1 to 3)
		human.sync_innate_features()
	TEST_ASSERT_EQUAL(human.get_bodypart(BODY_ZONE_L_LEG), tail, "Повторное применение не создаёт новую конечность.")
	TEST_ASSERT_EQUAL(tail.brute_dam, 18, "Синхронизация не лечит травмы.")
	TEST_ASSERT_EQUAL(tail.burn_dam, 7, "Синхронизация не лечит ожоги.")
	TEST_ASSERT_EQUAL(length(human.bodyparts), 5, "Повторное применение не накапливает хвосты.")

/datum/unit_test/supporting_tail/mind_locomotion/Run()
	var/mob/living/carbon/human/original = patient()
	original.mind_initialize()
	var/datum/mind/tail_mind = original.mind
	allocated += tail_mind
	TEST_ASSERT(HAS_TRAIT(tail_mind, TRAIT_NAGA_LOCOMOTION), "Новая личность с опорным хвостом получает хвостовую моторику.")
	var/mob/living/carbon/human/legs_body = allocate(/mob/living/carbon/human)
	legs_body.mind_initialize()
	var/datum/mind/legs_mind = legs_body.mind
	allocated += legs_mind
	tail_mind.transfer_to(legs_body)
	TEST_ASSERT_EQUAL(legs_body.get_num_legs(FALSE), 2, "Перенос разума не удаляет ноги нового тела.")
	TEST_ASSERT_EQUAL(legs_body.get_num_supporting_limbs(FALSE), 2, "Без проверки работоспособности учитываются физические ноги.")
	TEST_ASSERT_EQUAL(legs_body.get_num_supporting_limbs(), 0, "Непривычные ноги не дают личности опору для ходьбы.")
	TEST_ASSERT(!CHECK_MOBILITY(legs_body, MOBILITY_STAND), "После переноса личность сразу теряет возможность стоять на ногах.")
	TEST_ASSERT(CHECK_MOBILITY(legs_body, MOBILITY_MOVE) && (legs_body.movement_type & CRAWLING), "В новом теле сохраняется возможность ползать.")
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	var/list/scan = medical_scan_results(doctor, legs_body, TRUE)
	var/list/features = scan["innateFeatures"]
	TEST_ASSERT_EQUAL(length(features), 1, "Сканер показывает хвостовую моторику отдельно от анатомии нового тела.")
	var/list/motor_feature = features[1]
	TEST_ASSERT_EQUAL(motor_feature["id"], TRAIT_NAGA_LOCOMOTION, "Сканер объясняет личную причину невозможности ходить.")
	TEST_ASSERT(findtext(motor_feature["tooltip"], "ампутируйте обе ноги"), "Медик получает инструкцию по подготовке тела к пересадке.")
	legs_mind.transfer_to(original)
	original.mind_initialize()
	TEST_ASSERT(!HAS_TRAIT(legs_mind, TRAIT_NAGA_LOCOMOTION), "Чужая личность не наследует моторику тела с хвостом при входе в него.")
	legs_mind.transfer_to(legs_body)
	TEST_ASSERT_EQUAL(legs_body.get_num_supporting_limbs(), 2, "Владеющая ногами личность может пользоваться ими в том же теле.")
	legs_body.set_resting(FALSE, TRUE)
	TEST_ASSERT(CHECK_MOBILITY(legs_body, MOBILITY_STAND), "Замена разума снимает ограничение ходьбы без обработки Life.")
	tail_mind.transfer_to(original)
	original.set_resting(FALSE, TRUE)
	TEST_ASSERT_EQUAL(original.get_num_supporting_limbs(), 2, "После возвращения в хвостатое тело личность снова имеет опору.")
	TEST_ASSERT(CHECK_MOBILITY(original, MOBILITY_STAND), "Хвостовая моторика не мешает стоять на опорном хвосте.")
	var/mob/living/carbon/human/spawned = patient()
	var/datum/mind/spawn_mind = allocate(/datum/mind)
	spawn_mind.transfer_to(spawned)
	TEST_ASSERT(!HAS_TRAIT(spawn_mind, TRAIT_NAGA_LOCOMOTION), "Один перенос в тело с хвостом не меняет навык движения.")
	spawn_mind.set_original_character(spawned)
	TEST_ASSERT(HAS_TRAIT(spawn_mind, TRAIT_NAGA_LOCOMOTION), "Создание исходного персонажа из лобби закрепляет хвостовую моторику.")
	var/datum/preferences/prefs = preferences()
	prefs.apply_innate_features(spawned)
	TEST_ASSERT(!HAS_TRAIT(spawn_mind, TRAIT_NAGA_LOCOMOTION), "Явное снятие особенности в настройках снимает соответствующий навык.")
	TEST_ASSERT_EQUAL(spawned.get_num_supporting_limbs(), 2, "После явного снятия особенности обычные ноги снова дают опору.")

/datum/unit_test/supporting_tail/surgical_conversion/Run()
	var/mob/living/carbon/human/donor = patient("Naga, Fat")
	donor.mind_initialize()
	var/datum/mind/tail_mind = donor.mind
	allocated += tail_mind
	var/obj/item/bodypart/l_leg/naga_tail/tail = donor.get_bodypart(BODY_ZONE_L_LEG)
	tail.receive_damage(brute = 12, wound_bonus = CANT_WOUND, can_dismember = FALSE)
	tail.drop_limb()
	var/mob/living/carbon/human/recipient = allocate(/mob/living/carbon/human)
	tail_mind.transfer_to(recipient)
	recipient.Paralyze(30 SECONDS)
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	doctor.mind_initialize()
	allocated += doctor.mind
	doctor.zone_selected = BODY_ZONE_PRECISE_GROIN
	var/obj/item/surgical_drapes/drapes = allocate(/obj/item/surgical_drapes)
	var/datum/surgery/naga_tail_replacement/replacement = surgery_prototype(/datum/surgery/naga_tail_replacement)
	var/datum/surgery_step/add_prosthetic/regular_graft = allocate(/datum/surgery_step/add_prosthetic)
	TEST_ASSERT_EQUAL(regular_graft.preop(doctor, recipient, BODY_ZONE_L_LEG, tail, replacement), -1, "Опорный хвост нельзя поставить обычной операцией на одной ноге.")
	TEST_ASSERT(!replacement.can_start(doctor, recipient, drapes), "При наличии обеих ног пересадка хвоста не предлагается.")
	var/obj/item/bodypart/left = recipient.get_bodypart(BODY_ZONE_L_LEG)
	left.drop_limb()
	TEST_ASSERT(!replacement.can_start(doctor, recipient, drapes), "Одна оставшаяся нога также мешает пересадке хвоста.")
	var/obj/item/bodypart/right = recipient.get_bodypart(BODY_ZONE_R_LEG)
	right.drop_limb()
	TEST_ASSERT(replacement.can_start(doctor, recipient, drapes), "После обычной ампутации обеих ног предлагается пересадка через пах.")
	var/datum/surgery/operation = new /datum/surgery/naga_tail_replacement(recipient, BODY_ZONE_PRECISE_GROIN, recipient.get_bodypart(BODY_ZONE_CHEST))
	allocated += operation
	var/datum/surgery_step/attach_naga_tail/attach = allocate(/datum/surgery_step/attach_naga_tail)
	doctor.put_in_active_hand(tail)
	TEST_ASSERT(attach.success(doctor, recipient, BODY_ZONE_PRECISE_GROIN, tail, operation), "В новое тело пришивается хвост без актуализатора.")
	TEST_ASSERT_EQUAL(recipient.get_bodypart(BODY_ZONE_R_LEG), tail, "Пришит принесённый хвост, а не новая конечность.")
	TEST_ASSERT_EQUAL(tail.brute_dam, 12, "Переход к хвостатой анатомии сохраняет повреждения донора.")
	TEST_ASSERT(HAS_TRAIT(recipient, TRAIT_NAGA_ANATOMY), "Операция меняет анатомию тела.")
	TEST_ASSERT(INNATE_NAGA_TAIL in recipient.dna.features["innate_features"], "Хвостатая анатомия закреплена в ДНК.")
	TEST_ASSERT_EQUAL(recipient.dna.features["taur"], "Naga, Fat", "Внешность берётся с пересаженного хвоста.")
	recipient.sync_innate_features()
	TEST_ASSERT_EQUAL(recipient.get_bodypart(BODY_ZONE_L_LEG), tail, "Повторная синхронизация не пересоздаёт пришитый хвост.")
	recipient.SetParalyzed(0)
	recipient.set_resting(FALSE, TRUE)
	TEST_ASSERT(CHECK_MOBILITY(recipient, MOBILITY_STAND), "Пришитый хвост возвращает возможность стоять после наркоза.")
	var/mob/living/carbon/human/another_body = allocate(/mob/living/carbon/human)
	tail_mind.transfer_to(another_body)
	recipient.sync_innate_features()
	TEST_ASSERT_EQUAL(recipient.get_bodypart(BODY_ZONE_L_LEG), tail, "Уход разума не отменяет хирургическое изменение тела.")
	TEST_ASSERT_EQUAL(another_body.get_num_supporting_limbs(), 0, "Хвостовая моторика по-прежнему следует за личностью.")
	var/mob/living/carbon/human/empty_body = allocate(/mob/living/carbon/human)
	for(var/zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		empty_body.get_bodypart(zone).drop_limb()
	TEST_ASSERT(empty_body.can_receive_naga_tail(), "Медик может заранее подготовить безногую куклу без разума.")

/datum/unit_test/supporting_tail/limbgrower/Run()
	var/obj/machinery/limbgrower/grower = allocate(/obj/machinery/limbgrower)
	allocated += grower.stored_research
	var/datum/design/design = grower.stored_research.isDesignResearchedID("supporting_tail")
	TEST_ASSERT(istype(design), "Рецепт опорного хвоста доступен в Limb Grower без исследования.")
	TEST_ASSERT_EQUAL(design.build_path, /obj/item/bodypart/l_leg/naga_tail, "Печатается конечность, заменяющая ноги.")
	var/list/interface_data = grower.ui_static_data()
	var/found_recipe = FALSE
	for(var/list/category as anything in interface_data["categories"])
		if(category["name"] != "human")
			continue
		for(var/list/recipe as anything in category["designs"])
			if(recipe["id"] == design.id)
				found_recipe = TRUE
	TEST_ASSERT(found_recipe, "Рецепт виден в интерфейсе человеческих конечностей.")
	grower.reagents.add_reagent(/datum/reagent/medicine/synthflesh, 50)
	grower.being_built = design
	grower.build_item(design.reagents_list)
	var/obj/item/bodypart/l_leg/naga_tail/tail = locate() in get_turf(grower)
	TEST_ASSERT(istype(tail), "Limb Grower создаёт опорный хвост.")
	allocated += tail
	TEST_ASSERT_EQUAL(grower.reagents.total_volume, 0, "Печать расходует 50 единиц синтплоти.")
	TEST_ASSERT(!grower.busy, "После печати машина снова свободна.")
	TEST_ASSERT_EQUAL(tail.taur_style, "Naga", "Выращенный хвост имеет стандартную форму наги.")
	TEST_ASSERT(islist(tail.tail_item_color), "Цветовая маска хвоста получает нейтральную окраску вместо исходных цветов каналов.")
	TEST_ASSERT_EQUAL(tail.name, /obj/item/bodypart/l_leg/naga_tail::name, "Обработка обычных ног не перезаписывает название хвоста.")
	TEST_ASSERT_EQUAL(length(tail.get_limb_icon(TRUE)), 2, "Выращенный хвост отображает основу и срез.")
	var/mob/living/carbon/human/recipient = allocate(/mob/living/carbon/human)
	for(var/zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		recipient.get_bodypart(zone).drop_limb()
	TEST_ASSERT(tail.attach_limb(recipient), "Выращенный хвост можно пересадить в подготовленное тело без разума.")
	TEST_ASSERT_EQUAL(recipient.get_num_supporting_limbs(), 2, "Выращенный хвост возвращает опору.")

/datum/unit_test/supporting_tail/missing_and_regeneration/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	var/list/missing = human.get_missing_limbs()
	TEST_ASSERT_EQUAL(length(missing), 1, "Отсутствующий хвост учитывается один раз.")
	TEST_ASSERT_EQUAL(missing[1], BODY_ZONE_L_LEG, "У отсутствующего хвоста одна каноническая зона.")
	TEST_ASSERT_EQUAL(human.get_num_supporting_limbs(), 0, "Без хвоста нет опоры.")
	TEST_ASSERT(!HAS_TRAIT_FROM(human, TRAIT_HARD_SOLES, INNATE_NAGA_TAIL), "Потеря хвоста снимает его защиту ступней.")
	human.sync_innate_features()
	TEST_ASSERT_NULL(human.get_bodypart(BODY_ZONE_L_LEG), "Синхронизация не отращивает ампутированный хвост.")
	TEST_ASSERT_EQUAL(human.regenerate_limbs(), 1, "Регенерация восстанавливает одну конечность.")
	TEST_ASSERT(istype(human.get_bodypart(BODY_ZONE_R_LEG), /obj/item/bodypart/l_leg/naga_tail), "Регенерация не создаёт обычных ног.")

/datum/unit_test/supporting_tail/resting_and_reversion/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.set_resting(TRUE, TRUE)
	human.dna.features["taur"] = "Naga"
	human.dna.features["innate_features"] = list(INNATE_NAGA_TAIL)
	human.sync_innate_features()
	TEST_ASSERT(human.resting, "Выбранный отдых не отменяется заменой анатомии.")
	human.set_resting(FALSE, TRUE)
	human.dna.features["innate_features"] = list()
	human.sync_innate_features()
	TEST_ASSERT_EQUAL(human.get_num_legs(), 2, "Снятие особенности возвращает две ноги.")
	TEST_ASSERT(!HAS_TRAIT(human, TRAIT_NAGA_ANATOMY), "Снятие особенности удаляет признак анатомии.")
	TEST_ASSERT(!human.resting, "Обратная замена опоры не укладывает персонажа.")

/datum/unit_test/supporting_tail/hard_soles_sources/Run()
	var/mob/living/carbon/human/human = patient()
	ADD_TRAIT(human, TRAIT_HARD_SOLES, "ci_other_source")
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	TEST_ASSERT(HAS_TRAIT_FROM(human, TRAIT_HARD_SOLES, "ci_other_source"), "Удаление хвоста сохраняет чужой источник трейта.")
	REMOVE_TRAIT(human, TRAIT_HARD_SOLES, "ci_other_source")
	TEST_ASSERT(!HAS_TRAIT(human, TRAIT_HARD_SOLES), "Собственный источник хвоста не остаётся после отсечения.")

/datum/unit_test/supporting_tail/damage_zones/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	human.apply_damage(10, BRUTE, BODY_ZONE_L_LEG, wound_bonus = CANT_WOUND)
	human.apply_damage(15, BRUTE, BODY_ZONE_R_LEG, wound_bonus = CANT_WOUND)
	TEST_ASSERT_EQUAL(tail.brute_dam, 25, "Урон из двух зон суммируется на одном хвосте один раз.")
	TEST_ASSERT_EQUAL(human.getBruteLoss(), 25, "Суммарные травмы учитывают хвост один раз.")
	TEST_ASSERT_EQUAL(human.maxHealth - human.health, 25 * tail.body_damage_coeff, "Урон здоровью учитывает коэффициент хвоста.")
	human.get_bodypart(BODY_ZONE_R_LEG).heal_damage(10, 0)
	TEST_ASSERT_EQUAL(tail.brute_dam, 15, "Лечение через правую зону попадает в тот же хвост.")
	human.acid_act(100, 10, BODY_ZONE_R_LEG)
	TEST_ASSERT_EQUAL(tail.brute_dam, 20, "Кислота повреждает единый хвост один раз.")
	TEST_ASSERT_EQUAL(tail.burn_dam, 10, "Две зоны ног не удваивают кислотные ожоги хвоста.")

/datum/unit_test/supporting_tail/capacity_and_recovery/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	var/obj/item/bodypart/l_leg/leg = allocate(/obj/item/bodypart/l_leg)
	var/buff = tail.max_damage / (leg.max_damage * 2)
	TEST_ASSERT(buff > 1, "Хвост имеет усиление сверх суммы двух ног.")
	TEST_ASSERT_EQUAL(tail.max_stamina_damage, leg.max_stamina_damage * 2 * buff, "Запас стамины использует тот же бафф, что и прочность.")
	TEST_ASSERT_EQUAL(tail.disable_threshold, leg.disable_threshold * 2 * buff, "Порог травмы использует тот же бафф, что и прочность.")
	TEST_ASSERT_EQUAL(tail.body_damage_coeff, leg.body_damage_coeff, "Коэффициент влияния травмы на здоровье не ослаблен скрытым множителем.")
	TEST_ASSERT(abs(tail.stam_heal_tick - leg.stam_heal_tick * 2 * buff) < DAMAGE_PRECISION, "Восстановление стамины усилено согласованно с запасом.")
	tail.receive_damage(stamina = tail.stam_heal_tick * 2, wound_bonus = CANT_WOUND, can_dismember = FALSE)
	var/before = tail.stamina_dam
	tail.on_life(2, 1)
	TEST_ASSERT(abs(tail.stamina_dam - before + tail.stam_heal_tick) < DAMAGE_PRECISION, "Life действительно восстанавливает настроенный объём стамины.")

/datum/unit_test/supporting_tail/armor/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	var/obj/item/clothing/suit/armor/vest = allocate(/obj/item/clothing/suit/armor)
	var/unprotected = human.getarmor(tail, MELEE)
	vest.body_parts_covered = CHEST
	TEST_ASSERT(human.equip_to_slot_if_possible(vest, ITEM_SLOT_OCLOTHING), "Броня надевается на носителя хвоста.")
	var/protected = human.getarmor(human.get_bodypart(BODY_ZONE_R_LEG), MELEE)
	TEST_ASSERT_EQUAL(protected, unprotected + vest.armor.getRating(MELEE), "Броня тела защищает единый хвост при попадании в правую зону.")
	TEST_ASSERT_EQUAL(human.getarmor(tail, MELEE), protected, "У левой и правой зон одинаковая защита.")
	vest.clothing_flags |= THICKMATERIAL
	TEST_ASSERT_EQUAL(zone2body_parts_covered_complicated(BODY_ZONE_PRECISE_GROIN), CHEST, "Пах по-прежнему соответствует покрытию тела.")
	TEST_ASSERT_EQUAL(get_bodypart_protecting_clothing_by_coverage(human, tail), vest, "Лечение находит броню тела над хвостом.")
	for(var/zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		TEST_ASSERT(human.is_zone_covered_by_clothing(zone), "Одежда на теле закрывает хвост для инъекций: [zone].")
		TEST_ASSERT(!human.can_inject(null, FALSE, zone), "Толстая броня тела блокирует инъекции в хвост: [zone].")
		TEST_ASSERT(!get_location_accessible(human, zone), "Покрытие тела блокирует хирургический доступ к хвосту: [zone].")
	TEST_ASSERT(!get_location_accessible(human, BODY_ZONE_PRECISE_GROIN), "Одежда на теле закрывает доступ к основанию хвоста.")
	vest.body_parts_covered = GROIN
	TEST_ASSERT_EQUAL(human.getarmor(tail, MELEE), unprotected, "Отдельное покрытие паха без тела не даёт броню хвосту.")
	vest.body_parts_covered = LEGS
	TEST_ASSERT_EQUAL(human.getarmor(tail, MELEE), unprotected, "Броня только ног не защищает хвост.")
	TEST_ASSERT(!get_bodypart_protecting_clothing_by_coverage(human, tail), "Броня ног не мешает лечить хвост.")
	for(var/zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		TEST_ASSERT(!human.is_zone_covered_by_clothing(zone), "Покрытие ног не закрывает хвост для инъекций: [zone].")
		TEST_ASSERT(human.can_inject(null, FALSE, zone), "Броня ног не блокирует инъекции в хвост: [zone].")
		TEST_ASSERT(get_location_accessible(human, zone), "Броня ног не закрывает хирургический доступ к хвосту: [zone].")
	var/obj/item/clothing/under/uniform = allocate(/obj/item/clothing/under)
	uniform.limb_integrity = 1
	uniform.has_sensor = NO_SENSORS
	TEST_ASSERT(human.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING), "Форма надевается перед проверкой повреждения покрытия.")
	tail.check_woundings_mods(WOUND_SLASH, 30, 0, 0)
	TEST_ASSERT(!(uniform.body_parts_covered & CHEST), "Удар по хвосту разрывает покрытие тела.")
	TEST_ASSERT(!(uniform.body_parts_covered & GROIN), "Разрыв покрытия тела снимает и покрытие паха, как прежде.")
	TEST_ASSERT(uniform.body_parts_covered & LEG_LEFT, "Удар по хвосту не разрывает покрытие левой ноги.")
	TEST_ASSERT_EQUAL(human.getarmor(tail, MELEE), unprotected, "Разорванная форма перестаёт защищать хвост.")
	TEST_ASSERT(get_location_accessible(human, BODY_ZONE_R_LEG), "Разрыв покрытия открывает доступ к хвосту.")

/datum/unit_test/supporting_tail/fracture_and_paralysis/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.force_wound_upwards(/datum/wound/blunt/critical)
	var/datum/wound/blunt/critical/fracture = tail.get_wound_type(/datum/wound/blunt/critical)
	TEST_ASSERT_NOTNULL(fracture, "На хвост накладывается критический перелом.")
	TEST_ASSERT(!tail.disabled, "Критический перелом не отключает хвост целиком.")
	var/datum/status_effect/limp/limp = human.has_status_effect(/datum/status_effect/limp)
	TEST_ASSERT_NOTNULL(limp, "Перелом вызывает хромоту.")
	TEST_ASSERT_EQUAL(limp.slowdown_left + limp.slowdown_right, fracture.limp_slowdown, "Один хвост не удваивает штраф перелома.")
	ADD_TRAIT(human, TRAIT_PARALYSIS_R_LEG, "ci_paralysis")
	tail.update_disabled()
	TEST_ASSERT(tail.disabled, "Паралич правой зоны отключает общий хвост.")
	REMOVE_TRAIT(human, TRAIT_PARALYSIS_R_LEG, "ci_paralysis")
	tail.update_disabled()
	TEST_ASSERT(!tail.disabled, "После снятия паралича хвост снова служит опорой.")
	qdel(fracture)
	tail.force_wound_upwards(/datum/wound/blunt/moderate)
	var/datum/wound/blunt/moderate/dislocation = tail.get_wound_type(/datum/wound/blunt/moderate)
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	doctor.start_pulling(human)
	doctor.zone_selected = BODY_ZONE_R_LEG
	doctor.a_intent = INTENT_HELP
	TEST_ASSERT(dislocation.try_handling(doctor), "Выбор правой зоны позволяет начать ручное лечение вывиха хвоста.")
	doctor.stop_pulling()

/datum/unit_test/supporting_tail/jelly_cannibalism/Run()
	var/mob/living/carbon/human/human = patient()
	human.set_species(/datum/species/jelly)
	var/datum/species/jelly/species = human.dna.species
	species.Cannibalize_Body(human)
	TEST_ASSERT_NULL(human.get_bodypart(BODY_ZONE_L_LEG), "При нехватке крови желейный вид сначала поглощает хвост.")
	TEST_ASSERT(human.get_num_arms(FALSE) == 2, "Поглощение хвоста сохраняет обе руки.")
	for(var/iteration in 1 to 2)
		species.Cannibalize_Body(human)
	TEST_ASSERT_EQUAL(human.get_num_arms(FALSE), 0, "После хвоста поглощаются только существующие руки.")
	var/previous_losebreath = human.losebreath
	species.Cannibalize_Body(human)
	TEST_ASSERT_EQUAL(human.losebreath, previous_losebreath + 1, "Без конечностей начинается удушье, без обращения к несуществующей правой ноге.")

/datum/unit_test/supporting_tail/vehicle/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/vehicle/ridden/atv/vehicle = allocate(/obj/vehicle/ridden/atv)
	vehicle.buckle_mob(human, force = TRUE, check_loc = FALSE)
	TEST_ASSERT_EQUAL(human.buckled, vehicle, "Работающий хвост позволяет управлять транспортом.")
	vehicle.unbuckle_mob(human)
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	ADD_TRAIT(human, TRAIT_PARALYSIS_R_LEG, "ci_paralysis")
	tail.update_disabled()
	vehicle.buckle_mob(human, force = TRUE, check_loc = FALSE)
	TEST_ASSERT_NULL(human.buckled, "Парализованный хвост не позволяет управлять транспортом.")
	REMOVE_TRAIT(human, TRAIT_PARALYSIS_R_LEG, "ci_paralysis")
	tail.update_disabled()
	tail.drop_limb()
	vehicle.buckle_mob(human, force = TRUE, check_loc = FALSE)
	TEST_ASSERT_NULL(human.buckled, "После потери хвоста транспорт снова требует опору.")
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human)
	vehicle.buckle_mob(other, force = TRUE, check_loc = FALSE)
	TEST_ASSERT_EQUAL(other.buckled, vehicle, "Обычные ноги по-прежнему позволяют управлять транспортом.")

/datum/unit_test/supporting_tail/graft_retains_wounds/Run()
	var/mob/living/carbon/human/donor = patient("Naga, Fat")
	var/mob/living/carbon/human/recipient = patient()
	var/obj/item/bodypart/old_tail = recipient.get_bodypart(BODY_ZONE_L_LEG)
	old_tail.drop_limb()
	var/obj/item/bodypart/l_leg/naga_tail/tail = donor.get_bodypart(BODY_ZONE_L_LEG)
	tail.receive_damage(brute = 12, burn = 4, wound_bonus = CANT_WOUND, can_dismember = FALSE)
	tail.force_wound_upwards(/datum/wound/blunt/severe)
	var/datum/wound/blunt/severe/fracture = tail.get_wound_type(/datum/wound/blunt/severe)
	TEST_ASSERT_NOTNULL(fracture, "У донора есть перелом перед пересадкой.")
	tail.drop_limb()
	TEST_ASSERT(tail.attach_limb(recipient), "Повреждённый хвост можно пересадить подходящему телу.")
	TEST_ASSERT_EQUAL(tail.brute_dam, 12, "Пересадка сохраняет травмы.")
	TEST_ASSERT_EQUAL(tail.burn_dam, 4, "Пересадка сохраняет ожоги.")
	TEST_ASSERT(fracture in recipient.all_wounds, "Рана присоединяется к новому пациенту.")
	TEST_ASSERT_EQUAL(fracture.victim, recipient, "Рана больше не ссылается на донора.")
	TEST_ASSERT_EQUAL(recipient.dna.features["taur"], "Naga, Fat", "Пересадка сохраняет форму донора.")

/datum/unit_test/supporting_tail/reject_normal_legs/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	var/obj/item/bodypart/l_leg/leg = allocate(/obj/item/bodypart/l_leg)
	TEST_ASSERT(!leg.attach_limb(human), "Обычная нога не пришивается вместо хвоста.")
	TEST_ASSERT_NULL(leg.owner, "Отвергнутая нога не получает владельца.")
	var/mob/living/carbon/human/normal = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!tail.attach_limb(normal), "Хвост не пришивается телу с обычной анатомией.")

/datum/unit_test/supporting_tail/equipment/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/clothing/shoes/shoes = allocate(/obj/item/clothing/shoes)
	var/obj/item/socks = allocate(/obj/item)
	socks.slot_flags = ITEM_SLOT_SOCKS
	TEST_ASSERT(!human.equip_to_slot_if_possible(shoes, ITEM_SLOT_FEET, disable_warning = TRUE), "Обычное надевание обуви запрещено.")
	human.equip_to_slot(shoes, ITEM_SLOT_FEET)
	human.equip_to_slot(socks, ITEM_SLOT_SOCKS)
	TEST_ASSERT_NULL(human.shoes, "Низкоуровневое надевание не обходит запрет обуви.")
	TEST_ASSERT_NULL(human.w_socks, "Низкоуровневое надевание не обходит запрет носков.")

/datum/unit_test/supporting_tail/restraints/Run()
	var/mob/living/carbon/human/human = patient()
	var/mob/living/carbon/human/normal = allocate(/mob/living/carbon/human)
	var/obj/item/restraints/legcuffs/bola/bola = allocate(/obj/item/restraints/legcuffs/bola)
	var/obj/item/restraints/legcuffs/beartrap/trap = allocate(/obj/item/restraints/legcuffs/beartrap)
	TEST_ASSERT(!bola.can_apply_to_legs(human), "Бола не связывает один хвост.")
	TEST_ASSERT(bola.can_apply_to_legs(normal), "Бола по-прежнему подходит обычному человеку.")
	TEST_ASSERT(trap.can_apply_to_legs(human), "Капкан может зажать существующий хвост.")
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	TEST_ASSERT(!trap.can_apply_to_legs(human), "Без хвоста капкан не хватает пустую зону.")
	human.apply_status_effect(/datum/status_effect/bola_snared)
	TEST_ASSERT(!human.has_status_effect(/datum/status_effect/bola_snared), "Прямое наложение статуса болы также отвергается.")

/datum/unit_test/supporting_tail/mod_without_boots/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/mod/control/pre_equipped/standard/mod = allocate(/obj/item/mod/control/pre_equipped/standard)
	TEST_ASSERT(human.equip_to_slot_if_possible(mod, ITEM_SLOT_BACK), "Костюм надевается на носителя хвоста.")
	var/obj/item/boots = mod.get_boots()
	TEST_ASSERT(!(boots in mod.get_deployable_parts()), "Ботинки исключены из развёртываемых частей.")
	for(var/obj/item/part as anything in mod.get_deployable_parts())
		TEST_ASSERT(mod.deploy(human, part), "Доступная часть костюма разворачивается: [part.type].")
	TEST_ASSERT(boots.loc != human && mod.is_mod_part(boots), "Ботинки остаются свёрнутыми и принадлежат костюму.")
	TEST_ASSERT(mod.can_activate() && mod.all_parts_deployed(), "Костюм готов к включению без ботинок.")
	mod.finish_activation(TRUE)
	TEST_ASSERT(mod.is_active(), "Костюм включается без ботинок.")
	var/total_slowdown = 0
	for(var/obj/item/clothing/mod_part/part as anything in mod.get_deployable_parts())
		total_slowdown += part.slowdown
	TEST_ASSERT(abs(total_slowdown - mod.slowdown_active) < 0.001, "Штраф скорости полностью распределён по доступным частям.")
	var/obj/item/mod/module/magboot/magnets = allocate(/obj/item/mod/module/magboot)
	mod.install(magnets)
	TEST_ASSERT(!magnets.on_select(), "Ножной модуль не включается из свёрнутого ботинка.")
	TEST_ASSERT(!magnets.active, "Неудачная активация не выдаёт эффект модуля.")
	mod.finish_activation(FALSE)

/datum/unit_test/supporting_tail/surgery/Run()
	var/mob/living/carbon/human/human = patient()
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human)
	surgeon.mind_initialize()
	var/obj/item/surgical_drapes/drapes = allocate(/obj/item/surgical_drapes)
	surgeon.zone_selected = BODY_ZONE_PRECISE_GROIN
	human.Paralyze(30 SECONDS)
	var/datum/surgery/naga_tail_removal/removal = surgery_prototype(/datum/surgery/naga_tail_removal)
	var/datum/surgery/naga_tail_replacement/replacement = surgery_prototype(/datum/surgery/naga_tail_replacement)
	TEST_ASSERT(removal.can_start(surgeon, human, drapes), "Удаление предлагается при наличии хвоста.")
	TEST_ASSERT(!replacement.can_start(surgeon, human, drapes), "Второй хвост нельзя пришить поверх первого.")
	var/obj/item/bodypart/chest = human.get_bodypart(BODY_ZONE_CHEST)
	var/datum/surgery/operation = new /datum/surgery/naga_tail_removal(human, BODY_ZONE_PRECISE_GROIN, chest)
	allocated += operation
	var/datum/surgery_step/sever_naga_tail/sever = allocate(/datum/surgery_step/sever_naga_tail)
	TEST_ASSERT(sever.success(surgeon, human, BODY_ZONE_PRECISE_GROIN, null, operation), "Хирург удаляет именно хвост.")
	TEST_ASSERT_EQUAL(human.get_bodypart(BODY_ZONE_CHEST), chest, "Удаление хвоста не удаляет туловище.")
	TEST_ASSERT(!QDELETED(operation), "Отсоединение хвоста не удаляет операцию на пахе.")
	TEST_ASSERT(replacement.can_start(surgeon, human, drapes), "После удаления предлагается пересадка.")
	TEST_ASSERT(!removal.can_start(surgeon, human, drapes), "Повторно отсечь отсутствующий хвост нельзя.")
	var/obj/item/bodypart/l_leg/naga_tail/detached = locate() in get_turf(human)
	TEST_ASSERT_NOTNULL(detached, "Отделённый хвост появляется предметом на полу.")
	surgeon.put_in_active_hand(detached)
	var/datum/surgery_step/attach_naga_tail/attach = allocate(/datum/surgery_step/attach_naga_tail)
	TEST_ASSERT(attach.success(surgeon, human, BODY_ZONE_PRECISE_GROIN, detached, operation), "Хирург может пришить хвост из руки.")
	TEST_ASSERT_EQUAL(human.get_bodypart(BODY_ZONE_L_LEG), detached, "Пришит тот же хвост.")

/datum/unit_test/supporting_tail/surgery_bleeding/Run()
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human)
	for(var/preexisting_bleeding in list(0, 5))
		var/mob/living/carbon/human/human = patient()
		var/obj/item/bodypart/chest = human.get_bodypart(BODY_ZONE_CHEST)
		chest.generic_bleedstacks = preexisting_bleeding
		var/datum/surgery/operation = new /datum/surgery/naga_tail_removal(human, BODY_ZONE_PRECISE_GROIN, chest)
		allocated += operation
		for(var/step_type in operation.steps)
			var/datum/surgery_step/step = allocate(step_type)
			if(istype(step, /datum/surgery_step/close/naga_tail_removal))
				TEST_ASSERT_NULL(human.get_bodypart(BODY_ZONE_L_LEG), "Прижигание проводится после удаления хвоста.")
				TEST_ASSERT_EQUAL(chest.generic_bleedstacks, preexisting_bleeding + 4, "До закрытия разрез на оставшемся туловище ещё кровоточит.")
			TEST_ASSERT(step.success(surgeon, human, BODY_ZONE_PRECISE_GROIN, null, operation), "Этап удаления хвоста [step_type] завершается.")
		TEST_ASSERT_EQUAL(chest.generic_bleedstacks, preexisting_bleeding, "Закрытие устраняет кровотечение от операции, сохраняя прежние источники.")
		if(!preexisting_bleeding)
			TEST_ASSERT_EQUAL(chest.get_bleed_rate(), 0, "Завершённая операция не оставляет кровотечение из туловища.")
			TEST_ASSERT_NULL(chest.bleed_overlay_icon, "После закрытия исчезает оверлей хирургического кровотечения.")

/datum/unit_test/supporting_tail/surgery_parity/Run()
	var/datum/surgery/amputation/amputation = surgery_prototype(/datum/surgery/amputation)
	var/datum/surgery/prosthetic_replacement/prosthetic = surgery_prototype(/datum/surgery/prosthetic_replacement)
	var/datum/surgery/naga_tail_removal/removal = surgery_prototype(/datum/surgery/naga_tail_removal)
	var/datum/surgery/naga_tail_replacement/replacement = surgery_prototype(/datum/surgery/naga_tail_replacement)
	TEST_ASSERT_EQUAL(length(removal.steps), length(amputation.steps) + 1, "Удаление хвоста требует дополнительного закрытия разреза на туловище.")
	TEST_ASSERT_EQUAL(length(replacement.steps), length(prosthetic.steps), "Нет лишнего закрытия после пересадки.")
	for(var/index in 1 to length(amputation.steps) - 1)
		TEST_ASSERT_EQUAL(removal.steps[index], amputation.steps[index], "Подготовительные этапы удаления совпадают с ампутацией.")
	TEST_ASSERT_EQUAL(removal.steps[length(amputation.steps)], /datum/surgery_step/sever_naga_tail, "После подготовки отделяется хвост.")
	TEST_ASSERT_EQUAL(removal.steps[length(removal.steps)], /datum/surgery_step/close/naga_tail_removal, "Последний этап закрывает разрез каутером.")
	for(var/index in 1 to length(replacement.steps) - 1)
		TEST_ASSERT_EQUAL(replacement.steps[index], prosthetic.steps[index], "Подготовительные этапы пересадки совпадают с установкой конечности.")
	TEST_ASSERT_EQUAL(removal.icon_state, amputation.icon_state, "Иконка удаления совпадает с ампутацией.")
	TEST_ASSERT_EQUAL(replacement.icon_state, prosthetic.icon_state, "Иконка пересадки совпадает с установкой конечности.")
	var/datum/surgery_step/sever_naga_tail/sever = allocate(/datum/surgery_step/sever_naga_tail)
	var/datum/surgery_step/sever_limb/limb = allocate(/datum/surgery_step/sever_limb)
	TEST_ASSERT_EQUAL(sever.preop_sound, limb.preop_sound, "Сохранён звук начала отсечения.")
	TEST_ASSERT_EQUAL(sever.success_sound, limb.success_sound, "Сохранён звук завершения отсечения.")

/datum/unit_test/supporting_tail/surgery_underwear/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/underwear = allocate(/obj/item/clothing)
	underwear.body_parts_covered = CHEST | GROIN | LEGS | ARMS | HANDS | FEET
	human.w_underwear = underwear
	human.w_shirt = underwear
	human.w_socks = underwear
	human.wrists = underwear
	for(var/zone in list(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_GROIN, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_FOOT))
		TEST_ASSERT(get_location_accessible(human, zone), "Бельё, майка, носки и часы не закрывают хирургический доступ: [zone].")
	human.wrists = null
	human.w_socks = null
	human.w_shirt = null
	human.w_underwear = null
	human.w_uniform = underwear
	TEST_ASSERT(!get_location_accessible(human, BODY_ZONE_PRECISE_GROIN), "Обычная форма продолжает закрывать пах.")

/datum/unit_test/supporting_tail/medical_scan/Run()
	var/mob/living/carbon/human/human = patient()
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	var/list/data = medical_scan_results(doctor, human, TRUE)
	var/list/features = data["innateFeatures"]
	TEST_ASSERT_EQUAL(length(features), 1, "В сканер попадает применённая особенность.")
	var/list/feature = features[1]
	TEST_ASSERT_EQUAL(feature["id"], INNATE_NAGA_TAIL, "Сканер использует стабильный идентификатор.")
	TEST_ASSERT(findtext(feature["tooltip"], "паха"), "Медицинская подсказка содержит хирургический доступ.")
	TEST_ASSERT(!findtext(data["report"], "Правая нога отсутствует"), "Целый хвост не выдаёт отсутствующую ногу.")
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	data = medical_scan_results(doctor, human, TRUE)
	var/list/localization = data["damageLocalization"]
	TEST_ASSERT_EQUAL(length(localization), 1, "Сканер не дублирует отсутствующий хвост.")
	var/list/missing = localization[1]
	TEST_ASSERT_EQUAL(missing["name"], "Опорный хвост", "Сканер называет настоящую часть тела.")
	TEST_ASSERT_EQUAL(missing["missingText"], "оторван", "Сканер сообщает об оторванном хвосте.")
	TEST_ASSERT_EQUAL(length(data["innateFeatures"]), 1, "Потеря хвоста не скрывает врождённую анатомию.")

/datum/unit_test/supporting_tail/examine/Run()
	var/mob/living/carbon/human/human = patient()
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	var/text = jointext(human.examine(doctor, TRUE), "\n")
	TEST_ASSERT(findtext(text, "вместо ног опирается на хвост"), "Осмотр описывает опору на хвост.")
	TEST_ASSERT(!findtext(text, "нога отсутствует"), "При целом хвосте нет ложных ампутаций ног.")
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	text = jointext(human.examine(doctor, TRUE), "\n")
	TEST_ASSERT(findtext(text, "опорный хвост оторван"), "Осмотр сообщает о потере хвоста.")
	TEST_ASSERT(!findtext(text, "нога отсутствует"), "При потере хвоста нет двух отсутствующих ног.")

/datum/unit_test/supporting_tail/target_selector/Run()
	var/mob/living/carbon/human/human = patient()
	var/atom/movable/screen/zone_sel/selector = allocate(/atom/movable/screen/zone_sel)
	TEST_ASSERT_EQUAL(selector.get_zone_at(12, 5), BODY_ZONE_R_LEG, "На кукле прицеливания сохраняется правая нога.")
	TEST_ASSERT_EQUAL(selector.get_zone_at(19, 5), BODY_ZONE_L_LEG, "На кукле прицеливания сохраняется левая нога.")
	TEST_ASSERT_EQUAL(human.get_bodypart(selector.get_zone_at(12, 5)), human.get_bodypart(selector.get_zone_at(19, 5)), "Обе выбранные зоны поражают хвост только у соответствующей цели.")

/datum/unit_test/supporting_tail/preferences_requirements/Run()
	var/datum/preferences/prefs = preferences()
	var/datum/innate_feature/tail = GLOB.innate_features[INNATE_NAGA_TAIL]
	TEST_ASSERT(tail.available(prefs), "Подходящее тело с естественными ногами допускает особенность.")
	prefs.features["taur"] = "Tentacle"
	TEST_ASSERT(!tail.available(prefs), "Другой змеиный тавр не проходит проверку типа.")
	prefs.features["taur"] = "Naga"
	prefs.be_random_body = TRUE
	TEST_ASSERT(!tail.available(prefs), "Случайная внешность несовместима с требованием тела.")
	prefs.be_random_body = FALSE
	prefs.modified_limbs[BODY_ZONE_R_LEG] = list(LOADOUT_LIMB_AMPUTATED)
	TEST_ASSERT(!tail.available(prefs), "Ампутация в настройках несовместима с исходной анатомией.")
	prefs.modified_limbs = list()
	prefs.all_quirks = list(/datum/quirk/hard_soles::name)
	TEST_ASSERT(!tail.available(prefs), "Отдельные твёрдые ступни несовместимы с хвостом.")

/datum/unit_test/supporting_tail/preferences_primary_and_cost/Run()
	var/datum/preferences/prefs = preferences()
	var/datum/innate_feature/first = feature("ci_first", TRUE)
	var/datum/innate_feature/second = feature("ci_second", TRUE)
	var/datum/innate_feature/extra = feature("ci_extra", FALSE)
	prefs.innate_features = list(first.id)
	TEST_ASSERT(!second.available(prefs), "Нельзя выбрать вторую основную особенность.")
	TEST_ASSERT(extra.available(prefs), "Основная особенность не запрещает дополнительную.")
	var/balance = prefs.quirk_balance()
	extra.quirk_cost = 2
	prefs.innate_features += extra.id
	TEST_ASSERT_EQUAL(prefs.quirk_balance(), balance - 2, "Стоимость особенности вычитается из общего бюджета.")
	prefs.innate_features = list(first.id, second.id, extra.id, extra.id, "unknown", 123)
	prefs.sanitize_innate_features()
	TEST_ASSERT_EQUAL(length(prefs.innate_features), 2, "Санитизация убирает вторую основную, дубли и неизвестные значения.")
	TEST_ASSERT((first.id in prefs.innate_features) && (extra.id in prefs.innate_features), "Первая основная и дополнительные сохраняются.")

/datum/unit_test/supporting_tail/preferences_save/Run()
	var/datum/preferences/prefs = preferences()
	var/file_path = "data/unit_tests/[unit_test_shard_subdir()]supporting_tail_[REF(src)].sav"
	save_paths += file_path
	prefs.path = file_path
	prefs.innate_features = list(INNATE_NAGA_TAIL)
	TEST_ASSERT(prefs.save_character(bypass_cooldown = TRUE, silent = TRUE), "Настройки сохраняются в отдельный файл теста.")
	prefs.innate_features = list()
	TEST_ASSERT(prefs.load_character(bypass_cooldown = TRUE), "Сохранённый слот загружается.")
	TEST_ASSERT(INNATE_NAGA_TAIL in prefs.innate_features, "Особенность переживает сохранение и загрузку.")

/datum/unit_test/supporting_tail/colors_and_item/Run()
	var/mob/living/carbon/human/human = patient()
	human.dna.features["color_scheme"] = ADVANCED_CHARACTER_COLORING
	human.dna.features["taur_primary"] = "112233"
	human.dna.features["taur_secondary"] = "445566"
	human.dna.features["taur_tertiary"] = "778899"
	var/datum/sprite_accessory/taur/taur = GLOB.taur_list["Naga"]
	TEST_ASSERT_EQUAL(taur.get_severed_color(human, MUTCOLORS), "#112233", "Красный канал выбирает основную палитру хвоста.")
	TEST_ASSERT_EQUAL(taur.get_severed_color(human, MUTCOLORS2), "#445566", "Второй источник выбирает второй цвет.")
	TEST_ASSERT_EQUAL(taur.get_severed_color(human, MUTCOLORS3), "#778899", "Третий источник выбирает третий цвет.")
	TEST_ASSERT_NULL(taur.get_severed_color(human, NONE), "Статичный оверлей не перекрашивается.")
	var/obj/item/bodypart/l_leg/naga_tail/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	var/list/old_color = tail.tail_item_color
	TEST_ASSERT(islist(old_color), "Матричная окраска предмета хранится списком коэффициентов.")
	old_color = old_color.Copy()
	human.dna.features["taur_primary"] = "FFFFFF"
	TEST_ASSERT_EQUAL(tail.tail_item_color[1], old_color[1], "Предмет хранит снимок цвета донора.")
	TEST_ASSERT_NULL(tail.tail_item_extra_color, "Срез предмета сохраняет исходные цвета.")
	TEST_ASSERT_EQUAL(length(tail.get_limb_icon(TRUE)), 2, "Предмет отображает основу и отдельный срез.")
	var/mob/living/carbon/human/recipient = patient()
	recipient.get_bodypart(BODY_ZONE_L_LEG).drop_limb()
	TEST_ASSERT(tail.attach_limb(recipient), "Отделённый хвост пересаживается другому персонажу.")
	tail.update_limb(FALSE)
	tail.drop_limb()
	TEST_ASSERT_EQUAL(jointext(tail.tail_item_color, ";"), jointext(old_color, ";"), "Повторное отсечение сохраняет исходную палитру донора.")

/datum/unit_test/supporting_tail/asset_states/Run()
	for(var/style in list("Naga", "Naga (coiled)", "Naga, Fat", "RadDog Naga (Hyper)"))
		var/datum/sprite_accessory/taur/variant = GLOB.taur_list[style]
		var/list/body_states = icon_states(variant.icon)
		TEST_ASSERT("m_taur_[variant.severed_body_state]_ADJUP" in body_states, "Основной атлас хвоста содержит верхний слой культи для [style].")
		TEST_ASSERT("m_taur_[variant.severed_body_state]_FRONT" in body_states, "Основной атлас хвоста содержит передний слой культи для [style].")
		TEST_ASSERT("m_taur_extra_[variant.severed_body_extra_state]_FRONT" in body_states, "Основной атлас хвоста содержит срез для [style].")
	var/datum/sprite_accessory/taur/taur = GLOB.taur_list["Naga"]
	var/list/item_states = icon_states(taur.severed_item_icon)
	TEST_ASSERT(taur.severed_item_state in item_states, "В DMI существует подключённая основа предмета.")
	TEST_ASSERT(taur.severed_item_extra_state in item_states, "В DMI существует подключённый срез.")
	var/list/doll_states = icon_states(GLOB.naga_doll_icon)
	for(var/state in list("healthdoll_OVERLAY", "healthdoll_DEAD", "tail1", "tail2", "tail3", "tail4", "tail5", "tail6", "tail7"))
		TEST_ASSERT(state in doll_states, "Атлас куклы содержит состояние [state].")

/datum/unit_test/supporting_tail/proc/taur_states(mob/living/carbon/human/human)
	var/list/states = list()
	for(var/list/layer as anything in human.overlays_standing)
		if(!islist(layer))
			continue
		for(var/mutable_appearance/part as anything in layer)
			if(findtext(part.icon_state, "taur_"))
				states += part.icon_state
	return states

/datum/unit_test/supporting_tail/legacy_overlays/Run()
	saved_taurs = GLOB.taur_list
	GLOB.taur_list = saved_taurs.Copy()
	saved_taur_reference = GLOB.mutant_reference_list["taur"]
	GLOB.mutant_reference_list["taur"] = GLOB.taur_list
	var/datum/sprite_accessory/taur/naga/legacy = allocate(/datum/sprite_accessory/taur/naga)
	legacy.severed_body_state = null
	legacy.extra = TRUE
	legacy.extra2 = TRUE
	GLOB.taur_list["Naga"] = legacy
	var/mob/living/carbon/human/human = patient()
	var/list/before = taur_states(human)
	TEST_ASSERT(length(before) >= 3, "До удаления есть основной и дополнительные слои тавра.")
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	var/list/after = taur_states(human)
	TEST_ASSERT_EQUAL(jointext(after, ";"), jointext(before, ";"), "Без severed_body_state основной спрайт, extra и extra2 сохраняются.")

/datum/unit_test/supporting_tail/delete_attached/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	qdel(tail)
	TEST_ASSERT_NULL(human.get_bodypart(BODY_ZONE_R_LEG), "Удаление прикреплённого хвоста не оставляет ссылку в bodyparts.")
	TEST_ASSERT(!HAS_TRAIT_FROM(human, TRAIT_HARD_SOLES, INNATE_NAGA_TAIL), "Destroy снимает принадлежащий хвосту трейт.")
	TEST_ASSERT_EQUAL(human.get_num_supporting_limbs(), 0, "Destroy пересчитывает потерю опоры.")

/datum/unit_test/supporting_tail/preferences_copy_keeps_injuries/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.receive_damage(brute = 15, wound_bonus = CANT_WOUND, can_dismember = FALSE)
	var/datum/preferences/prefs = preferences()
	prefs.innate_features = list(INNATE_NAGA_TAIL)
	prefs.copy_to(human, icon_updates = FALSE, roundstart_checks = FALSE)
	TEST_ASSERT_EQUAL(human.get_bodypart(BODY_ZONE_L_LEG), tail, "Применение префов не пересоздаёт хвост через временно пустую ДНК.")
	TEST_ASSERT_EQUAL(tail.brute_dam, 15, "Применение префов не лечит хвост.")

/datum/unit_test/supporting_tail/preferences_incompatibilities/Run()
	var/datum/preferences/prefs = preferences()
	var/datum/innate_feature/first = feature("ci_a")
	var/datum/innate_feature/second = feature("ci_b")
	second.incompatible_features = list(first.id)
	prefs.innate_features = list(first.id)
	TEST_ASSERT(!second.available(prefs), "Несовместимость особенностей проверяется на сервере.")
	prefs.innate_features = list()
	TEST_ASSERT(second.available(prefs), "Удаление конфликта восстанавливает доступность.")
	second.required_quirks = list(/datum/quirk/hard_soles::name)
	TEST_ASSERT(!second.available(prefs), "Обязательный квирк проверяется на сервере.")
	prefs.all_quirks += /datum/quirk/hard_soles::name
	TEST_ASSERT(second.available(prefs), "Наличие обязательного квирка открывает особенность.")
	var/list/selection = list()
	for(var/index in 1 to 12)
		var/datum/innate_feature/additional = feature("ci_extra_[index]")
		selection += additional.id
	prefs.innate_features = selection
	prefs.sanitize_innate_features()
	TEST_ASSERT_EQUAL(length(prefs.innate_features), 12, "Дополнительные особенности не ограничены количеством.")

/datum/unit_test/supporting_tail/mod_normal_wearer/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/mod/control/pre_equipped/standard/mod = allocate(/obj/item/mod/control/pre_equipped/standard)
	human.equip_to_slot_if_possible(mod, ITEM_SLOT_BACK)
	TEST_ASSERT(mod.get_boots() in mod.get_deployable_parts(), "Для обычного носителя ботинки входят в набор частей.")
	for(var/obj/item/part as anything in mod.get_deployable_parts())
		if(part == mod.get_boots())
			continue
		mod.deploy(human, part)
	TEST_ASSERT(!mod.all_parts_deployed(), "Обычный носитель не может считать костюм полностью развёрнутым без ботинок.")
	TEST_ASSERT(mod.deploy(human, mod.get_boots()), "Обычный носитель разворачивает ботинки.")
	TEST_ASSERT(mod.all_parts_deployed(), "После ботинок обычный костюм готов.")
